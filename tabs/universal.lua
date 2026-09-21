--// Synium Hub - Universal Tab

return function(Window)
    local Tab = Window:CreateTab("Universal")

    Tab:AddButton({
        Name = "Infinite Yield",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
        end
    })

    Tab:AddButton({
        Name = "Simple ESP",
        Callback = function()
            for _, v in ipairs(game.Players:GetPlayers()) do
                if v ~= game.Players.LocalPlayer then
                    local highlight = Instance.new("Highlight")
                    highlight.Parent = v.Character
                end
            end
        end
    })
end
