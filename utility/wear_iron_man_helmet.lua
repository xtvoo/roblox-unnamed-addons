local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- --- CONFIGURATION & PART DEFINITIONS ---
local PART_EYES = "Meshes/Testing_Plane.028_Plane.021_Glow.001"
local PART_FACE = "Meshes/Testing_Plane.028_Plane.021_Gold.002"
local PART_TRIM = "Meshes/Testing_Plane.028_Plane.021_Grey.001"
local PART_MASK = "Meshes/Testing_Plane.028_Plane.021_Red.001"

-- Store offsets in a table for easy access
-- Default: Face/Eyes slightly forward/up, rest at 0
local Offsets = {
    [PART_EYES] = {X = 0, Y = -0.13, Z = -0.13},
    [PART_FACE] = {X = 0, Y = -0.06, Z = -0.51},
    [PART_TRIM] = {X = 0, Y = -0.2, Z = -0.2},
    [PART_MASK] = {X = 0, Y = 0, Z = 0},
}

-- For UI Display Names
local DisplayNames = {
    [PART_EYES] = "Eyes",
    [PART_FACE] = "Face",
    [PART_TRIM] = "Trim",
    [PART_MASK] = "Mask"
}

-- Order of offsets to show in UI
local Order = {PART_EYES, PART_FACE, PART_TRIM, PART_MASK}

-- --- GUI CREATION ---
local function createGUI()
    if LocalPlayer.PlayerGui:FindFirstChild("HelmetAdjuster") then
        LocalPlayer.PlayerGui.HelmetAdjuster:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "HelmetAdjuster"
    ScreenGui.Parent = LocalPlayer.PlayerGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 240, 0, 450)
    MainFrame.Position = UDim2.new(0.05, 0, 0.5, -225)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 2
    MainFrame.Parent = ScreenGui
    
    local Title = Instance.new("TextLabel")
    Title.Text = "Ultimate Helmet Adjuster"
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
    Title.ZIndex = 2
    Title.Parent = MainFrame
    
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 1, -30)
    Scroll.Position = UDim2.new(0, 0, 0, 30)
    Scroll.BackgroundTransparency = 1
    Scroll.ScrollBarThickness = 6
    Scroll.Parent = MainFrame
    
    local layoutOrder = 0
    local yPos = 10
    
    local function createSliderGroup(partKey)
        local displayName = DisplayNames[partKey] or "Part"
        
        -- Header
        local header = Instance.new("TextLabel")
        header.Text = "--- " .. displayName .. " ---"
        header.Size = UDim2.new(1, 0, 0, 20)
        header.Position = UDim2.new(0, 0, 0, yPos)
        header.BackgroundTransparency = 1
        header.TextColor3 = Color3.fromRGB(255, 215, 0)
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
            label.Text = axis .. ": " .. Offsets[partKey][axis]
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
            sliderBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
            sliderBtn.Parent = sliderBg
            
            -- Logic
            local dragging = false
            local range = 4 -- -2 to 2 studs
            local currentVal = Offsets[partKey][axis]
            
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
                    
                    local value = (alpha * range) - (range/2)
                    value = math.floor(value * 100) / 100 -- Round
                    
                    label.Text = axis .. ": " .. value
                    Offsets[partKey][axis] = value
                end
            end)
        end
        
        makeSlider("X")
        makeSlider("Y")
        makeSlider("Z")
        yPos = yPos + 10
    end
    
    -- Generate for all parts
    for _, partKey in ipairs(Order) do
        createSliderGroup(partKey)
    end
    
    Scroll.CanvasSize = UDim2.new(0, 0, 0, yPos + 50)
    
    MainFrame.Active = true
    MainFrame.Draggable = true
end

-- --- MAIN LOGIC ---
local function wearHelmet()
    createGUI() 
    
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local head = character:WaitForChild("Head")
    
    local originalHelmet = ReplicatedStorage:FindFirstChild("SecretKicksRoom")
        and ReplicatedStorage.SecretKicksRoom:FindFirstChild("Mark85")
        and ReplicatedStorage.SecretKicksRoom.Mark85:FindFirstChild("Mk 85 helmet")
        
    if not originalHelmet then
        warn("Helmet not found!")
        return
    end
    
    local helmetClone = originalHelmet:Clone()
    helmetClone.Name = "IronManHelmet_Equipped"
    
    for _, desc in ipairs(helmetClone:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc.Anchored = true
            desc.CanCollide = false
            desc.Massless = true
        end
    end
    
    helmetClone.Parent = character
    
    -- VISUAL CLEANUP
    local function hideCharacterVisuals()
        -- 1. Hide Head & Face
        if head then
            head.Transparency = 1
            for _, d in ipairs(head:GetChildren()) do
                if d:IsA("Decal") then d.Transparency = 1 end
            end
        end
        
        -- 2. Hide Hair/Hats
        for _, acc in ipairs(character:GetChildren()) do
            if acc:IsA("Accessory") then
                local handle = acc:FindFirstChild("Handle")
                if handle then
                    handle.Transparency = 1
                end
            end
        end
    end
    hideCharacterVisuals()
    
    -- Render Loop
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if helmetClone.Parent and head.Parent then
            
            if helmetClone:IsA("Model") then
                for _, part in ipairs(helmetClone:GetChildren()) do
                    if part:IsA("BasePart") then
                        -- Find offset for this specific part
                        local off = Offsets[part.Name]
                        if off then
                            local cf = head.CFrame * CFrame.new(off.X, off.Y, off.Z)
                            part.CFrame = cf
                        else
                            -- Fallback for unknown parts? Just stick to head
                            part.CFrame = head.CFrame
                        end
                    end
                end
            elseif helmetClone:IsA("BasePart") then
                 helmetClone.CFrame = head.CFrame -- Single part support (unlikely here)
            end
        else
            connection:Disconnect()
        end
    end)
end

wearHelmet()
