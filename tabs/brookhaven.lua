--// Synium Hub - Brookhaven Tab

return function(Window)
    local Tab = Window:CreateTab("Brookhaven")

    Tab:AddButton({
        Name = "Brookhaven Script 1",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/scripts/brookhaven/script1.lua"))()
        end
    })

    Tab:AddButton({
        Name = "Brookhaven Script 2",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/scripts/brookhaven/script2.lua"))()
        end
    })
end
