-- ue sticky glue (rage+silent, keybind via override_key_state)

api:set_lua_name("sticky_glue");

local players    = game:GetService("Players");
local runservice = game:GetService("RunService");
local localplayer = players.LocalPlayer;

-- ui
local tab   = api:AddTab("movement");
local group = tab:AddLeftGroupbox("sticky");

local stickyToggle = group:AddToggle("sticky_enabled", {
    Text    = "sticky strafe",
    Default = false,
});

local offsetXSlider = group:AddSlider("sticky_offset_x", {
    Text     = "offset x",
    Default  = 0,
    Min      = -10,
    Max      = 10,
    Rounding = 1,
});

local offsetYSlider = group:AddSlider("sticky_offset_y", {
    Text     = "offset y",
    Default  = 2,
    Min      = -10,
    Max      = 10,
    Rounding = 1,
});

local offsetZSlider = group:AddSlider("sticky_offset_z", {
    Text     = "offset z",
    Default  = 0,
    Min      = -10,
    Max      = 10,
    Rounding = 1,
});

local strengthSlider = group:AddSlider("sticky_strength", {
    Text     = "server lock",
    Default  = 150,
    Min      = 0,
    Max      = 300,
    Rounding = 0,
});

local function notify(msg, t)
    api:notify(msg, t or 1.5);
end

-- if you have a keybind element in UE with flag "sticky_keybind",
-- you can control it via override_key_state / get_ui_object [file:16]
local function sticky_key_active()
    local obj = api:get_ui_object("sticky_keybind"); -- may be nil if you didn't create one in the UI
    return not obj or obj.State; -- if no keybind defined, always active
end

local function pick_target()
    local cache = api:get_target_cache("ragebot");
    if cache and cache.player then
        return cache.player;
    end

    cache = api:get_target_cache("silent");
    if cache and cache.player then
        return cache.player;
    end

    cache = api:get_target_cache("aimbot");
    if cache and cache.player then
        return cache.player;
    end

    return nil;
end

local stickyConn;

local function stop_sticky()
    if stickyConn then
        stickyConn:Disconnect();
        stickyConn = nil;
    end
end

local function start_sticky()
    stop_sticky();

    stickyConn = api:add_connection(runservice.Heartbeat:Connect(function()
        if not stickyToggle.Value then
            return;
        end

        if not sticky_key_active() then
            return;
        end

        if not localplayer then
            return;
        end

        local character = localplayer.Character;
        local humanoid  = character and character:FindFirstChildOfClass("Humanoid");
        local root_part = humanoid and humanoid.RootPart;
        if not root_part then
            return;
        end

        local target_player = pick_target();
        if not target_player then
            return;
        end

        local target_char = target_player.Character;
        local target_hrp  = target_char and target_char:FindFirstChild("HumanoidRootPart");
        if not target_hrp then
            return;
        end

        sethiddenproperty(root_part, "PhysicsRepRootPart", target_hrp);

        local ox = offsetXSlider.Value or 0;
        local oy = offsetYSlider.Value or 2;
        local oz = offsetZSlider.Value or 0;

        local target_pos = target_hrp.Position + Vector3.new(ox, oy, oz);
        local look_dir   = target_hrp.CFrame.LookVector;
        local target_cf  = CFrame.new(target_pos, target_pos + look_dir);

        local strength_raw = strengthSlider.Value or 150;
        local strength     = strength_raw / 100;

        if api:can_desync() then
            if strength >= 1 then
                api:set_desync_cframe(target_cf);
            else
                local current_server = api:get_desync_cframe() or root_part.CFrame;
                local blended        = current_server:Lerp(target_cf, strength);
                api:set_desync_cframe(blended);
            end
        end
    end));

    notify("sticky strafe on", 1.5);
end

stickyToggle:OnChanged(function(state)
    if state then
        start_sticky();
    else
        stop_sticky();
        notify("sticky strafe off", 1.2);
    end
end)

api:on_event("unload", function()
    stop_sticky();
end)
