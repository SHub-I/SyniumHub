--// Synium Hub Loader
local base = "https://raw.githubusercontent.com/SHub-I/SyniumHub/main/"

local function load(path)
    return loadstring(game:HttpGet(base .. path))()
end

-- Core
load("core/orion_init.lua")
load("core/rank.lua")
load("core/rank_exclusions.lua")
load("core/tab_manager.lua")

-- UI
load("ui/loading_screen.lua")
load("ui/icons.lua")
load("ui/animations.lua")

-- Main Hub
load("main.lua")

-- Tabs
load("tabs/universal.lua")
load("tabs/ftap.lua")
load("tabs/brookhaven.lua")
load("tabs/mm2.lua")
