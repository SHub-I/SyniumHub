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

-- Save this window globally so next execution can close it
getgenv().SyniumWindow = window

-- TABS ---------------------------------


local home = window:CreateTab({ name = "Home", icon = 93364949241311 })
local closetab = window:CreateTab({ name = "Synium Hub" })
local universal = window:CreateTab({ name = "Universal Scripts" })
local nds = window:CreateTab({ name = "Natural Disaster Survival" })
local mm2 = window:CreateTab({ name = "Murder Mystery 2" })


-- TABS ---------------------------------



universal:CreateButton({
    name = "Infinite Yield",
    callback = function()
        window:Notify({
            title = "Ran script",
            content = "Infinite Yield"
        })

        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end,
})


universal:CreateButton({
    name = "Universal FE",
    callback = function()
        window:Notify({
            title = "Ran script",
            content = "Universal FE"
        })

        loadstring(game:HttpGet"https://you.whimper.xyz/UFE.lua")()
    end,
})


-- yarhm
universal:CreateButton({
    name = "YARHM",
    callback = function()
        window:Notify({
            title = "Ran script",
            content = "YARHM"
        })

        local src = ""
local CoreGui = game:GetService("StarterGui")

pcall(function() 
    src = game:HttpGet("https://yarhm.com", false)
end)
if src == "" then
  window:Notify({
  	title = "YARHM Outage",
  	content = "YARHM Online is currently unavailable! Sorry for the inconvenience. Using YARHM Offline."
  })
  src = game:HttpGet("https://raw.githubusercontent.com/Joystickplays/psychic-octo-invention/main/source/yarhm/1.21/yarhm.lua", false)
end


loadstring(src)()


    end,
})




-- UNIVERSAL ---------------------------------


-- NDS ---------------------------------------

nds:CreateButton({
    name = "Project Gravity",
    callback = function()
        window:Notify({
            title = "Ran script",
            content = "Project Gravity"
        })

        loadstring(game:HttpGet("https://maxitom.pages.dev/raw/Pbw0ZF1w"))()
    end,
})

nds:CreateButton({
    name = "NDS Surf",
    callback = function()
        window:Notify({
            title = "Ran script",
            content = "NDS Surf"
        })

        loadstring(game:HttpGet("https://pastefy.app/pTL8Ck6D/raw"))()
    end,
})


-- NDS ---------------------------------------


-- MM2 ---------------------------------------

universal:CreateButton({
    name = "YARHM",
    callback = function()
        window:Notify({
            title = "Ran script",
            content = "YARHM"
        })

        local src = ""
local CoreGui = game:GetService("StarterGui")

pcall(function() 
    src = game:HttpGet("https://yarhm.com", false)
end)
if src == "" then
  window:Notify({
  	title = "YARHM Outage",
  	content = "YARHM Online is currently unavailable! Sorry for the inconvenience. Using YARHM Offline."
  })
  src = game:HttpGet("https://raw.githubusercontent.com/Joystickplays/psychic-octo-invention/main/source/yarhm/1.21/yarhm.lua", false)
end


loadstring(src)()


    end,
})

-- MM2 ------------------------------------





closetab:CreateButton({
    name = "Close Synium Hub",
    callback = function()
        window:Notify({
            title = "Closing",
            content = "Bye bye :("
        })

        window:Unload()
        getgenv().SyniumWindow = nil
    end,
})
