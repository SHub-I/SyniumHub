--// Synium Hub Rank Exclusions

local HttpService = game:GetService("HttpService")

local rank = shared.SyniumRank
local url = "https://raw.githubusercontent.com/SHub-I/SyniumHub/main/config/ranks.json"

local function fetch()
    local raw = game:HttpGet(url)
    return HttpService:JSONDecode(raw)
end

local data = fetch()

-- Invalid rank → exclude everything
if not data[rank] then
    shared.SyniumExclusions = { "__ALL__" }
    return shared.SyniumExclusions
end

-- Valid rank → return its exclusion list
shared.SyniumExclusions = data[rank]
return shared.SyniumExclusions
