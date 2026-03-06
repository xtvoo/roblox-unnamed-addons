--[[
    Unnamed Addon: Cart Flight V3
    Simple fix: Enable Y-axis force on BodyVelocity for flight
]]

api:set_lua_name("CartFlight")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Settings
local Settings = {
    Enabled = false,
    Speed = 50,
    VerticalSpeed = 30,
}

-- Movement state
local Keys = {
    W = false,
    S = false,
    A = false,
    D = false,
    Q = false,
    E = false,
}

-- Connections
local connections = {}

-- UI Setup
local tabs = { Character = api:GetTab("character") or api:AddTab("character") }
local sec = tabs.Character:AddRightGroupbox("Cart Flight")

local EnableToggle = sec:AddToggle("CartFlight_Enable", { 
    Text = "Enable Cart Flight", 
    Default = false,
    Callback = function(val) 
        Settings.Enabled = val
        if val then
            StartCartFlight()
        else
            StopCartFlight()
        end
    end
})

sec:AddSlider("CartFlight_Speed", { 
    Text = "Speed", 
    Default = 50, 
    Min = 20, 
    Max = 150, 
    Rounding = 1,
    Callback = function(val) Settings.Speed = val end
})

sec:AddSlider("CartFlight_VerticalSpeed", { 
    Text = "Vertical Speed", 
    Default = 30, 
    Min = 10, 
    Max = 100, 
    Rounding = 1,
    Callback = function(val) Settings.VerticalSpeed = val end
})

sec:AddDivider()

-- Helper functions
local function GetSeat()
    local OldVehicles = Workspace:FindFirstChild("OldVehicles")
    if not OldVehicles then return nil end
    
    local BikeFolder = OldVehicles:FindFirstChild(LocalPlayer.Name .. "BIKE")
    if not BikeFolder then return nil end
    
    return BikeFolder:FindFirstChild("Seat")
end

local function CreatePhysicsObjects(seat)
    -- Remove old ones if they exist
    for _, name in ipairs({"Move", "Rotate", "Stabilizer"}) do
        local obj = seat:FindFirstChild(name)
        if obj then obj:Destroy() end
    end
    
    -- BodyVelocity with FULL 3D control (includes Y axis!)
    local BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.Name = "Move"
    BodyVelocity.MaxForce = Vector3.new(99e99, 99e99, 99e99) -- KEY CHANGE: Y force enabled!
    BodyVelocity.Velocity = Vector3.zero
    BodyVelocity.Parent = seat
    
    -- Rotation
    local BodyAngularVelocity = Instance.new("BodyAngularVelocity")
    BodyAngularVelocity.Name = "Rotate"
    BodyAngularVelocity.MaxTorque = Vector3.new(0, 99e99, 0)
    BodyAngularVelocity.AngularVelocity = Vector3.zero
    BodyAngularVelocity.Parent = seat
    
    -- Stabilizer
    local BodyGyro = Instance.new("BodyGyro")
    BodyGyro.Name = "Stabilizer"
    BodyGyro.MaxTorque = Vector3.new(99e99, 0, 99e99)
    BodyGyro.P = 10000
    BodyGyro.D = 1000
    BodyGyro.CFrame = seat.CFrame
    BodyGyro.Parent = seat
    
    api:notify("✅ Physics objects created", 2)
end

-- Main flight loop
local function UpdateFlight()
    if not Settings.Enabled then return end
    
    local seat = GetSeat()
    if not seat or not seat:FindFirstChild("SeatWeld") then return end
    
    local bodyVel = seat:FindFirstChild("Move")
    local bodyRot = seat:FindFirstChild("Rotate")
    local bodyGyro = seat:FindFirstChild("Stabilizer")
    
    if not (bodyVel and bodyRot and bodyGyro) then return end
    
    local lookVector = seat.CFrame.LookVector
    local position = seat.Position
    local unit = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
    
    -- Set custom physics
    seat.CustomPhysicalProperties = PhysicalProperties.new(0.1, 0.1, 0.1, 0.1, 0.1)
    
    -- Horizontal velocity (W/S)
    local horizontalVel = Vector3.zero
    if Keys.W then
        horizontalVel = Vector3.new(lookVector.X, 0, lookVector.Z) * Settings.Speed
    elseif Keys.S then
        horizontalVel = Vector3.new(-lookVector.X, 0, -lookVector.Z) * Settings.Speed
    end
    
    -- Vertical velocity (Q/E)
    local verticalVel = 0
    if Keys.Q then
        verticalVel = Settings.VerticalSpeed
    elseif Keys.E then
        verticalVel = -Settings.VerticalSpeed
    end
    
    -- Combine
    bodyVel.Velocity = horizontalVel + Vector3.new(0, verticalVel, 0)
    
    -- Rotation (A/D)
    if Keys.A then
        bodyRot.AngularVelocity = Vector3.new(0, 3, 0)
    elseif Keys.D then
        bodyRot.AngularVelocity = Vector3.new(0, -3, 0)
    else
        bodyRot.AngularVelocity = Vector3.zero
    end
    
    -- Stabilizer
    bodyGyro.CFrame = CFrame.new(position, position + unit)
end

-- Input handling
local function OnInputBegan(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.W then
        Keys.W = true
    elseif input.KeyCode == Enum.KeyCode.S then
        Keys.S = true
    elseif input.KeyCode == Enum.KeyCode.A then
        Keys.A = true
    elseif input.KeyCode == Enum.KeyCode.D then
        Keys.D = true
    elseif input.KeyCode == Enum.KeyCode.Q then
        Keys.Q = true
    elseif input.KeyCode == Enum.KeyCode.E then
        Keys.E = true
    end
end

local function OnInputEnded(input)
    if input.KeyCode == Enum.KeyCode.W then
        Keys.W = false
    elseif input.KeyCode == Enum.KeyCode.S then
        Keys.S = false
    elseif input.KeyCode == Enum.KeyCode.A then
        Keys.A = false
    elseif input.KeyCode == Enum.KeyCode.D then
        Keys.D = false
    elseif input.KeyCode == Enum.KeyCode.Q then
        Keys.Q = false
    elseif input.KeyCode == Enum.KeyCode.E then
        Keys.E = false
    end
end

function StartCartFlight()
    local seat = GetSeat()
    if not seat then
        api:notify("❌ Cart/Bike not found! Buy one from the shop.", 3)
        Settings.Enabled = false
        EnableToggle:SetValue(false)
        return
    end
    
    api:notify("✅ Found cart seat", 2)
    
    -- Create physics objects
    CreatePhysicsObjects(seat)
    
    -- Connect inputs
    table.insert(connections, UserInputService.InputBegan:Connect(OnInputBegan))
    table.insert(connections, UserInputService.InputEnded:Connect(OnInputEnded))
    
    -- Main loop
    table.insert(connections, RunService.Heartbeat:Connect(UpdateFlight))
    
    api:notify("🚗 Cart Flight Enabled! WASD + Q/E", 2)
end

function StopCartFlight()
    -- Disconnect all
    for _, conn in ipairs(connections) do
        conn:Disconnect()
    end
    connections = {}
    
    -- Reset keys
    for k, _ in pairs(Keys) do
        Keys[k] = false
    end
    
    -- Remove physics objects
    local seat = GetSeat()
    if seat then
        for _, name in ipairs({"Move", "Rotate", "Stabilizer"}) do
            local obj = seat:FindFirstChild(name)
            if obj then obj:Destroy() end
        end
    end
    
    api:notify("Cart Flight Disabled", 2)
end

-- Info section
sec:AddLabel("Controls:")
sec:AddLabel("W/S - Forward/Backward")
sec:AddLabel("A/D - Rotate Left/Right")
sec:AddLabel("Q - Fly Up")
sec:AddLabel("E - Fly Down")

api:notify("Cart Flight Loaded", 3)
