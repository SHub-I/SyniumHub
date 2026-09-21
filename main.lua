--// Synium Hub Main

local OrionLib = shared.OrionLib
local Icons = shared.SyniumIcons
local Anim = shared.SyniumAnim
local TabManager = shared.SyniumTabManager

-- Window
local Window = OrionLib:MakeWindow({
    Name = "Synium Hub",
    HidePremium = false,
    SaveConfig = false,
    IntroEnabled = false,
    Icon = Icons.HubIcon
})

shared.SyniumWindow = Window

-- Loading animation
Anim:PlayLoading()

-- Load tabs
TabManager:Load(Window)

-- Finish loading
Anim:Finish()
