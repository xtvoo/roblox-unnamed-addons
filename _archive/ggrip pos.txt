-- Silent Root Lock + Grip Desync Addon
-- Unnamed UE – Da Hood
api:set_lua_name("silent_root_grip")  -- static name for configs [file:1][file:4]

--// Services
local RunService = game:GetService("RunService")
local Players    = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--// Config + State
local gripEnabled     = false
local lockEnabled     = false

local heightOffset    = 50   -- above HumanoidRootPart
local forwardOffset   = 0
local sidewaysOffset  = 0

local manualOffsets = {
    x = 0, y = 0, z = 0,
    rx = 0, ry = 0, rz = 0
}

local originalGrips = {}

-- Cache objects (auto updating) [file:1]
local targetCache = api:get_target_cache("silent")   -- {player, part} [file:1]
local toolCache   = api:get_tool_cache()             -- {instance, handle, gun, ...} [file:1]

--// UI
local tabs = {
    main = api:AddTab("Silent Root Grip")            -- UI API example pattern [file:1][file:4]
}

local left  = tabs.main:AddLeftGroupbox("Offsets")
local right = tabs.main:AddRightGroupbox("Status / Toggles")

-- Toggles
right:AddToggle("srg_grip_enabled", {
    Text = "Enable Grip Modifier",
    Default = false,
    Callback = function(v)
        gripEnabled = v
        if not v then
            for tool, grip in pairs(originalGrips) do
                if tool and tool:IsA("Tool") then
                    tool.Grip = grip
                end
            end
            originalGrips = {}
            api:notify("Silent Root Grip: disabled", 2) [file:1]
        else
            api:notify("Silent Root Grip: enabled", 2) [file:1]
        end
    end
})

right:AddToggle("srg_lock_enabled", {
    Text = "Lock Above Silent Target",
    Default = false,
    Callback = function(v)
        lockEnabled = v
        if v then
            api:notify("Locking to silent target HumanoidRootPart", 3) [file:1]
        end
    end
})

-- Status labels
local lblTarget  = right:AddLabel("Target: none")
local lblServer  = right:AddLabel("Server Pos: normal")
local lblTool    = right:AddLabel("Tool: none")

-- Position sliders
left:AddSlider("srg_height", {
    Text = "Height Above Root",
    Default = heightOffset,
    Min = -200,
    Max = 200,
    Rounding = 1,
    Callback = function(v) heightOffset = v end
})

left:AddSlider("srg_side", {
    Text = "Sideways",
    Default = sidewaysOffset,
    Min = -200,
    Max = 200,
    Rounding = 1,
    Callback = function(v) sidewaysOffset = v end
})

left:AddSlider("srg_forward", {
    Text = "Forward",
    Default = forwardOffset,
    Min = -200,
    Max = 200,
    Rounding = 1,
    Callback = function(v) forwardOffset = v end
})

-- Manual grip offsets (local tweaks)
left:AddSlider("srg_pos_x", {
    Text = "Grip X",
    Default = 0, Min = -50, Max = 50, Rounding = 1,
    Callback = function(v) manualOffsets.x = v end
})

left:AddSlider("srg_pos_y", {
    Text = "Grip Y",
    Default = 0, Min = -50, Max = 50, Rounding = 1,
    Callback = function(v) manualOffsets.y = v end
})

left:AddSlider("srg_pos_z", {
    Text = "Grip Z",
    Default = 0, Min = -50, Max = 50, Rounding = 1,
    Callback = function(v) manualOffsets.z = v end
})

left:AddSlider("srg_rot_x", {
    Text = "Grip Rot X",
    Default = 0, Min = -180, Max = 180, Rounding = 1,
    Callback = function(v) manualOffsets.rx = v end
})

left:AddSlider("srg_rot_y", {
    Text = "Grip Rot Y",
    Default = 0, Min = -180, Max = 180, Rounding = 1,
    Callback = function(v) manualOffsets.ry = v end
})

left:AddSlider("srg_rot_z", {
    Text = "Grip Rot Z",
    Default = 0, Min = -180, Max = 180, Rounding = 1,
    Callback = function(v) manualOffsets.rz = v end
})

--// Helpers

local function getSilentRootCF()
    local plr = targetCache.player
    if not plr then return end

    local charCache = api:get_character_cache(plr)   -- has HumanoidRootPart [file:1]
    if not charCache or not charCache.HumanoidRootPart then return end

    local rootCF = charCache.HumanoidRootPart.CFrame
    local offsetCF = rootCF * CFrame.new(sidewaysOffset, heightOffset, forwardOffset)
    return offsetCF, plr
end

-- main per-frame logic
local function step()
    if not gripEnabled then return end

    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end

    local tool = toolCache.instance
    if not tool or not tool:IsA("Tool") then
        if lblTool then lblTool:SetText("Tool: none") end
        return
    end
    if lblTool then lblTool:SetText("Tool: " .. tool.Name) end

    if not originalGrips[tool] then
        originalGrips[tool] = tool.Grip
    end

    local rootCF, targetPlayer = getSilentRootCF()

    if lockEnabled and rootCF then
        -- 1) server: freeze above target root using desync [file:1][file:4]
        api:set_desync_cframe(rootCF)

        if lblServer then
            lblServer:SetText("Server Pos: above " .. targetPlayer.Name)
        end

        -- 2) client: move grip so gun sits at same world pos
        local myPos     = char.PrimaryPart.Position
        local targetPos = rootCF.Position
        local worldOffset = targetPos - myPos

        local gripPosOffset = Vector3.new(manualOffsets.x, manualOffsets.y, manualOffsets.z)
        local gripRotOffset = CFrame.Angles(
            math.rad(manualOffsets.rx),
            math.rad(manualOffsets.ry),
            math.rad(manualOffsets.rz)
        )

        local newGrip = originalGrips[tool]
            * CFrame.new(worldOffset + gripPosOffset)
            * gripRotOffset

        tool.Grip = newGrip
        if lblTarget then lblTarget:SetText("Target: " .. targetPlayer.Name) end
    else
        -- no lock: just manual grip offsets
        local gripPosOffset = Vector3.new(manualOffsets.x, manualOffsets.y, manualOffsets.z)
        local gripRotOffset = CFrame.Angles(
            math.rad(manualOffsets.rx),
            math.rad(manualOffsets.ry),
            math.rad(manualOffsets.rz)
        )

        tool.Grip = originalGrips[tool] * CFrame.new(gripPosOffset) * gripRotOffset

        if lblServer then lblServer:SetText("Server Pos: normal") end
        if lblTarget then lblTarget:SetText("Target: none") end
    end
end

-- heartbeat connection (must call desync every frame) [file:1][file:4]
api:add_connection(RunService.Heartbeat:Connect(step))

-- events / cleanup [file:2][file:4]
api:onevent("targetchanged", function(target)
    if target then
        api:notify("Silent target: " .. target.Name, 2)
    end
end)

api:onevent("localplayerspawned", function(character)
    originalGrips = {}
end)

api:onevent("unload", function()
    for tool, grip in pairs(originalGrips) do
        if tool and tool:IsA("Tool") then
            tool.Grip = grip
        end
    end
    api:notify("Silent Root Grip addon unloaded", 2)
end)

api:notify("Silent Root Grip addon loaded", 3)  -- entry notification [file:2][file:4]
