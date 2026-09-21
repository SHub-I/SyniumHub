--// Synium Hub - Universal Tab

return function(Window)
    local Tab = Window:CreateTab("Universal")

    Tab:AddButton({
        Name = "Run Script 1",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/scripts/universal/script1.lua"))()
        end
    })

    Tab:AddButton({
        Name = "Run Script 2",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/scripts/universal/script2.lua"))()
        end
    })
end
