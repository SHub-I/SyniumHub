local HttpService = game:GetService("HttpService")

local players = HttpService:JSONDecode(
    game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/config/players.json")
)

local Rank = {}

function Rank:GetRank()
    return players[game.Players.LocalPlayer.Name] or "None"
end

return Rank
