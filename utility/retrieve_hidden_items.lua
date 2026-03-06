-- Bring Hidden Items to Workspace (Original Position & Anchored)
-- Spawns items from SecretKicksRoom into Workspace without moving them, and fully anchors them
-- Also modifies map to reveal the room

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local function modifyMap()
    print("--- Modifying Map for Access ---")
    local map = Workspace:FindFirstChild("MAP")
    if map then
        -- Delete fake walls
        local fakeBlue = map:FindFirstChild("FakeBlueBrick")
        if fakeBlue then 
            fakeBlue:Destroy() 
            print("Deleted FakeBlueBrick")
        end
        
        local fakePart = map:FindFirstChild("FakePart")
        if fakePart then 
            fakePart:Destroy() 
            print("Deleted FakePart")
        end
        
        -- Disable collision on sign part
        local sign = map:FindFirstChild("sign")
        if sign then
            local part = sign:FindFirstChild("Part")
            if part then
                part.CanCollide = false
                part.Transparency = 0.5 -- Optional: make it see-through so you know it's ghost
                print("Disabled collision on sign.Part")
            end
        end
    else
        warn("Workspace.MAP not found!")
    end
end

local function anchorAll(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = true 
        end
    end
    if root:IsA("BasePart") then
        root.Anchored = true
        root.CanCollide = true
    end
end

-- Function to attach the suit model to the character
local function wearSuit(suitModel)
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    if not character then return end
    
    print("Applying Suit: " .. suitModel.Name)
    
    local suitClone = suitModel:Clone()
    suitClone.Name = "IronManSuit"
    
    -- Cleanup: Remove prompts and physics properties
    -- VITAL: Keep Anchored = true. We are manually moving them.
    for _, desc in ipairs(suitClone:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc.Anchored = true 
            desc.CanCollide = false 
            desc.Massless = true
        elseif desc:IsA("ProximityPrompt") then
            desc:Destroy()
        end
    end
    
    suitClone.Parent = character
    
    -- Rendering Loop for "Anchored" attachment
    local RunService = game:GetService("RunService")
    
    -- Function to bind a part to a limb
    local function bindPartToLimb(suitPart, limbName)
        local targetLimb = character:FindFirstChild(limbName)
        
        -- Fallback Mapping
        if not targetLimb then
            if limbName == "UpperTorso" or limbName == "LowerTorso" then targetLimb = character:FindFirstChild("Torso") end
            if limbName == "LeftHand" or limbName == "LeftLowerArm" or limbName == "LeftUpperArm" then targetLimb = character:FindFirstChild("Left Arm") end
            if limbName == "RightHand" or limbName == "RightLowerArm" or limbName == "RightUpperArm" then targetLimb = character:FindFirstChild("Right Arm") end
            if limbName == "LeftFoot" or limbName == "LeftLowerLeg" or limbName == "LeftUpperLeg" then targetLimb = character:FindFirstChild("Left Leg") end
            if limbName == "RightFoot" or limbName == "RightLowerLeg" or limbName == "RightUpperLeg" then targetLimb = character:FindFirstChild("Right Leg") end
        end
        
        -- Ultimate fallback: RootPart
        if not targetLimb then targetLimb = character:WaitForChild("HumanoidRootPart") end
        
        -- Start Loop
        if targetLimb and suitPart then
             print("Binding " .. suitPart.Name .. " -> " .. targetLimb.Name)
             local connection
             connection = RunService.RenderStepped:Connect(function()
                 if suitPart.Parent and targetLimb.Parent then
                     suitPart.CFrame = targetLimb.CFrame
                 else
                     connection:Disconnect() -- Stop if destroyed
                 end
             end)
        end
    end

    -- 1. Helmet
    local helmet = suitClone:FindFirstChild("Mk 85 helmet")
    if helmet then bindPartToLimb(helmet, "Head") end

    -- 2. Body Parts
    local bodyContainer = suitClone:FindFirstChild("Mark 85")
    if bodyContainer then
        for _, child in ipairs(bodyContainer:GetChildren()) do
            if child:IsA("BasePart") then
                bindPartToLimb(child, child.Name)
            end
        end
    else
        for _, child in ipairs(suitClone:GetChildren()) do
            if child:IsA("BasePart") and child.Name ~= "Mk 85 helmet" then
                 bindPartToLimb(child, child.Name)
            end
        end
    end
    
    print("Suit Equipped (Anchored & CFrame Locked)!")
end

local function setupInteraction(item)
    local promptPart = item:IsA("BasePart") and item or (item:IsA("Model") and item.PrimaryPart) or item:FindFirstChildWhichIsA("BasePart", true)
    if not promptPart then return end

    local prompt = Instance.new("ProximityPrompt")
    prompt.ObjectText = item.Name
    prompt.ActionText = "Equip"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 10
    prompt.RequiresLineOfSight = false
    prompt.Parent = promptPart
    
    prompt.Triggered:Connect(function(player)
        if player ~= game:GetService("Players").LocalPlayer then return end
        
        print("Interacting with: " .. item.Name)
        
        -- Strategy for Custom Items (Hamr, Shield which might be Models/Parts)
        local function equipCustomItem(sourceItem)
            local tool = Instance.new("Tool")
            tool.Name = sourceItem.Name
            tool.RequiresHandle = true
            
            local handle = sourceItem:Clone()
            
            -- Cleanup handle (remove prompts, etc)
            for _, p in ipairs(handle:GetDescendants()) do
                if p:IsA("ProximityPrompt") then p:Destroy() end
            end
            
            -- Prepare Handle based on type
            if handle:IsA("Model") then
                if handle.PrimaryPart then
                    local main = handle.PrimaryPart:Clone()
                    main.Name = "Handle"
                    main.Parent = tool
                    handle:Destroy() 
                    handle = main
                else
                    local part = handle:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        local main = part:Clone()
                        main.Name = "Handle"
                        main.Parent = tool
                        handle:Destroy() 
                        handle = main
                    end
                end
            elseif handle:IsA("BasePart") then
                handle.Name = "Handle"
                handle.Parent = tool
            end
            
            local finalHandle = tool:FindFirstChild("Handle")
            if not finalHandle then return warn("No handle created for " .. sourceItem.Name) end
            
            -- KEY PHYSICS FIX:
            -- 1. Anchor it so it doesn't fall in backpack or before equip
            finalHandle.Anchored = true 
            finalHandle.CanCollide = false
            finalHandle.Massless = true
            
            tool.Parent = player.Backpack
            
            -- 2. On Equip: Move to hand -> Weld -> Unanchor
            tool.Equipped:Connect(function()
                local char = player.Character
                local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
                
                if finalHandle and hand then
                    -- Move to hand
                    finalHandle.CFrame = hand.CFrame
                    
                    -- Weld
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = hand
                    weld.Part1 = finalHandle
                    weld.Parent = finalHandle
                    
                    -- Now Unanchor (Physics can simulate, but it's welded so it stays)
                    finalHandle.Anchored = false
                    print("Custom Tool Equipped & Welded: " .. tool.Name)
                end
            end)
            
            tool.Unequipped:Connect(function()
                -- Re-anchor on unequip so it doesn't fall through world if dropped (optional, usually it just goes to backpack)
                if finalHandle then finalHandle.Anchored = true end
            end)
            
            player.Character.Humanoid:EquipTool(tool)
        end
        
        -- Strategy for Existing Tools (Knives, etc)
        local function equipStandardTool(sourceTool)
            local toolClone = sourceTool:Clone()
            
            -- Remove prompt
            for _, p in ipairs(toolClone:GetDescendants()) do
                if p:IsA("ProximityPrompt") then p:Destroy() end
            end
            
            -- Ensure it's ready for physics
            -- Standard tools usually handle their own welding, so we just unanchor them
            for _, p in ipairs(toolClone:GetDescendants()) do
                if p:IsA("BasePart") then
                    p.Anchored = false
                    p.CanCollide = false 
                    p.Massless = true
                end
            end
            
            toolClone.Parent = player.Backpack
            player.Character.Humanoid:EquipTool(toolClone)
            print("Standard Tool Equipped: " .. toolClone.Name)
        end

        local lowerName = item.Name:lower()
        
        if item:IsA("Tool") then
            equipStandardTool(item)
            
        elseif lowerName:find("hamr") or lowerName:find("shield") then
            -- Force these to be custom tools because they are likely broken/missing scripts/just models
            equipCustomItem(item)
            
        elseif item.Name == "Mark85" or lowerName:find("suit") then
            wearSuit(item)
            
        elseif lowerName:find("cyan") then 
             -- Cyan might be a knife (Tool) or just a visual. 
             -- If it wasn't caught by IsA("Tool"), treat as custom.
             equipCustomItem(item)
        end
    end)
end

local function teleportToRoom()
    local player = game:GetService("Players").LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    
    -- Teleport to specific coordinates
    root.CFrame = CFrame.new(-241, 26, -423)
    print("Teleported to Hidden Room location")
end

local function spawnItems()
    -- Teleport first
    teleportToRoom()

    -- Apply map mods first
    modifyMap()

    local secretRoom = ReplicatedStorage:FindFirstChild("SecretKicksRoom")
    if not secretRoom then
        warn("SecretKicksRoom not found!")
        return
    end

    print("--- Restoring Items to Workspace (Anchored & Interactive) ---")

    for _, item in ipairs(secretRoom:GetChildren()) do
        local clone = item:Clone()
        clone.Parent = Workspace
        
        -- Anchor everything inside
        anchorAll(clone)
        
        -- Filter which items get interaction
        local name = item.Name:lower()
        if name:find("hamr") or 
           name:find("mark85") or name:find("suit") or 
           name:find("shield") or 
           name:find("cyan") then
            
            -- Add Interaction only to these specific items
            setupInteraction(clone)
            print("Restored & Interactive: " .. clone.Name)
        else
            print("Restored (No Interaction): " .. clone.Name)
        end
    end
    print("--- Restore Complete ---")
end
spawnItems()
