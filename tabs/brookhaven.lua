return function(Window, rank, Exclusions)

    local Tab = Window:MakeTab({
        Name = "Brookhaven",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })

    local Section = Tab:AddSection({
        Name = "Brookhaven Scripts"
    })

    local scripts = {
        {file = "script1.lua", name = "Brookhaven Script 1"},
        {file = "script2.lua", name = "Brookhaven Script 2"}
    }

    for _, s in ipairs(scripts) do
        local path = "brookhaven/" .. s.file

        if not Exclusions:IsExcluded(rank, path) then
            Tab:AddButton({
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
