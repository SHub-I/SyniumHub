-- Synium Key System (Rayfield Gen2 style)
-- Polished UI, keyboard support, animations, and safe loader behavior

local PremiumKey = "23209pre"
local LiteKey = "9023lite"

-- Cleanup previous UI if present
pcall(function()
    if getgenv().SyniumKeyUI then
        getgenv().SyniumKeyUI:Destroy()
    end
end)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Root ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SyniumKeyUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")
getgenv().SyniumKeyUI = ScreenGui

-- Main container
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 520, 0, 320)
Frame.Position = UDim2.new(0.5, -260, 0.5, -160)
Frame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
Frame.BorderSizePixel = 0
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 14)
FrameCorner.Parent = Frame

local FrameStroke = Instance.new("UIStroke")
FrameStroke.Thickness = 1.5
FrameStroke.Color = Color3.fromRGB(60, 60, 70)
FrameStroke.Transparency = 0.15
FrameStroke.Parent = Frame

-- Subtle background gradient
local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18,18,22)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10,10,12))
}
Gradient.Rotation = 90
Gradient.Parent = Frame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 72)
Header.BackgroundTransparency = 1
Header.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -24, 0, 36)
Title.Position = UDim2.new(0, 12, 0, 12)
Title.BackgroundTransparency = 1
Title.Text = "Synium Hub Key System"
Title.TextColor3 = Color3.fromRGB(235, 235, 240)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -24, 0, 20)
Subtitle.Position = UDim2.new(0, 12, 0, 44)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Enter your key to unlock the hub"
Subtitle.TextColor3 = Color3.fromRGB(160, 160, 170)
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 14
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

-- Key input area
local InputContainer = Instance.new("Frame")
InputContainer.Size = UDim2.new(1, -40, 0, 110)
InputContainer.Position = UDim2.new(0, 20, 0, 92)
InputContainer.BackgroundTransparency = 1
InputContainer.Parent = Frame

local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(1, 0, 0, 48)
InputBox.Position = UDim2.new(0, 0, 0, 0)
InputBox.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
InputBox.TextColor3 = Color3.fromRGB(235, 235, 240)
InputBox.PlaceholderText = "Paste your key here (Premium or Lite)"
InputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
InputBox.Font = Enum.Font.Gotham
InputBox.TextSize = 16
InputBox.ClearTextOnFocus = false
InputBox.Text = ""
InputBox.Parent = InputContainer

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = InputBox

local InputStroke = Instance.new("UIStroke")
InputStroke.Thickness = 1
InputStroke.Color = Color3.fromRGB(70, 70, 80)
InputStroke.Transparency = 0.2
InputStroke.Parent = InputBox

-- Small helper text
local Helper = Instance.new("TextLabel")
Helper.Size = UDim2.new(1, 0, 0, 18)
Helper.Position = UDim2.new(0, 0, 0, 56)
Helper.BackgroundTransparency = 1
Helper.Text = "Premium: 23209pre  •  Lite: 9023lite"
Helper.TextColor3 = Color3.fromRGB(140, 140, 150)
Helper.Font = Enum.Font.Gotham
Helper.TextSize = 12
Helper.TextXAlignment = Enum.TextXAlignment.Left
Helper.Parent = InputContainer

-- Error / status label
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 0, 20)
Status.Position = UDim2.new(0, 0, 0, 78)
Status.BackgroundTransparency = 1
Status.Text = ""
Status.TextColor3 = Color3.fromRGB(255, 80, 80)
Status.Font = Enum.Font.GothamSemibold
Status.TextSize = 14
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = InputContainer

-- Unlock button
local Button = Instance.new("TextButton")
Button.Size = UDim2.new(1, -40, 0, 46)
Button.Position = UDim2.new(0, 20, 0, 210)
Button.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.Font = Enum.Font.GothamBold
Button.TextSize = 16
Button.Text = "Unlock Hub"
Button.AutoButtonColor = false
Button.Parent = Frame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = Button

local ButtonStroke = Instance.new("UIStroke")
ButtonStroke.Thickness = 1
ButtonStroke.Color = Color3.fromRGB(40, 90, 220)
ButtonStroke.Transparency = 0.1
ButtonStroke.Parent = Button

-- Small subtle glow
local Glow = Instance.new("ImageLabel")
Glow.Size = UDim2.new(1, 40, 0, 80)
Glow.Position = UDim2.new(0, -20, 1, -100)
Glow.BackgroundTransparency = 1
Glow.Image = "rbxassetid://3570695787" -- subtle circle texture
Glow.ImageColor3 = Color3.fromRGB(60, 120, 255)
Glow.ImageTransparency = 0.92
Glow.ScaleType = Enum.ScaleType.Slice
Glow.SliceCenter = Rect.new(100,100,100,100)
Glow.Parent = Frame

-- Utility functions
local function tween(obj, props, time, style, dir)
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    local info = TweenInfo.new(time or 0.25, style, dir)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function flashStroke(color)
    tween(FrameStroke, {Color = color}, 0.12)
    delay(0.18, function()
        tween(FrameStroke, {Color = Color3.fromRGB(60, 60, 70)}, 0.22)
    end)
end

local function shakeGui(target)
    local origin = target.Position
    local amplitude = 6
    local steps = 8
    for i = 1, steps do
        local offset = UDim2.new(0, (i % 2 == 0 and amplitude or -amplitude), 0, 0)
        tween(target, {Position = origin + offset}, 0.03)
        RunService.Heartbeat:Wait()
    end
    tween(target, {Position = origin}, 0.12)
end

local function setStatus(text, color)
    Status.Text = text or ""
    if color then
        Status.TextColor3 = color
    else
        Status.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end

-- Focus animation
InputBox.Focused:Connect(function()
    tween(InputBox, {BackgroundColor3 = Color3.fromRGB(28,28,34)}, 0.12)
    tween(InputStroke, {Transparency = 0}, 0.12)
end)

InputBox.FocusLost:Connect(function(enterPressed)
    tween(InputBox, {BackgroundColor3 = Color3.fromRGB(24,24,28)}, 0.12)
    tween(InputStroke, {Transparency = 0.2}, 0.12)
    if enterPressed then
        Button:CaptureFocus()
        Button.MouseButton1Click:Fire()
    end
end)

-- Button hover effects
Button.MouseEnter:Connect(function()
    tween(Button, {BackgroundColor3 = Color3.fromRGB(80,150,255)}, 0.12)
    tween(ButtonStroke, {Transparency = 0}, 0.12)
end)
Button.MouseLeave:Connect(function()
    tween(Button, {BackgroundColor3 = Color3.fromRGB(60,120,255)}, 0.12)
    tween(ButtonStroke, {Transparency = 0.1}, 0.12)
end)

-- Disable/enable helper
local function setInteractive(enabled)
    InputBox.ClearTextOnFocus = false
    InputBox.TextEditable = enabled
    Button.Active = enabled
    Button.AutoButtonColor = enabled
    if enabled then
        tween(Button, {BackgroundTransparency = 0}, 0.12)
    else
        tween(Button, {BackgroundTransparency = 0.35}, 0.12)
    end
end

-- Fade out and load main
local function fadeOutAndLoad(mode)
    setInteractive(false)
    setStatus("Unlocking...", Color3.fromRGB(200,200,200))
    -- Fade children
    for _, obj in ipairs(Frame:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton") then
            tween(obj, {TextTransparency = 1, BackgroundTransparency = 1}, 0.35)
        elseif obj:IsA("UIStroke") or obj:IsA("UIGradient") or obj:IsA("ImageLabel") then
            pcall(function() tween(obj, {Transparency = 1}, 0.35) end)
        end
    end
    tween(Frame, {BackgroundTransparency = 1}, 0.35).Completed:Wait()

    -- Set globals and load main
    getgenv().SyniumMode = mode
    getgenv().SyniumKeySystemLoaded = true

    -- Destroy UI and load main
    pcall(function() ScreenGui:Destroy() end)
    -- Safe load main.lua
    local ok, src = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/main.lua")
    end)
    if ok and type(src) == "string" and #src > 10 then
        local suc, err = pcall(function() loadstring(src)() end)
        if not suc then
            -- If main fails, clear flags and notify
            getgenv().SyniumKeySystemLoaded = nil
            getgenv().SyniumMode = nil
            warn("Failed to execute main.lua:", err)
        end
    else
        -- Could not fetch main.lua
        getgenv().SyniumKeySystemLoaded = nil
        getgenv().SyniumMode = nil
        warn("Failed to download main.lua from remote.")
    end
end

-- Validate key
local function validateKey(key)
    if not key or key:match("^%s*$") then
        setStatus("Please enter a key.", Color3.fromRGB(255, 180, 80))
        flashStroke(Color3.fromRGB(255, 140, 80))
        return
    end

    key = key:lower():gsub("%s+", "")
    if key == PremiumKey:lower() then
        setStatus("Premium key accepted. Loading premium hub...", Color3.fromRGB(120, 220, 140))
        flashStroke(Color3.fromRGB(120, 220, 140))
        fadeOutAndLoad("premium")
    elseif key == LiteKey:lower() then
        setStatus("Lite key accepted. Loading lite hub...", Color3.fromRGB(120, 220, 140))
        flashStroke(Color3.fromRGB(120, 220, 140))
        fadeOutAndLoad("lite")
    else
        setStatus("Invalid key. Try again.", Color3.fromRGB(255, 100, 100))
        flashStroke(Color3.fromRGB(255, 100, 100))
        shakeGui(Frame)
    end
end

-- Button click
Button.MouseButton1Click:Connect(function()
    validateKey(InputBox.Text)
end)

-- Keyboard Enter support
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
        validateKey(InputBox.Text)
    end
end)

-- Initial entrance animation
do
    Frame.Position = Frame.Position + UDim2.new(0, 0, 0, 30)
    Frame.BackgroundTransparency = 1
    for _, obj in ipairs(Frame:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton") then
            obj.TextTransparency = 1
            if obj:IsA("TextBox") then obj.BackgroundTransparency = 1 end
        end
    end
    tween(Frame, {BackgroundTransparency = 0}, 0.28)
    tween(Frame, {Position = Frame.Position - UDim2.new(0, 0, 0, 30)}, 0.28)
    delay(0.06, function()
        for i, obj in ipairs(Frame:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton") then
                tween(obj, {TextTransparency = 0, BackgroundTransparency = 0}, 0.22)
                wait(0.02)
            end
        end
    end)
end

-- Safety: if CoreGui parenting fails, attempt to parent to PlayerGui (some exploits)
if not ScreenGui.Parent then
    pcall(function()
        local plr = game:GetService("Players").LocalPlayer
        if plr and plr:FindFirstChild("PlayerGui") then
            ScreenGui.Parent = plr.PlayerGui
        end
    end)
end
