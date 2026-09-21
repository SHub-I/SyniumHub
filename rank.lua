--// Synium Hub Rank System

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local url = "https://raw.githubusercontent.com/SHub-I/SyniumHub/main/config/players.json"

local function fetch()
    local raw = game:HttpGet(url)
    return HttpService:JSONDecode(raw)
end

local data = fetch()

-- If player not listed → "None"
local rank = data[LocalPlayer.Name] or "None"

shared.SyniumRank = rank
return rank
