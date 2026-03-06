--[[
    Unnamed Addon: Grenade Teleport V3
    Method: sethiddenproperty on Handle CFrame + zero Velocity/RotVelocity
    Works because the grenade is NOT anchored — we own the client physics.
    Runs every Heartbeat for maximum reliability.
]]

api:set_lua_name("GrenadeTP_V3")

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Workspace   = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ── Settings ────────────────────────────────────────────────────────────────
local CFG = {
    enabled   = false,
    offset    = Vector3.new(0, 2, 0),  -- land above HRP
    sticky    = true,                   -- keep glued every frame
    zeroVel   = true,                   -- kill velocity so it lands on target
    autoThrow = false,                  -- auto-throw on equip
}

-- ── Grenade name patterns ────────────────────────────────────────────────────
local GRENADE_PATTERNS = { "grenade", "flashbang", "frag", "molotov", "smoke", "bomb" }

local function isGrenadeName(name)
    name = name:lower()
    for _, pat in ipairs(GRENADE_PATTERNS) do
        if name:find(pat) then return true end
    end
    return false
end

-- ── Target resolution ────────────────────────────────────────────────────────
local function getTarget()
    -- 1. Unnamed silent aim target
    local sa = api:get_target("silent")
    if sa and sa.Character and sa.Character:FindFirstChild("HumanoidRootPart") then
        return sa.Character.HumanoidRootPart
    end

    -- 2. Global silent aim var set by other scripts
    local g = _G.SilentAimTarget
    if g and g.Character and g.Character:FindFirstChild("HumanoidRootPart") then
        return g.Character.HumanoidRootPart
    end

    -- 3. Mouse-closest fallback
    local mouse    = LocalPlayer:GetMouse()
    local cam      = Workspace.CurrentCamera
    local bestDist = 400
    local bestRoot = nil

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local dist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                    if dist < bestDist then
                        bestDist = dist
                        bestRoot = hrp
                    end
                end
            end
        end
    end

    return bestRoot
end

-- ── Core: apply sethiddenproperty to a single handle part ────────────────────
local function warpHandle(handle, targetCFrame)
    if not handle or not handle.Parent then return end

    -- CFrame: the main position override
    local ok, err = pcall(sethiddenproperty, handle, "CFrame", targetCFrame)
    if not ok then
        -- Executor might expose it directly, fall back
        pcall(function() handle.CFrame = targetCFrame end)
    end

    -- Kill velocity so it doesn't drift away
    if CFG.zeroVel then
        pcall(sethiddenproperty, handle, "Velocity",    Vector3.zero)
        pcall(sethiddenproperty, handle, "RotVelocity", Vector3.zero)
        -- Some executors use AssemblyLinearVelocity / AngularVelocity
        pcall(sethiddenproperty, handle, "AssemblyLinearVelocity",  Vector3.zero)
        pcall(sethiddenproperty, handle, "AssemblyAngularVelocity", Vector3.zero)
    end
end

-- ── Find the handle of a grenade instance ────────────────────────────────────
local function resolveHandle(obj)
    -- Model case: look for Handle child first, then any direct BasePart
    if obj:IsA("Model") then
        local h = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
        if h and not h.Anchored then return h end
    end

    -- Direct part case (e.g. Workspace.Ignored child)
    if obj:IsA("BasePart") and not obj.Anchored then
        return obj
    end

    return nil
end

-- ── Scan containers for live grenade parts ───────────────────────────────────
local CONTAINERS = { Workspace, pcall(function() return Workspace.Ignored end) and Workspace:FindFirstChild("Ignored") }

local function findActiveGrenades()
    local found = {}

    for _, container in ipairs(CONTAINERS) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if isGrenadeName(child.Name) then
                    local h = resolveHandle(child)
                    if h then
                        found[#found+1] = h
                    end
                end
            end
        end
    end

    return found
end

-- ── Active grenade registry (handles found this session) ─────────────────────
-- We also hook ChildAdded for instant response
local registry = {}  -- [handle] = true

local function registerFromContainer(container)
    if not container then return end
    container.ChildAdded:Connect(function(child)
        if not CFG.enabled then return end
        if not isGrenadeName(child.Name) then return end

        -- Short wait for children to replicate
        task.delay(0.05, function()
            local h = resolveHandle(child)
            if h then
                registry[h] = true

                -- Immediate one-shot warp
                local targetRoot = getTarget()
                if targetRoot then
                    warpHandle(h, targetRoot.CFrame + CFG.offset)
                end
            end
        end)
    end)
end

registerFromContainer(Workspace)
pcall(registerFromContainer, Workspace:FindFirstChild("Ignored"))

-- Also catch if Ignored is added later
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "Ignored" then
        registerFromContainer(child)
    end
end)

-- ── Heartbeat loop: sticky mode + cleanup ────────────────────────────────────
api:add_connection(RunService.Heartbeat:Connect(function()
    if not CFG.enabled then return end
    if not CFG.sticky  then return end

    local targetRoot = getTarget()
    if not targetRoot then return end

    local cf = targetRoot.CFrame + CFG.offset

    -- Merge live scan into registry every frame (catches things ChildAdded missed)
    for _, h in ipairs(findActiveGrenades()) do
        registry[h] = true
    end

    -- Warp all registered handles
    for h in pairs(registry) do
        if h and h.Parent then
            warpHandle(h, cf)
        else
            registry[h] = nil  -- cleaned up
        end
    end
end))

-- ── UI ───────────────────────────────────────────────────────────────────────
local tab = api:GetTab("Combat") or api:AddTab("Combat")
local sec = tab:AddRightGroupbox("Grenade TP V3")

sec:AddToggle("GTP3_Enable", {
    Text    = "Enable Grenade TP",
    Default = false,
    Callback = function(v)
        CFG.enabled = v
        if not v then registry = {} end  -- reset on disable
    end
})

sec:AddToggle("GTP3_Sticky", {
    Text    = "Sticky (loop every frame)",
    Default = true,
    Tooltip = "Keep grenade glued to target until it explodes",
    Callback = function(v) CFG.sticky = v end
})

sec:AddToggle("GTP3_ZeroVel", {
    Text    = "Zero Velocity",
    Default = true,
    Tooltip = "Kill grenade velocity so it doesn't bounce away",
    Callback = function(v) CFG.zeroVel = v end
})

sec:AddSlider("GTP3_OffsetY", {
    Text     = "Height Offset",
    Default  = 2,
    Min      = 0,
    Max      = 8,
    Rounding = 1,
    Suffix   = " st",
    Callback = function(v) CFG.offset = Vector3.new(0, v, 0) end
})

sec:AddDivider()

local buyAmt = sec:AddSlider("GTP3_BuyAmt", {
    Text     = "Buy Amount",
    Default  = 1,
    Min      = 1,
    Max      = 10,
    Rounding = 0
})

sec:AddButton({ Text = "Buy Grenade", Func = function()
    for i = 1, buyAmt.Value do
        api:buy_item("[Grenade]")
        task.wait(0.1)
    end
    api:notify("Bought " .. buyAmt.Value .. " grenade(s)", 2)
end })

sec:AddButton({ Text = "Warp Now (one-shot)", Func = function()
    local targetRoot = getTarget()
    if not targetRoot then
        api:notify("No target found", 2)
        return
    end

    -- Scan immediately and warp anything found
    local handles = findActiveGrenades()
    if #handles == 0 then
        api:notify("No grenades in workspace yet — throw one first!", 2)
        return
    end

    local cf = targetRoot.CFrame + CFG.offset
    for _, h in ipairs(handles) do
        warpHandle(h, cf)
    end
    api:notify("Warped " .. #handles .. " grenade(s) to " .. targetRoot.Parent.Name, 2)
end })

sec:AddButton({ Text = "Clear Registry", Func = function()
    registry = {}
    api:notify("Grenade registry cleared", 2)
end })

api:notify("Grenade TP V3 loaded", 3)
