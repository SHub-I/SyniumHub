local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/sirius-software/Rayfield/main/source"))()

local Window = Rayfield:CreateWindow({
    Name = "Synium Hub",
    LoadingTitle = "Synium Hub",
    LoadingSubtitle = "by Syn",
    ConfigurationSaving = false,
    Discord = {
        Enabled = false
    }
})

shared.SyniumWindow = Window

local TabManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/tab_manager.lua"))()

TabManager:Load(Window)
