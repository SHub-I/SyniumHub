
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
-- TABS (no key validation)
------------------------------------------------------------

local home = window:CreateTab({ name = "Home" })
local closetab = window:CreateTab({ name = "Synium Hub" })
local universal = window:CreateTab({ name = "Universal Scripts" })
local nds = window:CreateTab({ name = "Natural Disaster Survival" })
local mm2 = window:CreateTab({ name = "Murder Mystery 2" })
local ftap = window:CreateTab({ name = "Fling Things and People" })


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
-- FLY SYSTEM (unchanged)
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
    local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
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
                if not vfly and humanoid then
                    humanoid.PlatformStand = true
                end

                if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
                    SPEED = iyflyspeed * 15
                else
                    SPEED = 0
                end

                if SPEED > 0 then
                    desired = (
                        (camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) +
                        ((camera.CFrame * CFrame.new(
                            CONTROL.L + CONTROL.R,
                            (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2,
                            0
                        ).p) - camera.CFrame.p)
                    ) * SPEED

                    lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
                else
                    desired = Vector3.zero
                end

                current = current:Lerp(desired, smoothness)
                BV.Velocity = current

                BG.CFrame = camera.CFrame
            until not FLYING

            CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
            lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
            SPEED = 0
            BG:Destroy()
            BV:Destroy()

            if humanoid then humanoid.PlatformStand = false end
        end)
    end

    flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end

        local speed = (vfly and vehicleflyspeed or iyflyspeed)

        if input.KeyCode == Enum.KeyCode.W then CONTROL.F = speed
        elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = -speed
        elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = -speed
        elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = speed
        elseif input.KeyCode == Enum.KeyCode.E and QEfly then CONTROL.Q = speed * 2
        elseif input.KeyCode == Enum.KeyCode.Q and QEfly then CONTROL.E = -speed * 2
        end
    end)

    flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
        if processed then return end

        if input.KeyCode == Enum.KeyCode.W then CONTROL.F = 0
        elseif input.KeyCode == Enum.KeyCode.S then CONTROL.B = 0
        elseif input.KeyCode == Enum.KeyCode.A then CONTROL.L = 0
        elseif input.KeyCode == Enum.KeyCode.D then CONTROL.R = 0
        elseif input.KeyCode == Enum.KeyCode.E then CONTROL.Q = 0
        elseif input.KeyCode == Enum.KeyCode.Q then CONTROL.E = 0
        end
    end)

    FLY()
end

universal:CreateToggle({
    name = "Infinite Yield Fly",
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
-- NDS
------------------------------------------------------------

nds:CreateSection({ name = "Natural Disaster Survival Scripts" })

nds:CreateButton({
    name = "Project Gravity",
    callback = function()
        window:Notify({ title = "Ran script", content = "Project Gravity" })
        loadstring(game:HttpGet("loadstring(game:HttpGet("https://rawscripts.net/raw/Natural-Disaster-Survival-Project-Gravity-NDS-239526"))()"))()
    end,
})

nds:CreateButton({
    name = "NDS Surf",
    callback = function()
        window:Notify({ title = "Ran script", content = "NDS Surf" })
        loadstring(game:HttpGet("https://pastefy.app/pTL8Ck6D/raw"))()
    end,
})

------------------------------------------------------------
-- MM2
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

------------------------------------------------------------
-- FTAP
------------------------------------------------------------

ftap:CreateSection({ name = "Fling Things and People Scripts" })

ftap:CreateButton({
    name = "Blitz Hub",
    callback = function()
        window:Notify({ title = "Ran script", content = "Blitz" })
        loadstring(game:HttpGet("https://you.whimper.xyz/sources/blitz/source.lua"))()
    end,
})

------------------------------------------------------------
-- THEMES + MUSIC
------------------------------------------------------------

closetab:CreateSection({ name = "Themes" })

local themeToggles = {}

local function activateTheme(selected)
    for name, toggle in pairs(themeToggles) do
        if name ~= selected then
            toggle:Set(false)
        end
    end
end

local function applyTheme(name, enabled)
    if not enabled then
        window:ChangeTheme("default")
        return
    end

    activateTheme(name)

    if name == "default" then window:ChangeTheme("default")
    elseif name == "cobalt" then window:ChangeTheme("cobalt")
    elseif name == "ember" then window:ChangeTheme("ember")
    elseif name == "amethyst" then window:ChangeTheme("amethyst")
    elseif name == "frost" then window:ChangeTheme("frost")
    elseif name == "rose" then window:ChangeTheme("rose")
    elseif name == "founders" then
        window:ChangeTheme({
            WindowColor = ColorSequence.new(
                Color3.fromRGB(8, 8, 10),
                Color3.fromRGB(14, 14, 18)
            ),

            ContentColor = Color3.fromRGB(255, 60, 60),
            TitlingColor = Color3.fromRGB(255, 60, 60),
            ElementTextHoverColor = Color3.fromRGB(255, 80, 80),

            TabColor = Color3.fromRGB(255, 60, 60),

            NeutralButton = Color3.fromRGB(20, 20, 22),
            NeutralButtonHover = Color3.fromRGB(255, 60, 60),
            NeutralButtonStroke = Color3.fromRGB(255, 60, 60),

            ToggleTrack = Color3.fromRGB(20, 20, 22),
            ToggleKnobOff = Color3.fromRGB(20, 20, 22),
            ToggleKnobOffTransparency = 0,

            AccentColor = Color3.fromRGB(255, 60, 60),
            AccentStroke = Color3.fromRGB(255, 60, 60),

            SliderProgress = ColorSequence.new(
                Color3.fromRGB(255, 60, 60),
                Color3.fromRGB(180, 40, 40)
            ),
            SliderHandle = Color3.fromRGB(255, 60, 60),

            FieldBackground = Color3.fromRGB(14, 14, 18),
            PlaceholderColor = Color3.fromRGB(150, 150, 150),

            DropdownHighlight = Color3.fromRGB(255, 60, 60),

            ErrorColor = Color3.fromRGB(255, 80, 80),
            ErrorStrokeColor = Color3.fromRGB(255, 40, 40),
        })
    end
end

themeToggles["default"] = closetab:CreateToggle({
    name = "Default Theme",
    callback = function(v) applyTheme("default", v) end
})

themeToggles["cobalt"] = closetab:CreateToggle({
    name = "Cobalt Theme",
    callback = function(v) applyTheme("cobalt", v) end
})

themeToggles["ember"] = closetab:CreateToggle({
    name = "Ember Theme",
    callback = function(v) applyTheme("ember", v) end
})

themeToggles["amethyst"] = closetab:CreateToggle({
    name = "Amethyst Theme",
    callback = function(v) applyTheme("amethyst", v) end
})

themeToggles["frost"] = closetab:CreateToggle({
    name = "Frost Theme",
    callback = function(v) applyTheme("frost", v) end
})

themeToggles["rose"] = closetab:CreateToggle({
    name = "Rose Theme",
    callback = function(v) applyTheme("rose", v) end
})

themeToggles["founders"] = closetab:CreateToggle({
    name = "Founders Edition Theme",
    callback = function(v) applyTheme("founders", v) end
})

------------------------------------------------------------
-- HUB MUSIC
------------------------------------------------------------

local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://77446979841289"
sound.Looped = true
sound.Volume = 0
sound.Parent = workspace

local fadeSpeed = 0.05
local musicEnabled = false

local function fadeIn()
    task.spawn(function()
        if not sound.IsPlaying then
            sound:Play()
        end
        while sound.Volume < 1 and musicEnabled do
            sound.Volume += fadeSpeed
            task.wait()
        end
    end)
end

local function fadeOut()
    task.spawn(function()
        while sound.Volume > 0 and not musicEnabled do
            sound.Volume -= fadeSpeed
            task.wait()
        end
        if sound.Volume <= 0 then
            sound:Stop()
        end
    end)
end

closetab:CreateToggle({
    name = "Hub Music",
    callback = function(v)
        musicEnabled = v
        if v then
            fadeIn()
        else
            fadeOut()
        end
    end
})

closetab:CreateSection({ name = "Close Hub" })

closetab:CreateButton({
    name = "Close Synium Hub",
    callback = function()
        sound:Stop()
        window:Notify({ title = "Closing", content = "Bye bye :(" })
        window:Unload()
        getgenv().SyniumWindow = nil
    end,
})
