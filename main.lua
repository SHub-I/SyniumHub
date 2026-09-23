-- Synium Hub main.lua (FULL VERSION)
-- Requires keysystem.lua

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
-- CLEANUP
------------------------------------------------------------

if getgenv().SyniumWindow then
    getgenv().SyniumWindow:Unload()
end

------------------------------------------------------------
-- RAYFIELD WINDOW
------------------------------------------------------------

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local window = Rayfield:CreateWindow({
    name = "Synium Hub",
    subtitle = "Rayfield Gen2",
    sidebarLayout = true,

    configuration = {
        autoSave = true,
        autoLoad = true,
        fileName = "SyniumHubConfig"
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
-- TABS
------------------------------------------------------------

local home = window:CreateTab({ name = "Home" })
local closetab = window:CreateTab({ name = "Synium Hub" })
local universal = window:CreateTab({ name = "Universal Scripts" })
local nds = window:CreateTab({ name = "Natural Disaster Survival" })
local mm2 = window:CreateTab({ name = "Murder Mystery 2" })
local ftap = window:CreateTab({ name = "Fling Things and People" })

------------------------------------------------------------
-- UNIVERSAL TAB (always present)
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
-- FLY SYSTEM
------------------------------------------------------------

local FLYING = false
local QEfly = true
local iyflyspeed = 3
local vehicleflyspeed = 3

local flyKeyDown
local flyKeyUp

local function sFLY(vfly)
    local plr = Players.LocalPlayer
    local char = plr.Character or plr.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if not humanoid then
        repeat task.wait() until char:FindFirstChildOfClass("Humanoid")
        humanoid = char:FindFirstChildOfClass("Humanoid")
    end

    if flyKeyDown or flyKeyUp then
        flyKeyDown:Disconnect()
        flyKeyUp:Disconnect()
    end

    local T = getRoot(char)
    local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    local SPEED = 0

    local desired = Vector3.zero
    local current = Vector3.zero
    local smoothness = 0.25

    local function FLY()
        FLYING = true
        local BG = Instance.new('BodyGyro')
        local BV = Instance.new('BodyVelocity')
        BG.P = 9e4
        BG.Parent = T
        BV.Parent = T
        BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.CFrame = T.CFrame
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

        task.spawn(function()
            repeat task.wait()
                local camera = workspace.CurrentCamera
                humanoid.PlatformStand = true

                if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 then
                    SPEED = iyflyspeed * 15
                else
                    SPEED = 0
                end

                if SPEED > 0 then
                    desired = camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)
                else
                    desired = Vector3.zero
                end

                current = current:Lerp(desired, smoothness)
                BV.Velocity = current

                BG.CFrame = camera.CFrame
            until not FLYING

            BG:Destroy()
            BV:Destroy()
            humanoid.PlatformStand = false
        end)
    end

    flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end

        local speed = iyflyspeed

        if input.KeyCode == Enum.KeyCode.W then CONTROL.F = speed
        elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = -speed
        elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = -speed
        elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = speed
        end
    end)

    flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
        if processed then return end

        if input.KeyCode == Enum.KeyCode.W then CONTROL.F = 0
        elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = 0
        elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = 0
        elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = 0
        end
    end)

    FLY()
end

universal:CreateToggle({
    name = "Fly",
    callback = function(v)
        if v then
            sFLY(false)
        else
            FLYING = false
        end
    end
})

universal:CreateSlider({
    name = "Fly Speed",
    min = 1,
    max = 10,
    default = 3,
    callback = function(v)
        iyflyspeed = v
        vehicleflyspeed = v
    end
})

------------------------------------------------------------
-- PREMIUM-ONLY TABS
------------------------------------------------------------

if mode == "premium" then
    -- NDS
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

    -- MM2
    mm2:CreateSection({ name = "Murder Mystery 2 Scripts" })
    mm2:CreateButton({
        name = "YARHM",
        callback = function()
            window:Notify({ title = "Ran script", content = "YARHM" })
            local src = ""
            pcall(function() src = game:HttpGet("https://yarhm.com", false) end)
            if src == "" then
                src = game:HttpGet("https://raw.githubusercontent.com/Joystickplays/psychic-octo-invention/main/source/yarhm/1.21/yarhm.lua", false)
            end
            loadstring(src)()
        end,
    })
    mm2:CreateButton({
        name = "Eagle",
        callback = function()
            window:Notify({ title = "Ran script", content = "Eagle" })
            loadstring(game:HttpGet("https