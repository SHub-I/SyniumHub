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
local RunService = game:GetService("RunService")

------------------------------------------------------------
-- TABS (Lite: only essentials)
------------------------------------------------------------

local home = window:CreateTab({ name = "Home" })
local universal = window:CreateTab({ name = "Universal Scripts" })
local mm2 = window:CreateTab({ name = "Murder Mystery 2" })

------------------------------------------------------------
-- CLOSE SOUND (single definition)
------------------------------------------------------------

local closeSound = Instance.new("Sound")
closeSound.SoundId = "rbxassetid://3722232094"
closeSound.Volume = 1
closeSound.Looped = false
closeSound.Parent = workspace

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

        -- sandboxed execution to avoid runtime errors breaking the UI
        task.spawn(function()
            pcall(function()
                loadstring(src)()
            end)
        end)
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

------------------------------------------------------------
-- HOME TAB
------------------------------------------------------------

home:CreateText({
    name = "haha loser",
    text = "look at ts guy using lite LMAOO",
})

home:CreateButton({
    name = "Close Synium Hub",
    callback = function()
        -- safe close: use the single defined sound and the global window reference
        if closeSound then
            closeSound:Play()
        end

        window:Notify({ title = "Closing", content = "cya lite loser LMAO" })
        task.wait(3)

        if getgenv().SyniumWindow then
            getgenv().SyniumWindow:Unload()
            getgenv().SyniumWindow = nil
        end
    end,
})

------------------------------------------------------------
-- ULTRA-SMOOTH DRAGGING (safe hookup)
-- Hook events only after window and tabs are created and guard against nil
------------------------------------------------------------

local dragging = false
local dragStart
local startPos
local followSpeed = 0.18
local targetPos = window.Position or UDim2.new(0.5, 0, 0.5, 0)

-- helper to safely connect signals without indexing nil
local function safeConnect(signal, fn)
    if not signal then
        return nil
    end
    local ok, conn = pcall(function() return signal:Connect(fn) end)
    if ok then
        return conn
    end
    return nil
end

-- Connect window input signals safely (some Rayfield builds expose these; guard against nil)
local winInputBeganConn = safeConnect(window.InputBegan, function(input)
    if input and input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = window.Position
    end
end)

local winInputEndedConn = safeConnect(window.InputEnded, function(input)
    if input and input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Connect UserInputService and RenderStepped (these are engine services; still use safeConnect for consistency)
local uisChangedConn = safeConnect(UserInputService.InputChanged, function(input)
    if dragging and input and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        targetPos = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

local renderConn = safeConnect(RunService.RenderStepped, function()
    -- ensure window.Position and targetPos are valid UDim2s
    if not window or not window.Position or not targetPos then return end
    local curXOff = window.Position.X.Offset
    local curYOff = window.Position.Y.Offset
    local newX = curXOff + (targetPos.X.Offset - curXOff) * followSpeed
    local newY = curYOff + (targetPos.Y.Offset - curYOff) * followSpeed
    window.Position = UDim2.new(
        window.Position.X.Scale,
        newX,
        window.Position.Y.Scale,
        newY
    )
end)

-- keep references so they don't get garbage collected accidentally
local _conns = {
    winInputBeganConn,
    winInputEndedConn,
    uisChangedConn,
    renderConn
}
