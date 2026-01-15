--[[====================================================
    Unnamed: Custom Ragebot Strafes Addon
    Features:
      - UI tab: "Strafe"
      - Toggle: enable/disable custom strafes
      - Dropdown: Circle / Jitter / Line / Static Offset
      - Sliders: Radius, Speed
      - Uses ragebot_strafe_override
======================================================]]

api:set_lua_name("ue_custom_strafes")

api:on_event("unload", function()
    api:notify("Custom strafes unloaded", 2)
end)

-- config table
local cfg = {
    Enabled = false,
    Mode    = "Circle",
    Radius  = 12,
    Speed   = 3,
}

--======== UI SETUP ========--
local tabs = {
    lua = api:GetTab("ragebot") or api:AddTab("ragebot");
}

do
    local gb = tabs.lua:AddLeftGroupbox("Custom Strafes")

    gb:AddToggle("cs_enabled", {
        Text = "Enable custom strafes",
        Default = false
    }):OnChanged(function(v)
        cfg.Enabled = v
    end)

    gb:AddDropdown("cs_mode", {
        Text = "Mode",
        Default = "Circle",
        Values = { "Circle", "Jitter", "Line", "Static Offset" }
    }):OnChanged(function(v)
        cfg.Mode = v
    end)

    gb:AddSlider("cs_radius", {
        Text = "Radius",
        Default = 12,
        Min = 4,
        Max = 30,
        Rounding = 0
    }):OnChanged(function(v)
        cfg.Radius = v
    end)

    gb:AddSlider("cs_speed", {
        Text = "Speed",
        Default = 3,
        Min = 1,
        Max = 10,
        Rounding = 1
    }):OnChanged(function(v)
        cfg.Speed = v
    end)
end

--======== STRAFE LOGIC ========--
local angle = 0

api:ragebot_strafe_override(function(position, unsafe, part)
    -- only run when safe and when we have a position/part
    if unsafe or not position or not part then
        return
    end

    -- toggle off = let default ragebot strafe
    if not cfg.Enabled then
        return
    end

    local dt = task.wait()
    angle += dt * cfg.Speed

    local radius = cfg.Radius
    local mode   = cfg.Mode
    local new_pos

    if mode == "Circle" then
        -- orbit around target
        local offset = Vector3.new(
            math.cos(angle) * radius,
            0,
            math.sin(angle) * radius
        )
        new_pos = position + offset

    elseif mode == "Jitter" then
        -- random jitter around target
        local offset = Vector3.new(
            (math.random() - 0.5) * radius * 2,
            0,
            (math.random() - 0.5) * radius * 2
        )
        new_pos = position + offset

    elseif mode == "Line" then
        -- strafe in camera forward direction from target
        local cam = workspace.CurrentCamera
        if not cam then
            return
        end
        local dir = cam.CFrame.LookVector * radius
        new_pos = position + dir

    elseif mode == "Static Offset" then
        -- fixed offset relative to target
        new_pos = position + Vector3.new(radius, 0, radius)
    end

    if not new_pos then
        return
    end

    -- return custom strafe cframe (must be visible to target to validate)
    return CFrame.new(new_pos, position)
end)
