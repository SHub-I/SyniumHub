return function(Window, rank, Exclusions)

    local Tab = Window:CreateTab("FTAP", 4483345998)

    Tab:CreateSection("FTAP Scripts")

    local scripts = {
        {file = "script1.lua", name = "FTAP Script 1"},
        {file = "script2.lua", name = "FTAP Script 2"}
    }

    for _, s in ipairs(scripts) do
        local path = "ftap/" .. s.file

        if not Exclusions:IsExcluded(rank, path) then
            Tab:CreateButton({
                Name = s.name,
                Callback = function()
                    loadstring(game:HttpGet(
                        "https://raw.githubusercontent.com/SHub-I/SyniumHub/main/scripts/" .. path
                    ))()
                end
            })
        end
    end
end
