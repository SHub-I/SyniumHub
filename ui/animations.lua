--// Synium Hub UI Animations

local Anim = {}

function Anim:PlayLoading()
    if shared.OrionLib and shared.OrionLib:FindWindow("Synium Hub") then
        local window = shared.OrionLib:FindWindow("Synium Hub")
        window:Set("Loading...", true)
        task.wait(0.5)
    end
end

function Anim:Finish()
    if shared.OrionLib and shared.OrionLib:FindWindow("Synium Hub") then
        local window = shared.OrionLib:FindWindow("Synium Hub")
        window:Set("Loading...", false)
    end
end

shared.SyniumAnim = Anim
return Anim
