api:set_lua_name("auto_stomp_upper_glue_stick");

local players = game:GetService("Players");
local runservice = game:GetService("RunService");
local replicated = game:GetService("ReplicatedStorage");
local localplayer = players.LocalPlayer;
local MainEvent = replicated:WaitForChild("MainEvent");

local tab = api:GetTab("main") or api:AddTab("main")
local group = tab:AddRightGroupbox("Auto Stomp")

local autoStompToggle = group:AddToggle("auto_stomp_upper_enabled", {
    Text = "Enabled",
    Default = false,
})

autoStompToggle:AddKeyPicker("auto_stomp_keybind", {
    Default = "None",
    Text = "Auto Stomp",
    Mode = "Toggle",
    SyncToggleState = true,
})

local stompHeightSlider = group:AddSlider("auto_stomp_upper_height", {
    Text = "Height",
    Default = 3.1,
    Min = 0,
    Max = 8,
    Rounding = 1,
    Suffix = " studs",
})

local koRequiredToggle = group:AddToggle("auto_stomp_require_ko", {
    Text = "Require K.O",
    Default = true,
})

local skipDeadToggle = group:AddToggle("auto_stomp_skip_dead", {
    Text = "Skip Dead",
    Default = true,
})

local skipSDeathToggle = group:AddToggle("auto_stomp_skip_sdeath", {
    Text = "Skip Stomped",
    Default = true,
})

local UP_VECTOR = Vector3.new(0, 1, 0);
local FALLBACK_LOOK = Vector3.new(0, 0, -1);
local MIN_MAG_SQ = 1e-6;

local function notify(msg, t)
    api:notify(msg, t or 1.5);
end

local function pick_target()
    local cache = api:get_target_cache("silent");
    if cache and cache.player then return cache.player end;
    return nil;
end

local function is_valid(plr)
    local status = api:get_status_cache(plr);
    if not status then return false end;
    if skipDeadToggle.Value and status.Dead then return false end;
    if skipSDeathToggle.Value and status.SDeath then return false end;
    if koRequiredToggle.Value and not status["K.O"] then return false end;
    return true;
end

local function resolve_upper_root(plr)
    local char = plr.Character;
    if not char then return nil, nil end;
    local upper =
        char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("HumanoidRootPart");
    return char, upper;
end

local hbConn;
local currentTarget = nil;
local currentChar = nil;
local currentUpper = nil;

local function reset_target()
    currentTarget = nil;
    currentChar = nil;
    currentUpper = nil;
end

local function stop_auto_stomp()
    if hbConn then
        hbConn:Disconnect();
        hbConn = nil;
    end
    reset_target();
end

local function start_auto_stomp()
    stop_auto_stomp();
    hbConn = api:add_connection(runservice.Heartbeat:Connect(function()
        -- Double check toggle is still enabled
        if not autoStompToggle.Value then
            stop_auto_stomp();
            return;
        end

        local lp = localplayer;
        if not lp then
            return;
        end

        local character = lp.Character;
        if not character then
            return;
        end

        local humanoid = character:FindFirstChildOfClass("Humanoid");
        if not humanoid then
            return;
        end

        local root = humanoid.RootPart;
        if not root then
            return;
        end

        local target = currentTarget;
        if not target then
            target = pick_target();
            if not target or not is_valid(target) then
                return;
            end

            local char, upper = resolve_upper_root(target);
            if not upper then
                return;
            end

            currentTarget = target;
            currentChar = char;
            currentUpper = upper;
        else
            if not is_valid(target) then
                reset_target();
                return;
            end

            local char = currentChar;
            local upper = currentUpper;
            if not char or char ~= target.Character or not upper or not upper.Parent then
                char, upper = resolve_upper_root(target);
                if not upper then
                    reset_target();
                    return;
                end
                currentChar = char;
                currentUpper = upper;
            end
        end

        local upper_root = currentUpper;
        local h = stompHeightSlider.Value or 2;

        local base_cf = upper_root.CFrame;
        local torso_pos = base_cf.Position;
        local pos = torso_pos + UP_VECTOR * h;

        local look = base_cf.LookVector;
        local flat_look = Vector3.new(look.X, 0, look.Z);
        if flat_look.Magnitude * flat_look.Magnitude < MIN_MAG_SQ then
            flat_look = FALLBACK_LOOK;
        else
            flat_look = flat_look.Unit;
        end

        local glue_cf = CFrame.new(pos, pos + flat_look);
        sethiddenproperty(root, "PhysicsRepRootPart", upper_root);

        if api:can_desync() then
            api:set_desync_cframe(glue_cf);
        end

        MainEvent:FireServer("Stomp");
    end));
    notify("auto stomp (upper glue stick) enabled", 1.5);
end

-- listen for target changes to reset immediately
api:on_event("targetchanged", function(target)
    if not target then
        reset_target();
    end
end)

autoStompToggle:OnChanged(function(on)
    if on then
        start_auto_stomp();
    else
        stop_auto_stomp();
        notify("auto stomp disabled", 1.2);
    end
end)

api:on_event("unload", function()
    stop_auto_stomp();
end)
