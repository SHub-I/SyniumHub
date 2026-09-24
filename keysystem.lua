-- Synium Key System (clean, rounded, closes, loads hub)
-- Fully compatible with main.lua protection

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------

local PREMIUM_KEY = "23209pre"
local LITE_KEY = "9023lite"

------------------------------------------------------------
-- SERVICES
------------------------------------------------------------

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

------------------------------------------------------------
-- CLEANUP PREVIOUS UI
------------------------------------------------------------

pcall(function()
    if getgenv().SyniumKeyUI then
        getgenv().SyniumKeyUI:Destroy()
    end
end)

------------------------------------------------------------
-- SAFE DESCENDANTS
------------------------------------------------------------

local function safeDescendants(root)
    local ok, list = pcall(function() return root:GetDescendants() end)
    return ok and list or {}
end

------------------------------------------------------------
-- ROOT GUI
------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "SyniumKeyUI"
gui.ResetOnSpawn = false

pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not gui.Parent then
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

getgenv().SyniumKeyUI = gui

------------------------------------------------------------
-- TWEEN WRAPPER
------------------------------------------------------------

local function tween(obj, props, time, style, dir)
    TweenService:Create(
        obj,
        TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    ):Play()
end

------------------------------------------------------------
-- MAIN WINDOW (rounded)
------------------------------------------------------------

local window = Instance.new("Frame")

------------------------------------------------------------
-- ULTRA-SMOOTH DRAGGING (no overshoot, no pauses)
------------------------------------------------------------

local dragging = false
local dragStart
local startPos

local RunService = game:GetService("RunService")

-- how fast the window follows the mouse (0.1 = slow, 0.25 = fast)
local followSpeed = 0.08

local targetPos = window.Position

window.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = window.Position
    end
end)

window.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart

        targetPos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ultra-smooth interpolation every frame
RunService.RenderStepped:Connect(function()
    window.Position = UDim2.new(
        window.Position.X.Scale,
        window.Position.X.Offset + (targetPos.X.Offset - window.Position.X.Offset) * followSpeed,
        window.Position.Y.Scale,
        window.Position.Y.Offset + (targetPos.Y.Offset - window.Position.Y.Offset) * followSpeed
    )
end)


window.Name = "Window"
window.Size = UDim2.new(0, 520, 0, 260)
window.Position = UDim2.new(0.5, -260, 0.5, -150)
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
window.BorderSizePixel = 0
window.ZIndex = 10
window.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = window

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.2
stroke.Color = Color3.fromRGB(60, 60, 70)
stroke.Transparency = 0.9
stroke.Parent = window

------------------------------------------------------------
-- HEADER
------------------------------------------------------------

local header = Instance.new("Frame")
header.Size = UDim2.new(1, -32, 0, 72)
header.Position = UDim2.new(0, 16, 0, 16)
header.BackgroundTransparency = 1
header.ZIndex = 10
header.Parent = window

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundTransparency = 1
title.Text = "Synium Hub"
title.TextColor3 = Color3.fromRGB(235,235,240)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 10
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 20)
subtitle.Position = UDim2.new(0, 0, 0, 34)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Enter your key to unlock the hub"
subtitle.TextColor3 = Color3.fromRGB(160,160,170)
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 14
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 10
subtitle.Parent = header

------------------------------------------------------------
-- INPUT AREA
------------------------------------------------------------

local inputContainer = Instance.new("Frame")
inputContainer.Size = UDim2.new(1, -32, 0, 120)
inputContainer.Position = UDim2.new(0, 16, 0, 96)
inputContainer.BackgroundTransparency = 1
inputContainer.ZIndex = 10
inputContainer.Parent = window

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, 0, 0, 48)
inputBox.BackgroundColor3 = Color3.fromRGB(24,24,28)
inputBox.TextColor3 = Color3.fromRGB(235,235,240)
inputBox.PlaceholderText = "Paste your key here"
inputBox.PlaceholderColor3 = Color3.fromRGB(120,120,130)
inputBox.Font = Enum.Font.Gotham
inputBox.TextSize = 16
inputBox.ClearTextOnFocus = false
inputBox.Text = ""
inputBox.ZIndex = 10
inputBox.Parent = inputContainer

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = inputBox

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 20)
status.Position = UDim2.new(0, 0, 0, 56)
status.BackgroundTransparency = 1
status.Text = ""
status.TextColor3 = Color3.fromRGB(255,80,80)
status.Font = Enum.Font.GothamSemibold
status.TextSize = 14
status.TextXAlignment = Enum.TextXAlignment.Left
status.ZIndex = 10
status.Parent = inputContainer


local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, 0, 0, 4) -- thicker
divider.Position = UDim2.new(0, 0, 0, 70)
divider.BackgroundColor3 = Color3.fromRGB(115, 115, 115)
divider.BorderSizePixel = 0
divider.ZIndex = 10
divider.Parent = inputContainer

local dividerCorner = Instance.new("UICorner")
dividerCorner.CornerRadius = UDim.new(0, 3) -- rounded edges
dividerCorner.Parent = divider




------------------------------------------------------------
-- UNLOCK BUTTON
------------------------------------------------------------

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -32, 0, 46)
button.Position = UDim2.new(0, 16, 0, 190)
button.BackgroundColor3 = Color3.fromRGB(60,120,255)
button.TextColor3 = Color3.fromRGB(255,255,255)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Text = "Unlock Hub"
button.AutoButtonColor = false
button.ZIndex = 10
button.Parent = window

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = button

local buttonStroke = Instance.new("UIStroke")
buttonStroke.Thickness = 1
buttonStroke.Color = Color3.fromRGB(40,90,220)
buttonStroke.Transparency = 0.95
buttonStroke.ZIndex = 10
buttonStroke.Parent = button

------------------------------------------------------------
-- STATUS + FLASH
------------------------------------------------------------

local function setStatus(text, color)
    status.Text = text
    status.TextColor3 = color or Color3.fromRGB(255,80,80)
end

local function flash(color)
    local old = stroke.Color
    stroke.Transparency = 0
    stroke.Thickness = 2
    tween(stroke, {Color = color}, 0.12)
    task.wait(0.12)
    tween(stroke, {Color = old, Transparency = 0.9}, 0.22)
    stroke.Thickness = 1.2
end

------------------------------------------------------------
-- LOAD HUB (PREMIUM / LITE)
------------------------------------------------------------

local function loadHub(mode)
    -- REQUIRED BY main.lua protection
    getgenv().SyniumKeySystemLoaded = true
    getgenv().SyniumMode = mode

    -- Fade out UI
    for _, obj in ipairs(safeDescendants(window)) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            tween(obj, {TextTransparency = 1}, 0.25)
        end
    end

    tween(window, {BackgroundTransparency = 1}, 0.25)
    tween(stroke, {Transparency = 1}, 0.25)

    task.wait(0.3)
    gui:Destroy()

    -- Load correct hub depending on mode
    local url
    if mode == "premium" then
        url = "https://raw.githubusercontent.com/SHub-I/SyniumHub/main/main.lua"
    elseif mode == "lite" then
        url = "https://raw.githubusercontent.com/SHub-I/SyniumHub/main/mainlite.lua"
    else
        warn("Unknown mode: " .. tostring(mode))
        return
    end

    local ok, src = pcall(function()
        return game:HttpGet(url)
    end)

    if ok and type(src) == "string" and #src > 10 then
        loadstring(src)()
    else
        warn("Synium Hub: failed to load " .. mode .. " script.")
    end
end

------------------------------------------------------------
-- KEY VALIDATION
------------------------------------------------------------

local function validate(key)
    if key == "" then
        setStatus("Please enter a key.", Color3.fromRGB(255,180,80))
        flash(Color3.fromRGB(255,140,80))
        return
    end

    local normalized = key:lower():gsub("%s+", "")

    if normalized == PREMIUM_KEY then
        setStatus("Premium key accepted.", Color3.fromRGB(120,220,140))
        flash(Color3.fromRGB(120,220,140))
        loadHub("premium")

    elseif normalized == LITE_KEY then
        setStatus("Lite key accepted.", Color3.fromRGB(120,220,140))
        flash(Color3.fromRGB(120,220,140))
        loadHub("lite")

    else
        setStatus("Invalid key.", Color3.fromRGB(255,100,100))
        flash(Color3.fromRGB(255,100,100))
    end
end

button.MouseButton1Click:Connect(function()
    validate(inputBox.Text)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Return then
        validate(inputBox.Text)
    end
end)

------------------------------------------------------------
-- INPUT FOCUS EFFECT
------------------------------------------------------------

inputBox.Focused:Connect(function()
    tween(inputBox, {BackgroundColor3 = Color3.fromRGB(28,28,34)}, 0.12)
end)

inputBox.FocusLost:Connect(function()
    tween(inputBox, {BackgroundColor3 = Color3.fromRGB(24,24,28)}, 0.12)
end)

------------------------------------------------------------
-- BUTTON HOVER
------------------------------------------------------------

button.MouseEnter:Connect(function()
    tween(button, {BackgroundColor3 = Color3.fromRGB(80,150,255)}, 0.12)
    tween(buttonStroke, {Transparency = 0.6}, 0.12)
end)

button.MouseLeave:Connect(function()
    tween(button, {BackgroundColor3 = Color3.fromRGB(60,120,255)}, 0.12)
    tween(buttonStroke, {Transparency = 0.95}, 0.12)
end)

------------------------------------------------------------
-- ENTRANCE ANIMATION
------------------------------------------------------------

do
    local start = window.Position + UDim2.new(0, 0, 0, 30)
    window.Position = start
    window.BackgroundTransparency = 1

    tween(window, {BackgroundTransparency = 0}, 0.28)
    tween(window, {Position = start - UDim2.new(0, 0, 0, 30)}, 0.28)

    task.delay(0.06, function()
        for _, obj in ipairs(safeDescendants(window)) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                obj.TextTransparency = 1
            end
        end
        for _, obj in ipairs(safeDescendants(window)) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                tween(obj, {TextTransparency = 0}, 0.22)
                task.wait(0.01)
            end
        end
    end)
end
