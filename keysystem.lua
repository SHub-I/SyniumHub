-- Synium Hub Key System (Standalone Loader)

-- CONFIG
local PremiumKey = "23209pre"
local LiteKey = "9023lite"

-- CLEANUP
pcall(function()
    if getgenv().SyniumKeyUI then
        getgenv().SyniumKeyUI:Destroy()
    end
end)

-- GUI ROOT
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SyniumKeyUI"
ScreenGui.Parent = game:GetService("CoreGui")
getgenv().SyniumKeyUI = ScreenGui

-- MAIN FRAME
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 420, 0, 260)
Frame.Position = UDim2.new(0.5, -210, 0.5, -130)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Frame

-- TITLE
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = "Synium Hub Key System"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.Parent = Frame

-- INPUT BOX
local Input = Instance.new("TextBox")
Input.Size = UDim2.new(1, -40, 0, 45)
Input.Position = UDim2.new(0, 20, 0, 80)
Input.PlaceholderText = "Enter your key..."
Input.Text = ""
Input.TextColor3 = Color3.fromRGB(255, 255, 255)
Input.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
Input.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
Input.Font = Enum.Font.Gotham
Input.TextSize = 18
Input.Parent = Frame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = Input

-- BUTTON
local Button = Instance.new("TextButton")
Button.Size = UDim2.new(1, -40, 0, 45)
Button.Position = UDim2.new(0, 20, 0, 150)
Button.Text = "Unlock Hub"
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
Button.Font = Enum.Font.GothamBold
Button.TextSize = 20
Button.Parent = Frame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = Button

-- ERROR LABEL
local Error = Instance.new("TextLabel")
Error.Size = UDim2.new(1, 0, 0, 30)
Error.Position = UDim2.new(0, 0, 0, 200)
Error.BackgroundTransparency = 1
Error.Text = ""
Error.TextColor3 = Color3.fromRGB(255, 80, 80)
Error.Font = Enum.Font.GothamSemibold
Error.TextSize = 16
Error.Parent = Frame

-- SHAKE FUNCTION
local function shake()
    for i = 1, 6 do
        Frame.Position = Frame.Position + UDim2.new(0, math.random(-6, 6), 0, 0)
        task.wait(0.03)
    end
    Frame.Position = UDim2.new(0.5, -210, 0.5, -130)
end

-- BUTTON LOGIC
Button.MouseButton1Click:Connect(function()
    local key = Input.Text

    if key == PremiumKey then
        Error.Text = ""
        getgenv().SyniumMode = "premium"
        getgenv().SyniumKeySystemLoaded = true
        ScreenGui:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/main.lua"))()

    elseif key == LiteKey then
        Error.Text = ""
        getgenv().SyniumMode = "lite"
        getgenv().SyniumKeySystemLoaded = true
        ScreenGui:Destroy()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/main.lua"))()

    else
        Error.Text = "Invalid key!"
        shake()
    end
end)
