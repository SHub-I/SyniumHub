--// Synium Hub - FTAP Tab

return function(Window)
    local Tab = Window:CreateTab("FTAP")

    Tab:AddButton({
        Name = "Auto Tap",
        Callback = function()
            getgenv().tap = true
            while tap do
                task.wait()
                game:GetService("ReplicatedStorage").Events.Tap:FireServer()
            end
        end
    })

    Tab:AddButton({
        Name = "Stop Auto Tap",
        Callback = function()
            getgenv().tap = false
        end
    })
end
