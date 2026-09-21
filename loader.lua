-- Synium Hub Loader (Rayfield)
warn(("Starting Synium Hub"))
local base = "https://raw.githubusercontent.com/SHub-I/SyniumHub/main/"

local function load(path)
    return loadstring(game:HttpGet(base .. path))()
end

load("main.lua")
