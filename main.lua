-- Store previous window globally
if getgenv().SyniumWindow then
    getgenv().SyniumWindow:Unload()
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local window = Rayfield:CreateWindow({
    name = "Synium Hub",
    subtitle = "Rayfield Gen2",
    sidebarLayout = true,
})

getgenv().SyniumWindow = window

-- TABS ---------------------------------

local home = window:CreateTab({ name = "Home" })
local closetab = window:CreateTab({ name = "Synium Hub" })
local universal = window:CreateTab({ name = "Universal Scripts" })
local nds = window:CreateTab({ name = "Natural Disaster Survival" })
local mm2 = window:CreateTab({ name = "Murder Mystery 2" })
local ftap = window:CreateTab({ name = "Fling Things and People" })

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

universal:CreateButton({
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
                content = "YARHM Online unavailable. Using Offline version."
            })
            src = game:HttpGet("https://raw.githubusercontent.com/Joystickplays/psychic-octo-invention/main/source/yarhm/1.21/yarhm.lua", false)
        end

        loadstring(src)()
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

nds:CreateButton({
    name = "NDS Surf",
    callback = function()
        window:Notify({ title = "Ran script", content = "NDS Surf" })
        loadstring(game:HttpGet("https://pastefy.app/pTL8Ck6D/raw"))()
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
                content = "YARHM Online unavailable. Using Offline version."
            })
            src = game:HttpGet("https://raw.githubusercontent.com/Joystickplays/psychic-octo-invention/main/source/yarhm/1.21/yarhm.lua", false)
        end

        loadstring(src)()
    end,
})

mm2:CreateButton({
    name = "Eagle",
    callback = function()
        window:Notify({ title = "Ran script", content = "Eagle" })
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EagleRobloxScript/Eagle/refs/heads/main/Eagle.lua"))()
    end,
})

-- FTAP ---------------------------------------

ftap:CreateSection({ name = "Fling Things and People Scripts" })

ftap:CreateButton({
    name = "Blitz Hub",
    callback = function()
        window:Notify({ title = "Ran script", content = "Blitz" })
        loadstring(game:HttpGet("https://you.whimper.xyz/sources/blitz/source.lua"))()
    end,
})

-- SYNIUM HUB TAB ---------------------------------

closetab:CreateSection({ name = "Themes" })

closetab:CreateButton({
    name = "Default Theme",
    callback = function()
        window:ChangeTheme("default")
    end,
})

closetab:CreateButton({
    name = "Cobalt Theme",
    callback = function()
        window:ChangeTheme("cobalt")
    end,
})

closetab:CreateButton({
    name = "Ember Theme",
    callback = function()
        window:ChangeTheme("ember")
    end,
})

closetab:CreateButton({
    name = "Amethyst Theme",
    callback = function()
        window:ChangeTheme("amethyst")
    end,
})

closetab:CreateButton({
    name = "Frost Theme",
    callback = function()
        window:ChangeTheme("frost")
    end,
})

closetab:CreateButton({
    name = "Rose Theme",
    callback = function()
        window:ChangeTheme("rose")
    end,
})

closetab:CreateButton({
    name = "Founders Edition Theme",
    callback = function()
        window:ChangeTheme({
            -- Darker window background
            WindowColor = ColorSequence.new(
                Color3.fromRGB(8, 8, 10),
                Color3.fromRGB(14, 14, 18)
            ),

            -- Text colors
            ContentColor = Color3.fromRGB(255, 60, 60), -- red text
            TitlingColor = Color3.fromRGB(255, 60, 60), -- red title text
            ElementTextHoverColor = Color3.fromRGB(255, 80, 80),

            -- Tabs
            TabColor = Color3.fromRGB(255, 60, 60), -- red tab text/icons

            -- Buttons
            NeutralButton = Color3.fromRGB(20, 20, 22), -- black button
            NeutralButtonHover = Color3.fromRGB(255, 60, 60), -- red hover
            NeutralButtonStroke = Color3.fromRGB(255, 60, 60), -- red outline

            -- Toggles
            ToggleTrack = Color3.fromRGB(20, 20, 22), -- black track
            ToggleKnobOff = Color3.fromRGB(20, 20, 22), -- black knob when off
            ToggleKnobOffTransparency = 0,

            -- ON uses AccentColor automatically
            AccentColor = Color3.fromRGB(255, 60, 60), -- red toggle ON
            AccentStroke = Color3.fromRGB(255, 60, 60),

            -- Sliders
            SliderProgress = ColorSequence.new(
                Color3.fromRGB(255, 60, 60),
                Color3.fromRGB(180, 40, 40)
            ),
            SliderHandle = Color3.fromRGB(255, 60, 60),

            -- Fields
            FieldBackground = Color3.fromRGB(14, 14, 18),
            PlaceholderColor = Color3.fromRGB(150, 150, 150),

            -- Dropdown highlight
            DropdownHighlight = Color3.fromRGB(255, 60, 60),

            -- Error colors
            ErrorColor = Color3.fromRGB(255, 80, 80),
            ErrorStrokeColor = Color3.fromRGB(255, 40, 40),
        })
    end,
})



closetab:CreateSection({ name = "Close Hub" })

closetab:CreateButton({
    name = "Close Synium Hub",
    callback = function()
        window:Notify({ title = "Closing", content = "Bye bye :(" })
        window:Unload()
        getgenv().SyniumWindow = nil
    end,
})

-- HOME (AUTO UPDATES) ---------------------------------

local updates = {
    "Added new FTaP script 'Blitz Hub'",
    "Added new MM2 script 'Eagle'",
    "Added new Universal script 'YARHM'",
    "Added new Universal script 'Universal FE'",
    "Added new Universal script 'Infinite Yield'",
    "Added new NDS scripts 'Project Gravity' & 'NDS Surf'"
}

home:CreateSection({ name = "Updates" })

for _, update in ipairs(updates) do
    home:CreateText({
        name = "Update",
        text = update
    })
end
