--// Synium Hub Loading Screen

local Loading = {}

function Loading:Show()
    local OrionLib = shared.OrionLib
    if not OrionLib then return end

    local window = OrionLib:FindWindow("Synium Hub")
    if not window then return end

    window:Set("Loading...", true)
end

function Loading:Hide()
    local OrionLib = shared.OrionLib
    if not OrionLib then return end

    local window = OrionLib:FindWindow("Synium Hub")
    if not window then return end

    window:Set("Loading...", false)
end

shared.SyniumLoading = Loading
return Loading
