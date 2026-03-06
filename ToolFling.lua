-- ToolFling.lua
-- Unnamed Addon
-- Uses equipped tool handle to fling targets

api:set_lua_name("ToolFling")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local State = {
    Enabled = false,
    Mode = "Target", -- Target, Mouse, Nearest
    Target = nil,
    Prediction = 1.0,
    SpinSpeed = 20,
    Loop = nil
}

local currentTool = nil
local currentHandle = nil

-- UI Setup
local Tab = api:GetTab("ToolFling") or api:AddTab("ToolFling")
local Group = Tab:AddLeftGroupbox("Main")

-- Helpers
local function Notify(msg)
    api:notify(msg, 2)
end

local function GetTarget(name)
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and (v.Name:lower():sub(1, #name) == name:lower() or v.DisplayName:lower():sub(1, #name) == name:lower()) then
            return v
        end
    end
    return nil
end

local function GetNearest()
    local near = nil
    local dist = 9e9
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local d = LocalPlayer:DistanceFromCharacter(v.Character.HumanoidRootPart.Position)
            if d < dist then
                dist = d
                near = v
            end
        end
    end
    return near
end

-- Detach Tool Logic
local function DetachTool()
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildWhichIsA("Tool")
    if not tool or not tool:FindFirstChild("Handle") then
        Notify("❌ No tool with handle found!")
        return nil
    end

    currentTool = tool
    currentHandle = tool.Handle

    -- Break Weld
    if currentHandle:FindFirstChildWhichIsA("Weld") then
        currentHandle:FindFirstChildWhichIsA("Weld"):Destroy()
    end
    -- Also check Right Grip
    local arm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
    if arm and arm:FindFirstChild("RightGrip") then
        arm.RightGrip:Destroy()
    end

    -- Physics Setup
    currentHandle.CanCollide = false
    currentHandle.Massless = true
    return currentHandle
end

-- Fling Loop
local function StartFling()
    if State.Loop then State.Loop:Disconnect() end
    
    State.Loop = RunService.Heartbeat:Connect(function()
        if not State.Enabled then return end
        
        -- Ensure tool is ready
        if not currentHandle or not currentHandle.Parent then
            local h = DetachTool()
            if not h then return end
        end

        local handle = currentHandle
        
        -- Claim Ownership
        pcall(function()
            handle:SetNetworkOwner(LocalPlayer)
            sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
        end)
        
        -- Physics objects
        local bp = handle:FindFirstChild("FlingBP") or Instance.new("BodyPosition", handle)
        bp.Name = "FlingBP"
        bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bp.P = 15000
        bp.D = 800

        local bav = handle:FindFirstChild("FlingBAV") or Instance.new("BodyAngularVelocity", handle)
        bav.Name = "FlingBAV"
        bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bav.AngularVelocity = Vector3.new(State.SpinSpeed, State.SpinSpeed, State.SpinSpeed)

        -- Determine Target Position
        local targetPos = nil
        
        if State.Mode == "Mouse" then
            targetPos = Mouse.Hit.Position
        elseif State.Mode == "Target" then
            if State.Target and State.Target.Character and State.Target.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = State.Target.Character.HumanoidRootPart
                targetPos = hrp.Position + (hrp.AssemblyLinearVelocity * State.Prediction)
            end
        elseif State.Mode == "Nearest" then
            local near = GetNearest()
            if near and near.Character and near.Character:FindFirstChild("HumanoidRootPart") then
                targetPos = near.Character.HumanoidRootPart.Position
            end
        end

        -- Move
        if targetPos then
            bp.Position = targetPos
        else
            -- Return to player if no target
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
                bp.Position = LocalPlayer.Character.Head.Position + Vector3.new(0, 5, 0)
            end
        end
        
        -- Noclip Handle
        handle.CanCollide = false
    end)
end

-- UI
Group:AddToggle("EnableFling", {
    Text = "Enable Tool Fling",
    Default = false,
    Callback = function(v)
        State.Enabled = v
        if v then
            Notify("⚠️ Equip a tool first!")
            StartFling()
        else
            if State.Loop then State.Loop:Disconnect() end
            if currentHandle then
                -- Cleanup
                if currentHandle:FindFirstChild("FlingBP") then currentHandle.FlingBP:Destroy() end
                if currentHandle:FindFirstChild("FlingBAV") then currentHandle.FlingBAV:Destroy() end
                Notify("Resetting... Re-equip tool.")
                currentHandle = nil
                currentTool = nil
                LocalPlayer.Character.Humanoid:UnequipTools()
            end
        end
    end
})

Group:AddDropdown("FlingMode", {
    Values = {"Target", "Nearest", "Mouse"},
    Default = "Target",
    Text = "Mode",
    Callback = function(v) State.Mode = v end
})

Group:AddInput("TargetPlayer", {
    Default = "",
    Text = "Target Player",
    Placeholder = "Name...",
    Callback = function(v)
        local t = GetTarget(v)
        if t then
            State.Target = t
            Notify("Target: " .. t.Name)
        end
    end
})

Group:AddSlider("SpinSpeed", {
    Text = "Spin Speed",
    Default = 20,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(v) State.SpinSpeed = v end
})

api:notify("ToolFling Loaded. Equip a tool!", 5)
