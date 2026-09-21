-- tab_manager.lua (robust loader for tabs)
local base = "https://raw.githubusercontent.com/SHub-I/SyniumHub/main/"

local function fetchRaw(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok or not res or #res == 0 then
        return false, ("HttpGet failed for %s -> %s"):format(tostring(url), tostring(res))
    end
    if res:match("^%s*<!DOCTYPE") then
        return false, ("Remote returned HTML for %s"):format(url)
    end
    return true, res
end

local function safeLoadString(content, url)
    local ok, fn = pcall(function() return loadstring(content) end)
    if not ok or type(fn) ~= "function" then
        return false, ("compile failed for %s -> %s"):format(tostring(url), tostring(fn))
    end
    local ok2, ret = pcall(function() return fn() end)
    if not ok2 then
        return false, ("execute failed for %s -> %s"):format(tostring(url), tostring(ret))
    end
    return true, ret
end

-- Load Rank and Exclusions safely (fall back to safe defaults)
local Rank = { GetRank = function() return "None" end }
local Exclusions = { IsExcluded = function() return false end }

do
    local ok, res = fetchRaw(base .. "rank.lua")
    if ok then
        local ok2, ret = safeLoadString(res, "rank.lua")
        if ok2 and type(ret) == "table" then Rank = ret end
    end
end

do
    local ok, res = fetchRaw(base .. "rank_exclusions.lua")
    if ok then
        local ok2, ret = safeLoadString(res, "rank_exclusions.lua")
        if ok2 and type(ret) == "table" then Exclusions = ret end
    end
end

local Manager = {}

local tabs = {
    "universal",
    "ftap",
    "brookhaven",
    "mm2"
}

function Manager:Load(Window)
    if not Window then
        warn("tab_manager: Load called without Window")
        return
    end

    local rank = "None"
    if type(Rank) == "table" and type(Rank.GetRank) == "function" then
        local ok, r = pcall(function() return Rank:GetRank() end)
        if ok and r then rank = r end
    end

    for _, name in ipairs(tabs) do
        local path = "tabs/" .. name .. ".lua"
        local url = base .. path
        local ok, contentOrErr = fetchRaw(url)
        if not ok then
            warn(("tab_manager: failed to fetch %s -> %s"):format(path, contentOrErr))
        else
            local ok2, moduleOrErr = safeLoadString(contentOrErr, path)
            if not ok2 then
                warn(("tab_manager: failed to load %s -> %s"):format(path, moduleOrErr))
            else
                local mod = moduleOrErr
                local success, err
                if type(mod) == "function" then
                    success, err = pcall(function() mod(Window, rank, Exclusions) end)
                    if not success then
                        warn(("tab_manager: tab function %s errored -> %s"):format(name, tostring(err)))
                    end
                elseif type(mod) == "table" then
                    -- Common patterns: module returns table with Init/Load
                    if type(mod.Load) == "function" then
                        success, err = pcall(function() mod:Load(Window, rank, Exclusions) end)
                        if not success then
                            warn(("tab_manager: tab table %s Load errored -> %s"):format(name, tostring(err)))
                        end
                    elseif type(mod.Init) == "function" then
                        success, err = pcall(function() mod.Init(Window, rank, Exclusions) end)
                        if not success then
                            warn(("tab_manager: tab table %s Init errored -> %s"):format(name, tostring(err)))
                        end
                    else
                        warn(("tab_manager: tab %s returned unsupported module type (table without Load/Init)"):format(name))
                    end
                else
                    warn(("tab_manager: tab %s returned unsupported type: %s"):format(name, type(mod)))
                end
            end
        end
    end
end

return Manager
