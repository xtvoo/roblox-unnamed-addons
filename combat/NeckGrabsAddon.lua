-- Neck Grabs Addon Reborn
-- Reworked for stability and API compatibility

-- [WARN] Safe API Retrieval
local api = api or (getgenv and getgenv().api) or (shared and shared.api) or (_G and _G.api)

if not api then
    warn("[NeckGrabs] API object not found in standard globals. Checking fallback...")
    pcall(function()
        api = (getgenv and getgenv().api) or (shared and shared.api) or (_G and _G.api)
    end)
end

if not api then
    warn("[NeckGrabs] CRITICAL ERROR: 'api' object is nil. The addon cannot load.")
    return
end

-- [INFO] Set Script Name
pcall(function() api:set_lua_name("NeckGrabsAddon") end)

-- [UI] Construction
local Tab = api:GetTab("Neck Grabs Reborn") or api:AddTab("Neck Grabs Reborn")
if not Tab then
    warn("[NeckGrabs] Failed to create or get tab!")
    api:notify("Failed to create UI Tab!", 3)
    return
end
print("[NeckGrabs] Tab created/found:", Tab)
local MainGroup = Tab:AddLeftGroupbox("Main")
local ToolsGroup = Tab:AddLeftGroupbox("Grab Tools")
local FunGroup = Tab:AddRightGroupbox("Fun & Swag")
local DismemberGroup = Tab:AddRightGroupbox("Dismember")

-- [SERVICES]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local OWNER = Players.LocalPlayer

-- [VARIABLES]
local NeckgrabFunctions = {
    ["GrabbedCharacter"] = nil,
    ["ClonedCharacter"] = nil,
    ["Interval"] = false,
    ["RopeGrab"] = nil,
    ["SexSine"] = 8,
    ["CowgirlSine"] = 8,
}
local ToolConnections = {}

-- [HELPER FUNCTIONS]
local function PlaySound(id)
    if OWNER.Character and OWNER.Character:FindFirstChild("Head") then
        local Sound = Instance.new("Sound", OWNER.Character.Head)
        Sound.SoundId = "rbxassetid://" .. id
        Sound.Volume = 1
        Sound:Play()
        game.Debris:AddItem(Sound, 5)
    end
end

local function PlayBoombox(id)
    if OWNER.Backpack:FindFirstChild("[Boombox]") then
        OWNER.Backpack["[Boombox]"].Parent = OWNER.Character
        ReplicatedStorage.MainEvent:FireServer("Boombox", id)
        OWNER.Character["[Boombox]"].Parent = OWNER.Backpack
        OWNER.PlayerGui.MainScreenGui.BoomboxFrame.Visible = false
    end
end

local function PlayPhone(id)
    ReplicatedStorage.MainEvent:FireServer("RingTone", id)
end

local function CleanUpTools()
    for name, conn in pairs(ToolConnections) do
        if conn then conn:Disconnect() end
    end
    ToolConnections = {}
    
    local toolNames = "Combo|Finisher|Judgement|Control|Sex|Cowgirl|Dick Sucker|Almighty Push|Void|Fling|Puppet Master|Minion|Custom Poser|[Grab]"
    
    if OWNER.Backpack then
        for _, tool in ipairs(OWNER.Backpack:GetChildren()) do
            if tool:IsA("Tool") and string.match(tool.Name, toolNames) then tool:Destroy() end
        end
    end
    if OWNER.Character then
        for _, tool in ipairs(OWNER.Character:GetChildren()) do
            if tool:IsA("Tool") and string.match(tool.Name, toolNames) then tool:Destroy() end
        end
    end
end

local function CreateTool(name, callback)
    -- Clean existing
    local old = OWNER.Backpack:FindFirstChild(name) or OWNER.Character:FindFirstChild(name)
    if old then old:Destroy() end
    
    local Tool = Instance.new("Tool")
    Tool.Name = name
    Tool.RequiresHandle = false
    Tool.Parent = OWNER.Backpack
    
    if ToolConnections[name] then ToolConnections[name]:Disconnect() end
    ToolConnections[name] = Tool.Activated:Connect(callback)
    
    -- Persist on respawn
    if not ToolConnections[name.."_Respawn"] then
        ToolConnections[name.."_Respawn"] = api:add_connection(OWNER.CharacterAdded:Connect(function(char)
            char:WaitForChild("Humanoid")
            task.wait(1)
            CreateTool(name, callback)
        end))
    end
end

local function DestroyTool(name)
    local t = OWNER.Backpack:FindFirstChild(name) or OWNER.Character:FindFirstChild(name)
    if t then t:Destroy() end
    if ToolConnections[name] then 
        ToolConnections[name]:Disconnect() 
        ToolConnections[name] = nil 
    end
    if ToolConnections[name.."_Respawn"] then
        ToolConnections[name.."_Respawn"]:Disconnect()
        ToolConnections[name.."_Respawn"] = nil
    end
end

-- [LOGIC FUNCTIONS]
local function Align(POWER, DAMPLING, TARGET_PART, OWNER_PART, POSITION, ROTATION)
    if not OWNER.Character or not OWNER.Character:FindFirstChild("BodyEffects") then return end
    
    local be = OWNER.Character.BodyEffects
    if not be:FindFirstChild("Grabbed") or not be.Grabbed.Value then return end

    local grabbedChar = NeckgrabFunctions["GrabbedCharacter"]
    if not grabbedChar or not grabbedChar.Parent then return end 
    
    local targetPart = grabbedChar:FindFirstChild(TARGET_PART)
    local ownerPart = OWNER.Character:FindFirstChild(OWNER_PART)
    
    if not targetPart or not ownerPart then return end
    
    -- Robustly get or create BP/BG
    local BP = targetPart:FindFirstChildWhichIsA("BodyPosition")
    if not BP then
        BP = Instance.new("BodyPosition", targetPart)
    end
    
    local BG = targetPart:FindFirstChildWhichIsA("BodyGyro")
    if not BG then
        BG = Instance.new("BodyGyro", targetPart)
    end
    
    -- Update properties EVERY FRAME to override game physics
    BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.P = 10000
    BG.CFrame = ownerPart.CFrame * ROTATION
    
    BP.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    BP.Position = ownerPart.CFrame * POSITION.Position
    BP.P = POWER
    BP.D = DAMPLING
end

local function DestroyAlign(PART)
    if NeckgrabFunctions["GrabbedCharacter"] and NeckgrabFunctions["GrabbedCharacter"]:FindFirstChild(PART) then
        local bp = NeckgrabFunctions["GrabbedCharacter"][PART]:FindFirstChildOfClass("BodyPosition")
        local bg = NeckgrabFunctions["GrabbedCharacter"][PART]:FindFirstChildOfClass("BodyGyro")
        if bp then bp:Destroy() end
        if bg then bg:Destroy() end
    end
end

local function ZeroVelocity(part)
    if part then
        part.Velocity = Vector3.zero
        part.AssemblyLinearVelocity = Vector3.zero
        part.AssemblyAngularVelocity = Vector3.zero
    end
end

local function AnimPlay(id, speed, time)
    local hum = OWNER.Character:FindFirstChild("Humanoid")
    if not hum then return end
    
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. id
    local track = hum:LoadAnimation(anim)
    track.Priority = Enum.AnimationPriority.Action4
    track:Play()
    if speed then track:AdjustSpeed(speed) end
    if time then track.TimePosition = time end
    -- Cleanup
    game.Debris:AddItem(anim, 2)
end

local function CloneCharacter(char)
    char.Archivable = true
    local clone = char:Clone()
    clone.Parent = workspace
    clone.Name = char.Name .. "_Clone"
    
    -- Clean up clone
    for _, v in pairs(clone:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Transparency = 1
            v.CanCollide = false
            v.Anchored = false
        elseif v:IsA("Decal") then
            v.Transparency = 1
        end
    end
    if clone:FindFirstChild("HumanoidRootPart") then
        clone.HumanoidRootPart.Transparency = 1
    end
    
    char.Archivable = false
    return clone
end

local function ControlAlign(P0, P1, Offset)
    if not P0 or not P1 then return end
    P0.AssemblyLinearVelocity = Vector3.zero
    P0.AssemblyAngularVelocity = Vector3.zero
    P0.CFrame = P1.CFrame * (Offset or CFrame.new())
    P0.CanCollide = false
    P1.CanCollide = false
end

local function CloneAnimPlay(id, speed, time)
    if not NeckgrabFunctions["ClonedCharacter"] then return end
    local hum = NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("Humanoid")
    if not hum then return end
    
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. id
    local track = hum:LoadAnimation(anim)
    track:Play()
    if speed then track:AdjustSpeed(speed) end
    if time then track.TimePosition = time end
    game.Debris:AddItem(anim, 2)
end

local function Grab()
    print("[NeckGrabs] Grab function called!")
    local be = OWNER.Character:FindFirstChild("BodyEffects")
    if not be or not be:FindFirstChild("Grabbed") then return end
    
    if be.Grabbed.Value then
        NeckgrabFunctions["GrabbedCharacter"] = be.Grabbed.Value
        print("[NeckGrabs] Target found: " .. tostring(NeckgrabFunctions["GrabbedCharacter"]))
        
        -- wait for constraint
        local GrabConstraint = NeckgrabFunctions["GrabbedCharacter"]:WaitForChild("GRABBING_CONSTRAINT", 2)
        if not GrabConstraint then 
             warn("[NeckGrabs] GRABBING_CONSTRAINT not found on target")
             return 
        end
        
        NeckgrabFunctions["RopeGrab"] = GrabConstraint:FindFirstChildOfClass("RopeConstraint")
        if NeckgrabFunctions["RopeGrab"] then
            NeckgrabFunctions["RopeGrab"].Length = math.huge
        end
        
        NeckgrabFunctions["Interval"] = false
        
        -- Wait for carry animation to start, then stop it
        local startTime = tick()
        print("[NeckGrabs] Waiting for carry animation...")
        repeat 
            task.wait()
            for _, Anim in pairs(OWNER.Character.Humanoid:GetPlayingAnimationTracks()) do
                -- User snippet uses :match so we use it too
                if Anim.Animation.AnimationId and Anim.Animation.AnimationId:match("rbxassetid://11075367458") then
                    Anim:Stop()
                    NeckgrabFunctions["Interval"] = true
                    print("[NeckGrabs] Carry animation stopped.")
                end
            end
            if tick() - startTime > 3 then 
                warn("[NeckGrabs] Timed out waiting for carry animation.")
                break 
            end 
        until NeckgrabFunctions["Interval"] == true
        
        -- Zero velocity
        for _, v in pairs(NeckgrabFunctions["GrabbedCharacter"]:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Velocity = Vector3.zero
                v.AssemblyLinearVelocity = Vector3.zero
                v.AssemblyAngularVelocity = Vector3.zero
                v.CanCollide = false
            end
        end
        
        NeckgrabFunctions["Interval"] = false
        
        -- Holding loop
        spawn(function()
            print("[NeckGrabs] Starting Holding loop.")
            repeat task.wait()
                Align(10000, 175, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 5, 5), CFrame.Angles(0, 0, 0))
            until be.Grabbed.Value == nil or NeckgrabFunctions["Interval"] == true
            print("[NeckGrabs] Holding loop ended.")
            DestroyAlign("UpperTorso")
        end)
    end
end


-- [FEATURES - MAIN]

MainGroup:AddToggle('NeckgrabToggle', {
    Text = 'Neckgrab Auto',
    Default = false,
    Tooltip = 'Automatically grabs players when you press E (No key required)',
    Callback = function(v)
        if v then
             local be = OWNER.Character:WaitForChild("BodyEffects", 10)
             if be and be:FindFirstChild("Grabbed") then
                ToolConnections["JointWatcher"] = api:add_connection(be.Grabbed:GetPropertyChangedSignal("Value"):Connect(function()
                    if not be.Grabbed.Value then return end
                    
                    -- Check if specific animation is playing (from user snippet)
                    local hum = OWNER.Character:FindFirstChild("Humanoid")
                    if hum then
                        for _, track in pairs(hum:GetPlayingAnimationTracks()) do
                            if track.Animation.AnimationId and track.Animation.AnimationId:match("rbxassetid://2838893290") then
                                return -- Don't neckgrab if this anim is playing
                            end
                        end
                    end
                    
                    Grab()
                end))
             end
        else
            if ToolConnections["JointWatcher"] then 
                ToolConnections["JointWatcher"]:Disconnect() 
                ToolConnections["JointWatcher"] = nil
            end
        end
    end
})

MainGroup:AddToggle('GrabToolToggle', {
    Text = 'Grab Tool (G)',
    Default = false,
    Callback = function(v)
        if v then
            CreateTool("[Grab]", function()
                -- Logic handled by keybind, mainly visual
            end)
            
            ToolConnections["GrabKey"] = api:add_connection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not gameProcessed and input.KeyCode == Enum.KeyCode.G then
                    -- Trigger grab on nearest knocked
                     local closest = nil
                     local minDist = 15
                     for _, p in pairs(Players:GetPlayers()) do
                         if p ~= OWNER and p.Character and p.Character:FindFirstChild("BodyEffects") then
                             local ko = p.Character.BodyEffects:FindFirstChild("K.O")
                             local grabbed = p.Character.BodyEffects:FindFirstChild("Grabbed")
                             if ko and ko.Value and grabbed and not grabbed.Value then
                                 local dist = (p.Character.HumanoidRootPart.Position - OWNER.Character.HumanoidRootPart.Position).Magnitude
                                 if dist < minDist then
                                     closest = p
                                     minDist = dist
                                 end
                             end
                         end
                     end
                     if closest then
                         ReplicatedStorage.MainEvent:FireServer("Grabbing", false)
                         task.wait(0.1) -- small delay
                         -- Teleport them to you logic handled by game usually, but we help
                         closest.Character.HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(0, 2, -2)
                     end
                end
            end))
        else
            DestroyTool("[Grab]")
            if ToolConnections["GrabKey"] then ToolConnections["GrabKey"]:Disconnect() end
        end
    end
})

-- [TOOLS]

ToolsGroup:AddToggle('ComboToggle', { Text = 'Combo', Default = false, Callback = function(v)
    if v then CreateTool("[Combo]", function()
        if not OWNER.Character.BodyEffects.Grabbed.Value then api:notify("No one grabbed!", 1) return end
        NeckgrabFunctions["Interval"] = true; task.wait(); NeckgrabFunctions["Interval"] = false
        
        spawn(function()
            repeat task.wait()
                Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 0, -10), CFrame.Angles(0, 0, 0))
            until NeckgrabFunctions["Interval"] or not OWNER.Character.BodyEffects.Grabbed.Value
        end)
        
        task.wait(0.6)
        NeckgrabFunctions["Interval"] = true -- Stop align
        task.wait(1)
        
        -- Flashstep combo effect
        for i=1, 40 do
            if not OWNER.Character or not OWNER.Character:FindFirstChild("HumanoidRootPart") then break end
            AnimPlay(2788292075, 1.4)
            PlayBoombox(558640653)
            OWNER.Character.HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -4)
            task.wait(0.03)
            OWNER.Character.HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 8)
            task.wait(0.03)
            OWNER.Character.HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -4)
            task.wait(0.03)
        end
        
        PlayPhone(186130717)
        ReplicatedStorage.MainEvent:FireServer("Grabbing") -- Release
        NeckgrabFunctions["Interval"] = false
    end) else DestroyTool("[Combo]") end
end})

ToolsGroup:AddToggle('FinisherToggle', { Text = 'Finisher', Default = false, Callback = function(v)
    if v then CreateTool("[Finisher]", function()
        if not OWNER.Character.BodyEffects.Grabbed.Value then api:notify("No one grabbed!", 1) return end
        NeckgrabFunctions["Interval"] = true; task.wait(); NeckgrabFunctions["Interval"] = false
        
        spawn(function()
            repeat task.wait() 
                Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 0, -10), CFrame.Angles(0, math.pi, 0))
            until NeckgrabFunctions["Interval"]
        end)
        
        task.wait(0.6)
        AnimPlay(2788292075, 1.4)
        PlayBoombox(558640653)
        
        -- Yeet
        local tween = TweenService:Create(OWNER.Character.HumanoidRootPart, TweenInfo.new(0.1), {CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -20)})
        tween:Play()
        tween.Completed:Wait()
        
        ReplicatedStorage.MainEvent:FireServer("Grabbing")
        NeckgrabFunctions["Interval"] = false 
    end) else DestroyTool("[Finisher]") end
end})

-- [COMBAT TOOLS]

ToolsGroup:AddToggle('JudgementToggle', { Text = 'Judgement', Default = false, Callback = function(v)
    if v then CreateTool("[Judgement]", function()
        if not OWNER.Character.BodyEffects.Grabbed.Value then api:notify("No one grabbed!", 1) return end
        
        local knife = OWNER.Backpack:FindFirstChild("[Knife]") or OWNER.Character:FindFirstChild("[Knife]")
        if not knife then api:notify("You need a [Knife]!", 2) return end

        NeckgrabFunctions["Interval"] = true; task.wait(); NeckgrabFunctions["Interval"] = false
        
        -- Position behind
        spawn(function()
            repeat task.wait() 
                Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 0, -10), CFrame.Angles(0, math.pi, 0))
            until NeckgrabFunctions["Interval"]
        end)
        
        task.wait(0.6)
        NeckgrabFunctions["Interval"] = true -- Pause alignment for animation
        
        -- Equip knife
        knife.Parent = OWNER.Character
        local originalGrip = knife.Grip
        
        -- Stab sequence
        AnimPlay(3096047107, 0.15) -- Raise knife
        knife.GripPos = Vector3.new(0, 0, 0)
        task.wait(0.5)
        
        AnimPlay(3096047107, 1.5) -- Stab
        PlayBoombox(6515725987)
        
        for i = 1, 15 do
            knife.GripPos = Vector3.new(0.5 * i, 0, 0)
            task.wait(0.05)
            knife.GripPos = Vector3.new(0.5 * i, 0, -0.5)
            task.wait(0.05)
        end
        
        knife.GripPos = Vector3.new(10, 0, -5) -- Dramatic pull out
        task.wait(0.3)
        
        NeckgrabFunctions["Interval"] = false -- Resume alignment for drop
        
        -- Drop body
        spawn(function()
            repeat task.wait()
                Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 50, -150), CFrame.Angles(math.pi/-2, math.pi, 0))
            until NeckgrabFunctions["Interval"]
        end)
        
        task.wait(0.5)
        
        -- Reset knife
        knife.Grip = originalGrip
        knife.Parent = OWNER.Backpack
        
        -- Finish
        ReplicatedStorage.MainEvent:FireServer("Grabbing")
        NeckgrabFunctions["Interval"] = true -- Stop align
        NeckgrabFunctions["Interval"] = false -- Reset state
        
    end) else DestroyTool("[Judgement]") end
end})

ToolsGroup:AddToggle('AlmightyPushToggle', { Text = 'Almighty Push', Default = false, Callback = function(v)
    if v then CreateTool("[Almighty Push]", function()
        if not OWNER.Character.BodyEffects.Grabbed.Value then api:notify("No one grabbed!", 1) return end
        NeckgrabFunctions["Interval"] = true; task.wait(); NeckgrabFunctions["Interval"] = false
        
        spawn(function()
            repeat task.wait()
                Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 0, -10), CFrame.Angles(0, math.pi*1, 0))
            until NeckgrabFunctions["Interval"]
        end)
        
        task.wait(0.6)
        AnimPlay(10714164866, 1.1) -- Push anim
        
        -- Float up
        local float = RunService.Heartbeat:Connect(function()
            OWNER.Character.HumanoidRootPart.Velocity = Vector3.new(0, 15, 0)
        end)
        task.wait(2)
        float:Disconnect()
        
        AnimPlay(10714164866, 0, 1.7) -- Hold pose
        PlayBoombox(6949501706) -- Charge sound
        task.wait(2.6)
        
        AnimPlay(10714164866, 0.5) -- Release
        PlayPhone(4798341571) -- Blast sound
        
        -- Blast away
        NeckgrabFunctions["Interval"] = true
        spawn(function()
             -- Simulate blast by moving far away fast
             repeat task.wait()
                 Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 50, -300), CFrame.Angles(math.rand(-3,3), math.rand(-3,3), math.rand(-3,3)))
             until NeckgrabFunctions["Interval"]
        end)
        NeckgrabFunctions["Interval"] = false
        
        task.wait(0.5)
        ReplicatedStorage.MainEvent:FireServer("Grabbing")
        NeckgrabFunctions["Interval"] = true
        NeckgrabFunctions["Interval"] = false
        
    end) else DestroyTool("[Almighty Push]") end
end})

-- [SWAG TOOLS]

FunGroup:AddToggle('ControlToggle', { Text = 'Control (Puppet)', Default = false, Callback = function(v)
    if v then CreateTool("[Control]", function()
        if not OWNER.Character.BodyEffects.Grabbed.Value then api:notify("No one grabbed!", 1) return end
        
        NeckgrabFunctions["Interval"] = true; task.wait(); NeckgrabFunctions["Interval"] = false
        
        -- Clone and setup
        NeckgrabFunctions["ClonedCharacter"] = CloneCharacter(NeckgrabFunctions["GrabbedCharacter"])
        workspace.CurrentCamera.CameraSubject = NeckgrabFunctions["ClonedCharacter"].Humanoid
        
        ToolConnections["ControlLoop"] = api:add_connection(RunService.Heartbeat:Connect(function()
             -- Stop owner anims so they don't interfere visually
             for _, v in pairs(OWNER.Character.Humanoid:GetPlayingAnimationTracks()) do v:Stop() end
             
             -- Hide owner under map
             OWNER.Character.HumanoidRootPart.CFrame = NeckgrabFunctions["ClonedCharacter"].HumanoidRootPart.CFrame * CFrame.new(0, -20, 0)
             ZeroVelocity(OWNER.Character.HumanoidRootPart)
             
             -- Bind grabbed char limbs to clone limbs
             local gc = NeckgrabFunctions["GrabbedCharacter"]
             local cc = NeckgrabFunctions["ClonedCharacter"]
             
             local limbs = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
             
             for _, limb in ipairs(limbs) do
                 ControlAlign(gc:FindFirstChild(limb), cc:FindFirstChild(limb))
             end
             
             -- Replicate animations from clone to itself (visual only really)
             -- Ideally we play animations on the clone based on movement
             if cc.Humanoid.MoveDirection.Magnitude > 0 then
                 -- Walking logic would go here, but default roblox anims might handle it on the clone
             end
             
             -- Sync Jump
             cc.Humanoid.Jump = OWNER.Character.Humanoid.Jump
             cc.Humanoid:Move(OWNER.Character.Humanoid.MoveDirection, false)
        end))
        
        -- Wait until released
        repeat task.wait() until OWNER.Character.BodyEffects.Grabbed.Value == nil or NeckgrabFunctions["Interval"]
        
        -- Cleanup
        if ToolConnections["ControlLoop"] then ToolConnections["ControlLoop"]:Disconnect() end
        
        OWNER.Character.HumanoidRootPart.CFrame = NeckgrabFunctions["ClonedCharacter"].HumanoidRootPart.CFrame
        ZeroVelocity(OWNER.Character.HumanoidRootPart)
        workspace.CurrentCamera.CameraSubject = OWNER.Character.Humanoid
        
        if NeckgrabFunctions["ClonedCharacter"] then NeckgrabFunctions["ClonedCharacter"]:Destroy() end
        DestroyAlign("UpperTorso") -- Cleanup aligns
        
    end) else DestroyTool("[Control]") end
end})

FunGroup:AddToggle('VoidToggle', { Text = 'Void', Default = false, Callback = function(v)
    if v then CreateTool("Void", function()
        if not OWNER.Character.BodyEffects.Grabbed.Value then api:notify("No one grabbed!", 1) return end
        NeckgrabFunctions["Interval"] = true; task.wait(); NeckgrabFunctions["Interval"] = false
        
        spawn(function()
             repeat task.wait()
                 Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, -500, 0), CFrame.Angles(0, 0, 0))
             until NeckgrabFunctions["Interval"]
        end)
        
        AnimPlay(2788292075, 1.4)
        task.wait(1)
        ReplicatedStorage.MainEvent:FireServer("Grabbing")
        NeckgrabFunctions["Interval"] = false
    end) else DestroyTool("Void") end
end})

FunGroup:AddToggle('FlingToggle', { Text = 'Fling', Default = false, Callback = function(v)
    if v then CreateTool("Fling", function()
        if not OWNER.Character.BodyEffects.Grabbed.Value then api:notify("No one grabbed!", 1) return end
        NeckgrabFunctions["Interval"] = true; task.wait(); NeckgrabFunctions["Interval"] = false
        
        spawn(function()
            for i = 1, 20 do
                if NeckgrabFunctions["Interval"] then break end
                Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 3, -8), CFrame.Angles(0, math.rad(i * 18), 0))
                task.wait(0.05)
            end
        end)
        
        task.wait(1)
        AnimPlay(2788292075, 1.4)
        
        -- Super spin fling
        NeckgrabFunctions["Interval"] = false
        spawn(function()
            repeat task.wait()
                Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 200, -300), CFrame.Angles(math.pi * 2, math.pi, 0))
            until NeckgrabFunctions["Interval"]
        end)
        task.wait(0.5)
        ReplicatedStorage.MainEvent:FireServer("Grabbing")
        NeckgrabFunctions["Interval"] = true
    end) else DestroyTool("Fling") end
end})

-- [DISMEMBERMENT]

local function DismemberPart(partName)
    if OWNER.Character.BodyEffects.Grabbed.Value then
        local victim = Players:GetPlayerFromCharacter(OWNER.Character.BodyEffects.Grabbed.Value)
        if victim and victim.Character and victim.Character:FindFirstChild(partName) then
            -- Create a "fake" disconnect by moving it to the void
            -- We use CFrame instead of Destroy because Destroy replicates poorly or breaks the character completely
            victim.Character[partName].CFrame = CFrame.new(0, -9000, 0)
        end
    end
end

DismemberGroup:AddButton('Remove Head', function() DismemberPart("Head") end)

DismemberGroup:AddLabel('Arms')
DismemberGroup:AddButton('Left Upper', function() DismemberPart("LeftUpperArm") end)
DismemberGroup:AddButton('Left Lower', function() DismemberPart("LeftLowerArm") end)
DismemberGroup:AddButton('Left Hand', function() DismemberPart("LeftHand") end)
DismemberGroup:AddButton('Right Upper', function() DismemberPart("RightUpperArm") end)
DismemberGroup:AddButton('Right Lower', function() DismemberPart("RightLowerArm") end)
DismemberGroup:AddButton('Right Hand', function() DismemberPart("RightHand") end)

DismemberGroup:AddLabel('Legs')
DismemberGroup:AddButton('Left Upper', function() DismemberPart("LeftUpperLeg") end)
DismemberGroup:AddButton('Left Lower', function() DismemberPart("LeftLowerLeg") end)
DismemberGroup:AddButton('Left Foot', function() DismemberPart("LeftFoot") end)
DismemberGroup:AddButton('Right Upper', function() DismemberPart("RightUpperLeg") end)
DismemberGroup:AddButton('Right Lower', function() DismemberPart("RightLowerLeg") end)
DismemberGroup:AddButton('Right Foot', function() DismemberPart("RightFoot") end)

DismemberGroup:AddLabel('Body')
DismemberGroup:AddButton('Upper Torso', function() DismemberPart("UpperTorso") end)
DismemberGroup:AddButton('Lower Torso', function() DismemberPart("LowerTorso") end)


-- [UNLOAD]
api:add_connection(game.Players.LocalPlayer.CharacterAdded:Connect(function()
    CleanUpTools()
end))

api:on_event("unload", function()
    CleanUpTools()
    api:notify("Neck Grabs Unloaded", 2)
end)

api:notify("Neck Grabs Reborn Loaded!", 3)
