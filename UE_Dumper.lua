-- =====================================================
--   UE DUMPER ADDON
--   Dumps everything to: workspace\unnamed\UE_Dumps\
--   Uses the official Unnamed API (api:method())
-- =====================================================

api:set_lua_name("UE_Dumper");

api:on_event("unload", function()
    api:notify("UE Dumper unloaded", 2);
end);

-- =====================================================
--  FILE OUTPUT SETUP
--  Saves to workspace\unnamed\UE_Dumps\
-- =====================================================

local DUMP_FOLDER = "UE_Dumps\\";

-- Make sure the folder exists (writefile creates parent dirs in most executors)
local function ensureFolder()
    -- Try creating a placeholder; if folder doesn't exist it gets created
    if not isfolder(DUMP_FOLDER) then
        makefolder(DUMP_FOLDER);
    end;
end;

local function getTimestamp()
    -- Format: YYYY-MM-DD_HH-MM-SS
    return os.date("%Y-%m-%d_%H-%M-%S");
end;

-- Build filename like: UE_Dump_full_2026-03-06_18-30-00.txt
local function makeFilename(tag)
    return DUMP_FOLDER .. "UE_Dump_" .. tag .. "_" .. getTimestamp() .. ".txt";
end;

local function saveToFile(filename, lines)
    local content = table.concat(lines, "\n");
    local ok, err = pcall(writefile, filename, content);
    if ok then
        api:notify("Saved: " .. filename:gsub("unnamed\\UE_Dumps\\", ""), 5);
    else
        api:notify("Write failed: " .. tostring(err), 5);
        warn("[UE Dumper] Write error: " .. tostring(err));
    end;
end;

-- =====================================================
--  SETUP UI TAB
-- =====================================================

local tab     = api:AddTab("Dumper");
local leftBox = tab:AddLeftGroupbox("Dump Controls");
local rightBox= tab:AddRightGroupbox("Info");

-- =====================================================
--  HELPERS
-- =====================================================

local outputLines = {};

local function logLine(line)
    table.insert(outputLines, tostring(line));
end;

local function logSection(title)
    logLine("");
    logLine("========== " .. title .. " ==========");
end;

local function logTable(name, t)
    if type(t) ~= "table" then
        logLine(name .. " = " .. tostring(t));
        return;
    end;
    logLine("[Table: " .. name .. "]");
    for k, v in pairs(t) do
        local val;
        if type(v) == "userdata" then
            local ok, str = pcall(tostring, v);
            val = ok and str or "<<Instance>>";
        elseif type(v) == "table" then
            val = "<<table>>";
        else
            val = tostring(v);
        end;
        logLine("  " .. tostring(k) .. " = " .. val);
    end;
end;

-- =====================================================
--  DUMP FUNCTIONS
-- =====================================================

local function dumpFlags()
    logSection("FLAG VALUES (via get_ui_object)");

    local allFlags = {
        -- Silent Aim
        "silent_toggle", "targeting_stickykeybind",
        "silent_showfov", "silent_color1", "silent_color2", "silent_color3",
        "silent_fov_outline", "silent_outline_color1", "silent_outline_color2", "silent_outline_color3",
        "silent_fov_fill", "silent_fill_color1", "silent_fill_color2", "silent_fill_color3",
        "silent_fov_lerp", "silent_fov_moving",
        "silent_fov_rotation", "silent_fov_rotation_speed",
        "silent_fov_settings", "silent_closestpart", "silent_matchy",
        "silent_radius", "silent_hitchance",
        -- Aimbot
        "aimbot_toggle", "aimbot_keybind",
        "aimbot_showfov", "aimbot_color1", "aimbot_color2", "aimbot_color3",
        "aimbot_closestpart", "aimbot_matchy", "aimbot_radius", "aimbot_smoothing",
        -- Targeting
        "targeting_sticky", "targeting_sticky_flags", "targeting_visibleonly",
        "targeting_spawn_prot", "targeting_allowko",
        "targeting_ignorecrew", "targeting_limitdistance",
        "targeting_whitelist", "targeting_part",
        -- Exploits
        "exploits_magic", "exploits_manipulation",
        "exploits_car_kill", "exploits_extra_pellet", "exploits_firerate",
        -- Gun
        "gun_noshootanimation", "gun_fullauto",
        "gun_autoreload", "gun_auto_ammo", "gun_auto_ammo_value", "gun_recoil",
        -- Aug
        "exploits_aug_aura", "exploits_aug_aura_adjust", "exploits_no_cooldown_value",
        -- Target HUD / Strafe
        "target_view", "target_viewbind", "target_stomp", "target_stompbind",
        "strafe_enabled", "strafe_keybind", "strafe_predict",
        "prediction_multiplier", "prediction_base",
        "strafe_random_mode", "strafe_random_offset",
        "strafe_rotation", "strafe_offset", "strafe_offsety",
        -- Ragebot
        "ragebot_enabled", "ragebot_status_color", "ragebot_keybind",
        "ragebot_flame", "ragebot_weapon", "ragebot_settings",
        "ragebot_spare", "ragebot_stomp_offset",
        "ragebot_stomp_random", "ragebot_random_offset",
        -- Resolver
        "ragebot_resolver", "ragebot_resolver_disable_within",
        "ragebot_resolver_refresh", "ragebot_resolver_forgiveness",
        "ragebot_resolver_out_of_void_bonus", "ragebot_resolver_distance_penalty",
        -- Bait
        "ragebot_defensive_enabled", "ragebot_defensive_chase",
        "ragebot_defensive_chase_forgiveness", "ragebot_defensive_chase_mode",
        "ragebot_defensive_bait_for", "ragebot_defensive_shoot_for",
        -- Abuse Spawn
        "ragebot_abuse_spawn", "ragebot_abuse_spawn_time",
        -- Spiral
        "ragebot_spiral", "ragebot_spiral_safe",
        "ragebot_spiral_distance", "ragebot_spiral_speed",
        -- Target Ragebot
        "ragebot_add_target", "ragebot_add_targetkeybind",
        "ragebot_use_selected", "ragebot_targets",
        "ragebot_whitelist", "ragebot_kill_nearby",
        "ragebot_kill_nearby_distance", "ragebot_kill_nearby_settings",
        "ragebot_target_swap", "ragebot_target_randomization_time",
        "ragebot_input",
        -- Void Spam
        "ragebot_void_in", "ragebot_void_out", "ragebot_void_when",
        -- Prediction
        "ragebot_predict", "ragebot_prediction_multiplier", "ragebot_prediction_base",
        -- World
        "color_correction_enabled", "color_correction_tint",
        "color_correction_saturation", "color_correction_contrast", "color_correction_brightness",
        -- Atmosphere
        "atmosphere_enabled", "atmosphere_color", "atmosphere_decay",
        "atmosphere_glare", "atmosphere_haze", "atmosphere_offset", "atmosphere_density",
        -- Lighting
        "lighting_toggle_Ambient", "lighting_colorAmbient",
        "lighting_toggle_ColorShift_Bottom", "lighting_colorColorShift_Bottom",
        "lighting_toggle_ColorShift_Top", "lighting_colorColorShift_Top",
        "lighting_toggle_FogColor", "lighting_colorFogColor",
        "lighting_toggle_FogEnd", "lighting_number_FogEnd",
        "lighting_toggle_FogStart", "lighting_number_FogStart",
        "lighting_toggle_ExposureCompensation", "lighting_number_ExposureCompensation",
        "lighting_toggle_Brightness", "lighting_number_Brightness",
        "lighting_toggle_ClockTime", "lighting_number_ClockTime",
        "lighting_bool_GlobalShadows", "lighting_technology",
        -- Skybox
        "skybox_enabled", "skybox_value",
        -- Weather
        "weather_enabled", "weather_color_1", "weather_color_2", "weather_color_3",
        "weather_value", "weather_rate_multiplier", "weather_lifetime_multiplier",
        "weather_timescale_multiplier",
        -- Sun rays
        "sunrays_enabled", "sunrays_intensity", "sunrays_spread",
        -- Camera
        "camera_inf_zoom", "camera_fov_changer", "camera_fov_changer_amount",
        "camera_aspect_ratio", "camera_aspect_ratio_x", "camera_aspect_ratio_y", "camera_blur",
        -- ESP
        "esp_box", "esp_box_color", "esp_box_color2", "esp_box_color3",
        "esp_fill", "esp_fill_color_start", "esp_fill_color_middle", "esp_fill_color_end",
        "esp_name", "esp_name_color", "esp_name_color2", "esp_name_color3",
        "esp_name_rotation", "esp_exploiter_color",
        "esp_weapon", "esp_weapon_color", "esp_weapon_color2", "esp_weapon_color3",
        "esp_distance", "esp_distance_color", "esp_distance_color2", "esp_distance_color3",
        "esp_distance_rotation",
        "esp_accuracy", "esp_accuracy_prefix_color", "esp_accuracy_text_color",
        "esp_healthbar", "esp_healthbar_color_start", "esp_healthbar_color_middle", "esp_healthbar_color_end",
        "esp_shield", "esp_shield_color_start", "esp_shield_color_middle", "esp_shield_color_end",
        "esp_healthbar_resize", "esp_healthbar_moving", "esp_healthbar_type",
        "esp_healthbar_slices", "esp_healthbar_speed", "esp_healthbar_health_lerp",
        -- Override Appearance
        "esp_override_appearance", "esp_material",
        "esp_body_color", "esp_body_color_value",
        "esp_body_disables", "esp_body_transparency",
        -- Chams / Highlight
        "esp_chams", "esp_chams_color2", "esp_chams_color",
        "esp_chams_alpha_fill", "esp_chams_alpha_outline", "esp_chams_settings",
        -- ESP Effects
        "esp_effects_particle", "esp_effects_particle_color1", "esp_effects_particle_color2", "esp_effects_particle_color3",
        "esp_effects_particle_value",
        "esp_effects_aura", "esp_effects_aura_color1", "esp_effects_aura_color2", "esp_effects_aura_color3",
        -- ESP Text
        "esp_font", "esp_name_type", "esp_accuracy_type",
        -- Visuals (Self)
        "self_customization_material",
        "self_customization_color", "self_customization_color_value",
        "self_customization_disable_decals", "self_customization_transparency",
        "self_customization_material_value",
        "local_highlight", "local_highlight_fill", "local_highlight_outline",
        "self_effects_particle", "self_effects_particle_color1", "self_effects_particle_color2", "self_effects_particle_color3",
        "self_effects_aura", "self_effects_aura_color1", "self_effects_aura_color2", "self_effects_aura_color3",
        -- Tracer Override
        "bullet_tracer_disable", "bullet_tracer_disable_value",
        "bullet_tracer_override", "bullet_tracer_override_value",
        -- Custom Tracer
        "custom_tracer_enabled", "custom_tracer_color", "custom_tracer_color2",
        "custom_tracer_outline", "custom_tracer_selected",
        "custom_tracer_lifetime", "custom_tracer_fade", "custom_tracer_position_lerp",
        "custom_tracer_width", "custom_tracer_length",
        "custom_tracer_emission", "custom_tracer_glow", "custom_tracer_speed",
        -- Shoot Sound
        "shoot_sound_change", "shoot_sound_change_value",
        "shoot_sound_apply_mode", "shoot_sound_custom_value",
        "shoot_sound_speed", "shoot_sound_volume", "shoot_sound_start",
        -- Crosshair
        "crosshair_enabled", "crosshair_color_1", "crosshair_color_2", "crosshair_color_3", "crosshair_color_4",
        "crosshair_outline", "crosshair_outline_color_1", "crosshair_outline_color_2", "crosshair_outline_color_3", "crosshair_outline_color_4",
        "crosshair_rotation", "crosshair_rotation_speed",
        "crosshair_bounce", "crosshair_bounce_speed",
        "crosshair_offset", "crosshair_length", "crosshair_thickness",
        "crosshair_lerp", "crosshair_settings", "crosshair_misc",
        -- Server Position Indicator
        "indicator_server_enabled", "indicator_server_color",
        "indicator_server_display_over", "indicator_server_always",
        "indicator_server_moving", "indicator_server_icon",
        "indicator_server_lerp", "indicator_server_size",
        "indicator_server_rotation", "indicator_server_speed",
        -- Tool Style
        "tool_customization_material",
        "tool_customization_color", "tool_customization_color_value",
        "tool_customization_disable_decals", "tool_customization_transparency",
        "tool_customization_material_value",
        -- Skin Changer
        "skin_changer_enabled", "skin_changer_weapon",
        "skin_changer_values", "skin_changer_search",
        -- Hit Effects
        "hit_effects_enabled", "hit_effects_col_1", "hit_effects_col_2", "hit_effects_col_3",
        "hit_effects_weld", "hit_effects_selected",
        "hit_effects_settings", "hit_effects_material",
        -- Indicators
        "indicator_manipulated", "indicator_manipulated_color",
        "indicator_ammo", "indicator_ammo_color",
        "indicator_offset_x", "indicator_offset_y",
        "indicator_font", "indicator_style",
        -- Desync Visualizer
        "desync_visualizer_enabled", "desync_visualizer_customization",
        "desync_visualizer_copy_animations", "desync_visualizer_transparency",
        "desync_visualizer_material",
        -- Target Visual
        "target_tracer", "target_tracer_customization",
        "target_highlight", "target_highlight_outline", "target_highlight_fill",
        "target_highlight_type",
        -- Character / Movement
        "movement_velocity", "movement_velocitykeybind",
        "movement_walkspeed", "movement_jumppower",
        "movement_velocityvalue", "movement_walkspeedvalue", "movement_jumppowervalue",
        -- Desync
        "desync_enabled", "desync_keybind", "desync_anti_clip",
        "desync_x_min", "desync_x_max",
        "desync_y_min", "desync_y_max",
        "desync_z_min", "desync_z_max",
        "desync_pitch", "desync_yaw", "desync_roll", "desync_random_angle",
        -- Animation Player
        "animation_player_enabled", "animation_player_keybind",
        "animation_player_value", "animation_player_custom_input",
        "animation_player_speed",
        "animation_player_start_position", "animation_player_end_position",
        -- Noclip / Fly
        "movement_noclip", "movement_noclipkeybind",
        "movement_fly", "movement_flykeybind", "movement_flyvalue",
        -- Protection
        "character_prot_anti_stomp", "character_prot_perfect_block",
        "character_prot_anti_stomp_type",
        -- Fake Position
        "protection_fake_position", "protection_fake_position_keybind",
        "protection_fake_settings",
        -- Void
        "character_prot_void", "character_prot_voidkeybind",
        "character_prot_void_spam",
        "character_prot_void_in", "character_prot_void_out",
        -- Velocity Breaker
        "breaker_velocity_enabled", "breaker_velocity_keybind",
        "breaker_velocity_type", "breaker_velocity_mult",
        -- Ragdoll
        "ragdoll_enabled", "ragdoll_keybind", "ragdoll_shape",
        -- Misc
        "shop_selected_item", "shop_item_input",
        "chat_spy_enabled",
        "chat_spam_enabled", "chat_spam_order", "chat_spam_mode", "chat_spam_input",
        "boxer_rig", "boxer_rigoverride", "boxer_rigvalue",
        "basketball_rig", "basketball_value",
        "image_sender",
        "auto_stomp_enabled", "auto_stomp_keybind", "auto_stomp_animation", "auto_stomp_delay",
        "detector_mod", "detector_modvalue",
        "target_hit_notify", "target_hit_notify_duration", "target_hit_notify_input",
        "self_damage_notify", "self_damage_notify_duration", "self_damage_notify_text", "self_damage_notify_input",
        "auto_mask_enabled", "auto_mask_type",
        "auto_armor_enabled", "auto_armor_damage", "auto_armor_type",
        "server_spoofer_value",
        -- Settings
        "MenuKeybind", "MenuBlurTransparency",
        "KeybindMenu", "KeybindMenuTransparency", "KeybindMenuValue",
        -- Notifications
        "NotificationClips", "NotificationClipsDistance",
        "NotificationColors", "NotificationColorsMain", "NotificationColorsAccent",
        "NotificationColorsOutline", "NotificationColorsFont",
        "NotificationPositionX", "NotificationPositionY",
        "NotificationTransparency", "NotificationAnchorStyle",
        "NotificationBarStyle", "NotificationStyleSortOrder",
        -- Themes
        "BackgroundColor", "MainColor", "AccentColor", "OutlineColor", "FontColor",
        "ThemeManager_ThemeList", "ThemeManager_CustomThemeName", "ThemeManager_CustomThemeList",
        "RANDOM_THEME_OVERRIDE", "RANDOM_THEME_OVERRIDE1", "RANDOM_THEME_OVERRIDE2",
        -- Config
        "SaveManager_ConfigName", "SaveManager_ConfigList",
        -- Lua
        "lua_selected_script", "lua_selected_config_name", "lua_selected_config",
    };

    local found   = 0;
    local missing = 0;

    for _, flag in ipairs(allFlags) do
        local ok, obj = pcall(function()
            return api:get_ui_object(flag);
        end);
        if ok and obj ~= nil then
            local valueOk, value = pcall(function()
                if obj.Value ~= nil then return obj.Value; end;
                return "<<object (no .Value)>>";
            end);
            local display = valueOk and tostring(value) or "<<error reading value>>";
            logLine("[FLAG]    " .. flag .. " = " .. display);
            found = found + 1;
        else
            logLine("[MISSING] " .. flag);
            missing = missing + 1;
        end;
    end;

    logLine("");
    logLine("Flags found: " .. found .. " | Missing/nil: " .. missing);
end;

local function dumpToolCache()
    logSection("TOOL CACHE");
    local ok, cache = pcall(function() return api:get_tool_cache(); end);
    if ok and cache then
        logTable("tool_cache", cache);
    else
        logLine("tool_cache: unavailable or nil");
    end;
end;

local function dumpDataCache()
    logSection("DATA CACHE");
    local players = game:GetService("Players");
    local lp = players.LocalPlayer;
    local ok, cache = pcall(function() return api:get_data_cache(lp); end);
    if ok and cache then
        logTable("data_cache [" .. lp.Name .. "]", cache);
    else
        logLine("data_cache [local]: unavailable or nil");
    end;
    for _, player in ipairs(players:GetPlayers()) do
        if player ~= lp then
            local ok2, c2 = pcall(function() return api:get_data_cache(player); end);
            if ok2 and c2 then
                logTable("data_cache [" .. player.Name .. "]", c2);
            else
                logLine("data_cache [" .. player.Name .. "]: nil");
            end;
        end;
    end;
end;

local function dumpStatusCache()
    logSection("STATUS CACHE");
    local players = game:GetService("Players");
    local lp = players.LocalPlayer;
    local ok, cache = pcall(function() return api:get_status_cache(lp); end);
    if ok and cache then
        logTable("status_cache [" .. lp.Name .. "]", cache);
    else
        logLine("status_cache [local]: unavailable or nil");
    end;
    for _, player in ipairs(players:GetPlayers()) do
        if player ~= lp then
            local ok2, c2 = pcall(function() return api:get_status_cache(player); end);
            if ok2 and c2 then
                logTable("status_cache [" .. player.Name .. "]", c2);
            else
                logLine("status_cache [" .. player.Name .. "]: nil");
            end;
        end;
    end;
end;

local function dumpTargetCache()
    logSection("TARGET CACHE");
    for _, t in ipairs({"ragebot", "aimbot", "silent"}) do
        local ok, cache = pcall(function() return api:get_target_cache(t); end);
        if ok and cache then
            logTable("target_cache [" .. t .. "]", cache);
        else
            logLine("target_cache [" .. t .. "]: nil or error");
        end;
    end;
end;

local function dumpCharacterCache()
    logSection("CHARACTER CACHE");
    local players = game:GetService("Players");
    for _, player in ipairs(players:GetPlayers()) do
        local ok, cache = pcall(function() return api:get_character_cache(player); end);
        if ok and cache then
            local parts = {};
            for k, v in pairs(cache) do
                local ok2, str = pcall(tostring, v);
                table.insert(parts, tostring(k) .. "=" .. (ok2 and str or "<<err>>"));
            end;
            logLine("char_cache [" .. player.Name .. "]: " .. table.concat(parts, ", "));
        else
            logLine("char_cache [" .. player.Name .. "]: nil / no character");
        end;
    end;
end;

local function dumpRagebotStatus()
    logSection("RAGEBOT STATUS");
    local ok, rb = pcall(function() return api:is_ragebot(); end);
    logLine("is_ragebot = " .. (ok and tostring(rb) or "error"));
    local ok2, s, d = pcall(function()
        local s2, d2 = api:get_ragebot_status();
        return s2, d2;
    end);
    if ok2 then
        local s2, d2 = api:get_ragebot_status();
        logLine("ragebot_status = " .. tostring(s2));
        if d2 ~= nil then
            local ok3, ds = pcall(tostring, d2);
            logLine("ragebot_data = " .. (ok3 and ds or "<<err>>"));
        end;
    else
        logLine("get_ragebot_status: error");
    end;
end;

local function dumpDesync()
    logSection("DESYNC");
    local ok1, cd = pcall(function() return api:can_desync(); end);
    logLine("can_desync = " .. (ok1 and tostring(cd) or "error"));

    local ok2, cc = pcall(function() return api:get_client_cframe(); end);
    if ok2 and cc then
        local ok3, str = pcall(tostring, cc);
        logLine("client_cframe = " .. (ok3 and str or "<<err>>"));
    else
        logLine("client_cframe = nil (not desyncing)");
    end;

    local ok4, dc = pcall(function() return api:get_desync_cframe(); end);
    if ok4 and dc then
        local ok5, str = pcall(tostring, dc);
        logLine("desync_cframe = " .. (ok5 and str or "<<err>>"));
    else
        logLine("desync_cframe = nil (not desyncing)");
    end;
end;

local function dumpLocalInfo()
    logSection("LOCAL PLAYER INFO");
    local players = game:GetService("Players");
    local lp = players.LocalPlayer;
    logLine("Name            = " .. lp.Name);
    logLine("DisplayName     = " .. lp.DisplayName);
    logLine("UserId          = " .. tostring(lp.UserId));
    logLine("AccountAge      = " .. tostring(lp.AccountAge));
    logLine("MembershipType  = " .. tostring(lp.MembershipType));

    local ok, veh = pcall(function() return api:get_current_vehicle(); end);
    if ok and veh then
        local ok2, str = pcall(tostring, veh);
        logLine("current_vehicle = " .. (ok2 and str or "<<err>>"));
    else
        logLine("current_vehicle = nil");
    end;

    local ok2, tool = pcall(function() return api:get_tool(); end);
    if ok2 and tool then
        local ok3, str = pcall(tostring, tool);
        logLine("current_tool    = " .. (ok3 and str or "<<err>>"));
    else
        logLine("current_tool    = nil");
    end;
end;

local function dumpAllPlayers()
    logSection("ALL PLAYERS");
    local players = game:GetService("Players");
    local lp = players.LocalPlayer;
    for _, player in ipairs(players:GetPlayers()) do
        logLine("Player: " .. player.Name .. "  (UserId: " .. tostring(player.UserId) .. ")");
        if player ~= lp then
            local ok, crewResult = pcall(function() return api:is_crew(lp, player); end);
            logLine("  is_crew(local, " .. player.Name .. ") = " .. (ok and tostring(crewResult) or "error"));
        end;
    end;
end;

-- =====================================================
--  SAVE HELPER — writes current outputLines to a file
-- =====================================================

local function flushToFile(tag)
    ensureFolder();
    local filename = makeFilename(tag);
    saveToFile(filename, outputLines);
end;

-- =====================================================
--  FULL DUMP
-- =====================================================

local function runFullDump()
    outputLines = {};
    logLine("UE DUMPER — Full Dump");
    logLine("Timestamp : " .. os.date("%Y-%m-%d %H:%M:%S"));
    logLine("Game      : " .. tostring(game.PlaceId));
    logLine("Server    : " .. tostring(game.JobId));

    pcall(dumpLocalInfo);
    pcall(dumpAllPlayers);
    pcall(dumpRagebotStatus);
    pcall(dumpDesync);
    pcall(dumpToolCache);
    pcall(dumpDataCache);
    pcall(dumpStatusCache);
    pcall(dumpTargetCache);
    pcall(dumpCharacterCache);
    pcall(dumpFlags);

    logLine("");
    logLine("Total lines: " .. #outputLines);
    flushToFile("full");
end;

-- =====================================================
--  UI BUTTONS
-- =====================================================

leftBox:AddButton({
    Text = "Run Full Dump",
    Func = function()
        task.spawn(runFullDump);
    end;
});

leftBox:AddButton({
    Text = "Dump Flags Only",
    Func = function()
        task.spawn(function()
            outputLines = {};
            logLine("UE DUMPER — Flags Only");
            logLine("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S"));
            pcall(dumpFlags);
            flushToFile("flags");
        end);
    end;
});

leftBox:AddButton({
    Text = "Dump Caches",
    Func = function()
        task.spawn(function()
            outputLines = {};
            logLine("UE DUMPER — Cache Dump");
            logLine("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S"));
            pcall(dumpToolCache);
            pcall(dumpDataCache);
            pcall(dumpStatusCache);
            pcall(dumpTargetCache);
            pcall(dumpCharacterCache);
            flushToFile("caches");
        end);
    end;
});

leftBox:AddButton({
    Text = "Dump Ragebot/Desync",
    Func = function()
        task.spawn(function()
            outputLines = {};
            logLine("UE DUMPER — Ragebot & Desync");
            logLine("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S"));
            pcall(dumpRagebotStatus);
            pcall(dumpDesync);
            flushToFile("ragebot_desync");
        end);
    end;
});

leftBox:AddButton({
    Text = "Dump All Players",
    Func = function()
        task.spawn(function()
            outputLines = {};
            logLine("UE DUMPER — Player Dump");
            logLine("Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S"));
            pcall(dumpAllPlayers);
            pcall(dumpDataCache);
            pcall(dumpStatusCache);
            pcall(dumpCharacterCache);
            flushToFile("players");
        end);
    end;
});

rightBox:AddLabel("Saves to:\nworkspace\\UE_Dumps\\\n\nFiles named:\nUE_Dump_<type>_<timestamp>.txt\n\nOne file per button press.");

api:notify("UE Dumper loaded! Go to [Dumper] tab.", 4);
