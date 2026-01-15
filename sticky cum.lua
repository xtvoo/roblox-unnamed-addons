-- Auto Bag Target Script for Unnamed (Fixed Stalling)
api:set_lua_name("auto_bag_target")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Variables
local LocalPlayer = Players.LocalPlayer
local connection
local current_target = nil
local bag_start_time = nil
local is_in_void = false
local current_state = "IDLE"
local state_start_time = 0
local last_bag_activate = 0

-- Create UI
local tab = api:AddTab("Auto Bag")
local groupbox = tab:AddLeftGroupbox("Auto Bag Settings")

groupbox:AddToggle("auto_bag_enabled", {
    Text = "Enable Auto Bag",
    Default = false
})

groupbox:AddLabel("Keybind"):AddKeyPicker("auto_bag_keybind", {
    Default = "None",
    Text = "Auto Bag",
    Mode = "Toggle",
    SyncToggleState = true
})

groupbox:AddToggle("auto_bag_kill", {
    Text = "Auto Kill After Bag",
    Default = true,
    Tooltip = "Automatically kill target after bagging"
})

groupbox:AddToggle("auto_bag_void", {
    Text = "Sit in Void When Bagged",
    Default = true,
    Tooltip = "Go to void when target is bagged"
})

groupbox:AddToggle("auto_bag_debug", {
    Text = "Debug Mode",
    Default = false,
    Tooltip = "Show debug notifications"
})

groupbox:AddSlider("auto_bag_height", {
    Text = "Bag Height",
    Default = -3,
    Min = -10,
    Max = 5,
    Rounding = 1,
    Suffix = " studs"
})

groupbox:AddSlider("auto_bag_forward", {
    Text = "Bag Distance",
    Default = 2,
    Min = -5,
    Max = 10,
    Rounding = 1,
    Suffix = " studs",
    Tooltip = "How far in front/behind target"
})

groupbox:AddSlider("auto_bag_timeout", {
    Text = "Bag Timeout",
    Default = 10,
    Min = 5,
    Max = 30,
    Rounding = 0,
    Suffix = "s",
    Tooltip = "Reset if bagging takes too long"
})

-- State display
groupbox:AddLabel("Status: Idle"):AddLabel("auto_bag_status")

-- Function to debug log
local function debug_log(text)
    if api:get_ui_object("auto_bag_debug") and api:get_ui_object("auto_bag_debug").Value then
        api:notify("[DEBUG] " .. text, 1)
    end
end

-- Function to update status label
local function update_status(text)
    pcall(function()
        api:get_ui_object("auto_bag_status").Text = "Status: " .. text
    end)
end

-- Function to change state
local function set_state(new_state, reason)
    if current_state ~= new_state then
        debug_log("State: " .. current_state .. " -> " .. new_state .. " (" .. (reason or "no reason") .. ")")
        current_state = new_state
        state_start_time = os.clock()
    end
end

-- Function to find brownbag
local function find_bag_anywhere()
    if not LocalPlayer then
        return nil, nil
    end
    
    local character = LocalPlayer.Character
    if character then
        local bag = character:FindFirstChild("[BrownBag]")
        if bag then
            return bag, character
        end
    end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local bag = backpack:FindFirstChild("[BrownBag]")
        if bag then
            return bag, backpack
        end
    end
    
    return nil, nil
end

-- Function to ensure we have a bag
local function ensure_bag()
    local bag = select(1, find_bag_anywhere())
    if bag then
        debug_log("Have bag: " .. bag.Name)
        return true
    end
    
    debug_log("No bag found, attempting to buy...")
    -- Buy brownbag if we don't have one
    if api:can_desync() then
        api:buy_item("brownbag")
        debug_log("Bought brownbag")
    else
        debug_log("Cannot desync, cannot buy bag")
    end
    
    return false
end

-- Function to get bag tool equipped
local function get_bag_tool()
    local bag, parent = find_bag_anywhere()
    if not bag then
        return nil
    end
    
    -- Equip bag if not equipped
    if parent ~= LocalPlayer.Character then
        bag.Parent = LocalPlayer.Character
        debug_log("Equipped bag")
    end
    
    return bag
end

-- Function to check if target is bagged
local function is_target_bagged(target)
    if not target then
        return false
    end
    
    local players_folder = Workspace:FindFirstChild("Players")
    if not players_folder then
        return false
    end
    
    local model_folder = players_folder:FindFirstChild("Model")
    if not model_folder then
        return false
    end
    
    local char_folder = model_folder:FindFirstChild(target.Name)
    if not char_folder then
        return false
    end
    
    return char_folder:FindFirstChild("Christmas_Sock") ~= nil
end

-- Function to check if target is dead
local function is_target_dead(target)
    if not target then
        return true
    end
    
    local status_cache = api:get_status_cache(target)
    if not status_cache then
        return true
    end
    
    return status_cache.Dead == true or status_cache["K.O"] == true
end

-- Function to check if target is alive and spawned
local function is_target_alive_and_spawned(target)
    if not target or not target.Character then
        return false
    end
    
    local status_cache = api:get_status_cache(target)
    if not status_cache then
        return false
    end
    
    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
    local is_alive = status_cache.Dead == false and status_cache["K.O"] == false and humanoid and humanoid.Health > 0
    
    if is_alive then
        debug_log(target.Name .. " is alive and spawned")
    end
    
    return is_alive
end

-- Function to add target to ragebot
local function add_to_ragebot(target)
    if not target then
        return false
    end
    
    pcall(function()
        local use_selected = api:get_ui_object("ragebot_use_selected")
        if use_selected then
            use_selected:SetValue(true)
        end
        
        local targets_obj = api:get_ui_object("ragebot_targets")
        if targets_obj then
            local current_targets = targets_obj.Value or ""
            if not string.find(current_targets, target.Name) then
                if current_targets == "" then
                    targets_obj:SetValue(target.Name)
                else
                    targets_obj:SetValue(current_targets .. "\n" .. target.Name)
                end
            end
        end
    end)
    
    api:notify("Added " .. target.Name .. " to ragebot", 2)
    return true
end

-- Function to remove target from ragebot
local function remove_from_ragebot(target)
    if not target then
        return
    end
    
    pcall(function()
        local targets_obj = api:get_ui_object("ragebot_targets")
        if targets_obj then
            local current_targets = targets_obj.Value or ""
            current_targets = string.gsub(current_targets, target.Name .. "\n", "")
            current_targets = string.gsub(current_targets, target.Name, "")
            targets_obj:SetValue(current_targets)
        end
    end)
end

-- Function to go to void
local function enter_void()
    if is_in_void then
        return
    end
    
    pcall(function()
        local void_in = api:get_ui_object("character_prot_void_in")
        if void_in then
            void_in:SetValue(true)
        end
    end)
    
    is_in_void = true
    debug_log("Entered void")
end

-- Function to exit void
local function exit_void()
    if not is_in_void then
        return
    end
    
    pcall(function()
        local void_out = api:get_ui_object("character_prot_void_out")
        if void_out then
            void_out:SetValue(true)
        end
    end)
    
    is_in_void = false
    debug_log("Exited void")
end

-- Main loop
local function main_loop()
    -- Check if enabled (toggle OR keybind)
    local toggle_obj = api:get_ui_object("auto_bag_enabled")
    local keybind_obj = api:get_ui_object("auto_bag_keybind")
    
    local is_enabled = (toggle_obj and toggle_obj.Value) or (keybind_obj and keybind_obj.Active)
    
    if not is_enabled then
        if is_in_void then
            exit_void()
        end
        if api:is_ragebot() then
            api:set_ragebot(false)
        end
        set_state("IDLE", "disabled")
        update_status("Disabled")
        return
    end
    
    if not LocalPlayer then
        return
    end
    
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = humanoid and humanoid.RootPart
    
    if not root then
        debug_log("No root part")
        return
    end
    
    -- Get silent aim target
    local target = api:get_target("silent")
    
    if not target then
        if current_target then
            debug_log("Lost target")
        end
        current_target = nil
        bag_start_time = nil
        set_state("IDLE", "no target")
        update_status("No Target")
        if is_in_void then
            exit_void()
        end
        if api:is_ragebot() then
            api:set_ragebot(false)
        end
        return
    end
    
    -- Detect new target
    if target ~= current_target then
        debug_log("New target: " .. target.Name)
        current_target = target
        bag_start_time = os.clock()
        set_state("BAGGING", "new target")
        if is_in_void then
            exit_void()
        end
        if api:is_ragebot() then
            api:set_ragebot(false)
        end
        remove_from_ragebot(target)
    end
    
    -- Check for timeout in BAGGING state
    local timeout = api:get_ui_object("auto_bag_timeout").Value or 10
    if current_state == "BAGGING" and (os.clock() - state_start_time) > timeout then
        debug_log("Bagging timeout, resetting")
        set_state("BAGGING", "timeout reset")
        bag_start_time = os.clock()
    end
    
    -- State Machine
    if current_state == "BAGGING" then
        update_status("Bagging " .. target.Name .. " (" .. math.floor(os.clock() - state_start_time) .. "s)")
        
        -- Check if target is bagged
        local target_bagged = is_target_bagged(target)
        
        if target_bagged then
            local elapsed = os.clock() - bag_start_time
            api:notify(string.format("✓ Bagged %s in %.3fs", target.Name, elapsed), 2)
            
            -- Check if auto kill is enabled
            if api:get_ui_object("auto_bag_kill").Value then
                set_state("KILLING", "target bagged")
                add_to_ragebot(target)
                api:set_ragebot(true)
            else
                set_state("IDLE", "bag complete, no auto kill")
            end
            
            -- Enter void
            if api:get_ui_object("auto_bag_void").Value then
                enter_void()
            end
            return
        end
        
        -- Continue bagging logic
        if is_in_void then
            exit_void()
        end
        
        if not ensure_bag() then
            debug_log("Failed to ensure bag")
            return
        end
        
        local bag = get_bag_tool()
        if not bag then
            debug_log("Failed to get bag tool")
            return
        end
        
        local target_char = target.Character
        local target_hrp = target_char and target_char:FindFirstChild("HumanoidRootPart")
        
        if not target_hrp then
            debug_log("Target has no HRP")
            return
        end
        
        -- Get slider values
        local height = api:get_ui_object("auto_bag_height").Value
        local forward = api:get_ui_object("auto_bag_forward").Value
        
        -- Calculate position
        local base_cf = target_hrp.CFrame
        local pos = base_cf.Position
        local forward_vec = base_cf.LookVector
        local desired_pos = pos + Vector3.new(0, height, 0) - (forward_vec * forward)
        local glue_cf = CFrame.new(desired_pos, pos)
        
        -- Apply PhysicsRepRootPart
        local physics_success = pcall(function()
            if sethiddenproperty then
                sethiddenproperty(root, "PhysicsRepRootPart", target_hrp)
            end
        end)
        
        if not physics_success then
            debug_log("Failed to set PhysicsRepRootPart")
        end
        
        -- Set desync CFrame
        local desync_success = pcall(function()
            api:set_desync_cframe(glue_cf)
        end)
        
        if not desync_success then
            debug_log("Failed to set desync cframe")
        end
        
        -- Activate bag (throttled to every 0.1s)
        local current_time = os.clock()
        if current_time - last_bag_activate >= 0.1 then
            pcall(function()
                bag:Activate()
                last_bag_activate = current_time
            end)
        end
        
    elseif current_state == "KILLING" then
        update_status("Killing " .. target.Name)
        
        -- Make sure ragebot is on
        if not api:is_ragebot() then
            api:set_ragebot(true)
            debug_log("Re-enabled ragebot")
        end
        
        -- Stay in void
        if api:get_ui_object("auto_bag_void").Value and not is_in_void then
            enter_void()
        end
        
        -- Check if target is dead
        if is_target_dead(target) then
            api:notify(target.Name .. " is dead, waiting for respawn...", 2)
            set_state("WAITING_RESPAWN", "target dead")
            api:set_ragebot(false)
            remove_from_ragebot(target)
        end
        
    elseif current_state == "WAITING_RESPAWN" then
        update_status("Waiting for " .. target.Name .. " to respawn")
        
        -- Disable ragebot
        if api:is_ragebot() then
            api:set_ragebot(false)
        end
        
        -- Stay in void
        if api:get_ui_object("auto_bag_void").Value and not is_in_void then
            enter_void()
        end
        
        -- Check if target is alive and spawned
        if is_target_alive_and_spawned(target) then
            api:notify(target.Name .. " respawned, bagging again!", 2)
            set_state("BAGGING", "target respawned")
            bag_start_time = os.clock()
            exit_void()
        end
    end
end

-- Connect heartbeat
connection = api:add_connection(RunService.Heartbeat:Connect(main_loop))

-- Unload
api:on_event("unload", function()
    current_target = nil
    bag_start_time = nil
    set_state("IDLE", "unload")
    
    if is_in_void then
        exit_void()
    end
    
    if api:is_ragebot() then
        api:set_ragebot(false)
    end
    
    api:notify("Auto Bag Target unloaded", 2)
end)

-- Load message
api:notify("Auto Bag Kill Cycle loaded!", 3)
