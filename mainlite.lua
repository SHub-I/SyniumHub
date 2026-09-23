-- Synium Hub Lite + Player Whitelist
if getgenv().SyniumWindow then
    getgenv().SyniumWindow:Unload()
end

-- PLAYER WHITELIST SYSTEM ---------------------------------

local function loadPlayersYML()
    local raw = ""

    -- Try local file first
    pcall(function()
        raw = readfile("players.yml")
    end)

    -- If not found, load from GitHub
    if raw == "" then
        raw = game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/players.yml")
    end

    local sections = { lite = {}, premium = {} }
    local current = nil

    for line in raw:gmatch("[^\r\n]+") do
        local section = line:match("^(%w+):")
        if section and sections[section] then
            current = section
        else
            local name = line:match("%-%s*(.+)")
            if name and current then
                table.insert(sections[current], name)
            end
        end
    end

    return sections
end

local whitelist = loadPlayersYML()
local localName = game.Players.LocalPlayer.Name

local function isAllowed(list)
    for _, v in ipairs(list) do
        if v == localName then
            return true
        end
    end
    return false
end

-- LITE CHECK (must run BEFORE Rayfield loads)
if not isAllowed(whitelist.lite) then
    if getgenv().SyniumWindow then
        getgenv().SyniumWindow:Unload()
    end
    return
end

-- RAYFIELD ---------------------------------

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local window = Rayfield:CreateWindow({
    name = "Synium Hub Lite",
    subtitle = "Rayfield Gen2",
    sidebarLayout = true,

    configuration = {
        autoSave = true,
        autoLoad = true,
        fileName = "SyniumHubLite"
    }
})

getgenv().SyniumWindow = window

-- TABS ---------------------------------

local home = window:CreateTab({ name = "Home" })
local universal = window:CreateTab({ name = "Universal Scripts" })
local nds = window:CreateTab({ name = "Natural Disaster Survival" })
local mm2 = window:CreateTab({ name = "Murder Mystery 2" })
local ftap = window:CreateTab({ name = "Fling Things & People" })
local close = window:CreateTab({ name = "Close Hub" })

-- UNIVERSAL ---------------------------------

universal:CreateSection({ name = "Universal Scripts" })

universal:CreateButton({
    name = "Infinite Yield",
    callback = function()
        window:Notify({ title = "Ran script", content = "Infinite Yield" })
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end,
})

universal:CreateButton({
    name = "Universal FE",
    callback = function()
        window:Notify({ title = "Ran script", content = "Universal FE" })
        loadstring(game:HttpGet("https://you.whimper.xyz/UFE.lua"))()
    end,
})

-- NDS ---------------------------------------

nds:CreateSection({ name = "Natural Disaster Survival Scripts" })

nds:CreateButton({
    name = "Project Gravity",
    callback = function()
        window:Notify({ title = "Ran script", content = "Project Gravity" })
        loadstring(game:HttpGet("https://maxitom.pages.dev/raw/Pbw0ZF1w"))()
    end,
})

-- MM2 ---------------------------------------

mm2:CreateSection({ name = "Murder Mystery 2 Scripts" })

mm2:CreateButton({
    name = "YARHM",
    callback = function()
        window:Notify({ title = "Ran script", content = "YARHM" })

        local src = ""
        pcall(function()
            src = game:HttpGet("https://yarhm.com", false)
        end)

        if src == "" then
            window:Notify({
                title = "YARHM Outage",
                content = "Using Offline version."
            })
            src = game:HttpGet("https://raw.githubusercontent.com/Joystickplays/psychic-octo-invention/main/source/yarhm/1.21/yarhm.lua", false)
        end

        loadstring(src)()
    end,
})

-- FTAP ---------------------------------------

ftap:CreateSection({ name = "Fling Things & People Scripts" })

ftap:CreateButton({
    name = "Blitz Hub",
    callback = function()
        window:Notify({ title = "Ran script", content = "Blitz Hub" })
        loadstring(game:HttpGet("https://you.whimper.xyz/sources/blitz/source.lua"))()
    end,
})

-- CLOSE HUB ---------------------------------

close:CreateSection({ name = "Close Synium Hub" })

close:CreateButton({
    name = "Close Hub",
    callback = function()
        window:Notify({ title = "Closing", content = "Bye bye :(" })
        window:Unload()
        getgenv().SyniumWindow = nil
    end,
})

-- HOME ---------------------------------

local updates = {
    "Lite version created",
    "Whitelist system added",
    "Hub unloads if player not in players.yml"
}

home:CreateSection({ name = "Updates" })

for _, update in ipairs(updates) do
    home:CreateText({
        name = "Update",
        text = update
    })
end
