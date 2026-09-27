-- HL1/HL2 midground movement (NO surfing, NO sliding, uses Roblox humanoid height)
-- Anti-sinking measures: use root.Velocity, substepping, and sweep raycasts before applying movement.
-- Added animation handling: walk animation playback speed is increased while walking.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

-- Config (surf + slide removed)
local Config = {
    AIR_FRICTION = 0.4,
    FRICTION = 6,
    GRAVITY = 80,
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

    -- anti-tunneling
    MAX_STEP_DISPLACEMENT = 1.0, -- studs per substep (reduce to avoid tunneling)
    MAX_SUBSTEPS = 6,             -- max substeps per frame

    -- animation
    WALK_ANIM_ID = "rbxassetid://507766666", -- placeholder: replace with your walk animation asset
    IDLE_ANIM_ID = "rbxassetid://507777826", -- placeholder: replace with your idle animation asset
    JUMP_ANIM_ID = "rbxassetid://507777860", -- placeholder: replace with your jump animation asset

    -- how fast the walk animation should play when walking (simulate laggy/fast stepping)
    WALK_PLAYBACK_SPEED = 4.0, -- increase for more "fast/laggy" look
    IDLE_PLAYBACK_SPEED = 1.0,
    JUMP_PLAYBACK_SPEED = 1.0,
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

-- Footstep sounds (unchanged)
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

    local result = workspace:Raycast(root.Position, Vector3.new(0, -4, 0), rayParams)
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

-- GUI creation (kept minimal here; original GUI code can be reinserted)
local function createGui()
    -- minimal GUI to avoid errors if original GUI removed
    local ok, _ = pcall(function()
        local g = Instance.new("ScreenGui")
        g.ResetOnSpawn = false
        g.Name = "SourceDBG"
        g.Parent = gui
        g.Enabled = false
    end)
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

-- Grounded using humanoid state + raycast for material detection
local function grounded()
    -- Use humanoid's floor material as primary grounded indicator
    return humanoid.FloorMaterial ~= Enum.Material.Air
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

    velocity = Vector3.new(vel.X, velocity.Y, vel.Z)
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

-- Sweep test helper: returns hit result if a raycast from start to end hits something (excluding character)
local function sweepTest(startPos, endPos)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    return workspace:Raycast(startPos, endPos - startPos, rayParams)
end

-- Apply movement with substepping and sweep tests to avoid tunneling/sinking
local function applyMovementWithSafety(dt)
    -- compute intended displacement this frame
    local intendedDisp = velocity * dt
    local dispMag = intendedDisp.Magnitude

    -- determine substeps based on max allowed displacement
    local maxDisp = Config.MAX_STEP_DISPLACEMENT
    local steps = 1
    if dispMag > maxDisp and maxDisp > 0 then
        steps = math.clamp(math.ceil(dispMag / maxDisp), 1, Config.MAX_SUBSTEPS)
    end

    -- perform substeps: for each substep, do a sweep test and adjust velocity if collision ahead
    for i = 1, steps do
        if not root or not root:IsA("BasePart") then break end

        local stepVel = velocity / steps
        local stepDisp = stepVel * dt

        -- small safety raycast from current root position to next position
        local from = root.Position
        local to = from + stepDisp

        local hit = sweepTest(from, to)
        if hit and hit.Instance then
            -- collision detected in this substep: zero horizontal components that would penetrate
            -- project velocity onto hit normal and remove the component into the surface
            local normal = hit.Normal or Vector3.new(0, 1, 0)
            local velVec = Vector3.new(velocity.X, velocity.Y, velocity.Z)
            -- remove component along normal
            local into = normal * velVec:Dot(normal)
            local corrected = velVec - into
            -- keep vertical velocity if moving away from surface; if into surface on Y, zero Y
            if velVec.Y < 0 and normal.Y > 0.5 then
                corrected = Vector3.new(corrected.X, 0, corrected.Z)
            end
            velocity = corrected
            -- after correction, stop further substeps to let physics resolve
            break
        else
            -- no collision: continue
        end
    end

    -- finally apply velocity using root.Velocity (plays nicer with Roblox solver)
    if root and root:IsA("BasePart") then
        -- clamp very large velocities to avoid huge per-frame displacement
        local flat = Vector3.new(velocity.X, 0, velocity.Z)
        local maxGlobalSpeed = 200
        if flat.Magnitude > maxGlobalSpeed then
            flat = flat.Unit * maxGlobalSpeed
            velocity = Vector3.new(flat.X, velocity.Y, flat.Z)
        end

        -- set velocity
        root.Velocity = velocity
    end
end

-- Animation setup
local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then
    animator = Instance.new("Animator")
    animator.Parent = humanoid
end

local walkAnim = Instance.new("Animation")
walkAnim.Name = "DBG_Walk"
walkAnim.AnimationId = Config.WALK_ANIM_ID

local idleAnim = Instance.new("Animation")
idleAnim.Name = "DBG_Idle"
idleAnim.AnimationId = Config.IDLE_ANIM_ID

local jumpAnim = Instance.new("Animation")
jumpAnim.Name = "DBG_Jump"
jumpAnim.AnimationId = Config.JUMP_ANIM_ID

local walkTrack = animator:LoadAnimation(walkAnim)
local idleTrack = animator:LoadAnimation(idleAnim)
local jumpTrack = animator:LoadAnimation(jumpAnim)

-- ensure tracks loop appropriately
walkTrack.Looped = true
idleTrack.Looped = true
jumpTrack.Looped = false

-- helper to play/stop tracks and set playback speed
local function playTrack(track, speed)
    if not track then return end
    if track.IsPlaying then
        track:AdjustSpeed(speed or 1)
    else
        track:Play()
        track:AdjustSpeed(speed or 1)
    end
end

local function stopTrack(track)
    if track and track.IsPlaying then
        track:Stop()
    end
end

-- state for animation
local animState = {
    current = "idle" -- "idle", "walk", "jump"
}

local function updateAnimation()
    -- priority: jump > walk > idle
    if not humanoid or humanoid.Health <= 0 then
        stopTrack(walkTrack); stopTrack(idleTrack); stopTrack(jumpTrack)
        return
    end

    if not isGrounded then
        -- jumping/falling
        if animState.current ~= "jump" then
            stopTrack(walkTrack)
            stopTrack(idleTrack)
            playTrack(jumpTrack, Config.JUMP_PLAYBACK_SPEED)
            animState.current = "jump"
        end
    else
        -- grounded
        if moveDir.Magnitude > 0.1 then
            -- walking/running: play walk with sped-up playback
            if animState.current ~= "walk" then
                stopTrack(idleTrack)
                stopTrack(jumpTrack)
                playTrack(walkTrack, Config.WALK_PLAYBACK_SPEED)
                animState.current = "walk"
            else
                -- already walking: ensure playback speed is set
                walkTrack:AdjustSpeed(Config.WALK_PLAYBACK_SPEED)
            end
        else
            -- idle
            if animState.current ~= "idle" then
                stopTrack(walkTrack)
                stopTrack(jumpTrack)
                playTrack(idleTrack, Config.IDLE_PLAYBACK_SPEED)
                animState.current = "idle"
            else
                idleTrack:AdjustSpeed(Config.IDLE_PLAYBACK_SPEED)
            end
        end
    end
end

local function process(dt)
    if not scriptEnabled then return end

    -- disable default humanoid movement so we can control movement via velocity
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0

    wasGrounded = isGrounded
    isGrounded = grounded()

    if isGrounded and not wasGrounded and velocity.Y < -5 and not spaceHeld then
        playLand()
        footstepTimer = 0
    end

    -- align yaw to camera (only orientation, not position)
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
    if gameModes[currentModeIndex]:find("hard") then
        currentMaxAirSpeed = Config.AIR_MAX_SPEED * 0.35
    end

    -- movement
    if isGrounded then
        ApplyFriction(dt, false)

        local wishDir = moveDir
        local wishSpeed = Config.RUN_SPEED * speedMult * (moveDir.Magnitude > 0 and 1 or 0)
        Accelerate(wishDir, wishSpeed, Config.GROUND_ACCEL, dt, nil)

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
            -- keep vertical velocity zero while grounded to avoid fighting the solver
            velocity = Vector3.new(velocity.X, 0, velocity.Z)
        end
    else
        local flat = Vector3.new(velocity.X, 0, velocity.Z)
        local currSpeed = flat.Magnitude
        if currSpeed > Config.AIR_MAX_SPEED then
            states.air_friction = Config.AIR_MAX_SPEED_FRIC
        end

        if states.air_friction > 0 then
            ApplyFriction(dt, true, 0.01 * states.air_friction)
        end

        local wishDir = moveDir
        local wishSpeed = Config.RUN_SPEED * speedMult * (moveDir.Magnitude > 0 and 1 or 0)
        Accelerate(wishDir, wishSpeed, Config.AIR_ACCEL, dt, currentMaxAirSpeed)
        AirControl(wishDir, dt)

        velocity = velocity + Vector3.new(0, -Config.GRAVITY * dt, 0)
    end

    if states.air_friction > 0 then
        local sub = Config.AIR_MAX_SPEED_FRIC_DEC * dt * 60
        states.air_friction = math.max(0, states.air_friction - sub)
    end

    -- apply movement with safety checks to avoid tunneling/sinking
    applyMovementWithSafety(dt)

    -- update animation state after movement decisions
    updateAnimation()
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
        if currentMode:find("no grenades") or currentMode:find("hard") then
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

        rocket.Velocity = direction * 150

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
                    local dir = (root.Position - explosionPos)
                    if dir.Magnitude > 0 then
                        dir = dir.Unit
                        local forceMagnitude = 80
                        velocity = velocity + dir * forceMagnitude
                    end
                end

                rocket:Destroy()
                if connection then
                    connection:Disconnect()
                end
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
        -- clamp dt to avoid huge physics steps (helps stability)
        local safeDt = math.clamp(dt, 0, 1/30)
        process(safeDt)
    end
end)

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    root = char:WaitForChild("HumanoidRootPart")
    -- reattach animator and reload animations for new character
    animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    walkTrack = animator:LoadAnimation(walkAnim)
    idleTrack = animator:LoadAnimation(idleAnim)
    jumpTrack = animator:LoadAnimation(jumpAnim)
    walkTrack.Looped = true
    idleTrack.Looped = true
    jumpTrack.Looped = false

    velocity = Vector3.new()
    states.air_friction = 0
end)

print("Movement script loaded: HL1/HL2 midground (surfing and sliding removed). Walk animation playback sped up for fast/laggy look.")
