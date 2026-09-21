--// Synium Hub Tab Manager

local TabManager = {}

function TabManager:Load(Window)
    -- Load each tab file
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/tabs/universal.lua"))()(Window)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/tabs/ftap.lua"))()(Window)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/tabs/brookhaven.lua"))()(Window)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/tabs/mm2.lua"))()(Window)
end

shared.SyniumTabManager = TabManager
return TabManager
