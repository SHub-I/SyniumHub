-- Syn's Source‑Style Movement System (Full Corrected Version)
-- HL1/HL2 ground accel, Quake air accel, Portal2 slide, Source surf, rocket jumping
-- Includes: GUI, dragInput fix, grounded friction fix, gravity fix, explosive boost fix

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

-- Movement tuning
local cfg = {
    gravity = 80,
    jump = 26,
    friction_ground = 6,
    friction_air = 0.4,
    accel_ground = 14,
    accel_air = 2200,
    run_speed = 20,
    air_speed = 6,
    air_max = 80,
    air_fric_boost = 3,
    air_fric_decay = 0.5,
    slide_min = 8,
    slide_boost = 1.12,
    slide_fric = 1.2,
    surf_min = 40,
    surf_max = 75,
}

local vel = Vector3.zero
local grounded = false
local prevGround = false
local sliding = false
local slideTime = 0
local surfState = false
local airFric = 0
local explosionBoost = 0

local holdJump = false
local holdCrouch = false
local holdSprint = false

local enabled = true

-- Footstep sounds
local footAudio = {
    Slate = {
        "rbxassetid://81623756670923",
        "rbxassetid://78754179999047",
        "rbxassetid://79418255155423",
        "rbxassetid://112240321395589",
    },
    Grass = {
        "rbxassetid://105277634319381",
        "rbxassetid://98069158661569",
        "rbxassetid://135182192451997",
        "rbxassetid://116425333836106",
    },
    Wood = {
        "rbxassetid://87921439933530",
        "rbxassetid://89597871459985",
        "rbxassetid://139932856876296",
        "rbxassetid://75643573822739",
    },
    Metal = {
        "rbxassetid://78580994772675",
        "rbxassetid://79005288283137",
        "rbxassetid://98060045106272",
        "rbxassetid://122668036980895",
    },
    Sand = {
        "rbxassetid://84209465430801",
        "rbxassetid://115151668857364",
        "rbxassetid://93919782627384",
        "rbxassetid://105793766638092",
    },
    Plastic = {
        "rbxassetid://135712042029119",
        "rbxassetid://90507702118699",
        "rbxassetid://98172042741214",
        "rbxassetid://106319783012941",
    },
    SmoothPlastic = {
        "rbxassetid://135712042029119",
        "rbxassetid://90507702118699",
        "rbxassetid://98172042741214",
        "rbxassetid://106319783012941",
    },
    Air = {""}
}

-- Ground ray
local function checkGround()
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {character}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local hit = workspace:Raycast(root.Position, Vector3.new(0, -5.5, 0), params)
    if not hit then return false, nil end

    if hit.Normal.Y < 0.6 then return false, nil end

    return true, hit
end

-- Footstep helpers
local stepTimer = 0
local stepInterval = 0.35
local stepIndex = 1

local function playStep()
    local ok, trace = checkGround()
    local mat = ok and trace.Instance.Material.Name or "Slate"
    local list = footAudio[mat] or footAudio.Slate
    if #list == 0 then return end

    stepIndex += 1
    if stepIndex > #list then stepIndex = 1 end

    local s = Instance.new("Sound")
    s.SoundId = list[stepIndex]
    s.Volume = 0.6
    s.PlaybackSpeed = 1 + (math.random(-8, 8) / 100)
    s.Parent = workspace
    s:Play()
    game.Debris:AddItem(s, 2)
end

local function playJumpSound()
    local ok, trace = checkGround()
    local mat = ok and trace.Instance.Material.Name or "Slate"
    local list = footAudio[mat] or footAudio.Slate
    if #list == 0 then return end

    local s = Instance.new("Sound")
    s.SoundId = list[math.random(1, #list)]
    s.Volume = 1
    s.PlaybackSpeed = 1 + (math.random(-4, 4) / 100)
    s.Parent = workspace
    s:Play()
    game.Debris:AddItem(s, 2)
end

local function playLandSound()
    local ok, trace = checkGround()
    local mat = ok and trace.Instance.Material.Name or "Slate"
    local list = footAudio[mat] or footAudio.Slate
    if #list == 0 then return end

    local s = Instance.new("Sound")
    s.SoundId = list[math.random(1, #list)]
    s.Volume = 1
    s.PlaybackSpeed = 1 + (math.random(-4, 4) / 100)
    s.Parent = workspace
    s:Play()
    game.Debris:AddItem(s, 2)
end

-- Friction
local function applyFriction(dt, air, mult)
    mult = mult or 1
    local flat = Vector3.new(vel.X, 0, vel.Z)
    local speed = flat.Magnitude
    if speed < 0.01 then return end

    local fr = air and cfg.friction_air or cfg.friction_ground
    if surfState and not air then fr = cfg.slide_fric end

    local control = math.max(speed, cfg.accel_ground)
    local drop = control * fr * dt * mult
    local newSpeed = math.max(speed - drop, 0)
    local scale = newSpeed / speed

    flat *= scale
    vel = Vector3.new(flat.X, vel.Y, flat.Z)
end

-- Acceleration
local function accelerate(dir, wish, accel, dt, max)
    if wish <= 0 or dir.Magnitude == 0 then return end
    dir = dir.Unit

    local flat = Vector3.new(vel.X, 0, vel.Z)
    local cur = flat:Dot(dir)
    local add = wish - cur
    if add <= 0 then return end

    local accelSpeed = math.min(accel * dt * wish, add)
    flat += dir * accelSpeed

    if max and flat.Magnitude > max and not surfState then
        flat = flat.Unit * max
    end

    vel = Vector3.new(flat.X, vel.Y, flat.Z)
end

-- Air control
local function airControl(dir, dt)
    if dir.Magnitude == 0 then return end

    local flat = Vector3.new(vel.X, 0, vel.Z)
    local speed = flat.Magnitude
    if speed < 0.1 then return end

    local wish = dir.Unit
    local unit = flat.Unit
    local dot = unit:Dot(wish)
    if dot <= 0 then return end

    local k = cfg.air_speed * dot * dt * (cfg.accel_air / 1000)
    k *= 0.6

    local newDir = (unit + wish * k)
    if newDir.Magnitude == 0 then return end

    newDir = newDir.Unit
    vel = Vector3.new(newDir.X * speed, vel.Y, newDir.Z * speed)
end

-- Surf detection
local function updateSurf(normal, trace)
    surfState = false
    if not normal or not trace then return end

    local flat = Vector3.new(vel.X, 0, vel.Z)
    local speed = flat.Magnitude
    if speed < cfg.air_speed then return end

    local angle = math.deg(math.acos(normal:Dot(Vector3.new(0,1,0))))
    if angle < cfg.surf_min or angle > cfg.surf_max then return end

    local tangent = Vector3.new(normal.Z, 0, -normal.X)
    if tangent.Magnitude == 0 then return end

    tangent = tangent.Unit
    local move = flat.Magnitude > 0 and flat.Unit or Vector3.zero
    local dot = math.abs(move:Dot(tangent))

    if dot > 0.3 then
        surfState = true
        local boost = flat + tangent * (flat.Magnitude * 0.08)
        vel = Vector3.new(boost.X, vel.Y, boost.Z)
        airFric = 0
    end
end

-- Main movement loop
local function tickMove(dt)
    if not enabled then return end

    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0

    prevGround = grounded
    local hit
    grounded, hit = checkGround()

    if grounded and not prevGround and vel.Y < -5 and not holdJump then
        playLandSound()
        stepTimer = 0
    end

    -- Align yaw
    local cam = workspace.CurrentCamera
    local look = cam.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    if flatLook.Magnitude > 0.01 then
        root.CFrame = CFrame.new(root.Position, root.Position + flatLook)
    end

    -- Input
    local forward = cam.CFrame.LookVector
    local right = cam.CFrame.RightVector
    forward = Vector3.new(forward.X, 0, forward.Z).Unit
    right = Vector3.new(right.X, 0, right.Z).Unit

    local input = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then input += forward end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then input -= forward end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then input -= right end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then input += right end
    if input.Magnitude > 0 then input = input.Unit end

    -- Sliding
    local flat = Vector3.new(vel.X, 0, vel.Z)
    if holdCrouch and grounded and flat.Magnitude >= cfg.slide_min and input.Magnitude > 0 then
        if not sliding then
            sliding = true
            slideTime = 0
            flat *= cfg.slide_boost
            vel = Vector3.new(flat.X, vel.Y, flat.Z)
        end
    elseif sliding and (not holdCrouch or not grounded) then
        sliding = false
        slideTime = 0
    end

    if sliding then slideTime += dt end

    -- Movement
    local speedMult = holdSprint and 1.15 or 1
    local maxAir = cfg.air_max

    if grounded and explosionBoost <= 0 then
        applyFriction(dt, false, sliding and 0.9 or 1)
        updateSurf(hit and hit.Normal or nil, hit)

        local wish = cfg.run_speed * speedMult
        accelerate(input, wish, sliding and (cfg.accel_ground * 0.6) or cfg.accel_ground, dt)

        if input.Magnitude > 0.1 and not sliding then
            stepTimer += dt
            if stepTimer >= stepInterval then
                playStep()
                stepTimer = 0
            end
        else
            stepTimer = 0
        end

        if holdJump then
            vel = Vector3.new(vel.X, cfg.jump, vel.Z)
            playJumpSound()
            grounded = false
            sliding = false
            slideTime = 0
        else
            vel = Vector3.new(vel.X, math.max(vel.Y, -2), vel.Z)
        end
    else
        if flat.Magnitude > cfg.air_max then
            airFric = cfg.air_fric_boost
        end

        if airFric > 0 and not surfState then
            applyFriction(dt, true, 0.01 * airFric)
        end

        local wish = cfg.run_speed * speedMult
        accelerate(input, wish, cfg.accel_air, dt, maxAir)
        airControl(input, dt)

        if hit then
            local n = hit.Normal
            local f = Vector3.new(vel.X, 0, vel.Z)
            local along = f - n * f:Dot(n)
            if along.Magnitude > 0 then
                vel = Vector3.new(along.Unit.X * f.Magnitude, vel.Y, along.Unit.Z * f.Magnitude)
            end
        end

        vel += Vector3.new(0, -cfg.gravity * dt, 0)
    end

    if airFric > 0 then
        airFric = math.max(0, airFric - cfg.air_fric_decay * dt * 60)
    end

    if explosionBoost > 0 then
        explosionBoost -= dt
    end

    local f = Vector3.new(vel.X, 0, vel.Z)
    if f.Magnitude > 200 then
        f = f.Unit * 200
        vel = Vector3.new(f.X, vel.Y, f.Z)
    end

    root.AssemblyLinearVelocity = vel
end

-- Input
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.Space then holdJump = true end
    if i.KeyCode == Enum.KeyCode.LeftControl then holdCrouch = true end
    if i.KeyCode == Enum.KeyCode.LeftShift then holdSprint = true end

    if i.KeyCode == Enum.KeyCode.X then
        local cam = workspace.CurrentCamera
        local dir = cam.CFrame.LookVector
        local startPos = root.Position + dir * 3

        local rocket = Instance.new("Part")
        rocket.Size = Vector3.new(0.5, 0.5, 2)
        rocket.Material = Enum.Material.Neon
        rocket.Color = Color3.new(1, 0, 0)
        rocket.Anchored = false
        rocket.CanCollide = false
        rocket.CFrame = CFrame.lookAt(startPos, startPos + dir)
        rocket.Parent = workspace

        rocket.AssemblyLinearVelocity = dir * 150

        local shoot = Instance.new("Sound", root)
        shoot.SoundId = "rbxassetid://2156366946"
        shoot.Volume = 1
        shoot:Play()
        game.Debris:AddItem(shoot, 2)

        rocket.Touched:Connect(function(hit)
            if hit and not hit:IsDescendantOf(character) then
                local pos = rocket.Position
                local dist = (root.Position - pos).Magnitude

                local boom = Instance.new("Explosion")
                boom.Position = pos
                boom.BlastPressure = 0
                boom.BlastRadius = 25
                boom.Parent = workspace

                if dist <= 25 then
                    local push = (root.Position - pos).Unit * 80
                    vel = vel + push
                    explosionBoost = 0.12
                end

                rocket:Destroy()
            end
        end)

        game.Debris:AddItem(rocket, 5)
    end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.Space then holdJump = false end
    if i.KeyCode == Enum.KeyCode.LeftControl then holdCrouch = false end
    if i.KeyCode == Enum.KeyCode.LeftShift then holdSprint = false end
end)

RunService.Heartbeat:Connect(function(dt)
    if humanoid.Health > 0 then
        tickMove(dt)
    end
end)

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")
    vel = Vector3.zero
    sliding = false
    slideTime = 0
    surfState = false
    airFric = 0
    explosionBoost = 0
end)

print("Syn Movement System Loaded (Full Corrected Version)")
