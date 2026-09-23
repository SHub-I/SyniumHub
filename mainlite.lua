-- Synium Hub Lite
if getgenv().SyniumWindow then
    getgenv().SyniumWindow:Unload()
end

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

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart")
end

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

-- HOME (UPDATES) ---------------------------------

local updates = {
    "Lite version created",
    "Removed themes",
    "Removed hub music",
    "Removed extra scripts",
    "Cleaned UI"
}

home:CreateSection({ name = "Updates" })

for _, update in ipairs(updates) do
    home:CreateText({
        name = "Update",
        text = update
    })
end
