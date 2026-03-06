local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- --- CONFIGURATION ---
-- Keys for every single part for maximum control
local KEYS = {
    L_HAND = "LeftHand",
    L_LOW_ARM = "LeftLowerArm",
    L_UP_ARM = "LeftUpperArm",
    
    R_HAND = "RightHand",
    R_LOW_ARM = "RightLowerArm",
    R_UP_ARM = "RightUpperArm",
    
    L_FOOT = "LeftFoot",
    L_LOW_LEG = "LeftLowerLeg",
    L_UP_LEG = "LeftUpperLeg",
    
    R_FOOT = "RightFoot",
    R_LOW_LEG = "RightLowerLeg",
    R_UP_LEG = "RightUpperLeg",
    
    HEAD = "Head", -- Just in case
    UP_TORSO = "UpperTorso",
    LOW_TORSO = "LowerTorso"
}

-- Default Offsets (start at 0, 0, 0)
local Offsets = {}
for _, key in pairs(KEYS) do
    Offsets[key] = {X = 0, Y = 0, Z = 0}
end

-- Apply Defaults from Screenshots
Offsets[KEYS.UP_TORSO] = {X = -0.26, Y = -0.01, Z = -0.01}
Offsets[KEYS.LOW_TORSO] = {X = -0.24, Y = -0.04, Z = 0}

Offsets[KEYS.L_UP_ARM] = {X = -0.59, Y = -0.04, Z = 0}
Offsets[KEYS.L_LOW_ARM] = {X = -0.29, Y = -0.29, Z = 0.09}
Offsets[KEYS.L_HAND] = {X = -0.24, Y = -0.21, Z = 0.34}

-- Right Arm (User Provided)
Offsets[KEYS.R_UP_ARM] = {X = 0.11, Y = -0.04, Z = 0.01}
Offsets[KEYS.R_LOW_ARM] = {X = -0.14, Y = -0.39, Z = 0.14}
Offsets[KEYS.R_HAND] = {X = -0.21, Y = -0.49, Z = 0.46}

-- Legs
Offsets[KEYS.L_UP_LEG] = {X = -0.29, Y = 0.26, Z = -0.26}
Offsets[KEYS.L_LOW_LEG] = {X = -0.21, Y = 0.41, Z = -0.06}

-- Mirror Left Leg to Right Leg (Proactive)
Offsets[KEYS.R_UP_LEG] = {X = 0.29, Y = 0.26, Z = -0.26}
Offsets[KEYS.R_LOW_LEG] = {X = 0.21, Y = 0.41, Z = -0.06}

-- Logical Order for UI
local Order = {
    KEYS.HEAD,
    KEYS.UP_TORSO, KEYS.LOW_TORSO,
    KEYS.L_UP_ARM, KEYS.L_LOW_ARM, KEYS.L_HAND,
    KEYS.R_UP_ARM, KEYS.R_LOW_ARM, KEYS.R_HAND,
    KEYS.L_UP_LEG, KEYS.L_LOW_LEG, KEYS.L_FOOT,
    KEYS.R_UP_LEG, KEYS.R_LOW_LEG, KEYS.R_FOOT
}

-- Map Suit Part Name -> Offset Key AND Character Limb Name
-- Note: The Suit Part Names must match exactly what's in the model
local BodyMap = {
    ["LeftHand"]      = {Key = KEYS.L_HAND, Limb = "LeftHand"},
    ["LeftLowerArm"]  = {Key = KEYS.L_LOW_ARM, Limb = "LeftLowerArm"},
    ["LeftUpperArm"]  = {Key = KEYS.L_UP_ARM, Limb = "LeftUpperArm"},
    
    ["RightHand"]     = {Key = KEYS.R_HAND, Limb = "RightHand"},
    ["RightLowerArm"] = {Key = KEYS.R_LOW_ARM, Limb = "RightLowerArm"},
    ["RightUpperArm"] = {Key = KEYS.R_UP_ARM, Limb = "RightUpperArm"},
    
    ["LeftFoot"]      = {Key = KEYS.L_FOOT, Limb = "LeftFoot"},
    ["LeftLowerLeg"]  = {Key = KEYS.L_LOW_LEG, Limb = "LeftLowerLeg"},
    ["LeftUpperLeg"]  = {Key = KEYS.L_UP_LEG, Limb = "LeftUpperLeg"},
    
    ["RightFoot"]     = {Key = KEYS.R_FOOT, Limb = "RightFoot"},
    ["RightLowerLeg"] = {Key = KEYS.R_LOW_LEG, Limb = "RightLowerLeg"},
    ["RightUpperLeg"] = {Key = KEYS.R_UP_LEG, Limb = "RightUpperLeg"},
    
    ["LowerTorso"]    = {Key = KEYS.LOW_TORSO, Limb = "LowerTorso"},
    ["UpperTorso"]    = {Key = KEYS.UP_TORSO, Limb = "UpperTorso"},
    
    ["Mk 85 helmet"]  = {Key = KEYS.HEAD, Limb = "Head"}, -- Support helmet if it's there
}

-- --- GUI CREATION ---
local function createGUI()
    if LocalPlayer.PlayerGui:FindFirstChild("SuitAdjuster") then
        LocalPlayer.PlayerGui.SuitAdjuster:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SuitAdjuster"
    ScreenGui.Parent = LocalPlayer.PlayerGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 260, 0, 500)
    MainFrame.Position = UDim2.new(0.02, 0, 0.5, -250)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MainFrame.BorderSizePixel = 2
    MainFrame.Parent = ScreenGui
    
    local Title = Instance.new("TextLabel")
    Title.Text = "Suit Adjuster (Per-Limb)"
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
    Title.Parent = MainFrame
    
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 1, -30)
    Scroll.Position = UDim2.new(0, 0, 0, 30)
    Scroll.BackgroundTransparency = 1
    Scroll.ScrollBarThickness = 8
    Scroll.Parent = MainFrame
    
    local yPos = 10
    
    local function createGroup(groupName)
        local header = Instance.new("TextLabel")
        header.Text = "--- " .. groupName .. " ---"
        header.Size = UDim2.new(1, 0, 0, 20)
        header.Position = UDim2.new(0, 0, 0, yPos)
        header.TextColor3 = Color3.fromRGB(255, 215, 0)
        header.BackgroundTransparency = 1
        header.Font = Enum.Font.SourceSansBold
        header.Parent = Scroll
        yPos = yPos + 25
        
        local function makeSlider(axis)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, -20, 0, 40)
            frame.Position = UDim2.new(0, 10, 0, yPos)
            frame.BackgroundTransparency = 1
            frame.Parent = Scroll
            yPos = yPos + 45
            
            local label = Instance.new("TextLabel")
            label.Text = axis .. ": " .. Offsets[groupName][axis]
            label.Size = UDim2.new(1, 0, 0, 20)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
            label.Parent = frame
            
            local sliderBg = Instance.new("Frame")
            sliderBg.Size = UDim2.new(1, 0, 0, 10)
            sliderBg.Position = UDim2.new(0, 0, 0, 25)
            sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            sliderBg.Parent = frame
            
            local sliderBtn = Instance.new("TextButton")
            sliderBtn.Text = ""
            sliderBtn.Size = UDim2.new(0, 10, 1, 6)
            sliderBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
            sliderBtn.Parent = sliderBg
            
            local dragging = false
            local range = 6 -- -3 to 3 studs (Wider range for finding lost parts)
            local currentVal = Offsets[groupName][axis]
            local startAlpha = (currentVal + (range/2)) / range
            sliderBtn.Position = UDim2.new(math.clamp(startAlpha, 0, 1), -5, 0.5, -3)

            sliderBtn.MouseButton1Down:Connect(function() dragging = true end)
            game:GetService("UserInputService").InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
            
            game:GetService("RunService").RenderStepped:Connect(function()
                if dragging then
                    local mouse = LocalPlayer:GetMouse()
                    local relativeX = mouse.X - sliderBg.AbsolutePosition.X
                    local alpha = math.clamp(relativeX / sliderBg.AbsoluteSize.X, 0, 1)
                    sliderBtn.Position = UDim2.new(alpha, -5, 0.5, -3)
                    local val = (alpha * range) - (range/2)
                    val = math.floor(val * 100) / 100
                    label.Text = axis .. ": " .. val
                    Offsets[groupName][axis] = val
                end
            end)
        end
        makeSlider("X")
        makeSlider("Y")
        makeSlider("Z")
        yPos = yPos + 10 -- spacer
    end
    
    -- Filter order to only show keys that exist in BodyMap (if you wanted to filter)
    -- But we'll just show all in Order
    for _, grp in ipairs(Order) do
         createGroup(grp)
    end
    Scroll.CanvasSize = UDim2.new(0, 0, 0, yPos + 50)
    MainFrame.Active = true
    MainFrame.Draggable = true
end

-- --- MAIN LOGIC ---
local function wearSuit()
    createGUI()
    
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = character:WaitForChild("HumanoidRootPart")
    
    -- Hide Body (Optional, keep it to see where mapped)
    local function hideVisuals()
        for _, desc in ipairs(character:GetDescendants()) do
             if desc:IsA("Accessory") then
                local h = desc:FindFirstChild("Handle")
                if h then h.Transparency = 1 end
             end
             -- Maybe don't hide body parts yet so user can see where to align?
             -- user asked to hide hair previously.
             if desc:IsA("BasePart") and desc.Name == "Head" then
                 desc.Transparency = 1
             end
             if desc:IsA("Decal") and desc.Parent.Name == "Head" then
                 desc.Transparency = 1
             end
        end
    end
    hideVisuals()
    
    -- Find Suit
    local source = ReplicatedStorage:FindFirstChild("SecretKicksRoom")
        and ReplicatedStorage.SecretKicksRoom:FindFirstChild("Mark85")
        and ReplicatedStorage.SecretKicksRoom.Mark85:FindFirstChild("Mark 85") 
        
    if not source then warn("Suit 'Mark 85' container not found!") return end
    
    local suitClone = source:Clone()
    suitClone.Name = "EquippedSuit_Config_Full"
    
    -- Anchor Everything
    for _, desc in ipairs(suitClone:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc.Anchored = true
            desc.CanCollide = false
            desc.Massless = true
        end
    end
    
    suitClone.Parent = character
    
    -- Render Loop
    game:GetService("RunService").RenderStepped:Connect(function()
        if not character.Parent then return end
        
        for _, child in ipairs(suitClone:GetChildren()) do
            local mapInfo = BodyMap[child.Name]
            
            if mapInfo and (child:IsA("BasePart") or child:IsA("Model")) then
                -- Identify Target Limb
                local targetLimb = character:FindFirstChild(mapInfo.Limb)
                
                -- R6 Fallback Logic
                if not targetLimb then
                    if string.find(mapInfo.Limb, "Torso") then targetLimb = character:FindFirstChild("Torso") end
                    if string.find(mapInfo.Limb, "Left") and string.find(mapInfo.Limb, "Arm") then targetLimb = character:FindFirstChild("Left Arm") end
                    if string.find(mapInfo.Limb, "Right") and string.find(mapInfo.Limb, "Arm") then targetLimb = character:FindFirstChild("Right Arm") end
                    if string.find(mapInfo.Limb, "Left") and string.find(mapInfo.Limb, "Leg") then targetLimb = character:FindFirstChild("Left Leg") end
                    if string.find(mapInfo.Limb, "Right") and string.find(mapInfo.Limb, "Leg") then targetLimb = character:FindFirstChild("Right Leg") end
                end
                 -- If Hand/Foot missing in R6, map to Arm/Leg
                if not targetLimb then
                     if mapInfo.Limb == "LeftHand" then targetLimb = character:FindFirstChild("Left Arm") end
                     if mapInfo.Limb == "RightHand" then targetLimb = character:FindFirstChild("Right Arm") end
                     if mapInfo.Limb == "LeftFoot" then targetLimb = character:FindFirstChild("Left Leg") end
                     if mapInfo.Limb == "RightFoot" then targetLimb = character:FindFirstChild("Right Leg") end
                end

                
                if targetLimb then
                    -- Get Offset for this SPECIFIC KEY
                    local off = Offsets[mapInfo.Key]
                    local finalCF = targetLimb.CFrame * CFrame.new(off.X, off.Y, off.Z)
                    
                    if child:IsA("Model") then
                        child:PivotTo(finalCF)
                    elseif child:IsA("BasePart") then
                        child.CFrame = finalCF
                    end
                end
            end
        end
    end)
    print("Full Suit Equipped (Granular Control)")
end

wearSuit()
