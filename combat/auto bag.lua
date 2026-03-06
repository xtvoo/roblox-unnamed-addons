-- Auto Bag Target Script for Unnamed (Fixed Position)
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

-- Create UI
-- Create UI
local tab = api:GetTab("misc") or api:AddTab("misc")
local groupbox = tab:AddLeftGroupbox("Auto Bag")

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

groupbox:AddToggle("auto_bag_void", {
    Text = "Sit in Void When Bagged",
    Default = true,
    Tooltip = "Go to void when target is bagged"
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
        return true
    end
    
    -- Buy brownbag if we don't have one
    if api:can_desync() then
        api:buy_item("brownbag")
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
    end
    
    return bag
end

-- Function to check if target is bagged
local function is_target_bagged(target)
    if not target then
        return false
    end
    
    -- Correct path: workspace.Players.Model.[PlayerName].Christmas_Sock
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
    
    -- Check if Christmas_Sock exists
    return char_folder:FindFirstChild("Christmas_Sock") ~= nil
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
        return
    end
    
    if not LocalPlayer then
        return
    end
    
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = humanoid and humanoid.RootPart
    
    if not root then
        return
    end
    
    -- Get silent aim target
    local target = api:get_target("silent")
    
    if not target then
        -- No target, reset and exit void
        current_target = nil
        bag_start_time = nil
        if is_in_void then
            exit_void()
        end
        return
    end
    
    -- Timing: detect new target
    if target ~= current_target then
        current_target = target
        bag_start_time = os.clock()
        if is_in_void then
            exit_void()
        end
    end
    
    -- Check if target has Christmas_Sock
    local target_is_bagged = is_target_bagged(target)
    
    if target_is_bagged then
        -- Target has Christmas_Sock - STOP BAGGING
        if bag_start_time then
            local elapsed = os.clock() - bag_start_time
            api:notify(string.format("✓ Bagged %s in %.3fs", target.Name, elapsed), 2)
            bag_start_time = nil
        end
        
        -- Sit in void if enabled
        if api:get_ui_object("auto_bag_void").Value then
            enter_void()
        end
        
        return
    end
    
    -- Target doesn't have Christmas_Sock - CONTINUE BAGGING
    if is_in_void then
        exit_void()
    end
    
    -- Ensure we have a bag
    if not ensure_bag() then
        return
    end
    
    -- Get bag tool
    local bag = get_bag_tool()
    if not bag then
        return
    end
    
    -- Get target HRP
    local target_char = target.Character
    local target_hrp = target_char and target_char:FindFirstChild("HumanoidRootPart")
    
    if not target_hrp then
        return
    end
    
    -- Get slider values
    local height = api:get_ui_object("auto_bag_height").Value
    local forward = api:get_ui_object("auto_bag_forward").Value
    
    -- Calculate position (same as Juju)
    local base_cf = target_hrp.CFrame
    local pos = base_cf.Position
    local forward_vec = base_cf.LookVector
    
    -- Calculate desired position: target position + height offset - forward distance
    local desired_pos = pos + Vector3.new(0, height, 0) - (forward_vec * forward)
    
    -- Create CFrame looking at target from desired position
    local glue_cf = CFrame.new(desired_pos, pos)
    
    -- Apply PhysicsRepRootPart FIRST
    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(root, "PhysicsRepRootPart", target_hrp)
        end
    end)
    
    -- Then set desync CFrame (must be called EVERY FRAME)
    pcall(function()
        api:set_desync_cframe(glue_cf)
    end)
    
    -- Activate bag
    pcall(function()
        bag:Activate()
    end)
end

-- Connect heartbeat
connection = api:add_connection(RunService.Heartbeat:Connect(main_loop))

-- Unload
api:on_event("unload", function()
    current_target = nil
    bag_start_time = nil
    
    -- Exit void on unload
    if is_in_void then
        exit_void()
    end
    
    api:notify("Auto Bag Target unloaded", 2)
end)

-- Load message
api:notify("Auto Bag Target loaded!", 3)
