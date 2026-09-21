--// Synium Hub - FTAP Tab

return function(Window)
    local Tab = Window:CreateTab("FTAP")

    Tab:AddButton({
        Name = "FTAP Script 1",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/scripts/ftap/script1.lua"))()
        end
    })

    Tab:AddButton({
        Name = "FTAP Script 2",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/SHub-I/SyniumHub/main/scripts/ftap/script2.lua"))()
        end
    })
end
