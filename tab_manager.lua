local Rank = loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/rank.lua"))()
local Exclusions = loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/rank_exclusions.lua"))()

local Manager = {}

local tabs = {
    "universal",
    "ftap",
    "brookhaven",
    "mm2"
}

function Manager:Load(Window)
    local rank = Rank:GetRank()

    for _, name in ipairs(tabs) do
        local url = "https://raw.githubusercontent.com/SHub-I/SyniumHub/main/tabs/" .. name .. ".lua"
        local fn = loadstring(game:HttpGet(url))
        fn(Window, rank, Exclusions)
    end
end

return Manager
