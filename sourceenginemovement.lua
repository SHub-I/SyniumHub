-- Full movement script (HL1/HL2 midground + Portal2 slide + Quake air + Source surf features)
-- Integrates Config-style constants, air_friction, AIR_MAX_SPEED_FRIC decay, surfing, sliding, crouch, sprint.
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
    GRAVITY = 80,
    JUMP_VELOCITY = 26,

    GROUND_ACCEL = 14,
    GROUND_DECCEL = 10,
    AIR_ACCEL = 2200,

    AIR_SPEED = 6,
    RUN_SPEED = 25,
    WALK_SPEED = 25,
    CROUCH_SPEED = 25,

    AIR_MAX_SPEED = 36.5,
    AIR_MAX_SPEED_FRIC = 3,
    AIR_MAX_SPEED_FRIC_DEC = 0.5,
    MIN_SLOPE_ANGLE = 40,
    MAX_SLOPE_ANGLE = 75,

    LEG_HEIGHT = 1.9 + 0.3,
    TORSO_TO_FEET = 3.1 + 1.9,
    FEET_HB_SIZE = Vector3.new(1, 0.1, 1),
    TORSO_HB_SIZE = Vector3.new(3, 1, 3),
    FOOT_OFFSET_AMOUNT = 1.2,

    SLIDE_FRICTION = 1.2,
    SLIDE_BOOST = 1.12,
    SLIDE_MIN_SPEED = 8,
    SLIDE_DURATION = 0.9,
    SURF_INFLUENCE = 0.6,
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

local sliding = false
local slideTimer = 0
local states = {
    air_friction = 0,
    surfing = false,
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

-- GUI (improved, draggable, smoothing, buttons fully inside)
local function createGui()
    local g = Instance.new("ScreenGui")
    g.ResetOnSpawn = false
    g.Name = "SourceDBG"
    g.Parent = gui

-- container
local container = Instance.new("Frame")
container.Name = "DBGContainer"
container.Size = UDim2.new(0, 240, 0, 140)
container.Position = UDim2.new(0, 12, 1, -20)
container.AnchorPoint = Vector2.new(0, 1)
container.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
container.BorderSizePixel = 0
container.Parent = g

local containerCorner = Instance.new("UICorner", container)
containerCorner.CornerRadius = UDim.new(0, 8)

local containerStroke = Instance.new("UIStroke", container)
containerStroke.Color = Color3.fromRGB(18, 18, 18)
containerStroke.Thickness = 1

-- header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 28)
header.BackgroundTransparency = 1
header.Parent = container

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Parent = header
title.Size = UDim2.new(1, -16, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.BackgroundTransparency = 1
title.Text = "SourceDBG"
title.TextColor3 = Color3.fromRGB(230, 230, 230)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

-- padding
local padding = Instance.new("UIPadding", container)
padding.PaddingTop = UDim.new(0, 32)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.PaddingBottom = UDim.new(0, 8)

-- layout
local vLayout = Instance.new("UIListLayout", container)
vLayout.SortOrder = Enum.SortOrder.LayoutOrder
vLayout.Padding = UDim.new(0, 6)
vLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
vLayout.VerticalAlignment = Enum.VerticalAlignment.Top

-- destroy button
local destroy = Instance.new("TextButton")
destroy.Name = "DestroyButton"
destroy.Size = UDim2.new(1, -16, 0, 28)
destroy.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
destroy.TextColor3 = Color3.new(1, 1, 1)
destroy.Text = "DESTROY"
destroy.Font = Enum.Font.GothamBold
destroy.TextSize = 14
destroy.LayoutOrder = 1
destroy.Parent = container

local destroyCorner = Instance.new("UICorner", destroy)
destroyCorner.CornerRadius = UDim.new(0, 6)

-- on button
local on = Instance.new("TextButton")
on.Name = "OnButton"
on.Size = UDim2.new(1, -16, 0, 28)
on.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
on.TextColor3 = Color3.new(1, 1, 1)
on.Text = "ON"
on.Font = Enum.Font.GothamBold
on.TextSize = 14
on.LayoutOrder = 2
on.Parent = container

local onCorner = Instance.new("UICorner", on)
onCorner.CornerRadius = UDim.new(0, 6)

-- mode button
local mode = Instance.new("TextButton")
mode.Name = "ModeButton"
mode.Size = UDim2.new(1, -16, 0, 28)
mode.BackgroundColor3 = Color3.fromRGB(40, 80, 180)
mode.TextColor3 = Color3.new(1, 1, 1)
mode.Text = "Mode: default (PC)"
mode.Font = Enum.Font.GothamBold
mode.TextSize = 14
mode.LayoutOrder = 3
mode.Parent = container

local modeCorner = Instance.new("UICorner", mode)
modeCorner.CornerRadius = UDim.new(0, 6)

    -- helper to create buttons
    local function makeButton(text, size, bg)
        local b = Instance.new("TextButton")
        b.Size = size
        b.BackgroundColor3 = bg
        b.Text = text
        b.TextColor3 = Color3.fromRGB(240,240,240)
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 14
        b.AutoButtonColor = true

        local corner = Instance.new("UICorner", b)
        corner.CornerRadius = UDim.new(0, 6)
        local stroke = Instance.new("UIStroke", b)
        stroke.Color = Color3.fromRGB(12,12,12)
        stroke.Thickness = 1
        return b
    end

    -- top row (destroy + toggle)
    local topRow = Instance.new("Frame", container)
    topRow.Size = UDim2.new(1, 0, 0, 36)
    topRow.BackgroundTransparency = 1
    topRow.LayoutOrder = 1

    local topLayout = Instance.new("UIListLayout", topRow)
    topLayout.FillDirection = Enum.FillDirection.Horizontal
    topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    topLayout.Padding = UDim.new(0, 8)

    local destroy = makeButton("DESTROY", UDim2.new(0, 140, 1, 0), Color3.fromRGB(220, 60, 60))
    destroy.Parent = topRow

    local toggle = makeButton("ON", UDim2.new(0, 96, 1, 0), Color3.fromRGB(60, 200, 110))
    toggle.Parent = topRow

    -- mode row (full width)
    local modeRow = Instance.new("Frame", container)
    modeRow.Size = UDim2.new(1, 0, 0, 36)
    modeRow.BackgroundTransparency = 1
    modeRow.LayoutOrder = 2

    local modeButton = makeButton("Mode: " .. gameModes[currentModeIndex], UDim2.new(1, 0, 1, 0), Color3.fromRGB(90, 130, 230))
    modeButton.Parent = modeRow
    modeButton.TextSize = 13

    -- mobile row (two large buttons) - only visible on mobile
    local mobileRow = Instance.new("Frame", container)
    mobileRow.Size = UDim2.new(1, 0, 0, 96)
    mobileRow.BackgroundTransparency = 1
    mobileRow.LayoutOrder = 3

    local mobileLayout = Instance.new("UIListLayout", mobileRow)
    mobileLayout.FillDirection = Enum.FillDirection.Horizontal
    mobileLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    mobileLayout.Padding = UDim.new(0, 8)

    local grenadeButton, jumpButton
    if isMobile then
        grenadeButton = makeButton("GRENADE", UDim2.new(0, 90, 0, 90), Color3.fromRGB(40, 40, 40))
        grenadeButton.Parent = mobileRow

        jumpButton = makeButton("JUMP", UDim2.new(0, 90, 0, 90), Color3.fromRGB(40, 40, 40))
        jumpButton.Parent = mobileRow
    end

    -- wire up behaviors (same logic as before)
    destroy.MouseButton1Click:Connect(function()
        humanoid.WalkSpeed = 16
        humanoid.JumpPower = 50
        for _, c in pairs(getconnections(RunService.Heartbeat)) do
            if c.Function then pcall(function() c:Disconnect() end) end
        end
        g:Destroy()
        scriptEnabled = false
        if script and type(script.Destroy) == "function" then pcall(function() script:Destroy() end) end
    end)

    toggle.MouseButton1Click:Connect(function()
        scriptEnabled = not scriptEnabled
        if scriptEnabled then
            toggle.BackgroundColor3 = Color3.fromRGB(60, 200, 110)
            toggle.Text = "ON"
            if isMobile and jumpButton then jumpButton.Visible = true end
        else
            toggle.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
            toggle.Text = "OFF"
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
            velocity = Vector3.new()
            if isMobile and jumpButton then jumpButton.Visible = false end
            for _, sound in pairs(root:GetChildren()) do if sound:IsA("Sound") then sound.Volume = 0.5 end end
            for _, sound in pairs(humanoid:GetChildren()) do if sound:IsA("Sound") then sound.Volume = 0.5 end end
        end
    end)

    modeButton.MouseButton1Click:Connect(function()
        currentModeIndex = currentModeIndex + 1
        if currentModeIndex > #gameModes then currentModeIndex = 1 end
        modeButton.Text = "Mode: " .. gameModes[currentModeIndex]
    end)

    if isMobile and grenadeButton and jumpButton then
        grenadeButton.MouseButton1Click:Connect(function()
            local currentMode = gameModes[currentModeIndex]
            if currentMode == "no grenades (mobile)" or currentMode == "hard (mobile)" then return end
            if not scriptEnabled then return end
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
            explodeSound.Volume = 1.0
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
        end)

        jumpButton.MouseButton1Down:Connect(function() spaceHeld = true end)
        jumpButton.MouseButton1Up:Connect(function() spaceHeld = false end)
    end

    -- Draggable with smoothing
    do
        local dragging = false
        local dragInput = nil
        local dragStart = nil
        local startPos = nil
        local smoothing = 0.18
        local targetPosition = container.Position
        local renderConn

        local function updateTarget(inputPos)
            if not startPos or not dragStart then return end
            local delta = inputPos - dragStart
            local newX = startPos.X.Offset + delta.X
            local newY = startPos.Y.Offset + delta.Y
            targetPosition = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
        end

        local function beginDrag(input)
            dragging = true
            dragStart = input.Position
            startPos = container.Position
            dragInput = input
            if renderConn then renderConn:Disconnect() end
            renderConn = RunService.RenderStepped:Connect(function()
                if dragInput and dragging then updateTarget(dragInput.Position) end
                container.Position = container.Position:Lerp(targetPosition, smoothing)
            end)
        end

        local function endDrag()
            dragging = false
            dragInput = nil
            dragStart = nil
            startPos = nil
            if renderConn then renderConn:Disconnect() renderConn = nil end
            pcall(function()
                local tweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                TweenService:Create(container, tweenInfo, {Position = targetPosition}):Play()
            end)
        end

        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                beginDrag(input)
            end
        end)

        container.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if input.Target and input.Target:IsA("TextButton") then return end
                beginDrag(input)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                dragInput = input
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                endDrag()
            end
        end)

        container.AncestryChanged:Connect(function()
            if not container:IsDescendantOf(game) then if renderConn then renderConn:Disconnect() end end
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
    if states.surfing and not inAir then
        fric = Config.SLIDE_FRICTION or (Config.FRICTION * 0.5)
    end

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

    if maxSpeed and maxSpeed > 0 and newFlat.Magnitude > maxSpeed and not states.surfing then
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
    k = k * (Config.SURF_INFLUENCE or 0.6)
    local newDir = (velUnit + wish * k)
    if newDir.Magnitude == 0 then return end
    newDir = newDir.Unit
    local newFlat = newDir * speed
    velocity = Vector3.new(newFlat.X, velocity.Y, newFlat.Z)
end

local function UpdateSurfState(groundNormal, trace)
    local flat = Vector3.new(velocity.X, 0, velocity.Z)
    local speed = flat.Magnitude
    local minAngle = Config.MIN_SLOPE_ANGLE or 40
    local maxAngle = Config.MAX_SLOPE_ANGLE or 75

    local wasSurfing = states.surfing
    states.surfing = false

    if groundNormal and speed > Config.AIR_SPEED and trace then
        local angle = math.deg(math.acos(math.clamp(groundNormal:Dot(Vector3.new(0,1,0)), -1, 1)))
        if angle >= minAngle and angle <= maxAngle then
            local slopeTangent = Vector3.new(groundNormal.Z, 0, -groundNormal.X)
            if slopeTangent.Magnitude > 0 then
                slopeTangent = slopeTangent.Unit
                local moveUnit = (flat.Magnitude > 0) and flat.Unit or Vector3.new(0,0,0)
                local dot = math.abs(moveUnit:Dot(slopeTangent))
                if dot > 0.3 then
                    states.surfing = true
                end
            end
        end
    end

    if states.surfing and not wasSurfing then
        local flatVel = Vector3.new(velocity.X, 0, velocity.Z)
        local slopeTangent = Vector3.new(groundNormal.Z, 0, -groundNormal.X)
        if slopeTangent.Magnitude > 0 then
            slopeTangent = slopeTangent.Unit
            local boost = flatVel + slopeTangent * (flatVel.Magnitude * 0.08)
            velocity = Vector3.new(boost.X, velocity.Y, boost.Z)
        end
        states.air_friction = 0
    end
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

    -- sliding detection
    if crouchHeld and isGrounded and Vector3.new(velocity.X,0,velocity.Z).Magnitude >= Config.SLIDE_MIN_SPEED and moveDir.Magnitude > 0 then
        if not sliding then
            sliding = true
            slideTimer = 0
            local flat = Vector3.new(velocity.X, 0, velocity.Z)
            flat = flat * Config.SLIDE_BOOST
            velocity = Vector3.new(flat.X, velocity.Y, flat.Z)
        end
    end
    if sliding and (not crouchHeld or not isGrounded) then
        sliding = false
        slideTimer = 0
    end
    if sliding then slideTimer = slideTimer + dt end

    -- mode adjustments
    local speedMult = sprintHeld and 1.15 or 1
    local currentMaxAirSpeed = Config.AIR_MAX_SPEED
    if gameModes[currentModeIndex] == "hard (PC)" or gameModes[currentModeIndex] == "hard (mobile)" then
        currentMaxAirSpeed = Config.AIR_MAX_SPEED * 0.35
    end

    -- movement branches
    if isGrounded then
        -- friction & surf update
        ApplyFriction(dt, false, sliding and 0.9 or 1)
        UpdateSurfState(groundTrace and groundTrace.Normal or nil, groundTrace)

        local wishDir = moveDir
        local wishSpeed = Config.RUN_SPEED * speedMult * (moveDir.Magnitude > 0 and 1 or 0)
        local groundAccel = sliding and (Config.GROUND_ACCEL * 0.6) or Config.GROUND_ACCEL
        Accelerate(wishDir, wishSpeed, groundAccel, dt, nil)

        if moveDir.Magnitude > 0.1 and not sliding then
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
            sliding = false
            slideTimer = 0
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

        if states.air_friction > 0 and not states.surfing then
            ApplyFriction(dt, true, 0.01 * states.air_friction)
        end

        -- air accel & control
        local wishDir = moveDir
        local wishSpeed = Config.RUN_SPEED * speedMult * (moveDir.Magnitude > 0 and 1 or 0)
        Accelerate(wishDir, wishSpeed, Config.AIR_ACCEL, dt, currentMaxAirSpeed)
        AirControl(wishDir, dt)

        -- surf influence if near slope
        if groundTrace then
            local normal = groundTrace.Normal
            local flatVel = Vector3.new(velocity.X, 0, velocity.Z)
            local along = flatVel - normal * flatVel:Dot(normal)
            if along.Magnitude > 0 then
                local newFlat = along.Unit * flatVel.Magnitude
                velocity = Vector3.new(newFlat.X, velocity.Y, newFlat.Z)
            end
        end

        -- gravity
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
    sliding = false
    slideTimer = 0
    states.air_friction = 0
    states.surfing = false
end)

print("Movement script loaded: HL1/HL2 midground + Portal2 slide + Quake air + Source surf features (GUI improved, draggable)")
