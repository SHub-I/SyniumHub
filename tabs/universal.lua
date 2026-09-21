-- tabs/universal.lua
return function(Window, rank, Exclusions)
    local Tab = Window:CreateTab("Universal", 4483345998)
    Tab:CreateSection("Universal Scripts")
    local scripts = {
        { path = "scripts/universal/script1.lua", name = "Infinite Yield" },
        { path = "scripts/universal/script2.lua", name = "Universal Script 2" },
    }
    for _, s in ipairs(scripts) do
        Tab:CreateButton({
            Name = s.name,
            Callback = function()
                local ok, content = pcall(function() return game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/"..s.path) end)
                if not ok or not content or #content == 0 then
                    warn("Failed to fetch", s.path)
                    return
                end
                local ok2, fn = pcall(function() return loadstring(content) end)
                if not ok2 or type(fn) ~= "function" then warn("Compile failed", s.path) return end
                local ok3, ret = pcall(function() return fn() end)
                if not ok3 then warn("Execute failed", s.path, ret) return end
                if type(ret) == "function" then pcall(ret) end
            end
        })
    end
end
