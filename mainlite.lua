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

if getgenv().SyniumWindow then
    getgenv().SyniumWindow:Unload()
end

------------------------------------------------------------
-- RAYFIELD WINDOW (Lite+)
------------------------------------------------------------

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local window = Rayfield:CreateWindow({
    name = "Synium Hub (Lite+)",
    subtitle = "Rayfield Gen2",
    sidebarLayout = true,

    configuration = {
        autoSave = true,
        autoLoad = true,
        fileName = "SyniumHubConfig_LitePlus"
    }
})

getgenv().SyniumWindow = window

------------------------------------------------------------
-- CLOSE SOUND
------------------------------------------------------------

local closeSound = Instance.new("Sound")
closeSound.SoundId = "rbxassetid://3722232094"
closeSound.Volume = 1
closeSound.Parent = workspace

------------------------------------------------------------
-- SERVICES
------------------------------------------------------------

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

------------------------------------------------------------
-- ULTRA-SMOOTH DRAGGING
------------------------------------------------------------

local dragging = false
local dragStart
local startPos
local followSpeed = 0.18
local targetPos = window.Position

window.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = window.Position
    end
end)

window.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        targetPos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

RunService.RenderStepped:Connect(function()
    window.Position = UDim2.new(
        window.Position.X.Scale,
        window.Position.X.Offset + (targetPos.X.Offset - window.Position.X.Offset) * followSpeed,
        window.Position.Y.Scale,
        window.Position.Y.Offset + (targetPos.Y.Offset - window.Position.Y.Offset) * followSpeed
    )
end)

------------------------------------------------------------
-- TABS (Lite+)
------------------------------------------------------------

local home      = window:CreateTab({ name = "Home" })
local universal = window:CreateTab({ name = "Universal Scripts" })
local mm2       = window:CreateTab({ name = "Murder Mystery 2" })

------------------------------------------------------------
-- HOME TAB
------------------------------------------------------------

home:CreateText({
    name = "haha loser",
    text = "look at this guy using lite LMAOO",
})

home:CreateButton({
    name = "Close Synium Hub",
    callback = function()
        closeSound:Play()
        window:Notify({ title = "Closing", content = "cya lite loser LMAO" })
        task.wait(3)
        getgenv().SyniumWindow:Unload()
        getgenv().SyniumWindow = nil
    end,
})

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

-- YARHM (sandboxed so Lite doesn't crash)
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

        task.spawn(function()
            pcall(function()
                loadstring(src)()
            end)
        end)
    end,
})

------------------------------------------------------------
-- MM2 TAB (sandboxed)
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

        task.spawn(function()
            pcall(function()
                loadstring(src)()
            end)
        end)
    end,
})

mm2:CreateButton({
    name = "Eagle",
    callback = function()
        window:Notify({ title = "Ran script", content = "Eagle" })
        task.spawn(function()
            pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/EagleRobloxScript/Eagle/refs/heads/main/Eagle.lua"))()
            end)
        end)
    end,
})
