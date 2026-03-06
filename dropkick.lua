--[[
    Dropkick Fling Script (Final v8 - UI Init Fix)
    Integration: api:set_lua_name + Safe Tab Creation
]]

-- Init API Name (Critical from glue.txt)
local api = getgenv().api or api
if api and api.set_lua_name then
    api:set_lua_name("dropkick_script")
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local AnimationId = "rbxassetid://133566007754001"

-- Validate API
if not api then
    StarterGui:SetCore("SendNotification", {
        Title = "Dropkick Script";
        Text = "FATAL: 'api' global missing!";
        Duration = 5;
    })
    return
end

local function Notify(msg)
    if api.notify then
        api:notify(msg, 3)
    elseif Library and Library.Notify then
        Library:Notify(msg)
    end
end

-- UI Integration (Safe Method)
local Tab = api:GetTab("ragebot")
if not Tab then
    Tab = api:AddTab("ragebot")
end

-- Fallback to Misc if Ragebot fails entirely?
if not Tab and api.GetTab then
    Tab = api:GetTab("misc") or api:AddTab("misc")
end

local Group = nil
if Tab then
    Group = Tab:AddLeftGroupbox("Dropkick Script")
else
    Notify("UI Error: Could not find/create Tab!")
end

-- Helper: Get Target
local function GetTarget()
    if api.get_target then
        return api:get_target("silent") or api:get_target("closet")
    end
    -- Fallback
    local SilentTarget = getgenv().SilentAimTarget
    if SilentTarget and SilentTarget.Character then return SilentTarget end
    return nil
end

-- Glue Logic
local GlueConnection = nil

local function EnableGlue(TargetRoot)
    local LocalRoot = LocalPlayer.Character.HumanoidRootPart
    
    if GlueConnection then GlueConnection:Disconnect() GlueConnection = nil end
    
    -- Initial Physics Link
    pcall(function()
        sethiddenproperty(LocalRoot, "PhysicsRepRootPart", TargetRoot)
    end)
    
    -- Update Loop
    GlueConnection = RunService.Heartbeat:Connect(function()
        if not TargetRoot or not LocalRoot then return end
        
        -- Desync Logic
        local DesyncCFrame = TargetRoot.CFrame * CFrame.new(0, 0, -3)
        DesyncCFrame = CFrame.lookAt(DesyncCFrame.Position, TargetRoot.Position)
        
        if api.set_desync_cframe then
            api:set_desync_cframe(DesyncCFrame)
        end
    end)
    
    if Toggles.desync_enabled then Toggles.desync_enabled:SetValue(true) end
end

local function DisableGlue()
    if GlueConnection then GlueConnection:Disconnect() GlueConnection = nil end
    if Toggles.desync_enabled then Toggles.desync_enabled:SetValue(false) end
    
    local LocalRoot = LocalPlayer.Character.HumanoidRootPart
    if LocalRoot then
        pcall(function()
            sethiddenproperty(LocalRoot, "PhysicsRepRootPart", nil)
        end)
    end
end

local IsAttacking = false

local function PerformDropkick()
    if IsAttacking then return end
    local Target = GetTarget()
    if not Target then return Notify("No Target Found!") end
    
    IsAttacking = true
    
    if Options.animation_player_custom_input then
        Options.animation_player_custom_input:SetValue(AnimationId)
    end
    
    local TargetRoot = Target.Character:FindFirstChild("HumanoidRootPart")
    if TargetRoot then
        EnableGlue(TargetRoot)
    end
    
    if Toggles.animation_player_enabled then
        Toggles.animation_player_enabled:SetValue(true)
    end
    
    task.wait(0.3)
    
    if Toggles.breaker_velocity_enabled then
        Toggles.breaker_velocity_enabled:SetValue(true)
    end
    
    task.wait(0.5)
    
    if Toggles.breaker_velocity_enabled then Toggles.breaker_velocity_enabled:SetValue(false) end
    if Toggles.animation_player_enabled then Toggles.animation_player_enabled:SetValue(false) end
    DisableGlue()
    
    IsAttacking = false
end

-- UI Elements
if Group then
    Group:AddLabel("Keybind"):AddKeyPicker("DropkickKey", {
        Default = "F", 
        SyncToggleState = false,
        Mode = "Toggle",
        Text = "Dropkick Player",
        NoUI = false,
        Callback = function(Value)
            if Value then
                PerformDropkick()
            end
        end,
        ChangedCallback = function(NewKey)
           Notify("Dropkick Keybind: " .. tostring(NewKey))
        end
    })
    Notify("Dropkick Loaded (Ragebot)")
else
    -- Fallback Keybind if UI fails
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F then
            PerformDropkick()
        end
    end)
    Notify("Dropkick Loaded (No UI - F Key)")
end
