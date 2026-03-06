local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- 1. Target Variables (Initialized to nil to prevent blocking)
local TargetPath = nil
local VehicleSeat = nil
local MainPart = nil

-- 2. API / UI Setup
-- We use the global 'api' from the Unnamed cheat if available
local api = getgenv().api

-- If 'api' is missing or doesn't have UI access, we load Linoria Lib as fallback for the MENU
local Window = nil
local UI_API = api -- Separate reference for UI methods vs Cheat methods if needed

if not api or not (api.GetTab or api.AddTab) then
    local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua'))()
     Window = Library:CreateWindow({
        Title = 'Cart Control',
        Center = true,
        AutoShow = true,
    })
    
    -- Mock the UI methods on a fallback object if real api doesn't have them
    local fallback_ui = {
        GetTab = function(self, name) return Window:AddTab(name) end,
        AddTab = function(self, name) return Window:AddTab(name) end
    }
    
    -- If api existed but lacked UI, merge; else use fallback
    if api then
        setmetatable(fallback_ui, {__index = api})
        UI_API = fallback_ui
    else
        UI_API = fallback_ui
    end
end

-- Use UI_API for Tabs
local Tab = UI_API:GetTab("Cart Control") or UI_API:AddTab("Cart Control")
local Group = Tab:AddLeftGroupbox("Controls")

-- Target Status & Refresh
local StatusLabel = Group:AddLabel('Status: Checking...')

local function RefreshTarget()
    local oldVehicles = Workspace:FindFirstChild("OldVehicles")
    if not oldVehicles then
        StatusLabel:SetText('Status: "OldVehicles" missing')
        return false
    end

    local bike = oldVehicles:FindFirstChild("VictoriaCrazeMagicBIKE")
    if not bike then
        StatusLabel:SetText('Status: Bike missing')
        return false
    end

    -- Update references
    TargetPath = bike
    VehicleSeat = bike:FindFirstChild("VehicleSeat")
    MainPart = bike:FindFirstChild("Main")

    if VehicleSeat and MainPart then
        StatusLabel:SetText('Status: Connected')
        return true
    else
        StatusLabel:SetText('Status: Bike incomplete')
        return false
    end
end

Group:AddButton({
    Text = 'Refresh Target',
    Func = function()
        RefreshTarget()
    end
})

-- Attempt to find immediately (non-blocking)
task.spawn(RefreshTarget)

-- 3. Teleport & Sit Logic
Group:AddButton({
    Text = 'Teleport & Sit',
    Func = function()
        -- Ensure target is valid
        if not VehicleSeat then
            if not RefreshTarget() then return end
        end
        
        local TargetCFrame = VehicleSeat.CFrame + Vector3.new(0, 3, 0)
        
        -- Use Unnamed API Teleport if available
        if api and api.teleport then
            api:teleport(TargetCFrame)
            if api.notify then api:notify("Teleported to Bike") end
        elseif LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
             LocalPlayer.Character.HumanoidRootPart.CFrame = TargetCFrame
        end
        
        -- Wait a split second for physics to register
        task.wait(0.1)
        
        -- Force sit (requires Humanoid)
        local Hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if Hum then
            VehicleSeat:Sit(Hum)
        end
    end
})

-- 4. Vehicle Fly Logic
local FlyEnabled = false
local FlySpeed = 100
local ControlSource = "Self (WASD)" -- Default
local FlightMover = { BV = nil, BG = nil }

Group:AddToggle('VehicleFly', {
    Text = 'Vehicle Fly',
    Default = false,
    Callback = function(Value)
        FlyEnabled = Value
        
        if FlyEnabled then
            -- Check if MainPart exists (try refresh if not)
            if not MainPart then 
                RefreshTarget()
            end
            
            if not MainPart then
                if api and api.notify then api:notify("Cannot Fly: bike not found") end
                warn("Main part not found!")
                return 
            end
            
            if api and api.notify then api:notify("Fly Enabled: " .. ControlSource) end

            -- Create BodyVelocity (Controls Movement)
            local BV = Instance.new("BodyVelocity")
            BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            BV.Velocity = Vector3.new(0, 0, 0)
            BV.Parent = MainPart
            
            -- Create BodyGyro (Controls Rotation/Stability)
            local BG = Instance.new("BodyGyro")
            BG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            BG.P = 3000 -- Power
            BG.D = 500  -- Dampening
            BG.CFrame = MainPart.CFrame
            BG.Parent = MainPart
            
            FlightMover.BV = BV
            FlightMover.BG = BG
            
        else
            -- Cleanup Movers
            if FlightMover.BV then FlightMover.BV:Destroy() end
            if FlightMover.BG then FlightMover.BG:Destroy() end
            FlightMover.BV = nil
            FlightMover.BG = nil
        end
    end
})

Group:AddDropdown('ControlSource', {
    Values = { 'Self (WASD)', 'Driver (Seat)' },
    Default = 1,
    Multi = false,
    Text = 'Control Source',
    Callback = function(Value)
        ControlSource = Value
        if FlyEnabled and api and api.notify then
            api:notify("Switched Control to: " .. ControlSource)
        end
    end
})

Group:AddSlider('FlySpeed', {
    Text = 'Fly Speed',
    Default = 100,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(Value)
        FlySpeed = Value
    end
})

-- 5. Control Loop (Bind to RenderStep for smooth controls)
RunService.RenderStepped:Connect(function()
    -- Guard clauses
    if not FlyEnabled then return end
    
    -- Check part existence validity
    if not MainPart or not MainPart.Parent then
        -- Cleanup if part disappeared
        if FlightMover.BV then FlightMover.BV:Destroy() end
        if FlightMover.BG then FlightMover.BG:Destroy() end
        FlightMover.BV = nil
        FlightMover.BG = nil
        return
    end
    
    -- Ensure movers exist
    if not FlightMover.BV or not FlightMover.BG then return end
    
    local MoveDir = Vector3.new(0, 0, 0)
    local TargetRot = FlightMover.BG.CFrame -- Maintain current rotation by default
    
    if ControlSource == 'Self (WASD)' then
        -- Calculate Direction based on Camera
        local LookVector = Camera.CFrame.LookVector
        local RightVector = Camera.CFrame.RightVector
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            MoveDir = MoveDir + LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            MoveDir = MoveDir - LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            MoveDir = MoveDir + RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            MoveDir = MoveDir - RightVector
        end
        -- Space to go UP, Ctrl to go DOWN (World Space)
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            MoveDir = MoveDir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            MoveDir = MoveDir - Vector3.new(0, 1, 0)
        end
        
        -- Apply Rotation (Face where camera looks)
        TargetRot = Camera.CFrame
        
    elseif ControlSource == 'Driver (Seat)' then
        if not VehicleSeat then return end
        
        -- Read Inputs directly from the VehicleSeat
        local Throttle = VehicleSeat.Throttle -- 1 (W), -1 (S), 0 (None)
        local Steer = VehicleSeat.Steer       -- 1 (D), -1 (A), 0 (None)
        
        -- Movement is based on where the *Bike* is facing, not the camera
        -- Throttle moves forward/back relative to the bike
        MoveDir = MainPart.CFrame.LookVector * Throttle
        
        -- Steering rotates the bike
        -- We rotate the TargetRot around the Y axis
        if Steer ~= 0 then
            -- Rotate roughly 2 degrees per frame in the steer direction
            local RotSpeed = math.rad(2) 
            TargetRot = FlightMover.BG.CFrame * CFrame.Angles(0, -Steer * RotSpeed, 0)
        else
            TargetRot = FlightMover.BG.CFrame -- Keep current rotation
        end
        
        -- Optional: Driver can't easily go Up/Down without keybinds, 
        -- but we could map other seat properties or just keep it flat fly.
    end
    
    -- Apply Velocity
    FlightMover.BV.Velocity = MoveDir * FlySpeed
    
    -- Apply Rotation
    FlightMover.BG.CFrame = TargetRot
end)
