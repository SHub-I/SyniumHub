--// Synium Hub - Brookhaven Tab

return function(Window)
    local Tab = Window:CreateTab("Brookhaven")

    Tab:AddButton({
        Name = "Give All Tools",
        Callback = function()
            for _, v in ipairs(game.ReplicatedStorage.Tools:GetChildren()) do
                game.ReplicatedStorage.Events.GiveTool:FireServer(v.Name)
            end
        end
    })

    Tab:AddButton({
        Name = "Speed Boost",
        Callback = function()
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 32
        end
    })
end
