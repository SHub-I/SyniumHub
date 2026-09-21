--// Synium Hub - MM2 Tab

return function(Window)
    local Tab = Window:CreateTab("MM2")

    Tab:AddButton({
        Name = "MM2 Script 1",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/scripts/mm2/script1.lua"))()
        end
    })

    Tab:AddButton({
        Name = "MM2 Script 2",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/scripts/mm2/script2.lua"))()
        end
    })
end
