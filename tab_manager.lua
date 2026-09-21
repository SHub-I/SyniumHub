local Manager = {}

local function loadAuto()
    local url = "https://raw.githubusercontent.com/SHub-I/SyniumHub/main/tabs/auto_tab.lua?ts="..os.time()
    local ok,raw = pcall(function() return game:HttpGet(url) end)
    if not ok then return nil end
    local ok2,fn = pcall(function() return loadstring(raw) end)
    if not ok2 or type(fn)~="function" then return nil end
    return fn()
end

local auto = loadAuto()

function Manager:Load(Window)
    if not auto then
        local Tab = Window:CreateTab("Error", 4483345998)
        Tab:CreateSection("Failed")
        Tab:CreateLabel({Text="auto_tab.lua missing"})
        return
    end

    pcall(function() auto(Window, "None", {}, "universl") end)
    pcall(function() auto(Window, "None", {}, "ftap") end)
    pcall(function() auto(Window, "None", {}, "nds") end)
    pcall(function() auto(Window, "None", {}, "brookhaven") end)
    pcall(function() auto(Window, "None", {}, "mm2") end)
end

return Manager
