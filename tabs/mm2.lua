return function(Window, rank, Exclusions)

    local Tab = Window:CreateTab("MM2", 4483345998)

    Tab:CreateSection("MM2 Scripts")

    local scripts = {
        {file = "script1.lua", name = "MM2 Script 1"},
        {file = "script2.lua", name = "MM2 Script 2"}
    }

    for _, s in ipairs(scripts) do
        local path = "mm2/" .. s.file

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
