-- main.lua (Rayfield Gen2, GitHub-powered Synium Hub)
-- Full file: forced tabs, robust GitHub loader, Rayfield Gen2 UI, Home tab with live color picker, hex input, palette, persistence.
-- Paste this into your repository at SyniumHub/main.lua and run with:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/main.lua"))()

-- User's Edge browser tabs metadata (for context; not used by the loader)
-- edge_all_open_tabs = [
-- {"pageTitle":"<WebsiteContent_oSAMtnsYzGScVE8trvqhL></WebsiteContent_oSAMtnsYzGScVE8trvqhL>","pageUrl":"<WebsiteContent_oSAMtnsYzGScVE8trvqhL></WebsiteContent_oSAMtnsYzGScVE8trvqhL>","tabId":-1,"isCurrent":true}
-- ]

local HttpService = game:GetService("HttpService")
local REPO = "SHub-I/SyniumHub"
local SCRIPTS_PATH = "scripts"

-- Rayfield Gen2 stable loader (Sirius)
local RAYFIELD_URL = "https://sirius.menu/gen2"

-- Tabs you always want visible (even if GitHub hides empty folders)
local FORCED_TABS = { "brookhaven", "mm2", "ftap", "universal" }

-- Utilities -----------------------------------------------------------------

local function api(path) return "https://api.github.com/repos/"..REPO.."/contents/"..path end
local function raw(path) return "https://raw.githubusercontent.com/"..REPO.."/main/"..path end

local function safeGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok or not res then return nil end
    return res
end

local function getJSON(url)
    local res = safeGet(url)
    if not res then return nil end
    local ok, decoded = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok then return nil end
    return decoded
end

-- GitHub listing ------------------------------------------------------------

local function getFolders()
    local data = getJSON(api(SCRIPTS_PATH))
    if not data or type(data) ~= "table" then
        local copy = {}
        for _, v in ipairs(FORCED_TABS) do table.insert(copy, v) end
        table.sort(copy)
        return copy
    end
    local out = {}
    for _, item in ipairs(data) do if item.type == "dir" then table.insert(out, item.name) end end
    local seen = {}
    for _, v in ipairs(out) do seen[v] = true end
    for _, v in ipairs(FORCED_TABS) do if not seen[v] then table.insert(out, v) end end
    table.sort(out)
    return out
end

local function getScripts(folder)
    local data = getJSON(api(SCRIPTS_PATH .. "/" .. folder))
    if not data or type(data) ~= "table" then return {} end
    local out = {}
    for _, item in ipairs(data) do
        if item.type == "file" and item.name:match("%.lua$") then table.insert(out, item.name) end
    end
    table.sort(out)
    return out
end

local function fetchScript(folder, file)
    return safeGet(raw(SCRIPTS_PATH .. "/" .. folder .. "/" .. file))
end

-- Compile sandbox -----------------------------------------------------------

-- compile: returns table { Name=string, Description=string?, Icon=string|number?, Run=function, Meta=table? }
local function compile(code, id)
    if type(code) ~= "string" then return nil end
    local ok, fn = pcall(function() return loadstring(code) end)
    if not ok or type(fn) ~= "function" then return nil end

    local regName, regFn
    local env = {
        Register = function(name, fnc)
            if type(name) == "string" and type(fnc) == "function" then regName, regFn = name, fnc end
        end,
        Description = nil,
        Icon = nil,
        Meta = nil,
        print = print, warn = warn, tostring = tostring,
        string = string, table = table, math = math,
        os = { time = os.time }, wait = task.wait
    }

    if setfenv then pcall(setfenv, fn, env) end

    local ok2, ret = pcall(fn)
    if not ok2 then return nil end

    -- If Register was used
    if regFn then
        return { Name = regName or id, Description = env.Description, Icon = env.Icon, Run = regFn, Meta = env.Meta }
    end

    -- If script returned a function
    if type(ret) == "function" then
        return { Name = id, Description = env.Description, Icon = env.Icon, Run = ret, Meta = env.Meta }
    end

    -- If script returned a table with Run
    if type(ret) == "table" and type(ret.Run) == "function" then
        return { Name = ret.Name or id, Description = ret.Description, Icon = ret.Icon, Run = ret.Run, Meta = ret.Meta }
    end

    return nil
end

-- Rayfield loader -----------------------------------------------------------

local Rayfield = nil
do
    local loader = safeGet(RAYFIELD_URL)
    if loader then
        local ok, lib = pcall(function() return loadstring(loader)() end)
        if ok and lib then Rayfield = lib end
    end
end

-- Fallback stub so UI code never crashes (keeps API shape)
if not Rayfield then
    Rayfield = {
        CreateWindow = function()
            return {
                CreateTab = function() return {
                    CreateSection = function() end,
                    CreateGroup = function() return { CreateButton = function() end, CreateSection = function() end } end,
                    CreateButton = function() end,
                    CreateLabel = function() end,
                    Select = function() end
                } end,
                CreateSection = function() end,
                Notify = function() end,
                ChangeTheme = function() end,
                Save = function() return false end,
                Load = function() return false end,
                Navigate = function() end,
                Get = function() return nil end,
                Set = function() end
            }
        end
    }
end

-- Create window -------------------------------------------------------------

local Window = Rayfield.CreateWindow({
    name = "Synium Hub",
    subtitle = "Rayfield Gen2",
    sidebarLayout = true,
    theme = "default",
    configuration = { enabled = true, autoSave = true, autoLoad = true, fileName = "synium_config" }
})

-- Helper: add button to a group (handles API variants)
local function addButtonToGroup(group, mod, folder)
    local ok, err = pcall(function()
        if group.CreateButton then
            group:CreateButton({
                name = mod.Name or ("script:"..(mod.Name or folder)),
                description = mod.Description or "",
                icon = mod.Icon or 0,
                callback = function() pcall(mod.Run) end
            })
        else
            -- older API fallback
            group:AddButton({
                Name = mod.Name or ("script:"..(mod.Name or folder)),
                Callback = function() pcall(mod.Run) end
            })
        end
    end)
    if not ok then warn("Failed to add button:", err) end
end

-- Color helpers -------------------------------------------------------------

local function colorToHex(c)
    if typeof(c) ~= "Color3" then return "#000000" end
    local r = math.floor(c.R * 255)
    local g = math.floor(c.G * 255)
    local b = math.floor(c.B * 255)
    return string.format("#%02X%02X%02X", r, g, b)
end

local function hexToColor(hex)
    if type(hex) ~= "string" then return nil end
    hex = hex:gsub("#","")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1,2),16)
    local g = tonumber(hex:sub(3,4),16)
    local b = tonumber(hex:sub(5,6),16)
    if not r or not g or not b then return nil end
    return Color3.fromRGB(r,g,b)
end

local function darker(color, amount)
    amount = amount or 18
    local r = math.max(0, math.floor(color.R*255 - amount))
    local g = math.max(0, math.floor(color.G*255 - amount))
    local b = math.max(0, math.floor(color.B*255 - amount))
    return Color3.fromRGB(r,g,b)
end

local function applyAccentColor(window, color)
    if typeof(color) ~= "Color3" then return end
    local patch = {
        AccentColor = color,
        AccentGlow = 0.12,
        TabColor = color,
        TabBackground = ColorSequence.new(color, darker(color, 18))
    }
    pcall(function() window:ChangeTheme(patch) end)
end

-- Home tab: color picker, hex input, palette, quick actions -----------------

local function createHomeTab(window)
    local homeTab = window:CreateTab({ name = "Home", icon = 93364949241311 })
    homeTab:CreateSection({ name = "Appearance" })

    -- Preview label
    local previewLabel = homeTab:CreateLabel({ name = "Current color: #0078FF" })

    -- Load stored color if present
    local storedColor = nil
    pcall(function() storedColor = window:Get and window:Get("ThemeColor") end)
    if storedColor and typeof(storedColor) == "Color3" then
        pcall(function() previewLabel:Set({ name = "Current color: " .. colorToHex(storedColor) }) end)
        pcall(function() applyAccentColor(window, storedColor) end)
    end

    -- Internal state for the picker handle
    local pickerState = {
        value = storedColor or Color3.fromRGB(0,120,255),
        alpha = 1
    }

    -- Helper to call the external callback safely
    local function safeCallback(cb, color, alpha)
        if type(cb) == "function" then
            pcall(function() cb(color, alpha) end)
        end
    end

    -- Create the actual color picker UI and capture its handle if available
    local pickerHandle = nil
    local created = false

    local function onColorChanged(color, alpha)
        if typeof(color) == "Color3" then
            pickerState.value = color
        end
        if type(alpha) == "number" then
            pickerState.alpha = alpha
        end
        local hex = colorToHex(pickerState.value)
        pcall(function() previewLabel:Set({ name = "Current color: " .. hex }) end)
        applyAccentColor(window, pickerState.value)
        -- persist transient selection
        pcall(function() if window.Set then window:Set("ThemeColor", pickerState.value) end end)
    end

    -- Try the common Rayfield Gen2 API names and capture the returned handle
    local ok = pcall(function()
        pickerHandle = homeTab:CreateColorPicker({
            name = "Accent Color",
            color = pickerState.value,
            alpha = pickerState.alpha,
            callback = function(color, alpha)
                onColorChanged(color, alpha)
            end
        })
        created = true
    end)

    if not ok or not pickerHandle then
        -- fallback to alternate API name
        pcall(function()
            pickerHandle = homeTab:CreateColor({
                name = "Accent Color",
                color = pickerState.value,
                alpha = pickerState.alpha,
                callback = function(color, alpha)
                    onColorChanged(color, alpha)
                end
            })
            created = true
        end)
    end

    -- If the UI didn't return a handle, create a minimal stub so scripts can still call methods
    if not created or not pickerHandle then
        pickerHandle = {}
    end

    -- Expose handle properties and methods per Rayfield docs
    -- .value (Color3), .alpha (number), Set(color, skipCallback?), SetAlpha(alpha, skipCallback?)
    pickerHandle.value = pickerState.value
    pickerHandle.alpha = pickerState.alpha

    function pickerHandle.Set(color, skipCallback)
        if typeof(color) ~= "Color3" then return end
        pickerState.value = color
        pickerHandle.value = color
        -- update UI if the handle supports it
        pcall(function()
            if pickerHandle.Set then
                -- some Rayfield handles implement Set already; call it
                pickerHandle:Set(color)
            elseif pickerHandle.SetValue then
                pickerHandle:SetValue(color)
            elseif pickerHandle.SetColor then
                pickerHandle:SetColor(color)
            end
        end)
        if not skipCallback then
            onColorChanged(color, pickerState.alpha)
        end
    end

    function pickerHandle.SetAlpha(alpha, skipCallback)
        if type(alpha) ~= "number" then return end
        alpha = math.clamp(alpha, 0, 1)
        pickerState.alpha = alpha
        pickerHandle.alpha = alpha
        pcall(function()
            if pickerHandle.SetAlpha then
                pickerHandle:SetAlpha(alpha)
            elseif pickerHandle.SetTransparency then
                pickerHandle:SetTransparency(1 - alpha)
            end
        end)
        if not skipCallback then
            onColorChanged(pickerState.value, alpha)
        end
    end

    -- If the returned handle already had Set/SetAlpha, wrap them to keep state in sync
    pcall(function()
        if type(pickerHandle.Set) == "function" then
            local originalSet = pickerHandle.Set
            pickerHandle.Set = function(col, skipCallback)
                originalSet(col, skipCallback)
                pickerHandle.value = col
                pickerState.value = col
                if not skipCallback then onColorChanged(col, pickerState.alpha) end
            end
        end
    end)

    pcall(function()
        if type(pickerHandle.SetAlpha) == "function" then
            local originalSetAlpha = pickerHandle.SetAlpha
            pickerHandle.SetAlpha = function(a, skipCallback)
                originalSetAlpha(a, skipCallback)
                pickerHandle.alpha = a
                pickerState.alpha = a
                if not skipCallback then onColorChanged(pickerState.value, a) end
            end
        end
    end)

    -- Hex input (keeps picker and UI in sync)
    local hexInput = homeTab:CreateInput({
        name = "Hex (e.g. #FF00AA)",
        placeholder = colorToHex(pickerState.value),
        default = colorToHex(pickerState.value),
        callback = function(text)
            local col = hexToColor(text)
            if col then
                pickerHandle.Set(col)
                -- try to sync UI handle if it supports Set
                pcall(function() if pickerHandle.Set then pickerHandle:Set(col, true) end end)
            else
                pcall(function() window:Notify({ title = "Invalid hex", content = "Enter a 6-digit hex like #RRGGBB" }) end)
            end
        end
    })

    -- Palette dropdown and save button (keeps sync)
    local palette = window:Get and window:Get("PaletteColors") or nil
    if not palette or type(palette) ~= "table" then
        palette = { "#0078FF", "#00C8AA", "#FF7A50", "#A36BFF", "#FFD166" }
    end

    local paletteDropdown = homeTab:CreateDropdown({
        name = "Saved palette",
        options = palette,
        default = palette[1],
        callback = function(choice)
            local col = hexToColor(choice)
            if col then
                pickerHandle.Set(col)
                pcall(function() if pickerHandle.Set then pickerHandle:Set(col, true) end end)
            end
        end
    })

    homeTab:CreateButton({
        name = "Add current color to palette",
        callback = function()
            local ok, hex = pcall(function()
                local text = previewLabel and previewLabel.Name or ""
                return text:match("#%x%x%x%x%x%x")
            end)
            if ok and hex then
                for _, v in ipairs(palette) do if v == hex then
                    pcall(function() window:Notify({ title = "Palette", content = hex .. " already saved" }) end)
                    return
                end end
                table.insert(palette, 1, hex)
                pcall(function() if window.Set then window:Set("PaletteColors", palette) end end)
                pcall(function() if window.Save then window:Save() end end)
                pcall(function() window:Notify({ title = "Palette", content = hex .. " saved" }) end)
                pcall(function() if paletteDropdown and paletteDropdown.SetOptions then paletteDropdown:SetOptions(palette) end end)
            else
                pcall(function() window:Notify({ title = "Save failed", content = "No color to save" }) end)
            end
        end
    })

    -- Reset and Save buttons (sync picker handle)
    homeTab:CreateButton({
        name = "Reset to default theme",
        callback = function()
            pcall(function() window:ChangeTheme("default") end)
            local defaultCol = Color3.fromRGB(0,120,255)
            pickerHandle.Set(defaultCol)
            pcall(function() if pickerHandle.Set then pickerHandle:Set(defaultCol, true) end end)
            pcall(function() previewLabel:Set({ name = "Current color: " .. colorToHex(defaultCol) }) end)
            pcall(function() window:Notify({ title = "Theme", content = "Reset to default" }) end)
        end
    })

    homeTab:CreateButton({
        name = "Save theme (persist)",
        callback = function()
            local ok, hex = pcall(function()
                local text = previewLabel and previewLabel.Name or ""
                return text:match("#%x%x%x%x%x%x")
            end)
            if ok and hex then
                local col = hexToColor(hex)
                if col then
                    pcall(function() if window.Set then window:Set("ThemeColor", col) end end)
                    pcall(function() if window.Save then window:Save() end end)
                    pcall(function() window:Notify({ title = "Theme saved", content = hex }) end)
                else
                    pcall(function() window:Notify({ title = "Save failed", content = "Invalid color" }) end)
                end
            else
                pcall(function() window:Notify({ title = "Save failed", content = "No color to save" }) end)
            end
        end
    })

    -- Return the picker handle so other code can use it if needed
    return pickerHandle
end

-- Build tabs and script buttons ---------------------------------------------

-- Build tabs from GitHub (forced tabs included)
for _, folder in ipairs(getFolders()) do
    local okTab, err = pcall(function()
        local tabName = (folder and #folder>0) and (folder:sub(1,1):upper() .. folder:sub(2)) or folder
        local Tab = Window:CreateTab({ name = tabName or "Unknown", icon = 93364949241311 })
        Tab:CreateSection({ name = (tabName or "Unknown") .. " Scripts", icon = 93364949241311 })

        -- two-column grid
        local grid = Tab:CreateGroup({})
        local left = grid:CreateGroup({ direction = "column" })
        local right = grid:CreateGroup({ direction = "column" })

        local scripts = {}
        local ok, res = pcall(function() return getScripts(folder) end)
        if ok and type(res) == "table" then scripts = res end

        if #scripts == 0 then
            Tab:CreateLabel({ name = "No scripts found" })
            -- placeholder button so tab isn't empty
            Tab:CreateButton({
                name = "Placeholder: add scripts/"..folder,
                description = "Add a .lua file to this folder on GitHub",
                callback = function() print("No scripts in folder:", folder) end
            })
        else
            for i, file in ipairs(scripts) do
                local code = fetchScript(folder, file)
                local id = file:gsub("%.lua$", "")
                local mod = compile(code, id)
                if mod then
                    local target = (i % 2 == 1) and left or right
                    addButtonToGroup(target, mod, folder)
                else
                    Tab:CreateLabel({ name = "Failed to load: " .. id })
                end
            end
        end
    end)
    if not okTab then warn("Error building tab for folder:", folder, err) end
end

-- Create Home tab (color picker + controls)
pcall(function() createHomeTab(Window) end)

-- Expose example window methods (safe calls)
pcall(function()
    -- Navigate example: Window:Navigate("Brookhaven")
    -- Change theme example: Window:ChangeTheme("ember")
    -- Save/Load: Window:Save(), Window:Load()
    -- These are available to scripts that run inside the hub.
end)

-- Finalize / Init ----------------------------------------------------------

pcall(function() if Window.Init then Window.Init() end end)

-- End of file
