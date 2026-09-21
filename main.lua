-- Synium Hub Main

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/jensonhirst/Orion/main/source"))()

local Window = OrionLib:MakeWindow({
    Name = "Synium Hub",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = false,
    Icon = "rbxassetid://4483345998"
})

shared.SyniumWindow = Window

local TabManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/tab_manager.lua"))()

TabManager:Load(Window)

OrionLib:Init()
