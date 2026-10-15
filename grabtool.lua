-- Grab Tool v2 (client-side LocalScript)
-- Stabilized align behaviour + animated loading outline for unowned/unanchored parts

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local StarterGui       = game:GetService("StarterGui")

------------------------------------------------------------------------
-- CONFIG
------------------------------------------------------------------------
local CFG = {
    DEBUG = false,

    -- Distance
    SURFACE_OFFSET  = 5,
    DRAG_MIN        = 1,
    DRAG_MAX        = 150,
    AIM_WITH_CAMERA = true,

    -- Motion
    SMOOTH_SPEED         = 24,
    MAX_PULL_SPEED       = 800,
    ALIGN_RESPONSIVENESS = 200,
    RIGID_POSITION       = true,

    -- Input
    GRAB_RANGE         = 1000,
    RESPECT_GUI_CLICKS = false,
    CLICK_DEBOUNCE     = 0.10,
    DROP_KEY           = Enum.KeyCode.Q,
    SINGLE_PART_KEY    = Enum.KeyCode.G,
    THROW_SPEED        = 160,
    THROW_CLICK_TIME   = 0.20,
    THROW_CLICK_MOVE   = 8,

    -- Grouping
    LINK_CONSTRAINED_ASSEMBLIES = true,
    LINK_SCAN_PART_LIMIT        = 400,
    ASSEMBLY_SCAN_LIMIT         = 1500,
    REFRESH_INTERVAL            = 0.5,
    INCLUDE_MODEL_ASSEMBLIES    = true,
    MAX_ASSEMBLIES              = 12,
    MODEL_DESCENDANT_LIMIT      = 400,

    -- Network ownership
    NETWORK_OWNER_ENABLED  = true,
    OWNER_REMOTE_PATH      = {
        "ReplicatedStorage",
        "GrabEvents",
        "SetNetworkOwner"
    },
    OWNER_REMOTE_ARGS      = function(parts)
        return parts
    end,
    OWNER_REQUEST_INTERVAL = 0.03,
    OWNER_BATCH            = 128,

    -- Visuals / collisions
    GLOW_ENABLED              = true,
    MAX_GLOW_PARTS            = 16,
    GLOW_PENDING              = Color3.fromRGB(255, 170, 80),
    GLOW_OWNED                = Color3.fromRGB(90, 255, 140),
    COLLISION_RESTORE_TIMEOUT = 2.0,

    -- Release tolerance
    INVALID_RELEASE_GRACE = 0.25,

    -- Emergency recovery
    OWNER_EMERGENCY_DISTANCE = 60,
    OWNER_EMERGENCY_INTERVAL = 0.20,
    PRIMARY_RETRY_TIME       = 0.5,

    -- Stability tuning
    ALIGN_MAX_FORCE_SAFE          = 1e6,
    ALIGN_MAX_VELOCITY_SAFE       = 1200,
    UNOWNED_RESPONSIVENESS_FACTOR = 0.25,
    PULSE_SPEED                   = 2.0,
    COLOR_ROTATE_SPEED            = 90,
}

local function dbg(...)
    if CFG.DEBUG then
        print("[GrabTool]", ...)
    end
end

------------------------------------------------------------------------
-- Single instance guard
------------------------------------------------------------------------
local genv = (getgenv and getgenv()) or _G

if genv.__GrabToolV2 and genv.__GrabToolV2.cleanup then
    pcall(genv.__GrabToolV2.cleanup)
end

local plr = Players.LocalPlayer
local isOwner = typeof(isnetworkowner) == "function"
    and isnetworkowner
    or nil

------------------------------------------------------------------------
-- Scene objects
------------------------------------------------------------------------
local folder = Instance.new("Folder")
folder.Name = "GrabTool_" .. HttpService:GenerateGUID(false)
folder.Parent = workspace

local dragPart = Instance.new("Part")
dragPart.Name = "DragPart"
dragPart.Size = Vector3.new(0.1, 0.1, 0.1)
dragPart.Transparency = 1
dragPart.Anchored = true
dragPart.CanCollide = false
dragPart.CanTouch = false
dragPart.CanQuery = false
dragPart.Parent = folder

local dragAttach = Instance.new("Attachment")
dragAttach.Name = "DragAttach"
dragAttach.Parent = dragPart

------------------------------------------------------------------------
-- State
------------------------------------------------------------------------
local held = nil
local connections = {}
local singlePartMode = false

local savedCollide = setmetatable({}, {
    __mode = "k"
})

local restoreEpoch = setmetatable({}, {
    __mode = "k"
})

------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------
local function notify(text)
    task.spawn(function()
        for _ = 1, 5 do
            local success = pcall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = "Grab Tool",
                    Text = text,
                    Duration = 3
                })
            end)

            if success then
                return
            end

            task.wait(0.2)
        end
    end)
end

local function getHead()
    local char = plr.Character
    return char and char:FindFirstChild("Head")
end

local function aimDirection(head)
    local cam = workspace.CurrentCamera

    if CFG.AIM_WITH_CAMERA and cam then
        return cam.CFrame.LookVector
    end

    if head then
        return head.CFrame.LookVector
    end

    return cam and cam.CFrame.LookVector
        or Vector3.new(0, 0, -1)
end

local function belongsToCharacter(inst)
    local model = inst:FindFirstAncestorOfClass("Model")

    while model do
        if model:FindFirstChildOfClass("Humanoid") then
            return true
        end

        model = model:FindFirstAncestorOfClass("Model")
    end

    return false
end

------------------------------------------------------------------------
-- Network ownership
------------------------------------------------------------------------
local remoteCache = nil

local function getOwnerRemote()
    if remoteCache and remoteCache.Parent then
        return remoteCache
    end

    local node = game

    for _, name in ipairs(CFG.OWNER_REMOTE_PATH) do
        node = node and node:FindFirstChild(name)
    end

    if node and node:IsA("RemoteEvent") then
        remoteCache = node
    end

    return remoteCache
end

local function requestOwnershipBatch(parts)
    if not CFG.NETWORK_OWNER_ENABLED then
        return
    end

    local remote = getOwnerRemote()

    if not remote then
        dbg("owner remote not found")
        return
    end

    pcall(function()
        remote:FireServer(CFG.OWNER_REMOTE_ARGS(parts))
    end)
end

local function partIsOwned(part)
    if typeof(isOwner) ~= "function" then
        return false
    end

    local success, result = pcall(isOwner, part)
    return success and result == true
end

local function sendOwnerRequests(h)
    if not h then
        return
    end

    local remote = getOwnerRemote()

    if not remote then
        dbg("sendOwnerRequests: remote missing")
        return
    end

    if not h._firstPrioritySent then
        h._firstPrioritySent = true

        local initial = {}

        for _, part in ipairs(h.ownerPriority) do
            if part
                and part.Parent
                and not part.Anchored
                and not partIsOwned(part)
            then
                initial[#initial + 1] = part
            end
        end

        local index = 1

        while #initial < CFG.OWNER_BATCH
            and index <= #h.ownerRest
        do
            local part = h.ownerRest[index]

            if part
                and part.Parent
                and not part.Anchored
                and not partIsOwned(part)
            then
                initial[#initial + 1] = part
            end

            index = index + 1
        end

        if #initial > 0 then
            dbg("sending initial ownership batch, size:", #initial)
            requestOwnershipBatch(initial)
        end

        return
    end

    local rest = h.ownerRest
    local count = #rest

    if count == 0 then
        return
    end

    local batch = {}
    local attempts = 0

    while #batch < CFG.OWNER_BATCH and attempts < count do
        local part = rest[h.ownerCursor]
        h.ownerCursor = (h.ownerCursor % count) + 1
        attempts = attempts + 1

        if part
            and part.Parent
            and not part.Anchored
            and not partIsOwned(part)
        then
            batch[#batch + 1] = part
        end
    end

    if #batch > 0 then
        dbg("sending rotating ownership batch, size:", #batch)
        requestOwnershipBatch(batch)
    end
end

------------------------------------------------------------------------
-- Collision bookkeeping
------------------------------------------------------------------------
local function holdCollision(part)
    if savedCollide[part] == nil then
        savedCollide[part] = part.CanCollide
    end

    restoreEpoch[part] = (restoreEpoch[part] or 0) + 1
    part.CanCollide = false
end

local function scheduleRestore(parts, char)
    local snapshot = {}

    for _, part in ipairs(parts) do
        snapshot[part] = restoreEpoch[part]
    end

    task.spawn(function()
        if char then
            local params = OverlapParams.new()
            params.FilterType = Enum.RaycastFilterType.Include
            params.FilterDescendantsInstances = {
                char
            }

            local startTime = os.clock()

            while os.clock() - startTime
                < CFG.COLLISION_RESTORE_TIMEOUT
            do
                local blocked = false
                local checked = 0

                for part, epoch in pairs(snapshot) do
                    if restoreEpoch[part] == epoch
                        and part.Parent
                    then
                        local success, hits = pcall(
                            workspace.GetPartsInPart,
                            workspace,
                            part,
                            params
                        )

                        if success and #hits > 0 then
                            blocked = true
                            break
                        end

                        checked = checked + 1

                        if checked >= 40 then
                            break
                        end
                    end
                end

                if not blocked then
                    break
                end

                task.wait(0.1)
            end
        end

        for part, epoch in pairs(snapshot) do
            if restoreEpoch[part] == epoch then
                local original = savedCollide[part]

                if original ~= nil then
                    pcall(function()
                        part.CanCollide = original
                    end)
                end

                savedCollide[part] = nil
                restoreEpoch[part] = nil
            end
        end
    end)
end

------------------------------------------------------------------------
-- Grouping and assembly helpers
------------------------------------------------------------------------
local function getAssemblyParts(root)
    local list = {
        root
    }

    local seen = {
        [root] = true
    }

    local function add(part)
        if part
            and not seen[part]
            and part:IsA("BasePart")
            and part.AssemblyRootPart == root
        then
            seen[part] = true
            list[#list + 1] = part
        end
    end

    local success, connected = pcall(
        root.GetConnectedParts,
        root,
        true
    )

    if success and connected then
        for _, part in ipairs(connected) do
            add(part)
        end
    end

    local container = root:FindFirstAncestorOfClass("Model")

    if not container and root.Parent ~= workspace then
        container = root.Parent
    end

    if container and container ~= workspace then
        local descendants = container:GetDescendants()

        if #descendants <= CFG.ASSEMBLY_SCAN_LIMIT then
            for _, descendant in ipairs(descendants) do
                if descendant:IsA("BasePart") then
                    add(descendant)
                end
            end
        end
    end

    return list
end

local function assemblyHasCharacter(parts)
    for _, part in ipairs(parts) do
        if belongsToCharacter(part) then
            return true
        end
    end

    return false
end

local function linkedPartsOf(part)
    local output = {}
    local success, joints = pcall(part.GetJoints, part)

    if not success or not joints then
        return output
    end

    for _, joint in ipairs(joints) do
        local first
        local second

        if joint:IsA("JointInstance") then
            first = joint.Part0
            second = joint.Part1
        elseif joint:IsA("Constraint") then
            first = joint.Attachment0
                and joint.Attachment0.Parent

            second = joint.Attachment1
                and joint.Attachment1.Parent
        end

        local other

        if first == part then
            other = second
        elseif second == part then
            other = first
        end

        if other
            and typeof(other) == "Instance"
            and other:IsA("BasePart")
        then
            output[#output + 1] = other
        end
    end

    return output
end

local function collectAssemblies(root, clicked)
    if singlePartMode then
        if belongsToCharacter(clicked) then
            dbg("rejected: part belongs to a character")
            return nil
        end

        return {
            {
                root = clicked,
                parts = {
                    clicked
                }
            }
        }
    end

    local primary = {
        root = root,
        parts = getAssemblyParts(root)
    }

    if assemblyHasCharacter(primary.parts) then
        dbg("rejected: object belongs to a character")
        return nil
    end

    local list = {
        primary
    }

    local seen = {
        [root] = true
    }

    local function addAssembly(newRoot)
        if not newRoot
            or seen[newRoot]
            or newRoot.Anchored
            or #list >= CFG.MAX_ASSEMBLIES
        then
            return
        end

        seen[newRoot] = true

        local parts = getAssemblyParts(newRoot)

        if not assemblyHasCharacter(parts) then
            list[#list + 1] = {
                root = newRoot,
                parts = parts
            }
        end
    end

    if CFG.LINK_CONSTRAINED_ASSEMBLIES then
        local index = 1

        while index <= #list
            and #list < CFG.MAX_ASSEMBLIES
        do
            local parts = list[index].parts

            for partIndex = 1, math.min(
                #parts,
                CFG.LINK_SCAN_PART_LIMIT
            ) do
                for _, other in ipairs(
                    linkedPartsOf(parts[partIndex])
                ) do
                    addAssembly(other.AssemblyRootPart)
                end
            end

            index = index + 1
        end
    end

    if CFG.INCLUDE_MODEL_ASSEMBLIES then
        local model = clicked:FindFirstAncestorOfClass("Model")

        if model
            and not model:FindFirstChildOfClass("Humanoid")
        then
            local descendants = model:GetDescendants()

            if #descendants <= CFG.MODEL_DESCENDANT_LIMIT then
                for _, descendant in ipairs(descendants) do
                    if descendant:IsA("BasePart") then
                        addAssembly(descendant.AssemblyRootPart)
                    end
                end
            end
        end
    end

    return list
end

local function computeCorners(parts, frame)
    local inverse = frame:Inverse()
    local minimum = Vector3.new(
        math.huge,
        math.huge,
        math.huge
    )

    local maximum = Vector3.new(
        -math.huge,
        -math.huge,
        -math.huge
    )

    for _, part in ipairs(parts) do
        local relative = inverse * part.CFrame
        local halfSize = part.Size * 0.5

        for x = -1, 1, 2 do
            for y = -1, 1, 2 do
                for z = -1, 1, 2 do
                    local corner = relative * Vector3.new(
                        halfSize.X * x,
                        halfSize.Y * y,
                        halfSize.Z * z
                    )

                    minimum = Vector3.new(
                        math.min(minimum.X, corner.X),
                        math.min(minimum.Y, corner.Y),
                        math.min(minimum.Z, corner.Z)
                    )

                    maximum = Vector3.new(
                        math.max(maximum.X, corner.X),
                        math.max(maximum.Y, corner.Y),
                        math.max(maximum.Z, corner.Z)
                    )
                end
            end
        end
    end

    local corners = {}

    for _, x in ipairs({
        minimum.X,
        maximum.X
    }) do
        for _, y in ipairs({
            minimum.Y,
            maximum.Y
        }) do
            for _, z in ipairs({
                minimum.Z,
                maximum.Z
            }) do
                corners[#corners + 1] = Vector3.new(x, y, z)
            end
        end
    end

    return corners
end

local function frontExtent(h, direction)
    local localDirection =
        h.holdRot:VectorToObjectSpace(direction)

    local extent = 0

    for _, corner in ipairs(h.corners) do
        local distance = -corner:Dot(localDirection)

        if distance > extent then
            extent = distance
        end
    end

    return extent
end

------------------------------------------------------------------------
-- Glow
------------------------------------------------------------------------
local function makeHighlightForPart(part, color)
    local highlight = Instance.new("Highlight")
    highlight.Adornee = part
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.85
    highlight.OutlineTransparency = 0
    highlight.DepthMode =
        Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = folder

    return highlight
end

local function animateHighlights(h)
    if not h or not h.glow or h._animating then
        return
    end

    h._animating = true

    task.spawn(function()
        local startTime = os.clock()

        while held == h do
            local elapsed = os.clock() - startTime

            local pulse = 0.5 + 0.5 * math.sin(
                (elapsed / CFG.PULSE_SPEED)
                * math.pi
                * 2
            )

            local hueShift =
                (elapsed * CFG.COLOR_ROTATE_SPEED) % 360

            for _, highlight in ipairs(h.glow) do
                if highlight.Parent then
                    highlight.FillTransparency =
                        0.6 + 0.35 * (1 - pulse)

                    local baseColor =
                        h.glowColor or CFG.GLOW_PENDING

                    local hue, saturation, value =
                        Color3.toHSV(baseColor)

                    local newColor = Color3.fromHSV(
                        (hue + hueShift / 360) % 1,
                        saturation,
                        value
                    )

                    highlight.OutlineColor = newColor
                    highlight.FillColor = newColor
                end
            end

            task.wait(1 / 30)
        end

        h._animating = false
    end)
end

local function buildGlow(parts)
    local list = {}

    if not CFG.GLOW_ENABLED then
        return list
    end

    local sorted = table.clone(parts)

    table.sort(sorted, function(first, second)
        local firstSize = first.Size
        local secondSize = second.Size

        return firstSize.X
            * firstSize.Y
            * firstSize.Z
            > secondSize.X
            * secondSize.Y
            * secondSize.Z
    end)

    for index = 1, math.min(
        #sorted,
        CFG.MAX_GLOW_PARTS
    ) do
        list[#list + 1] = makeHighlightForPart(
            sorted[index],
            CFG.GLOW_PENDING
        )
    end

    return list
end

local function setGlowColor(h, color)
    if not h or h.glowColor == color then
        return
    end

    h.glowColor = color

    for _, highlight in ipairs(h.glow) do
        if highlight.Parent then
            highlight.FillColor = color
            highlight.OutlineColor = color
        end
    end
end

------------------------------------------------------------------------
-- Controls
------------------------------------------------------------------------
local function createAssemblyControls(
    assembly,
    holdCF
)
    local root = assembly.root

    if not root or not root.Parent then
        return false
    end

    local attachment = Instance.new("Attachment")
    attachment.Name = "GrabTool_Attachment"
    attachment.CFrame =
        root.CFrame:ToObjectSpace(holdCF)
    attachment.Parent = root

    local alignPosition = Instance.new("AlignPosition")
    alignPosition.Attachment0 = attachment
    alignPosition.Attachment1 = dragAttach
    alignPosition.ApplyAtCenterOfMass = true
    alignPosition.RigidityEnabled =
        CFG.RIGID_POSITION
    alignPosition.Responsiveness =
        CFG.ALIGN_RESPONSIVENESS
    alignPosition.MaxForce =
        CFG.ALIGN_MAX_FORCE_SAFE
    alignPosition.MaxVelocity =
        CFG.ALIGN_MAX_VELOCITY_SAFE
    alignPosition.Parent = root

    local alignOrientation =
        Instance.new("AlignOrientation")

    alignOrientation.Attachment0 = attachment
    alignOrientation.Attachment1 = dragAttach
    alignOrientation.RigidityEnabled = false
    alignOrientation.Responsiveness =
        CFG.ALIGN_RESPONSIVENESS
    alignOrientation.MaxTorque =
        CFG.ALIGN_MAX_FORCE_SAFE
    alignOrientation.MaxAngularVelocity =
        CFG.ALIGN_MAX_VELOCITY_SAFE
    alignOrientation.Parent = root

    assembly.att = attachment
    assembly.ap = alignPosition
    assembly.ao = alignOrientation

    pcall(function()
        root.AssemblyAngularVelocity = Vector3.zero
    end)

    return true
end

local function recreateAssemblyControls(
    assembly,
    holdCF
)
    pcall(function()
        if assembly.att then
            assembly.att:Destroy()
        end
    end)

    pcall(function()
        if assembly.ap then
            assembly.ap:Destroy()
        end
    end)

    pcall(function()
        if assembly.ao then
            assembly.ao:Destroy()
        end
    end)

    return createAssemblyControls(assembly, holdCF)
end

local function emergencyRecover(h)
    if not h or not h.root then
        return
    end

    local primary = h.assemblies[1]

    if not primary or not primary.root then
        return
    end

    local root = primary.root

    if not root.Parent then
        return
    end

    local holdRotation = root.CFrame.Rotation
    local center = root.AssemblyCenterOfMass
    local holdCF = CFrame.new(center) * holdRotation

    pcall(function()
        dragPart.CFrame = holdCF
    end)

    h.pos = center
    h.holdRot = holdRotation
    h.corners = computeCorners(h.parts, holdCF)

    for _, assembly in ipairs(h.assemblies) do
        pcall(function()
            recreateAssemblyControls(
                assembly,
                holdCF
            )
        end)
    end

    local burst = {}

    if primary.root
        and primary.root.Parent
        and not primary.root.Anchored
    then
        burst[#burst + 1] = primary.root
    end

    for index = 1, math.min(
        #h.ownerRest,
        CFG.OWNER_BATCH - #burst
    ) do
        local part = h.ownerRest[index]

        if part
            and part.Parent
            and not part.Anchored
        then
            burst[#burst + 1] = part
        end
    end

    if #burst > 0 then
        dbg(
            "emergencyRecover: sending burst ownership for",
            #burst,
            "parts"
        )

        requestOwnershipBatch(burst)
    end

    h._lastEmergency = os.clock()
end

------------------------------------------------------------------------
-- Release / grab
------------------------------------------------------------------------
local function release(throw)
    local h = held

    if not h then
        return
    end

    held = nil

    local throwDirection

    if throw then
        throwDirection = aimDirection(getHead())
    end

    for _, assembly in ipairs(h.assemblies) do
        pcall(function()
            assembly.ap:Destroy()
        end)

        pcall(function()
            assembly.ao:Destroy()
        end)

        pcall(function()
            assembly.att:Destroy()
        end)
    end

    for _, highlight in ipairs(h.glow) do
        pcall(function()
            highlight:Destroy()
        end)
    end

    if throwDirection then
        for _, assembly in ipairs(h.assemblies) do
            pcall(function()
                assembly.root.AssemblyLinearVelocity =
                    throwDirection * CFG.THROW_SPEED

                assembly.root.AssemblyAngularVelocity =
                    Vector3.zero
            end)
        end
    end

    scheduleRestore(h.parts, plr.Character)
end

local function tryGrab(part)
    local head = getHead()

    if not head then
        dbg("rejected: no head")
        return
    end

    if not part or not part:IsA("BasePart") then
        return
    end

    local assemblyRoot = part.AssemblyRootPart

    if not assemblyRoot then
        dbg(
            "rejected: no assembly root for",
            part:GetFullName()
        )
        return
    end

    if assemblyRoot.Anchored then
        if assemblyRoot == part then
            dbg(
                "rejected: this part is anchored:",
                part:GetFullName()
            )
        else
            dbg(
                "rejected: part is connected to an anchored part:",
                part:GetFullName(),
                "->",
                assemblyRoot:GetFullName()
            )
        end

        return
    end

    local assemblies = collectAssemblies(
        assemblyRoot,
        part
    )

    if not assemblies then
        return
    end

    local allParts = {}
    local partSet = {}

    for _, assembly in ipairs(assemblies) do
        for _, assemblyPart in ipairs(assembly.parts) do
            if not partSet[assemblyPart] then
                allParts[#allParts + 1] = assemblyPart
                partSet[assemblyPart] = true
            end
        end
    end

    local controlRoot = assemblies[1].root
    local holdRotation = controlRoot.CFrame.Rotation

    local center

    if singlePartMode then
        center = part.Position
    else
        center = assemblyRoot.AssemblyCenterOfMass
    end

    local holdCF =
        CFrame.new(center) * holdRotation

    dragPart.CFrame = holdCF

    for _, assembly in ipairs(assemblies) do
        createAssemblyControls(
            assembly,
            holdCF
        )
    end

    for _, assemblyPart in ipairs(allParts) do
        holdCollision(assemblyPart)
    end

    local priority = {}
    local seenTarget = {}

    local function addPriority(target)
        if target and not seenTarget[target] then
            seenTarget[target] = true
            priority[#priority + 1] = target
        end
    end

    addPriority(part)

    if not singlePartMode then
        local model =
            part:FindFirstAncestorOfClass("Model")

        if model and model.PrimaryPart then
            addPriority(model.PrimaryPart)
        end
    end

    for _, assembly in ipairs(assemblies) do
        addPriority(assembly.root)
    end

    local rest = {}

    for _, assemblyPart in ipairs(allParts) do
        if not seenTarget[assemblyPart] then
            rest[#rest + 1] = assemblyPart
        end
    end

    local h = {
        root = controlRoot,
        assemblies = assemblies,
        parts = allParts,
        partSet = partSet,
        holdRot = holdRotation,
        corners = computeCorners(allParts, holdCF),
        pos = center,
        ownerTimer = 0,
        refreshTimer = 0,
        age = 0,
        warned = false,
        ownerPriority = priority,
        ownerRest = rest,
        ownerCursor = 1,
        glow = buildGlow(allParts),
        glowColor = CFG.GLOW_PENDING,
        invalidTimer = 0,
        _lastEmergency = 0,
        _primaryRetryTimer = 0,
    }

    held = h

    animateHighlights(h)
    sendOwnerRequests(h)

    dbg(
        "grabbed",
        part:GetFullName(),
        "|",
        singlePartMode
            and "single part"
            or (
                tostring(#assemblies)
                .. " assemblies"
            ),
        "|",
        #allParts,
        "parts"
    )
end

------------------------------------------------------------------------
-- Per-frame update
------------------------------------------------------------------------
local function stillValid(h)
    local success, result = pcall(function()
        local root = h.root

        if not root
            or not root.Parent
            or not root:IsDescendantOf(workspace)
        then
            return false
        end

        local currentAssemblyRoot =
            root.AssemblyRootPart

        if not currentAssemblyRoot
            or currentAssemblyRoot.Anchored
        then
            return false
        end

        for _, assembly in ipairs(h.assemblies) do
            local assemblyRoot = assembly.root

            if not assemblyRoot
                or not assemblyRoot.Parent
            then
                return false
            end

            local attachment = assembly.att
            local alignPosition = assembly.ap
            local alignOrientation = assembly.ao

            local attachmentValid =
                attachment
                and attachment.Parent == assemblyRoot

            local positionValid =
                alignPosition
                and alignPosition.Parent == assemblyRoot

            local orientationValid =
                alignOrientation
                and alignOrientation.Parent == assemblyRoot

            if not (
                attachmentValid
                and positionValid
                and orientationValid
            ) then
                return false
            end
        end

        return true
    end)

    if not success then
        dbg("stillValid check error:", result)
        return false
    end

    return result
end

local function updateAlignResponsiveness(
    h,
    owned
)
    local responsiveness =
        CFG.ALIGN_RESPONSIVENESS

    if not owned then
        responsiveness = math.max(
            8,
            CFG.ALIGN_RESPONSIVENESS
                * CFG.UNOWNED_RESPONSIVENESS_FACTOR
        )
    end

    for _, assembly in ipairs(h.assemblies) do
        local alignPosition = assembly.ap
        local alignOrientation = assembly.ao

        if alignPosition and alignPosition.Parent then
            pcall(function()
                alignPosition.Responsiveness =
                    responsiveness

                alignPosition.MaxForce =
                    CFG.ALIGN_MAX_FORCE_SAFE

                alignPosition.MaxVelocity =
                    CFG.ALIGN_MAX_VELOCITY_SAFE
            end)
        end

        if alignOrientation
            and alignOrientation.Parent
        then
            pcall(function()
                alignOrientation.Responsiveness =
                    responsiveness

                alignOrientation.MaxTorque =
                    CFG.ALIGN_MAX_FORCE_SAFE

                alignOrientation.MaxAngularVelocity =
                    CFG.ALIGN_MAX_VELOCITY_SAFE
            end)
        end
    end
end

local function onStep(dt)
    local h = held

    if not h then
        return
    end

    local char = plr.Character
    local head = getHead()
    local humanoid = char
        and char:FindFirstChildOfClass("Humanoid")

    if not head
        or (humanoid and humanoid.Health <= 0)
    then
        release(false)
        return
    end

    local valid = stillValid(h)

    if not valid then
        h.invalidTimer =
            (h.invalidTimer or 0) + dt

        if h.invalidTimer
            >= CFG.INVALID_RELEASE_GRACE
        then
            dbg("releasing: invalid state persisted")
            release(false)
        end

        return
    end

    h.invalidTimer = 0

    local aim = aimDirection(head)

    local distance = math.clamp(
        CFG.SURFACE_OFFSET + frontExtent(h, aim),
        CFG.DRAG_MIN,
        CFG.DRAG_MAX
    )

    local target =
        head.Position + aim * distance

    local movement =
        (target - h.pos)
        * (1 - math.exp(-CFG.SMOOTH_SPEED * dt))

    local maxMovement =
        CFG.MAX_PULL_SPEED * dt

    if movement.Magnitude > maxMovement then
        movement = movement.Unit * maxMovement
    end

    h.pos = h.pos + movement

    local current = dragPart.CFrame
    local desired =
        CFrame.new(h.pos) * h.holdRot

    dragPart.CFrame = current:Lerp(
        desired,
        math.clamp(
            1 - math.exp(-CFG.SMOOTH_SPEED * dt),
            0,
            1
        )
    )

    local now = os.clock()

    if now - (h._lastEmergency or 0)
        >= CFG.OWNER_EMERGENCY_INTERVAL
    then
        for _, assembly in ipairs(h.assemblies) do
            local root = assembly.root

            if root and root.Parent then
                local rootDistance =
                    (root.Position - dragPart.Position)
                    .Magnitude

                if rootDistance
                    >= CFG.OWNER_EMERGENCY_DISTANCE
                then
                    dbg(
                        "emergency recovery:",
                        rootDistance
                    )

                    emergencyRecover(h)
                    break
                end
            end
        end
    end

    h.age = h.age + dt
    h.ownerTimer = h.ownerTimer + dt
    h._primaryRetryTimer =
        (h._primaryRetryTimer or 0) + dt

    if h.ownerTimer
        >= CFG.OWNER_REQUEST_INTERVAL
    then
        h.ownerTimer = 0

        local allOwned = false
        local primaryOwned = false

        if isOwner then
            allOwned = true

            for index, assembly in ipairs(
                h.assemblies
            ) do
                local success, result = pcall(
                    isOwner,
                    assembly.root
                )

                local owned =
                    success and result == true

                if index == 1 then
                    primaryOwned = owned
                end

                if not owned then
                    allOwned = false
                end
            end
        end

        updateAlignResponsiveness(
            h,
            primaryOwned
        )

        if not allOwned then
            sendOwnerRequests(h)
        end

        if isOwner
            and not primaryOwned
            and not h.warned
            and h.age > 2
        then
            h.warned = true

            dbg(
                "server hasn't given ownership after 2s"
            )
        end

        setGlowColor(
            h,
            primaryOwned
                and CFG.GLOW_OWNED
                or CFG.GLOW_PENDING
        )
    end

    if isOwner
        and h._primaryRetryTimer
        >= CFG.PRIMARY_RETRY_TIME
    then
        local primaryOwned = false

        local success, result = pcall(
            isOwner,
            h.assemblies[1].root
        )

        primaryOwned =
            success and result == true

        if not primaryOwned then
            local burst = {}
            local primaryRoot =
                h.assemblies[1].root

            if primaryRoot
                and primaryRoot.Parent
                and not primaryRoot.Anchored
            then
                burst[#burst + 1] = primaryRoot
            end

            for index = 1, math.min(
                #h.ownerRest,
                math.max(
                    8,
                    CFG.OWNER_BATCH - #burst
                )
            ) do
                local part = h.ownerRest[index]

                if part
                    and part.Parent
                    and not part.Anchored
                then
                    burst[#burst + 1] = part
                end
            end

            if #burst > 0 then
                requestOwnershipBatch(burst)
            end
        end

        h._primaryRetryTimer = 0
    end
end

------------------------------------------------------------------------
-- Picking and input
------------------------------------------------------------------------
local function pickPart()
    local cam = workspace.CurrentCamera

    if not cam then
        return nil
    end

    local mouse =
        UserInputService:GetMouseLocation()

    local ray = cam:ViewportPointToRay(
        mouse.X,
        mouse.Y
    )

    local ignore = {}

    if plr.Character then
        ignore[#ignore + 1] = plr.Character
    end

    local params = RaycastParams.new()
    params.FilterType =
        Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true

    for _ = 1, 8 do
        params.FilterDescendantsInstances = ignore

        local result = workspace:Raycast(
            ray.Origin,
            ray.Direction * CFG.GRAB_RANGE,
            params
        )

        if not result then
            return nil
        end

        local instance = result.Instance

        if instance:IsA("BasePart")
            and instance.Transparency >= 0.98
            and instance.Anchored
        then
            ignore[#ignore + 1] = instance
        else
            return instance
        end
    end

    return nil
end

local lastClick = 0

local function onLeftClick()
    local now = os.clock()

    if now - lastClick < CFG.CLICK_DEBOUNCE then
        return
    end

    lastClick = now

    local part = pickPart()

    if not part then
        dbg("click: nothing under the cursor")
        return
    end

    if held then
        if held.partSet[part] then
            release(false)
            return
        end

        release(false)
    end

    tryGrab(part)
end

local rmb = {
    down = false,
    t = 0,
    moved = 0
}

local function bind(signal, callback)
    connections[#connections + 1] =
        signal:Connect(callback)
end

bind(
    UserInputService.InputBegan,
    function(input, processed)
        local inputType = input.UserInputType

        if inputType
            == Enum.UserInputType.MouseButton1
        then
            if not (
                processed
                and CFG.RESPECT_GUI_CLICKS
            ) then
                onLeftClick()
            end

            return
        end

        if processed then
            return
        end

        if inputType
            == Enum.UserInputType.MouseButton2
        then
            rmb.down = true
            rmb.t = os.clock()
            rmb.moved = 0

        elseif input.KeyCode == CFG.DROP_KEY then
            release(false)

        elseif input.KeyCode
            == CFG.SINGLE_PART_KEY
        then
            singlePartMode = not singlePartMode

            if held then
                release(false)
            end

            notify(
                singlePartMode
                    and "Single Part Mode Enabled"
                    or "Single Part Mode Disabled"
            )
        end
    end
)

bind(
    UserInputService.InputChanged,
    function(input)
        if rmb.down
            and input.UserInputType
            == Enum.UserInputType.MouseMovement
        then
            rmb.moved =
                rmb.moved + input.Delta.Magnitude
        end
    end
)

bind(
    UserInputService.InputEnded,
    function(input)
        if input.UserInputType
            == Enum.UserInputType.MouseButton2
            and rmb.down
        then
            rmb.down = false

            local quick =
                os.clock() - rmb.t
                    <= CFG.THROW_CLICK_TIME
                and rmb.moved
                    <= CFG.THROW_CLICK_MOVE

            if quick and held then
                release(true)
            end
        end
    end
)

bind(RunService.PreSimulation, onStep)

bind(plr.CharacterRemoving, function()
    release(false)
end)

------------------------------------------------------------------------
-- API
------------------------------------------------------------------------
local api = {}

function api.cleanup()
    release(false)

    for part, original in pairs(savedCollide) do
        pcall(function()
            part.CanCollide = original
        end)
    end

    table.clear(savedCollide)
    table.clear(restoreEpoch)

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    connections = {}

    pcall(function()
        folder:Destroy()
    end)

    if genv.__GrabToolV2 == api then
        genv.__GrabToolV2 = nil
    end
end

genv.__GrabToolV2 = api

return api
