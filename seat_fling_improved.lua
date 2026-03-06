
-- FLING SCRIPT IMPROVED - With Seat Claiming & Full Control
-- Click on parts to check if they're unanchored and rotate them

---------------------------------------------------------------------
-- SERVICES
---------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

---------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------
local OWNER = Players.LocalPlayer
local Mouse = OWNER:GetMouse()
local UnanchoredPart
local Whitelist = {}
local OriginalVelocity = {}
local Mode = "Target"
local Activated = false
local Active = false
local TARGET
local Random = false
local Prediction = 0.8
local Distance = 50
local axes = { x = 8, y = 8, z = 8 }
local rotation = { x = 0, y = 0, z = 0 }  -- Rotation in degrees
local Force = Vector3.new(-10000, -10000, -10000)
local hbConnection
local SelectionMode = false
local SelectionHighlight
local RotationEnabled = false

-- NEW STATE VARIABLES
local AutoClaim = false

---------------------------------------------------------------------
-- HELPER FUNCTIONS
---------------------------------------------------------------------
local function Notify(msg)
    game.StarterGui:SetCore("SendNotification", {
        Title = "Fling Script";
        Text = msg;
        Duration = 3;
    })
    print(msg)
end

local function ClaimSeat(seatPart)
    if not seatPart then return end
    if not (seatPart:IsA("Seat") or seatPart:IsA("VehicleSeat")) then
        Notify("⚠️ Not a Seat! Standard claim used.")
        return
    end

    Notify("🪑 Claiming Seat... Please wait.")
    
    local char = OWNER.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if root and hum then
        local originalCF = root.CFrame
        
        -- Teleport and Sit
        local seatCF = seatPart.CFrame
        root.CFrame = seatCF + Vector3.new(0, 2, 0)
        seatPart:Sit(hum)
        
        -- Wait for physics/network ownership transfer
        task.wait(0.2)
        pcall(function()
            seatPart:SetNetworkOwner(OWNER)
        end)
        task.wait(0.1)
        
        -- Jump out
        hum.Sit = false
        task.wait(0.1)
        
        -- Return
        root.CFrame = originalCF
        
        Notify("✅ Seat Claimed! Full Control ACQUIRED.")
    end
end

local function gplr(str)
    for _, v in pairs(Players:GetPlayers()) do
        if v.Name:lower():sub(1, #str) == str:lower()
            or v.DisplayName:lower():sub(1, #str) == str:lower() then
            if v ~= OWNER and v.Character and v.Character:FindFirstChild("Humanoid") then
                return v
            end
        end
    end
    return nil
end

local function gnearest()
    local Body = nil
    local distancee = Distance
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= OWNER
            and not table.find(Whitelist, v.Name)
            and v.Character
            and v.Character:FindFirstChild("HumanoidRootPart") then
            local dist = OWNER:DistanceFromCharacter(v.Character.HumanoidRootPart.Position)
            if dist < distancee then
                Body = v
                distancee = dist
            end
        end
    end
    return Body
end

local function Velocity(Plr)
    if Plr.Character and Plr.Character:FindFirstChild("HumanoidRootPart") then
        local CPosition = Plr.Character.HumanoidRootPart.Position
        local LastTick = tick()
        task.wait()
        local NPosition = Plr.Character.HumanoidRootPart.Position
        local NextTick = tick()
        local Offset = (NPosition - CPosition)
        local Elapsed = NextTick - LastTick
        return Offset / Elapsed
    end
end

local function Spawn()
    if UnanchoredPart and UnanchoredPart:FindFirstChildWhichIsA("BodyPosition") then
        if Random then
            UnanchoredPart.BodyPosition.Position =
                OWNER.Character.HumanoidRootPart.Position +
                Vector3.new(
                    math.random(-axes.x, axes.x),
                    math.random(-axes.y, axes.y),
                    math.random(-axes.z, axes.z)
                )
        else
            UnanchoredPart.BodyPosition.Position =
                OWNER.Character.HumanoidRootPart.Position + Vector3.new(axes.x, axes.y, axes.z)
        end
        UnanchoredPart.BodyThrust.Location = OWNER.Character.HumanoidRootPart.Position
        
        -- Apply rotation if enabled
        if RotationEnabled and UnanchoredPart:FindFirstChildWhichIsA("BodyGyro") then
            local rotCFrame = CFrame.Angles(
                math.rad(rotation.x),
                math.rad(rotation.y),
                math.rad(rotation.z)
            )
            UnanchoredPart.BodyGyro.CFrame = rotCFrame
        end
    end
end

local function DestroyIsA(typeofStr)
    if UnanchoredPart and UnanchoredPart:FindFirstChildWhichIsA(typeofStr) then
        UnanchoredPart:FindFirstChildWhichIsA(typeofStr):Destroy()
    end
end

local function ClaimNetworkOwnership()
    if UnanchoredPart then
        pcall(function()
            UnanchoredPart:SetNetworkOwner(OWNER)
        end)
    end
end

local function SetFlingPart(part)
    -- Stop current fling
    if Active then
        Active = false
        if hbConnection then
            hbConnection:Disconnect()
            hbConnection = nil
        end
    end
    
    -- Clean up old part
    if UnanchoredPart then
        DestroyIsA("BodyPosition")
        DestroyIsA("BodyThrust")
        DestroyIsA("BodyGyro")
        DestroyIsA("Highlight")
        UnanchoredPart.Velocity = Vector3.zero
        UnanchoredPart.AssemblyAngularVelocity = Vector3.zero
        UnanchoredPart.AssemblyLinearVelocity = Vector3.zero
    end
    
    -- Set new part
    UnanchoredPart = part
    part.Transparency = 0.5
    
    -- Auto Claim if enabled or just regular claim
    ClaimNetworkOwnership()
    if AutoClaim and (part:IsA("Seat") or part:IsA("VehicleSeat")) then
        ClaimSeat(part)
    end
    
    Notify("✅ New fling part: " .. part.Name)
    print("Part Path:", part:GetFullName())
end

local function CheckAndSelectPart(part)
    if not part or not part:IsA("BasePart") then
        Notify("❌ Not a valid part!")
        return
    end
    
    -- Check if it's a player part
    local isPlayerPart = false
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character and part:IsDescendantOf(player.Character) then
            isPlayerPart = true
            break
        end
    end
    
    if isPlayerPart then
        Notify("❌ Cannot use player parts!")
        return
    end
    
    -- Check if anchored
    if part.Anchored then
        Notify("⚠️ Part is ANCHORED: " .. part.Name)
    else
        local status = "✅ Part is UNANCHORED: " .. part.Name
        if part:IsA("Seat") or part:IsA("VehicleSeat") then
            status = status .. " (SEAT detected!)"
        end
        Notify(status)
        SetFlingPart(part)
    end
end

---------------------------------------------------------------------
-- SETUP INITIAL PART
---------------------------------------------------------------------

-- Try to find one automatically if none provided
if not UnanchoredPart then
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Part") and not v.Anchored then
            local isPlayerPart = false
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character and v:IsDescendantOf(player.Character) then
                    isPlayerPart = true
                    break
                end
            end
            
            if not isPlayerPart then
                CheckAndSelectPart(v)
                break
            end
        end
    end
end

if UnanchoredPart then
    ClaimNetworkOwnership()
    task.wait(0.5)
end

---------------------------------------------------------------------
-- CREATE GUI
---------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FlingGui_Improved"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 600) -- Increased height
Frame.Position = UDim2.new(0.5, -150, 0.5, -300)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(0, 255, 0)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Title.BorderSizePixel = 0
Title.Text = "FLING IMP. + SEAT CONTROL"
Title.TextColor3 = Color3.fromRGB(0, 255, 0)
Title.TextSize = 18
Title.Font = Enum.Font.Code
Title.Parent = Frame

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -40)
ScrollFrame.Position = UDim2.new(0, 5, 0, 35)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.Parent = Frame

local yOffset = 5

local function createLabel(text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 20)
    label.Position = UDim2.new(0, 5, 0, yOffset)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Font = Enum.Font.Code
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = ScrollFrame
    yOffset = yOffset + 25
    return label
end

local function createButton(text, callback, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 30)
    button.Position = UDim2.new(0, 5, 0, yOffset)
    button.BackgroundColor3 = color or Color3.fromRGB(0, 100, 0)
    button.BorderColor3 = Color3.fromRGB(0, 255, 0)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Font = Enum.Font.Code
    button.Parent = ScrollFrame
    button.MouseButton1Click:Connect(callback)
    yOffset = yOffset + 35
    return button
end

local function createToggle(text, default, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -10, 0, 30)
    button.Position = UDim2.new(0, 5, 0, yOffset)
    button.BackgroundColor3 = default and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 0, 0)
    button.BorderColor3 = Color3.fromRGB(0, 255, 0)
    button.Text = text .. ": " .. (default and "ON" or "OFF")
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Font = Enum.Font.Code
    button.Parent = ScrollFrame
    
    local state = default
    button.MouseButton1Click:Connect(function()
        state = not state
        button.BackgroundColor3 = state and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(100, 0, 0)
        button.Text = text .. ": " .. (state and "ON" or "OFF")
        callback(state)
    end)
    
    yOffset = yOffset + 35
    return button
end

local function createDropdown(text, options, default, callback)
    createLabel(text)
    
    for _, option in ipairs(options) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -20, 0, 25)
        button.Position = UDim2.new(0, 15, 0, yOffset)
        button.BackgroundColor3 = (option == default) and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(50, 50, 50)
        button.BorderColor3 = Color3.fromRGB(0, 255, 0)
        button.Text = option
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 12
        button.Font = Enum.Font.Code
        button.Parent = ScrollFrame
        
        button.MouseButton1Click:Connect(function()
            for _, child in pairs(ScrollFrame:GetChildren()) do
                if child:IsA("TextButton") and child.Text ~= text then
                    for _, opt in ipairs(options) do
                        if child.Text == opt then
                            child.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                        end
                    end
                end
            end
            button.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
            callback(option)
        end)
        
        yOffset = yOffset + 30
    end
end

local function createSlider(text, min, max, default, callback)
    local label = createLabel(text .. ": " .. tostring(default))
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -10, 0, 20)
    sliderFrame.Position = UDim2.new(0, 5, 0, yOffset)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    sliderFrame.BorderColor3 = Color3.fromRGB(0, 255, 0)
    sliderFrame.Parent = ScrollFrame
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    sliderButton.BorderSizePixel = 0
    sliderButton.Text = ""
    sliderButton.Parent = sliderFrame
    
    local dragging = false
    
    sliderButton.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    sliderFrame.InputChanged:Connect(function(input)
        if dragging or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation().X
            local framePos = sliderFrame.AbsolutePosition.X
            local frameSize = sliderFrame.AbsoluteSize.X
            local percent = math.clamp((mousePos - framePos) / frameSize, 0, 1)
            local value = math.floor(min + (max - min) * percent)
            
            sliderButton.Size = UDim2.new(percent, 0, 1, 0)
            callback(value)
            label.Text = text .. ": " .. tostring(value)
        end
    end)
    
    yOffset = yOffset + 25
end

-- UI ELEMENTS
-- PART SELECTION MODE
createToggle("Part Selection Mode", false, function(v)
    SelectionMode = v
    
    if SelectionMode then
        Notify("🔍 Click on a part to check/select it")
        
        if not SelectionHighlight then
            SelectionHighlight = Instance.new("Highlight")
            SelectionHighlight.FillTransparency = 0.7
            SelectionHighlight.OutlineTransparency = 0
            SelectionHighlight.OutlineColor = Color3.fromRGB(255, 255, 0)
        end
    else
        Notify("❌ Selection mode disabled")
        if SelectionHighlight then
            SelectionHighlight.Parent = nil
        end
    end
end)

createButton("🪑 CLAIM SEAT (Fix Lag) 🪑", function()
    if UnanchoredPart then
        ClaimSeat(UnanchoredPart)
    else
        Notify("❌ Select a Seat first!")
    end
end, Color3.fromRGB(200, 100, 0))

createToggle("Auto-Claim Seats", false, function(v)
    AutoClaim = v
    if v then Notify("⚠️ Auto-Claim Enabled (Will sit automatically)") end
end)

createDropdown("Mode", {"Target", "Nearest", "Key", "Constant"}, "Target", function(v)
    Mode = v
    print("Mode:", v)
end)

createToggle("Start Fling", false, function(v)
    Active = v
    
    if not UnanchoredPart then
        Notify("❌ No fling part! Use Selection Mode first!")
        Active = false
        return
    end
    
    if Active and UnanchoredPart then
        if hbConnection then
            hbConnection:Disconnect()
        end
        
        hbConnection = RunService.Heartbeat:Connect(function()
            UnanchoredPart.CanCollide = false
            UnanchoredPart.CanTouch = false
            
            pcall(function()
                sethiddenproperty(OWNER, "SimulationRadius", math.huge)
                UnanchoredPart.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
            end)
            
            ClaimNetworkOwnership()
            
            if not UnanchoredPart:FindFirstChildWhichIsA("BodyPosition") then
                Instance.new("BodyPosition", UnanchoredPart)
            end
            if not UnanchoredPart:FindFirstChildWhichIsA("BodyThrust") then
                Instance.new("BodyThrust", UnanchoredPart)
            end
            if not UnanchoredPart:FindFirstChildWhichIsA("Highlight") then
                Instance.new("Highlight", UnanchoredPart)
            end
            
            -- Create BodyGyro for rotation control
            if RotationEnabled and not UnanchoredPart:FindFirstChildWhichIsA("BodyGyro") then
                local gyro = Instance.new("BodyGyro", UnanchoredPart)
                gyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                gyro.P = 10000
                gyro.D = 500
            end
            
            UnanchoredPart.BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            UnanchoredPart.BodyPosition.P = 10000
            UnanchoredPart.BodyPosition.D = 175
            UnanchoredPart.Velocity = Vector3.new(0, -87, 0)
            
            -- Apply rotation
            if RotationEnabled and UnanchoredPart:FindFirstChildWhichIsA("BodyGyro") then
                local rotCFrame = CFrame.Angles(
                    math.rad(rotation.x),
                    math.rad(rotation.y),
                    math.rad(rotation.z)
                )
                UnanchoredPart.BodyGyro.CFrame = rotCFrame
            end
            
            local hl = UnanchoredPart:FindFirstChildWhichIsA("Highlight")
            if hl then
                local hsv = tick() % 5 / 5
                hl.OutlineTransparency = 0
                hl.FillTransparency = 0.5
                hl.OutlineColor = Color3.fromHSV(hsv, 1, 1)
                hl.FillColor = Color3.fromHSV(hsv, 1, 1)
            end
            
            if Mode == "Target" then
                if not Activated then
                    Spawn()
                else
                    if TARGET and TARGET.Character and TARGET.Character:FindFirstChild("HumanoidRootPart") then
                        UnanchoredPart.BodyThrust.Force = Force
                        UnanchoredPart.BodyPosition.Position =
                            TARGET.Character.HumanoidRootPart.Position +
                            (OriginalVelocity[1] or Vector3.zero) * Prediction
                        UnanchoredPart.BodyThrust.Location =
                            TARGET.Character.HumanoidRootPart.Position
                    else
                        Spawn()
                    end
                end
                
            elseif Mode == "Nearest" then
                TARGET = gnearest()
                if not TARGET then
                    Spawn()
                else
                    UnanchoredPart.BodyThrust.Force = Force
                    UnanchoredPart.BodyPosition.Position =
                        TARGET.Character.HumanoidRootPart.Position +
                        (OriginalVelocity[1] or Vector3.zero) * Prediction
                    UnanchoredPart.BodyThrust.Location =
                        TARGET.Character.HumanoidRootPart.Position
                end
                
            elseif Mode == "Key" then
                if not Activated then
                    Spawn()
                else
                    UnanchoredPart.BodyThrust.Force = Force
                    UnanchoredPart.BodyPosition.Position = Mouse.Hit.p
                    UnanchoredPart.BodyThrust.Location = OWNER.Character.HumanoidRootPart.Position
                end
                
            elseif Mode == "Constant" then
                Spawn()
            end
        end)
    else
        if hbConnection then
            hbConnection:Disconnect()
            hbConnection = nil
        end
        DestroyIsA("BodyPosition")
        DestroyIsA("BodyThrust")
        DestroyIsA("BodyGyro")
        DestroyIsA("Highlight")
        UnanchoredPart.Velocity = Vector3.zero
        UnanchoredPart.AssemblyAngularVelocity = Vector3.zero
        UnanchoredPart.AssemblyLinearVelocity = Vector3.zero
        UnanchoredPart.CanCollide = true
    end
end)

createToggle("Random Spawn", false, function(v)
    Random = v
end)

-- ROTATION CONTROLS
createToggle("Enable Rotation", false, function(v)
    RotationEnabled = v
    if v then
        Notify("🔄 Rotation enabled")
    else
        Notify("❌ Rotation disabled")
        DestroyIsA("BodyGyro")
    end
end)

createSlider("Rotate X", 0, 360, rotation.x, function(v)
    rotation.x = v
end)

createSlider("Rotate Y", 0, 360, rotation.y, function(v)
    rotation.y = v
end)

createSlider("Rotate Z", 0, 360, rotation.z, function(v)
    rotation.z = v
end)

createButton("Reset Rotation", function()
    rotation.x = 0
    rotation.y = 0
    rotation.z = 0
    Notify("🔄 Rotation reset to 0°")
end)

createSlider("Prediction", 0, 100, Prediction * 100, function(v)
    Prediction = v / 100
end)

createSlider("Distance", 0, 100, Distance, function(v)
    Distance = v
end)

createSlider("X Offset", -100, 100, axes.x, function(v)
    axes.x = v
end)

createSlider("Y Offset", -100, 100, axes.y, function(v)
    axes.y = v
end)

createSlider("Z Offset", -100, 100, axes.z, function(v)
    axes.z = v
end)

createButton("Refresh Ownership", function()
    if UnanchoredPart then
        ClaimNetworkOwnership()
        Notify("🔄 Ownership refreshed")
    else
        Notify("❌ No part selected!")
    end
end)

createButton("TP to Part", function()
    if UnanchoredPart and OWNER.Character and OWNER.Character:FindFirstChild("HumanoidRootPart") then
        OWNER.Character.HumanoidRootPart.CFrame = UnanchoredPart.CFrame
        Notify("✈️ Teleported to part")
    else
        Notify("❌ No part or character!")
    end
end)

ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 10)

---------------------------------------------------------------------
-- MOUSE HOVER (Selection Mode)
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if SelectionMode and SelectionHighlight then
        local target = Mouse.Target
        if target and target:IsA("BasePart") then
            SelectionHighlight.Parent = target
        else
            SelectionHighlight.Parent = nil
        end
    end
end)

---------------------------------------------------------------------
-- MOUSE CLICK (Selection Mode)
---------------------------------------------------------------------
Mouse.Button1Down:Connect(function()
    if SelectionMode then
        local target = Mouse.Target
        if target then
            CheckAndSelectPart(target)
        end
    end
end)

---------------------------------------------------------------------
-- CHAT COMMANDS
---------------------------------------------------------------------
OWNER.Chatted:Connect(function(message)
    local args = message:split(" ")
    if args[1] == ":smite" then
        if #args > 1 then
            TARGET = gplr(args[2])
            if TARGET and Active and Mode == "Target" then
                Activated = true
                Notify("🎯 Targeting: " .. TARGET.Name)
                task.wait(1)
                Activated = false
            end
        end
    elseif args[1] == ":w" then
        if #args > 1 then
            local plr = gplr(args[2])
            if plr and not table.find(Whitelist, plr.Name) then
                table.insert(Whitelist, plr.Name)
                Notify("✅ Whitelisted: " .. plr.Name)
            end
        end
    elseif args[1] == ":uw" then
        if #args > 1 then
            local plr = gplr(args[2])
            if plr then
                local index = table.find(Whitelist, plr.Name)
                if index then
                    table.remove(Whitelist, index)
                    Notify("❌ Unwhitelisted: " .. plr.Name)
                end
            end
        end
    end
end)

---------------------------------------------------------------------
-- INPUT
---------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.E and Active and Mode == "Key" then
        Activated = true
        task.wait(0.3)
        Activated = false
    end
end)

---------------------------------------------------------------------
-- VELOCITY TRACKER
---------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    if TARGET and typeof(TARGET) == "Instance" then
        OriginalVelocity[1] = Velocity(TARGET) or Vector3.zero
    end
end)

print("✅ Fling Script IMPROVED Loaded!")
if UnanchoredPart then
    print("📦 Part:", UnanchoredPart:GetFullName())
end
