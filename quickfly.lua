--// SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--// VARIABLES
local FLYING = false
local QEfly = true
local vehicleflyspeed = 1
local flyKeyDown
local flyKeyUp
local toggleKey = Enum.KeyCode.F -- default keybind
local bindingMode = false

--// ROOT FINDER
local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
end

--// ULTRA-SMOOTH VEHICLE FLY
local function sFLY(vfly)
    local plr = Players.LocalPlayer
    local char = plr.Character or plr.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        repeat task.wait() until char:FindFirstChildOfClass("Humanoid")
        humanoid = char:FindFirstChildOfClass("Humanoid")
    end

    if flyKeyDown then flyKeyDown:Disconnect() end
    if flyKeyUp then flyKeyUp:Disconnect() end

    local T = getRoot(char)
    local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    local desired = Vector3.zero
    local current = Vector3.zero
    local smoothness = 0.10

    local function FLY()
        FLYING = true
        local BG = Instance.new("BodyGyro")
        local BV = Instance.new("BodyVelocity")
        BG.P = 9e4
        BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.CFrame = T.CFrame
        BG.Parent = T
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        BV.Velocity = Vector3.zero
        BV.Parent = T

        task.spawn(function()
            repeat task.wait()
                local camera = workspace.CurrentCamera
                if not vfly then humanoid.PlatformStand = true end

                local SPEED = (vehicleflyspeed ^ 1.35) * 8

                if CONTROL.F + CONTROL.B ~= 0 or CONTROL.L + CONTROL.R ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
                    desired = (
                        (camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) +
                        ((camera.CFrame * CFrame.new(
                            CONTROL.L + CONTROL.R,
                            (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2,
                            0
                        )).p - camera.CFrame.p)
                    ) * SPEED
                else
                    desired = Vector3.zero
                end

                current = current:Lerp(desired, smoothness)
                BV.Velocity = current
                BG.CFrame = camera.CFrame
            until not FLYING

            BG:Destroy()
            BV:Destroy()
            humanoid.PlatformStand = false
        end)
    end

    flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        local speed = vehicleflyspeed
        if input.KeyCode == Enum.KeyCode.W then CONTROL.F = speed
        elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = -speed
        elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = -speed
        elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = speed
        elseif input.KeyCode == Enum.KeyCode.E and QEfly then CONTROL.Q = speed * 2
        elseif input.KeyCode == Enum.KeyCode.Q and QEfly then CONTROL.E = -speed * 2
        end
    end)

    flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.W then CONTROL.F = 0
        elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = 0
        elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = 0
        elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = 0
        elseif input.KeyCode == Enum.KeyCode.E then CONTROL.Q = 0
        elseif input.KeyCode == Enum.KeyCode.Q then CONTROL.E = 0
        end
    end)

    FLY()
end

--// STOP FLY
local function NOFLY()
    FLYING = false
    if flyKeyDown then flyKeyDown:Disconnect() end
    if flyKeyUp then flyKeyUp:Disconnect() end
    local char = Players.LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
end

--// GUI SETUP
if game.CoreGui:FindFirstChild("VehicleFlyGUI") then
    game.CoreGui.VehicleFlyGUI:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "VehicleFlyGUI"
gui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 170)
frame.Position = UDim2.new(0.5, -130, 0.5, -85)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

-- ensure children are clipped when shrinking
frame.ClipsDescendants = true
frame.Draggable = false -- use custom dragging

local uiCorner = Instance.new("UICorner", frame)
uiCorner.CornerRadius = UDim.new(0, 12)

local glow = Instance.new("UIStroke", frame)
glow.Thickness = 2
glow.Color = Color3.fromRGB(255, 200, 80)
glow.Transparency = 0.3

local orig = {
    Position = frame.Position,
    Size = frame.Size,
    BgColor = frame.BackgroundColor3,
    Corner = uiCorner.CornerRadius,
    GlowTransparency = glow.Transparency
}

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Fly"
title.TextColor3 = Color3.fromRGB(255, 220, 120)
title.Font = Enum.Font.GothamSemibold
title.TextSize = 20
title.Parent = frame

-- keybind label (always visible)
local keybindLabel = Instance.new("TextLabel")
keybindLabel.Size = UDim2.new(0, 90, 0, 20)
keybindLabel.Position = UDim2.new(1, -100, 0, 6)
keybindLabel.BackgroundTransparency = 1
keybindLabel.Text = toggleKey.Name
keybindLabel.TextColor3 = Color3.fromRGB(200, 180, 120)
keybindLabel.Font = Enum.Font.Gotham
keybindLabel.TextSize = 14
keybindLabel.Parent = frame

--// Toggle Button (fade tween)
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(1, -20, 0, 40)
toggle.Position = UDim2.new(0, 10, 0, 40)
toggle.BackgroundColor3 = Color3.fromRGB(70, 60, 50)
toggle.TextColor3 = Color3.fromRGB(255, 230, 140)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 18
toggle.Text = "Fly: OFF"
toggle.Parent = frame
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 10)

local toggleGrad = Instance.new("UIGradient", toggle)
toggleGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 210, 120)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 70))
}
toggleGrad.Rotation = 90
TweenService:Create(toggleGrad, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Rotation = 270
}):Play()

--// Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 20)
closeBtn.Position = UDim2.new(1, -34, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(200, 180, 120)
closeBtn.Font = Enum.Font.Gotham
closeBtn.TextSize = 14
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

--// Slider
local sliderFrame = Instance.new("Frame")
sliderFrame.Size = UDim2.new(1, -20, 0, 40)
sliderFrame.Position = UDim2.new(0, 10, 0, 90)
sliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
sliderFrame.Parent = frame
Instance.new("UICorner", sliderFrame).CornerRadius = UDim.new(0, 10)

local sliderBar = Instance.new("Frame")
sliderBar.Size = UDim2.new(0, 0, 1, 0)
sliderBar.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
sliderBar.Parent = sliderFrame
Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 10)

local sliderText = Instance.new("TextLabel")
sliderText.Size = UDim2.new(1, 0, 1, 0)
sliderText.BackgroundTransparency = 1
sliderText.Text = "Speed: 1"
sliderText.TextColor3 = Color3.fromRGB(255, 220, 120)
sliderText.Font = Enum.Font.GothamBold
sliderText.TextSize = 18
sliderText.Parent = sliderFrame

--// Slider dragging + disable frame dragging while sliding
local draggingSlider = false
local function setSliderFromX(x)
    local rel = math.clamp((x - sliderFrame.AbsolutePosition.X) / math.max(sliderFrame.AbsoluteSize.X, 1), 0, 1)
    local value = math.floor(rel * 20)
    if value < 1 then value = 1 end
    vehicleflyspeed = value
    sliderText.Text = "Speed: " .. vehicleflyspeed
    TweenService:Create(sliderBar, TweenInfo.new(0.12, Enum.EasingStyle.Sine), {Size = UDim2.new(rel, 0, 1, 0)}):Play()
end

sliderFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = true
        frame.Active = false -- disable frame dragging while sliding
        local mouse = UserInputService:GetMouseLocation()
        setSliderFromX(mouse.X)
    end
end)

sliderFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = false
        frame.Active = true -- re-enable frame dragging
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        local x = input.Position.X
        setSliderFromX(x)
    end
end)

--// Smooth custom dragging for the whole frame (uses Vector2 only)
local draggingFrame = false
local dragStart = Vector2.new()
local startPos = UDim2.new()

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if draggingSlider or frame:GetAttribute("Minimized") then return end
        draggingFrame = true
        dragStart = UserInputService:GetMouseLocation()
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingFrame = false
            end
        end)
    end
end)

RunService.RenderStepped:Connect(function()
    if draggingFrame then
        local mousePos = UserInputService:GetMouseLocation()
        local delta = mousePos - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

--// Toggle fade animation helper
local function setToggleVisual(on)
    local bgTarget = on and Color3.fromRGB(95, 75, 50) or Color3.fromRGB(70, 60, 50)
    local textColor = on and Color3.fromRGB(255, 240, 170) or Color3.fromRGB(255, 230, 140)
    TweenService:Create(toggle, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundColor3 = bgTarget}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.22, Enum.EasingStyle.Sine), {TextColor3 = textColor}):Play()
    TweenService:Create(toggle, TweenInfo.new(0.22, Enum.EasingStyle.Sine), {TextTransparency = (on and 0 or 0.05)}):Play()
end

--// Toggle Fly (fade)
local function toggleAction()
    FLYING = not FLYING
    toggle.Text = FLYING and "Fly: ON" or "Fly: OFF"
    setToggleVisual(FLYING)
    if FLYING then sFLY(true) else NOFLY() end
end

toggle.MouseButton1Click:Connect(function()
    toggleAction()
end)

--// Right-click keybind changer (bindingMode prevents accidental activation)
toggle.MouseButton2Click:Connect(function()
    if bindingMode then return end
    bindingMode = true
    local oldText = toggle.Text
    toggle.Text = "Press a key..."
    -- temporarily show binding state on keybind label
    keybindLabel.Text = "..."
    local conn
    conn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            toggleKey = input.KeyCode
            keybindLabel.Text = toggleKey.Name
            toggle.Text = "Fly: " .. toggleKey.Name
            conn:Disconnect()
            bindingMode = false
        end
    end)
    -- cancel if user clicks elsewhere after 8 seconds
    task.delay(8, function()
        if conn and conn.Connected then
            conn:Disconnect()
            bindingMode = false
            toggle.Text = oldText
            keybindLabel.Text = toggleKey.Name
        end
    end)
end)

--// Keybind toggle (reliable and ignores binding mode)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if bindingMode then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey then
        toggleAction()
    end
end)

--// MINIMIZE / RESTORE (close button -> circle in bottom-right)
local minimized = false
local circleButton

local function fadeChildren(toTransparency, tweenTime)
    for _, child in ipairs(frame:GetChildren()) do
        if child ~= uiCorner and child ~= glow then
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("Frame") then
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    TweenService:Create(child, TweenInfo.new(tweenTime, Enum.EasingStyle.Sine), {TextTransparency = toTransparency}):Play()
                end
                if child:IsA("Frame") or child:IsA("TextButton") then
                    TweenService:Create(child, TweenInfo.new(tweenTime, Enum.EasingStyle.Sine), {BackgroundTransparency = toTransparency}):Play()
                end
            end
        end
    end
end

local function minimizeToCircle()
    if minimized then return end
    minimized = true
    frame:SetAttribute("Minimized", true)
    frame.Active = false

    uiCorner.CornerRadius = UDim.new(0, 100)
    fadeChildren(1, 0.25)

    local targetSize = UDim2.new(0, 56, 0, 56)
    local targetPos = UDim2.new(1, -72, 1, -72)
    local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    TweenService:Create(frame, tweenInfo, {Size = targetSize, Position = targetPos, BackgroundColor3 = Color3.fromRGB(10,10,10)}):Play()
    TweenService:Create(glow, tweenInfo, {Transparency = 0}):Play()

    task.delay(0.36, function()
        circleButton = Instance.new("TextButton")
        circleButton.Name = "FlyCircle"
        circleButton.Size = targetSize
        circleButton.Position = targetPos
        circleButton.AnchorPoint = Vector2.new(0, 0)
        circleButton.BackgroundColor3 = Color3.fromRGB(10,10,10)
        circleButton.BorderSizePixel = 0
        circleButton.Text = ""
        circleButton.Parent = gui
        circleButton.ZIndex = frame.ZIndex + 1

        local cCorner = Instance.new("UICorner", circleButton)
        cCorner.CornerRadius = UDim.new(0, 100)

        local cStroke = Instance.new("UIStroke", circleButton)
        cStroke.Color = Color3.fromRGB(255, 200, 80)
        cStroke.Thickness = 2
        cStroke.Transparency = 0

        -- show small key label on circle
        local smallLabel = Instance.new("TextLabel", circleButton)
        smallLabel.Size = UDim2.new(1, 0, 1, 0)
        smallLabel.BackgroundTransparency = 1
        smallLabel.Text = toggleKey.Name
        smallLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
        smallLabel.Font = Enum.Font.Gotham
        smallLabel.TextSize = 12

        local pulse = TweenService:Create(cStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Thickness = 3})
        pulse:Play()

        circleButton.MouseButton1Click:Connect(function()
            if circleButton then
                pulse:Cancel()
                circleButton:Destroy()
                circleButton = nil
            end

            local restoreTween = TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
                Size = orig.Size,
                Position = orig.Position,
                BackgroundColor3 = orig.BgColor
            })
            TweenService:Create(glow, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Transparency = orig.GlowTransparency}):Play()
            restoreTween:Play()
            uiCorner.CornerRadius = orig.Corner
            fadeChildren(0, 0.28)

            task.delay(0.36, function()
                frame.Active = true
                frame:SetAttribute("Minimized", false)
                minimized = false
            end)
        end)
    end)
end

closeBtn.MouseButton1Click:Connect(function()
    minimizeToCircle()
end)
