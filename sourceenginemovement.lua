-- Full movement script (HL1/HL2 midground + Portal2 slide + Quake air features)
-- Integrates Config-style constants, air_friction, AIR_MAX_SPEED_FRIC decay, crouch, sprint.
-- GUI updated: improved layout, draggable with smoothing, buttons fully inside container

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

-- Config (merged from provided Config and tuned for HL1/HL2 midground)
local Config = {
    VISUALIZE_FEET_HB = false,
    VISUALIZE_COLLIDE_AND_SLIDE = false,
    STEP_OFFSET = 1.2,
    MASS = 16,
    AIR_FRICTION = 0.4,
    FRICTION = 6,
    GRAVITY = workspace.Gravity,
    JUMP_VELOCITY = 26,

    GROUND_ACCEL = 14,
    GROUND_DECCEL = 10,
    AIR_ACCEL = 2200,

    AIR_SPEED = 6,
    RUN_SPEED = 20,
    WALK_SPEED = 20,
    CROUCH_SPEED = 20,

    AIR_MAX_SPEED = 80,
    AIR_MAX_SPEED_FRIC = 3,
    AIR_MAX_SPEED_FRIC_DEC = 0.5,
    MIN_SLOPE_ANGLE = 40,
    MAX_SLOPE_ANGLE = 75,

    LEG_HEIGHT = 1.9 + 0.3,
    TORSO_TO_FEET = 3.1 + 1.9,
    FEET_HB_SIZE = Vector3.new(1, 0.1, 1),
    TORSO_HB_SIZE = Vector3.new(3, 1, 3),
    FOOT_OFFSET_AMOUNT = 1.2,
}

local scriptEnabled = true
local spaceHeld = false
local crouchHeld = false
local sprintHeld = false

local velocity = Vector3.new()
local isGrounded = false
local wasGrounded = false
local moveDir = Vector3.new()

local footstepTimer = 0
local footstepInterval = 0.35
local lastFootstepIndex = 0

local states = {
    air_friction = 0,
}

local rocketBlastRadius = 25

local footstepSounds = {
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
    Air = { "" },
}

local function getFloorMaterialAndTrace()
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(root.Position, Vector3.new(0, -3.8, 0), rayParams)
    if result and result.Instance then
        local floorMaterial = result.Instance.Material.Name
        if footstepSounds[floorMaterial] then
            return floorMaterial, result
        else
            return "Slate", result
        end
    end
    return "Slate", nil
end

local function playFootstep()
    local material, _ = getFloorMaterialAndTrace()
    local soundTable = footstepSounds[material]
    if not soundTable or #soundTable == 0 then return end

    lastFootstepIndex = lastFootstepIndex + 1
    if lastFootstepIndex > #soundTable then lastFootstepIndex = 1 end

    local sound = Instance.new("Sound", workspace)
    sound.SoundId = soundTable[lastFootstepIndex]
    sound.Volume = 0.6
    sound.PlaybackSpeed = 1.0 + math.random(-8, 8) / 100
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 2)
end

local function playJump()
    local material, _ = getFloorMaterialAndTrace()
    local soundTable = footstepSounds[material]
    if not soundTable or #soundTable == 0 or soundTable[1] == "" then return end

    local sound = Instance.new("Sound", workspace)
    sound.SoundId = soundTable[math.random(1, #soundTable)]
    sound.Volume = 1
    sound.PlaybackSpeed = 1.0 + math.random(-4, 4) / 100
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 2)
end

local function playLand()
    local material, _ = getFloorMaterialAndTrace()
    local soundTable = footstepSounds[material]
    if not soundTable or #soundTable == 0 or soundTable[1] == "" then return end

    local sound = Instance.new("Sound", workspace)
    sound.SoundId = soundTable[math.random(1, #soundTable)]
    sound.Volume = 1.0
    sound.PlaybackSpeed = 1.0 + math.random(-4, 4) / 100
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 2)
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local gameModes = {}

if isMobile then
    gameModes = {
        "default (mobile)",
        "no grenades (mobile)",
        "hard (mobile)"
    }
else
    gameModes = {
        "default (PC)",
        "no grenades (PC)",
        "hard (PC)"
    }
end

local currentModeIndex = 1

local function createGui()
    local g = Instance.new("ScreenGui")
    g.ResetOnSpawn = false
    g.Name = "SourceDBG"
    g.Parent = gui

    -- main panel
    local panel = Instance.new("Frame")
    panel.Name = "DBGPanel"
    panel.Size = UDim2.new(0, 260, 0, 160)
    panel.Position = UDim2.new(0, 20, 1, -200)
    panel.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    panel.BorderSizePixel = 0
    panel.Parent = g

    local corner = Instance.new("UICorner", panel)
    corner.CornerRadius = UDim.new(0, 4)

    local stroke = Instance.new("UIStroke", panel)
    stroke.Color = Color3.fromRGB(60, 60, 60)
    stroke.Thickness = 1

    -- header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 28)
    header.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    header.BorderSizePixel = 0
    header.Parent = panel

    local headerCorner = Instance.new("UICorner", header)
    headerCorner.CornerRadius = UDim.new(0, 4)

    local title = Instance.new("TextLabel", header)
    title.Size = UDim2.new(1, -10, 1, 0)
    title.Position = UDim2.new(0, 5, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "SourceDBG"
    title.TextColor3 = Color3.fromRGB(220, 220, 220)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- content area
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -10, 1, -38)
    content.Position = UDim2.new(0, 5, 0, 33)
    content.BackgroundTransparency = 1
    content.Parent = panel

    local layout = Instance.new("UIListLayout", content)
    layout.Padding = UDim.new(0, 6)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Top

    -- helper
    local function makeBtn(text, color)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 28)
        b.BackgroundColor3 = color
        b.Text = text
        b.TextColor3 = Color3.fromRGB(230, 230, 230)
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 13
        b.AutoButtonColor = true

        local bc = Instance.new("UICorner", b)
        bc.CornerRadius = UDim.new(0, 3)

        local bs = Instance.new("UIStroke", b)
        bs.Color = Color3.fromRGB(40, 40, 40)
        bs.Thickness = 1

        return b
    end

    -- destroy
    local destroy = makeBtn("DESTROY", Color3.fromRGB(150, 40, 40))
    destroy.Parent = content

    destroy.MouseButton1Click:Connect(function()
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50

        for _, c in pairs(getconnections(RunService.Heartbeat)) do
            pcall(function() c:Disconnect() end)
        end

        g:Destroy()
        scriptEnabled = false
        pcall(function() script:Destroy() end)
    end)

    -- toggle
    local toggle = makeBtn("ON", Color3.fromRGB(40, 120, 40))
    toggle.Parent = content

    toggle.MouseButton1Click:Connect(function()
        scriptEnabled = not scriptEnabled
        if scriptEnabled then
            toggle.Text = "ON"
            toggle.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        else
            toggle.Text = "OFF"
            toggle.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
            velocity = Vector3.new()
        end
    end)

    -- mode
    local modeBtn = makeBtn("Mode: " .. gameModes[currentModeIndex], Color3.fromRGB(40, 70, 140))
    modeBtn.Parent = content

    modeBtn.MouseButton1Click:Connect(function()
        currentModeIndex += 1
        if currentModeIndex > #gameModes then currentModeIndex = 1 end
        modeBtn.Text = "Mode: " .. gameModes[currentModeIndex]
    end)

    -- draggable with smoothing
    do
        local dragging = false
        local dragStart, startPos
        local target = panel.Position
        local smoothing = 0.18
        local conn

        local function update(pos)
            local delta = pos - dragStart
            target = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                               startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end

        local function begin(input)
            dragging = true
            dragStart = input.Position
            startPos = panel.Position

            if conn then conn:Disconnect() end
            conn = RunService.RenderStepped:Connect(function()
                if dragging then update(dragInput.Position) end
                panel.Position = panel.Position:Lerp(target, smoothing)
            end)
        end

        local function finish()
            dragging = false
            if conn then conn:Disconnect() end
            TweenService:Create(panel, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {Position = target}):Play()
        end

        header.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                dragInput = i
                begin(i)
            end
        end)

        UserInputService.InputChanged:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = i
            end
        end)

        UserInputService.InputEnded:Connect(function(i)
            if dragging and i.UserInputType == Enum.UserInputType.MouseButton1 then
                finish()
            end
        end)
    end
end


createGui()

task.spawn(function()
    while true do
        task.wait()
        if scriptEnabled then
            for _, sound in pairs(root:GetChildren()) do
                if sound:IsA("Sound") then sound.Volume = 0 end
            end
            for _, sound in pairs(humanoid:GetChildren()) do
                if sound:IsA("Sound") then sound.Volume = 0 end
            end
        end
    end
end)

local function grounded()
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(root.Position, Vector3.new(0, -3.8, 0), rayParams)
    if result and result.Instance then
        return result.Instance.CanCollide, result
    end
    return false, nil
end

local function ApplyFriction(dt, inAir, modifier)
    modifier = modifier or 1
    local vel = inAir and velocity or Vector3.new(velocity.X, 0, velocity.Z)
    local speed = vel.Magnitude
    if speed <= 0 then return end

    local fric = inAir and Config.AIR_FRICTION or Config.FRICTION

    local control = speed < Config.GROUND_DECCEL and Config.GROUND_DECCEL or speed
    local drop = control * fric * dt * modifier
    local newSpeed = math.max(speed - drop, 0)
    local scale = (speed > 0) and (newSpeed / speed) or 0

    vel = vel * scale

    if inAir then
        velocity = Vector3.new(vel.X, velocity.Y, vel.Z)
    else
        velocity = Vector3.new(vel.X, velocity.Y, vel.Z)
    end
end

local function Accelerate(wishDir, wishSpeed, accel, dt, maxSpeed)
    if wishSpeed <= 0 or wishDir.Magnitude == 0 then return end
    wishDir = wishDir.Unit
    local flat = Vector3.new(velocity.X, 0, velocity.Z)
    local currentSpeed = flat:Dot(wishDir)
    local addSpeed = wishSpeed - currentSpeed
    if addSpeed <= 0 then return end

    local accelSpeed = math.min(accel * dt * wishSpeed, addSpeed)
    local newFlat = flat + wishDir * accelSpeed

    if maxSpeed and maxSpeed > 0 and newFlat.Magnitude > maxSpeed then
        newFlat = newFlat.Unit * maxSpeed
    end

    velocity = Vector3.new(newFlat.X, velocity.Y, newFlat.Z)
end

local function AirControl(wishDir, dt)
    if wishDir.Magnitude == 0 then return end
    local flatVel = Vector3.new(velocity.X, 0, velocity.Z)
    local speed = flatVel.Magnitude
    if speed < 0.1 then return end

    local wish = wishDir.Unit
    local velUnit = flatVel.Unit
    local dot = velUnit:Dot(wish)
    if dot <= 0 then return end

    local k = Config.AIR_SPEED * dot * dt * (Config.AIR_ACCEL / 1000)
    local newDir = (velUnit + wish * k)
    if newDir.Magnitude == 0 then return end
    newDir = newDir.Unit
    local newFlat = newDir * speed
    velocity = Vector3.new(newFlat.X, velocity.Y, newFlat.Z)
end

local function process(dt)
    if not scriptEnabled then return end

    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0

    wasGrounded = isGrounded
    local groundTrace
    isGrounded, groundTrace = grounded()

    if isGrounded and not wasGrounded and velocity.Y < -5 and not spaceHeld then
        playLand()
        footstepTimer = 0
    end

    -- align yaw to camera
    local camLook = workspace.CurrentCamera.CFrame.LookVector
    local flatCam = Vector3.new(camLook.X, 0, camLook.Z)
    if flatCam.Magnitude > 0.01 then
        root.CFrame = CFrame.new(root.Position, root.Position + flatCam)
    end

    local cam = workspace.CurrentCamera
    local fwd = cam.CFrame.LookVector
    local right = cam.CFrame.RightVector
    fwd = Vector3.new(fwd.X, 0, fwd.Z)
    right = Vector3.new(right.X, 0, right.Z)
    if fwd.Magnitude > 0 then fwd = fwd.Unit end
    if right.Magnitude > 0 then right = right.Unit end

    local input = Vector3.new()
    if isMobile then
        local moveVector = humanoid.MoveDirection
        if moveVector.Magnitude > 0 then input = moveVector end
    else
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then input += fwd end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then input -= fwd end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then input -= right end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then input += right end
    end
    if input.Magnitude > 0 then input = input.Unit end
    moveDir = input

    -- mode adjustments
    local speedMult = sprintHeld and 1.15 or 1
    local currentMaxAirSpeed = Config.AIR_MAX_SPEED
    if gameModes[currentModeIndex] == "hard (PC)" or gameModes[currentModeIndex] == "hard (mobile)" then
        currentMaxAirSpeed = Config.AIR_MAX_SPEED * 0.35
    end

    -- movement branches
    if isGrounded then
        -- friction update
        ApplyFriction(dt, false, 1)

        local wishDir = moveDir
        local wishSpeed = Config.RUN_SPEED * speedMult * (moveDir.Magnitude > 0 and 1 or 0)
        local groundAccel = Config.GROUND_ACCEL
        Accelerate(wishDir, wishSpeed, groundAccel, dt, nil)

        if moveDir.Magnitude > 0.1 then
            footstepTimer = footstepTimer + dt
            if footstepTimer >= footstepInterval then
                playFootstep()
                footstepTimer = 0
            end
        else
            footstepTimer = 0
        end

        if spaceHeld then
            velocity = Vector3.new(velocity.X, Config.JUMP_VELOCITY, velocity.Z)
            playJump()
            isGrounded = false
        else
            velocity = Vector3.new(velocity.X, 0, velocity.Z)
        end
    else
        -- air: friction when exceeding max speed
        local flat = Vector3.new(velocity.X, 0, velocity.Z)
        local currSpeed = flat.Magnitude
        if currSpeed > Config.AIR_MAX_SPEED then
            states.air_friction = Config.AIR_MAX_SPEED_FRIC
        end

        if states.air_friction > 0 then
            ApplyFriction(dt, true, 0.01 * states.air_friction)
        end

        -- air accel & control
        local wishDir = moveDir
        local wishSpeed = Config.RUN_SPEED * speedMult * (moveDir.Magnitude > 0 and 1 or 0)
        Accelerate(wishDir, wishSpeed, Config.AIR_ACCEL, dt, currentMaxAirSpeed)
        AirControl(wishDir, dt)

        -- gravity: use Roblox workspace gravity
        velocity = velocity + Vector3.new(0, -Config.GRAVITY * dt, 0)
    end

    -- decay air_friction over time
    if states.air_friction and states.air_friction > 0 then
        local sub = Config.AIR_MAX_SPEED_FRIC_DEC * dt * 60
        states.air_friction = math.max(0, states.air_friction - sub)
    end

    -- clamp global speed
    local flat = Vector3.new(velocity.X, 0, velocity.Z)
    local flatSpeed = flat.Magnitude
    local maxGlobalSpeed = 200
    if flatSpeed > maxGlobalSpeed then
        flat = flat.Unit * maxGlobalSpeed
        velocity = Vector3.new(flat.X, velocity.Y, flat.Z)
    end

    -- apply to root
    if root and root:IsA("BasePart") then
        root.AssemblyLinearVelocity = velocity
    end
end

-- input handlers
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.Space then
        spaceHeld = true
    elseif i.KeyCode == Enum.KeyCode.LeftControl or i.KeyCode == Enum.KeyCode.RightControl then
        crouchHeld = true
    elseif i.KeyCode == Enum.KeyCode.LeftShift or i.KeyCode == Enum.KeyCode.RightShift then
        sprintHeld = true
    elseif i.KeyCode == Enum.KeyCode.X and scriptEnabled and not isMobile then
        local currentMode = gameModes[currentModeIndex]
        if currentMode == "no grenades (PC)" or currentMode == "no grenades (mobile)" or
           currentMode == "hard (PC)" or currentMode == "hard (mobile)" then
            return
        end

        local cam = workspace.CurrentCamera
        local direction = cam.CFrame.LookVector
        local startPos = root.Position + direction * 3

        local rocket = Instance.new("Part")
        rocket.Name = "Rocket"
        rocket.Size = Vector3.new(0.5, 0.5, 2)
        rocket.BrickColor = BrickColor.new("Really red")
        rocket.Material = Enum.Material.Neon
        rocket.Anchored = false
        rocket.CanCollide = false
        rocket.CFrame = CFrame.lookAt(startPos, startPos + direction)
        rocket.Parent = workspace

        local attachment0 = Instance.new("Attachment", rocket)
        attachment0.Position = Vector3.new(0, 0, -1)
        local attachment1 = Instance.new("Attachment", rocket)
        local trail = Instance.new("Trail", rocket)
        trail.Attachment0 = attachment0
        trail.Attachment1 = attachment1
        trail.Color = ColorSequence.new(Color3.fromRGB(255, 165, 0))
        trail.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        }
        trail.Lifetime = 0.3
        trail.MinLength = 0

        rocket.AssemblyLinearVelocity = direction * 150

        local explodeSound = Instance.new("Sound")
        explodeSound.SoundId = "rbxassetid://90586353104830"
        explodeSound.Volume = 0.2
        explodeSound.PlaybackSpeed = 1

        local shootSound = Instance.new("Sound", root)
        shootSound.SoundId = "rbxassetid://2156366946"
        shootSound.Volume = 1.0
        shootSound.PlaybackSpeed = 1.0
        shootSound:Play()
        game.Debris:AddItem(shootSound, 2)

        local connection
        connection = rocket.Touched:Connect(function(hit)
            if hit and not hit:IsDescendantOf(character) then
                local explosionPos = rocket.Position
                local dist = (root.Position - explosionPos).Magnitude
                local shouldPush = dist <= rocketBlastRadius

                explodeSound.Parent = workspace
                explodeSound:Play()
                game.Debris:AddItem(explodeSound, 2)

                local explosion = Instance.new("Explosion")
                explosion.Position = explosionPos
                explosion.BlastPressure = 0
                explosion.BlastRadius = rocketBlastRadius
                explosion.Parent = workspace

                if shouldPush then
                    local dir = (root.Position - explosionPos).Unit
                    local forceMagnitude = 80
                    velocity = velocity + dir * forceMagnitude
                end

                rocket:Destroy()
                connection:Disconnect()
            end
        end)

        game.Debris:AddItem(rocket, 5)
    end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.Space then spaceHeld = false end
    if i.KeyCode == Enum.KeyCode.LeftControl or i.KeyCode == Enum.KeyCode.RightControl then crouchHeld = false end
    if i.KeyCode == Enum.KeyCode.LeftShift or i.KeyCode == Enum.KeyCode.RightShift then sprintHeld = false end
end)

RunService.Heartbeat:Connect(function(dt)
    if humanoid and humanoid.Health > 0 then
        process(dt)
    end
end)

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")
    velocity = Vector3.new()
    states.air_friction = 0
end)

print("Movement script loaded: HL1/HL2 midground + Portal2 slide + Quake air features (surfing and sliding removed, GUI improved, draggable)")
