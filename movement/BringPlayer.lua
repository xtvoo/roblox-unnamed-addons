api:set_lua_name("Silent Bring Addon");

local players = game:GetService("Players");
local runservice = game:GetService("RunService");
local replicated = game:GetService("ReplicatedStorage");
local localplayer = players.LocalPlayer;
local MainEvent = replicated:WaitForChild("MainEvent");
local CoreGui = game:GetService("CoreGui");

-- Config State
local GrabDuration = 1.0
local ReturnDelay = 0.2
local BringHeight = 3.5
local BringDistance = 0
local CurrentSilentTarget = nil

-- UI Setup
local tab = api:GetTab("Silent Bring") or api:AddTab("Silent Bring")
local infoGroup = tab:AddLeftGroupbox("Target Info")
local settingsGroup = tab:AddRightGroupbox("Settings")

-- Info Labels (Mutable)
local NameLabel = infoGroup:AddLabel("Target: None", true)
local StatusLabel = infoGroup:AddLabel("Status: Idle", true)

-- PFP Injection
local PFPImage = Instance.new("ImageLabel")
PFPImage.Name = "TargetPFP"
PFPImage.Size = UDim2.new(0, 100, 0, 100)
PFPImage.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
PFPImage.BorderSizePixel = 0
PFPImage.Visible = false

task.spawn(function()
    task.wait(1) 
    if _G.windowname then
        local Screen = CoreGui:FindFirstChild(_G.windowname)
        if Screen then
             local Container = Screen:FindFirstChild("Target Info S", true)
             if Container and Container:FindFirstChild("Container") then
                 PFPImage.Parent = Container.Container
                 PFPImage.LayoutOrder = -1 
                 PFPImage.Visible = true
             end
        end
    end
end)

-- Settings UI
settingsGroup:AddButton("Bring Target", function()
    if CurrentSilentTarget then
        StartBringProcess(CurrentSilentTarget)
    else
        api:notify("No Silent Aim Target to Bring!", 3)
    end
end)

settingsGroup:AddSlider("GrabDuration", {
    Text = "Grab Duration",
    Default = 1.0, Min = 0.1, Max = 5.0, Rounding = 1,
    Suffix = "s",
    Callback = function(v) GrabDuration = v end
})

settingsGroup:AddSlider("ReturnDelay", {
    Text = "Return Delay",
    Default = 0.2, Min = 0.0, Max = 2.0, Rounding = 1,
    Suffix = "s",
    Callback = function(v) ReturnDelay = v end
})

settingsGroup:AddSlider("BringHeight", {
    Text = "Bring Height",
    Default = 3.5, Min = -10, Max = 10, Rounding = 1,
    Callback = function(v) BringHeight = v end
})

settingsGroup:AddSlider("BringDistance", {
    Text = "Bring Distance",
    Default = 0, Min = -10, Max = 10, Rounding = 1,
    Callback = function(v) BringDistance = v end
})


-- Logic Helpers (From Auto Stomp)
local UP_VECTOR = Vector3.new(0, 1, 0);
local FALLBACK_LOOK = Vector3.new(0, 0, -1);
local MIN_MAG_SQ = 1e-6;

local function notify(msg, t)
    api:notify(msg, t or 1.5);
end

local function SetStatus(text)
    pcall(function()
        if StatusLabel.SetText then StatusLabel:SetText(text)
        elseif StatusLabel.UpdateText then StatusLabel:UpdateText(text)
        elseif StatusLabel.SetValue then StatusLabel:SetValue(text) end
    end)
end

local function SetName(text)
    pcall(function()
        if NameLabel.SetText then NameLabel:SetText(text)
        elseif NameLabel.UpdateText then NameLabel:UpdateText(text)
        elseif NameLabel.SetValue then NameLabel:SetValue(text) end
    end)
end

local function resolve_upper_root(plr)
    local char = plr.Character;
    if not char then return nil, nil end;
    -- Prioritize RootPart for stability (Standing on top)
    local upper =
        char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso");
    return char, upper;
end

-- Logic State
local hbConn;
local processing = false;

local function cleanup_physics()
    pcall(function()
        local root = localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            sethiddenproperty(root, "PhysicsRepRootPart", nil)
            root.CanCollide = true -- Restore Collisions
        end
    end)
end

local function stop_bring()
    if hbConn then
        hbConn:Disconnect();
        hbConn = nil;
    end
    cleanup_physics() -- Ensure unglued
    processing = false
    SetStatus("Status: Done/Stopped")
end

function StartBringProcess(Target)
    if processing then return end
    processing = true
    
    SetStatus("Status: LOCKING...")
    
    -- Force Ragebot
    if Options and Options["ragebot_targets"] then
        Options["ragebot_targets"]:SetValue(Target.Name)
    end

    local State = "WAIT_KO"
    local GrabStart = 0
    local ReturnStart = 0
    local OriginalCFrame = nil

    hbConn = api:add_connection(runservice.Heartbeat:Connect(function()
        -- Validation
        if not Target or not Target.Parent then
            stop_bring()
            return
        end
        
        -- Logic
        local status = api:get_status_cache(Target);
        local is_ko = status and (status["K.O"] or status.SDeath) 
        
        if State == "WAIT_KO" then
            SetStatus("Status: Waiting for KO...")
            if is_ko then
                State = "GRABBING"
                GrabStart = os.clock()
                local root = localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart")
                if root then OriginalCFrame = root.CFrame end
                SetStatus("Status: GRABBING...")
            end
        elseif State == "GRABBING" then
             local elapsed = os.clock() - GrabStart
             if elapsed > GrabDuration then
                 State = "RETURNING"
                 ReturnStart = os.clock()
                 SetStatus("Status: RETURNING (Dragging)...")
                 
                 -- TELEPORT BACK NOW (While Glued)
                 if OriginalCFrame then
                    local root = localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                         if api:can_desync() then api:set_desync_cframe(OriginalCFrame) end
                         if api.set_server_cframe then api:set_server_cframe(OriginalCFrame) end
                         root.CFrame = OriginalCFrame
                    end
                end
             else
                 -- EXECUTE GRAB (AUTO STOMP COPY)
                 local char, upper_root = resolve_upper_root(Target)
                 local root = localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart")
                 
                 if char and upper_root and root then
                    -- Calc Position (Height + Distance)
                     local base_cf = upper_root.CFrame;
                     local torso_pos = base_cf.Position;
                     
                     -- World Up Logic
                     local look = base_cf.LookVector;
                     local flat_look = Vector3.new(look.X, 0, look.Z);
                     if flat_look.Magnitude * flat_look.Magnitude < MIN_MAG_SQ then
                         flat_look = FALLBACK_LOOK;
                     else
                         flat_look = flat_look.Unit;
                     end
                     
                     local pos = torso_pos + (UP_VECTOR * BringHeight) + (flat_look * BringDistance)
                     local target_pos_cf = CFrame.new(pos, pos + flat_look);
                     
                     -- Glue & Antifling
                     sethiddenproperty(root, "PhysicsRepRootPart", upper_root);
                     root.CanCollide = false -- Disable collisions to prevent flinging
                     
                     if api:can_desync() then
                        api:set_desync_cframe(target_pos_cf);
                     elseif api.set_server_cframe then
                        api:set_server_cframe(target_pos_cf);
                     end
                     
                     MainEvent:FireServer("Grabbing");
                 end
             end
        elseif State == "RETURNING" then
            -- Wait for ReturnDelay to ensure they arrive with us
            local elapsed = os.clock() - ReturnStart
            if elapsed > ReturnDelay then
                 stop_bring() -- This unglues and resets
            else
                -- Maintain Teleport Position (Clamp)
                 if OriginalCFrame then
                    local root = localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                         if api:can_desync() then api:set_desync_cframe(OriginalCFrame) end
                         if api.set_server_cframe then api:set_server_cframe(OriginalCFrame) end
                         root.CFrame = OriginalCFrame
                    end
                end
                
                -- KEEP FIRING GRAB REMOTE TO HOLD THEM
                MainEvent:FireServer("Grabbing");
            end
        end
    end))
end


-- Target Monitor Loop
api:add_connection(runservice.Heartbeat:Connect(function()
    local silent = api:get_target("silent")
    if silent ~= CurrentSilentTarget then
        CurrentSilentTarget = silent
        if silent then
            SetName("Target: " .. silent.Name)
            pcall(function()
                local content, r = players:GetUserThumbnailAsync(silent.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                if r then PFPImage.Image = content; PFPImage.Visible = true end
            end)
        else
            SetName("Target: None")
            PFPImage.Visible = false
        end
    end
end))

notify("Silent Bring (Return Tuned) Loaded", 2)
