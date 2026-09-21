local HttpService = game:GetService("HttpService")

local ranks = HttpService:JSONDecode(
    game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/config/ranks.json")
)

local Exclusions = {}

function Exclusions:IsExcluded(rank, scriptPath)
    local list = ranks[rank]
    if not list then return false end

    if table.find(list, "__ALL__") then
        return true
    end

    return table.find(list, scriptPath) ~= nil
end

return Exclusions
