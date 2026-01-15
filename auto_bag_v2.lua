-- Auto Bag V2 (Remake)
-- Advanced checks, toggles, delays, and instant execution.

api:set_lua_name("auto_bag_v2")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- State
local State = {
    Target = nil,
    StartTime = 0,
    IsBagging = false,
    IsInVoid = false,
    LastAction = 0
}

-- UI Setup
local Tab = api:GetTab("misc") or api:AddTab("misc")
local Group = Tab:AddLeftGroupbox("Auto Bag V2")

-- Main Toggles
Group:AddToggle("ab_enabled", { Text = "Enable Auto Bag", Default = false })
Group:AddLabel("Keybind"):AddKeyPicker("ab_keybind", { Default = "None", Text = "Auto Bag Bind", Mode = "Toggle" })

Group:AddDivider()

-- Multi-Target Dropdown
local PlayerDropdown = Group:AddDropdown("ab_target_list", {
    Values = {},
    Default = {},
    Multi = true,
    Text = "Select Targets",
    Tooltip = "Select specific players to bag"
})

Group:AddDivider()

-- Checks
Group:AddToggle("ab_check_ko", { Text = "Require KO", Default = true, Tooltip = "Only bag if target is knocked" })
Group:AddToggle("ab_check_crew", { Text = "Crew Check", Default = true, Tooltip = "Don't bag crew members" })
Group:AddToggle("ab_check_wall", { Text = "Wall Check", Default = false, Tooltip = "visible checks (not recommended for max speed)" })

Group:AddDivider()

-- Delays
Group:AddSlider("ab_delay_pre", { Text = "Pre-Bag Delay", Default = 0, Min = 0, Max = 2, Rounding = 1, Suffix = "s", Tooltip = "Wait before starting to bag" })
Group:AddSlider("ab_delay_action", { Text = "Action Speed", Default = 0, Min = 0, Max = 1, Rounding = 2, Suffix = "s", Tooltip = "0 = Instant/RenderStepped" })

Group:AddDivider()

-- Settings
Group:AddToggle("ab_void", { Text = "Void on Success", Default = true, Tooltip = "Teleport to void after bagging" })
Group:AddSlider("ab_dist", { Text = "Distance", Default = 3, Min = 1, Max = 10, Rounding = 1, Suffix = " studs" })
Group:AddSlider("ab_height", { Text = "Height", Default = -4, Min = -10, Max = 5, Rounding = 1, Suffix = " studs" })

-- Player List Management
local function GetPlayerFormat(player)
    return string.format("%s (@%s)", player.DisplayName, player.Name)
end

local function UpdatePlayerList()
    local values = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(values, GetPlayerFormat(player))
        end
    end
    -- Keep previously selected values valid if possible
    PlayerDropdown:SetValues(values)
end

-- Connect to player events
api:add_connection(Players.PlayerAdded:Connect(function()
    UpdatePlayerList()
end))

api:add_connection(Players.PlayerRemoving:Connect(function() 
    -- Small delay to unsure they are gone from list
    task.delay(0.1, UpdatePlayerList)
end))

-- Initial population
UpdatePlayerList()


-- Helpers
local function Notify(msg)
    api:notify(msg, 2)
end

local function IsBagged(player)
    if not player or not player.Parent then return false end
    -- Check for Christmas_Sock in character model inside workspace.Players.Model
    local char_folder = Workspace:FindFirstChild("Players") and Workspace.Players:FindFirstChild("Model") and Workspace.Players.Model:FindFirstChild(player.Name)
    if char_folder and char_folder:FindFirstChild("Christmas_Sock") then
        return true
    end
    return false
end

local function GetTarget()
    -- 1. Check Dropdown
    local selected_entries = Options.ab_target_list.Value
    local specific_targets = {}
    
    -- Parse selected names back to players
    for name_str, is_selected in pairs(selected_entries) do
        if is_selected then
            -- Extract username from "Display (@Username)"
            local username = name_str:match("@(.+)")
            -- If match failed (regex quirk), try end
            if not username then username = name_str:match("%((.+)%)") end -- fallback
            
            if username then
                -- Remove closing paren if my regex was lazy
                username = username:gsub("%)", "")
                
                local p = Players:FindFirstChild(username)
                if p then
                    table.insert(specific_targets, p)
                end
            end
        end
    end

    -- If we have specific targets selected, pick the first valid one
    if #specific_targets > 0 then
        for _, p in ipairs(specific_targets) do
            if not IsBagged(p) then
                 -- We found a selected player who isn't bagged yet
                 return p
            end
        end
        return nil -- All selected targets are bagged (or invalid)
    end

    -- 2. Fallback to normal targeting if no dropdown selection
    -- Prioritize Silent -> Rage -> Aimbot
    local target = api:get_target("silent")
    if not target then target = api:get_target("ragebot") end
    if not target then target = api:get_target("aimbot") end
    return target
end

local function HasBrownBag()
    if not LocalPlayer.Character then return false end
    if LocalPlayer.Character:FindFirstChild("[BrownBag]") then return true end
    if LocalPlayer.Backpack:FindFirstChild("[BrownBag]") then return true end
    return false
end

local function EquipBag()
    if not LocalPlayer.Character then return end
    local bag = LocalPlayer.Backpack:FindFirstChild("[BrownBag]")
    if bag then bag.Parent = LocalPlayer.Character end
    return LocalPlayer.Character:FindFirstChild("[BrownBag]")
end

local function IsKnocked(player)
    local status = api:get_status_cache(player)
    return status and (status["K.O"] or status.Dead)
end

local function IsCrew(player)
    local success, result = pcall(function()
        return api:is_crew_player(LocalPlayer, player)
    end)
    return success and result
end

local function ToggleVoid(state)
    if State.IsInVoid == state then return end
    State.IsInVoid = state
    
    local void_in = api:get_ui_object("character_prot_void_in")
    local void_out = api:get_ui_object("character_prot_void_out")
    
    pcall(function()
        if state and void_in then void_in:SetValue(true) end
        if not state and void_out then void_out:SetValue(true) end
    end)
end

-- Logic Loop
local function RunLoop()
    -- Check Enable
    local enabled = (Toggles.ab_enabled and Toggles.ab_enabled.Value) or (Options.ab_keybind and Options.ab_keybind.GetState())
    if not enabled then
        if State.IsInVoid then ToggleVoid(false) end
        State.Target = nil
        State.IsBagging = false
        return
    end

    -- 1. Find Target
    local new_target = GetTarget()
    
    -- Reset if target changed
    if new_target ~= State.Target then
        State.Target = new_target
        State.StartTime = os.clock()
        State.IsBagging = false
        if State.IsInVoid then ToggleVoid(false) end -- Exit void on new target search
    end

    if not State.Target then return end

    -- 2. Validate Target
    -- KO Check
    if Toggles.ab_check_ko.Value and not IsKnocked(State.Target) then
        return
    end

    -- Crew Check
    if Toggles.ab_check_crew.Value and IsCrew(State.Target) then
        return
    end
    
    -- Wall Check (Basic visibility)
    if Toggles.ab_check_wall.Value then
        local origin = LocalPlayer.Character and LocalPlayer.Character.Head.Position
        local dest = State.Target.Character and State.Target.Character.Head.Position
        if origin and dest then
            local ray = Ray.new(origin, (dest - origin).Unit * (dest - origin).Magnitude)
            local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, State.Target.Character})
            if hit then return end
        end
    end

    -- 3. Success Check
    if IsBagged(State.Target) then
        if Toggles.ab_void.Value then
            ToggleVoid(true)
        end
        return
    else
        if State.IsInVoid then ToggleVoid(false) end
    end

    -- 4. Delays
    local elapsed = os.clock() - State.StartTime
    if elapsed < Options.ab_delay_pre.Value then
        return -- Waiting for Pre-Delay
    end

    -- Action Delay (Rate Limit)
    if (os.clock() - State.LastAction) < Options.ab_delay_action.Value then
        return
    end
    State.LastAction = os.clock()

    -- 5. Execution (Bagging)
    if not HasBrownBag() then
        if api:can_desync() then
            api:notify("Buying brownbag...", 1)
            api:buy_item("brownbag")
        end
        return
    end

    local bag = EquipBag()
    if not bag then return end

    local target_char = State.Target.Character
    local target_hrp = target_char and target_char:FindFirstChild("HumanoidRootPart")
    
    if not target_hrp then return end

    -- Calculation
    local dist = Options.ab_dist.Value
    local height = Options.ab_height.Value
    
    local target_cf = target_hrp.CFrame
    local ideal_pos = target_cf.Position + Vector3.new(0, height, 0) - (target_cf.LookVector * dist)
    local look_cf = CFrame.new(ideal_pos, target_cf.Position)
    
    -- Desync & Interact
    pcall(function()
        if sethiddenproperty and LocalPlayer.Character and LocalPlayer.Character.HumanoidRootPart then
             sethiddenproperty(LocalPlayer.Character.HumanoidRootPart, "PhysicsRepRootPart", target_hrp)
        end
        
        api:set_desync_cframe(look_cf)
        bag:Activate()
    end)
    
    State.IsBagging = true
end

-- Hook
api:add_connection(RunService.Heartbeat:Connect(RunLoop))

api:on_event("unload", function()
    ToggleVoid(false)
    api:notify("Auto Bag V2 Unloaded", 2)
end)

api:notify("Auto Bag V2 Loaded", 3)
