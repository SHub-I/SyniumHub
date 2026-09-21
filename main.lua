-- Synium Hub Main

-- Load Orion Library
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()

-- Create window
local Window = OrionLib:MakeWindow({
    Name = "Synium Hub",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = false,
    Icon = "rbxassetid://4483345998"
})

shared.SyniumWindow = Window

-- Load icons, animations, tab manager
local Icons = shared.SyniumIcons
local Anim = shared.SyniumAnim
local TabManager = shared.SyniumTabManager

-- Play loading animation
Anim:PlayLoading()

-- Load tabs
TabManager:Load(Window)

-- Finish loading
Anim:Finish()

-- REQUIRED for OrionLib
OrionLib:Init()
