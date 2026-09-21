local Manager = {}
local tabs = {"universal","ftap","brookhaven","mm2"}

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
    for _,name in ipairs(tabs) do
        if auto then
            pcall(function()
                -- THIS is the important part:
                auto(Window, "None", {}, name)
            end)
        else
            local Tab = Window:CreateTab(name, 4483345998)
            Tab:CreateSection("Scripts")
            Tab:CreateLabel({Text="auto_tab.lua missing"})
        end
    end
end

return Manager
