------------------------------------------------------------
-- KEYSYSTEM PROTECTION
------------------------------------------------------------

if not getgenv().SyniumKeySystemLoaded then
    game.Players.LocalPlayer:Kick("Please run keysystem.lua first.")
    return
end

local mode = getgenv().SyniumMode
if not mode then
    game.Players.LocalPlayer:Kick("Key system failed to set mode.")
    return
end

------------------------------------------------------------
-- UNLOAD OLD WINDOW
------------------------------------------------------------

if gui and typeof(gui) == "Instance" and gui.Destroy then
    gui:Destroy()
end

------------------------------------------------------------
-- RAYFIELD WINDOW (Lite)
------------------------------------------------------------

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local window = Rayfield:CreateWindow({
    name = "Synium Hub (Lite)",
    subtitle = "Rayfield Gen2",
    sidebarLayout = true,

    configuration = {
        autoSave = true,
        autoLoad = true,
        fileName = "SyniumHubConfig_Lite"
    }
})

getgenv().SyniumWindow = window

------------------------------------------------------------
-- SERVICES
------------------------------------------------------------

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local function getRoot(char)
    return char:FindFirstChild("HumanoidRootPart")
end

------------------------------------------------------------
-- TABS (Lite: only essentials)
------------------------------------------------------------

local home = window:CreateTab({ name = "Home" })
local universal = window:CreateTab({ name = "Universal Scripts" })
local mm2 = window:CreateTab({ name = "Murder Mystery 2" })

------------------------------------------------------------
-- UNIVERSAL TAB
------------------------------------------------------------

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
                content = "Using Offline version."
            })
            src = game:HttpGet("https://raw.githubusercontent.com/Joystickplays/psychic-octo-invention/main/source/yarhm/1.21/yarhm.lua", false)
        end

        loadstring(src)()
    end,
})

------------------------------------------------------------
-- MM2 TAB
------------------------------------------------------------

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

mm2:CreateButton({
    name = "Eagle",
    callback = function()
        window:Notify({ title = "Ran script", content = "Eagle" })
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EagleRobloxScript/Eagle/refs/heads/main/Eagle.lua"))()
    end,
})



home:CreateText({
    name = "haha loser",
    text = "look at ts guy using lite LMAOO",
})


home:CreateButton({
    name = "Close Synium Hub",
    callback = function()
        sound:Stop()
        window:Notify({ title = "Closing", content = "Bye bye :(" })
        window:Unload()
        getgenv().SyniumWindow = nil
    end,
})