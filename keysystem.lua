-- Synium Hub Key System (Standalone Loader)

local PremiumKey = "23209pre"
local LiteKey = "9023lite"

pcall(function()
    if getgenv().SyniumKeyUI then
        getgenv().SyniumKeyUI:Destroy()
    end
end)

local TweenService = game:GetService("TweenService")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SyniumKeyUI"
ScreenGui.Parent = game:GetService("CoreGui")
getgenv().SyniumKeyUI = ScreenGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 420, 0, 260)
Frame.Position = UDim2.new(0.5, -210, 0.5, -130)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Frame

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 2
Stroke.Color = Color3.fromRGB(80, 80, 90)
Stroke.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = "Synium Hub Key System"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.Parent = Frame

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

local Error = Instance.new("TextLabel")
Error.Size = UDim2.new(1, 0, 0, 30)
Error.Position = UDim2.new(0, 0, 0, 200)
Error.BackgroundTransparency = 1
Error.Text = ""
Error.TextColor3 = Color3.fromRGB(255, 80, 80)
Error.Font = Enum.Font.GothamSemibold
Error.TextSize = 16
Error.Parent = Frame

local function flashStroke(color)
    local toColor = TweenService:Create(
        Stroke,
        TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        { Color = color }
    )
    local backColor = TweenService:Create(
        Stroke,
        TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        { Color = Color3.fromRGB(80, 80, 90) }
    )
    toColor:Play()
    toColor.Completed:Wait()
    backColor:Play()
end

local function fadeOutAndLoad(mode)
    local fade = TweenService:Create(
        Frame,
        TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 1 }
    )

    local children = Frame:GetDescendants()
    for _, obj in ipairs(children) do
        if obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton") then
            TweenService:Create(
                obj,
                TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { TextTransparency = 1 }
            ):Play()
        elseif obj:IsA("UIStroke") then
            TweenService:Create(
                obj,
                TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Transparency = 1 }
            ):Play()
        end
    end

    fade:Play()
    fade.Completed:Wait()

    getgenv().SyniumMode = mode
    getgenv().SyniumKeySystemLoaded = true

    ScreenGui:Destroy()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/main.lua"))()
end

Button.MouseButton1Click:Connect(function()
    local key = Input.Text

    if key == PremiumKey then
        Error.Text = ""
        flashStroke(Color3.fromRGB(60, 200, 100))
        fadeOutAndLoad("premium")
    elseif key == LiteKey then
        Error.Text = ""
        flashStroke(Color3.fromRGB(60, 200, 100))
        fadeOutAndLoad("lite")
    else
        Error.Text = "Invalid key!"
        flashStroke(Color3.fromRGB(255, 80, 80))
    end
end)
