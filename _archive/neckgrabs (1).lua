local function find_api()
    local success, result
    
    -- Try global 'api'
    success, result = pcall(function() return api end)
    if success and type(result) == "table" then return result end
    
    -- Try getgenv().api
    success, result = pcall(function() return getgenv().api end)
    if success and type(result) == "table" then return result end
    
    -- Try _G.api
    success, result = pcall(function() return _G.api end)
    if success and type(result) == "table" then return result end
    
    -- Try shared.api
    success, result = pcall(function() return shared.api end)
    if success and type(result) == "table" then return result end
    
    return nil
end
local api = find_api()

if not api then
    warn("Antigravity: 'api' table not found! Script cannot run.")
    return 
end


-- Create Script tab
local tabs = {
    script = api:AddTab("Script");
}

-- Create groupboxes
local Group = {
    Neckgrab = tabs.script:AddLeftGroupbox("Neckgrab"),
    Neckgrabs = tabs.script:AddLeftGroupbox("Dismember"),

}

-- Services
local Player = game:GetService("Players")
local OWNER = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MainEvent = ReplicatedStorage.MainEvent

-- Neckgrab Variables
local NeckgrabFunctions = {
    ["GrabbedCharacter"] = nil,
    ["ClonedCharacter"] = nil,
    ["Interval"] = false,
    ["RopeGrab"] = nil,
    ["SexSine"] = 8,
    ["CowgirlSine"] = 8,
    ["ControlFakeAttack"] = {2788309317, 2788309982, 2788311138, 2788308661}
}

local toolConnections = {}

-- Tool Management Functions
local function cleanUpTools()
    for name, connection in pairs(toolConnections) do
        connection:Disconnect()
        toolConnections[name] = nil
    end
    for _, tool in ipairs(OWNER.Backpack:GetChildren()) do
        if tool:IsA("Tool") and string.match(tool.Name, "Combo|Finisher|Judgement|Control|Sex|Cowgirl|Dick Sucker|Almighty Push|Void|Fling|Spin|Ragdoll|Slam|Orbit") then
            tool:Destroy()
        end
    end
    for _, tool in ipairs(OWNER.Character:GetChildren()) do
        if tool:IsA("Tool") and string.match(tool.Name, "Combo|Finisher|Judgement|Control|Sex|Cowgirl|Dick Sucker|Almighty Push|Void|Fling|Spin|Ragdoll|Slam|Orbit") then
            tool:Destroy()
        end
    end
end

function CreateTools(name, callback)
    local OldTool = OWNER.Backpack:FindFirstChild(name) or OWNER.Character:FindFirstChild(name)
    if OldTool then OldTool:Destroy() end
    
    if toolConnections[name] then
        toolConnections[name]:Disconnect()
        toolConnections[name] = nil
    end
    
    local Tool = Instance.new("Tool")
    Tool.Name = name
    Tool.RequiresHandle = false
    Tool.Parent = OWNER.Backpack
    
    toolConnections[name] = Tool.Activated:Connect(callback)
    
    if not toolConnections[name.."Added"] then
        toolConnections[name.."Added"] = api:add_connection(OWNER.CharacterAdded:Connect(function(character)
            character:WaitForChild("Humanoid")
            cleanUpTools()
            task.wait(1) 
            local newTool = Instance.new("Tool")
            newTool.Name = name
            newTool.RequiresHandle = false
            newTool.Parent = OWNER.Backpack
            toolConnections[name] = newTool.Activated:Connect(callback)
        end))
    end
    
    return Tool
end

function DestroyTools(name)
    local Tool = OWNER.Backpack:FindFirstChild(name) or OWNER.Character:FindFirstChild(name)
    if Tool then 
        Tool:Destroy()
    end
    
    if toolConnections[name] then
        toolConnections[name]:Disconnect()
        toolConnections[name] = nil
    end
    
    if toolConnections[name.."Added"] then
        toolConnections[name.."Added"]:Disconnect()
        toolConnections[name.."Added"] = nil
    end
end

api:add_connection(OWNER.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid")
    cleanUpTools()
end))

-- Helper Functions
function CloneCharacter(OldCharacter)
    OldCharacter.Archivable = true
    if OldCharacter:FindFirstChild("LeftLowerArmFake") then
        OldCharacter:FindFirstChild("LeftLowerArmFake"):Destroy()
        OldCharacter:FindFirstChild("RightLowerArmFake"):Destroy()
        OldCharacter:FindFirstChild("LeftLowerLegFake"):Destroy()
        OldCharacter:FindFirstChild("RightLowerLegFake"):Destroy()
    end    
    local newClone = OldCharacter:Clone()
    newClone.HumanoidRootPart.Anchored = false
    newClone.Humanoid.MaxHealth = 9e9
    newClone.Humanoid.Health = 9e9
    newClone.RagdollConstraints:Destroy()
    newClone.BodyEffects:Destroy()
    if OldCharacter ~= OWNER.Character then
        newClone:WaitForChild("GRABBING_CONSTRAINT"):Destroy()
    end
    for _, Class in pairs(newClone:GetDescendants()) do
        if Class:IsA("BasePart") and
        Class.Name ~= "Head" and
        Class.Name ~= "HumanoidRootPart" and
        Class.Name ~= "UpperTorso" and
        Class.Name ~= "LowerTorso" and
        Class.Name ~= "LeftUpperArm" and
        Class.Name ~= "RightUpperArm" and
        Class.Name ~= "LeftLowerArm" and
        Class.Name ~= "RightLowerArm" and
        Class.Name ~= "LeftHand" and
        Class.Name ~= "RightHand" and
        Class.Name ~= "LeftUpperLeg" and
        Class.Name ~= "RightUpperLeg" and
        Class.Name ~= "LeftLowerLeg" and
        Class.Name ~= "RightLowerLeg" and
        Class.Name ~= "LeftFoot" and
        Class.Name ~= "RightFoot" then
            Class.Massless = false
            Class:Destroy()
        end

        if Class:IsA("BasePart") or Class:IsA("MeshPart") or Class:IsA("Part") then
            Class.Transparency = 1
            Class.CustomPhysicalProperties = PhysicalProperties.new(100, 2, .5, 100, 1)
            Class.CanCollide = false
            if Class:FindFirstChildWhichIsA("BodyGyro") and Class:FindFirstChildWhichIsA("BodyPosition") then
                Class:Destroy()
            end
        end
        
        if Class:IsA("Decal") then
            Class.Transparency = 1
        end

        if Class:IsA("Beam") or Class:IsA("Highlight") or Class:IsA("ForceField") or Class:IsA("Motor6D") then
            Class:Destroy()
        end
    end
    newClone.HumanoidRootPart.Transparency = 1
    newClone.Parent = OWNER.Character
    newClone.Humanoid:ChangeState("GettingUp")
    newClone.HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame
    OldCharacter.Archivable = false
    return newClone
end

function Align(POWER, DAMPLING, TARGET_PART, OWNER_PART, POSITION, ROTATION)
    if OWNER.Character.BodyEffects.Grabbed.Value ~= nil then
        if not NeckgrabFunctions["GrabbedCharacter"][TARGET_PART]:FindFirstChildWhichIsA("BodyPosition") and not NeckgrabFunctions["GrabbedCharacter"][TARGET_PART]:FindFirstChildWhichIsA("BodyGyro") then
            local BP = Instance.new("BodyPosition", NeckgrabFunctions["GrabbedCharacter"][TARGET_PART])
            BP.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            local bg = Instance.new("BodyGyro", NeckgrabFunctions["GrabbedCharacter"][TARGET_PART])
            bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.P = 10000
        end
        NeckgrabFunctions["GrabbedCharacter"][TARGET_PART].BodyGyro.CFrame = OWNER.Character[OWNER_PART].CFrame * ROTATION
        NeckgrabFunctions["GrabbedCharacter"][TARGET_PART].BodyPosition.Position = OWNER.Character[OWNER_PART].CFrame * POSITION.Position
        NeckgrabFunctions["GrabbedCharacter"][TARGET_PART].BodyPosition.P = POWER
        NeckgrabFunctions["GrabbedCharacter"][TARGET_PART].BodyPosition.D = DAMPLING
    end
end

function Destroy(PART)
    if NeckgrabFunctions["GrabbedCharacter"][PART]:FindFirstChildOfClass("BodyGyro") or NeckgrabFunctions["GrabbedCharacter"][PART]:FindFirstChildOfClass("BodyPosition") then
        NeckgrabFunctions["GrabbedCharacter"][PART]:FindFirstChildOfClass("BodyGyro"):Destroy()
        NeckgrabFunctions["GrabbedCharacter"][PART]:FindFirstChildOfClass("BodyPosition"):Destroy()
    end
end

function Holding()
    repeat task.wait()
        Align(10000, 175, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 5, 5), CFrame.Angles(0, 0, 0))
    until OWNER.Character.BodyEffects.Grabbed.Value == nil or NeckgrabFunctions["Interval"] == true
end

function Grab()
    if OWNER.Character.BodyEffects.Grabbed.Value then
        NeckgrabFunctions["GrabbedCharacter"] = OWNER.Character.BodyEffects.Grabbed.Value
        local GrabConstraint = NeckgrabFunctions["GrabbedCharacter"]:WaitForChild("GRABBING_CONSTRAINT")
        if not GrabConstraint then return end
        
        NeckgrabFunctions["RopeGrab"] = GrabConstraint:FindFirstChildOfClass("RopeConstraint")
        NeckgrabFunctions["RopeGrab"].Length = 1/0
        NeckgrabFunctions["Interval"] = false
        repeat task.wait()
            for _, Anim in pairs(OWNER.Character.Humanoid:GetPlayingAnimationTracks()) do
                if (Anim.Animation.AnimationId:match("rbxassetid://11075367458")) then
                    NeckgrabFunctions["Interval"] = true
                    Anim:Stop()
                end
            end
        until NeckgrabFunctions["Interval"] == true
        for _, Class in pairs(NeckgrabFunctions["GrabbedCharacter"]:GetDescendants()) do
            if Class:IsA("BasePart") then
                Class.Velocity = Vector3.zero
                Class.AssemblyAngularVelocity = Vector3.zero
                Class.AssemblyLinearVelocity = Vector3.zero
                Class.CanCollide = false
            end
        end
        NeckgrabFunctions["Interval"] = false
        Holding()
        Destroy("UpperTorso")
    end
end

function ControlAlign(P0, P1, Offset)
    P0.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    P0.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    P0.Velocity = Vector3.new(0, 0, 0)
    P0.CFrame = P1.CFrame * (Offset or CFrame.new())
    P0.CanCollide = false
    P1.CanCollide = false
end

function ZeroVelocity___(PATH)
    PATH.Velocity = Vector3.zero
    PATH.AssemblyAngularVelocity = Vector3.zero
    PATH.AssemblyLinearVelocity = Vector3.zero
end

function Play(ID)
    if OWNER.Backpack:FindFirstChild("[Boombox]") then
        OWNER.Backpack["[Boombox]"].Parent = OWNER.Character
        ReplicatedStorage.MainEvent:FireServer("Boombox", ID)
        OWNER.Character["[Boombox]"].Parent = OWNER.Backpack
        OWNER.PlayerGui.MainScreenGui.BoomboxFrame.Visible = false
        OWNER.Character.LowerTorso:WaitForChild("BOOMBOXSOUND")
    end
end

function Play_(ID)
    ReplicatedStorage.MainEvent:FireServer("RingTone", ID)
    local Tool = nil
    if OWNER.Character:FindFirstChildWhichIsA("Tool") then
        Tool = OWNER.Character:FindFirstChildWhichIsA("Tool")
        OWNER.Character:FindFirstChildWhichIsA("Tool").Parent = OWNER.Backpack
    end
    OWNER.Backpack["[Phone]"].Parent = OWNER.Character
    OWNER.Character["[Phone]"].Parent = OWNER.Backpack
    if Tool then
        Tool.Parent = OWNER.Character
    end
end

function AnimPlay(ID, SPEED, Time, Smoothing)
    for i, v in pairs(OWNER.Character:WaitForChild("Humanoid"):GetPlayingAnimationTracks()) do 
        if (v.Animation.AnimationId:match("rbxassetid://"..ID)) then v:Stop() end 
    end
    local animation = Instance.new('Animation', workspace)
    animation.AnimationId = 'rbxassetid://'..ID
    local playing = OWNER.Character:WaitForChild("Humanoid"):LoadAnimation(animation)
    playing.Priority = Enum.AnimationPriority.Action4
    if tonumber(Smoothing) then
        playing:Play(Smoothing) 
    else
        playing:Play() 
    end
    if tonumber(SPEED) then
        playing:AdjustSpeed(SPEED)
    else
        playing:AdjustSpeed(1)
    end
    if tonumber(Time) then
        playing.TimePosition = Time
    end
    animation:Destroy()
end

function AnimStop(ID, SPEED)
    for i, v in pairs(OWNER.Character:WaitForChild("Humanoid"):GetPlayingAnimationTracks()) do
        if (v.Animation.AnimationId:match("rbxassetid://"..ID)) then
            if tonumber(SPEED) then
                v:Stop(SPEED)
            else
                v:Stop()
            end
        end 
    end
end

function CloneAnimStop(ID, SPEED)
    for i, v in pairs(NeckgrabFunctions["ClonedCharacter"].Humanoid:GetPlayingAnimationTracks()) do
        if (v.Animation.AnimationId:match("rbxassetid://"..ID)) then
            if tonumber(SPEED) then
                v:Stop(SPEED)
            else
                v:Stop()
            end
        end 
    end
end

function CloneAnimPlay(ID, SPEED, Time)
    for i, v in pairs(NeckgrabFunctions["ClonedCharacter"].Humanoid:GetPlayingAnimationTracks()) do 
        if (v.Animation.AnimationId:match("rbxassetid://"..ID)) then v:Stop() end 
    end
    local animation = Instance.new('Animation', workspace)
    animation.AnimationId = 'rbxassetid://'..ID
    local playing = NeckgrabFunctions["ClonedCharacter"].Humanoid:LoadAnimation(animation)
    playing:Play() 
    if tonumber(SPEED) then
        playing:AdjustSpeed(SPEED)
    else
        playing:AdjustSpeed(1)
    end
    if tonumber(Time) then
        playing.TimePosition = Time
    end
    animation:Destroy()
end

function CloneAnimPlayWStop(ID)
    for i, v in pairs(OWNER.Character.Humanoid:GetPlayingAnimationTracks()) do
        if (v.Animation.AnimationId:match("rbxassetid://"..ID)) then
            v:Stop()
            if not NeckgrabFunctions["ClonedCharacter"]:FindFirstChild(ID) then
                local animation = Instance.new('Animation', NeckgrabFunctions["ClonedCharacter"])
                animation.AnimationId = 'rbxassetid://'..ID
                animation.Name = "x"
                playing = NeckgrabFunctions["ClonedCharacter"].Humanoid:LoadAnimation(animation)
                playing.Priority = Enum.AnimationPriority.Action4
                playing:Play()
            end
        end
    end
    if OWNER.Character.Humanoid.MoveDirection.magnitude > 0 then
        CloneAnimStop(ID)
        for _, v in pairs(NeckgrabFunctions["ClonedCharacter"]:GetChildren()) do
            if v.Name == "x" then
                v:Destroy()
            end
        end
    end    
end

-- Neckgrab Toggle
Group.Neckgrab:AddToggle('NeckgrabToggle', {
    Text = 'Neckgrab',
    Default = false,
    Tooltip = 'Automatically grabs players',
    Callback = function(v)
        if v then
            api:add_connection(OWNER.Character.BodyEffects.Grabbed:GetPropertyChangedSignal("Value"):Connect(function()
                for i, v in pairs(OWNER.Character:WaitForChild("Humanoid"):GetPlayingAnimationTracks()) do
                    if v.Animation.AnimationId:match("rbxassetid://2838893290") then
                        return
                    end
                end
                Grab()
            end))
        end
    end
})

-- Combo Tool
Group.Neckgrab:AddToggle('ComboToggle', {
    Text = 'Combo',
    Default = false,
    Callback = function(v)
        if v then
            CreateTools("Combo", function()
                if OWNER.Character.BodyEffects.Grabbed.Value == nil then 
                    api:notify("No Grabbed Found", 1) 
                    return 
                end
                NeckgrabFunctions["Interval"] = true
                task.wait()
                NeckgrabFunctions["Interval"] = false
                spawn(function()
                    repeat task.wait()
                        Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 0, -10), CFrame.Angles(0, 0, 0))
                    until NeckgrabFunctions["Interval"] == true
                end)
                task.wait(.6)
                NeckgrabFunctions["Interval"] = true
                task.wait(1)
                OWNER.Character.HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -10)
                task.wait(.2)
                for i = 1, 40 do
                    AnimPlay(2788292075, 1.4)
                    Play(558640653)
                    OWNER.Character.HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -4)
                    task.wait(0.03)
                    OWNER.Character.HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 8)
                    task.wait(0.03)
                    OWNER.Character.HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -4)
                    task.wait(0.03)
                    OWNER.Character.HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(-4, 0, 0)
                    task.wait(0.03)
                    OWNER.Character.HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(8, 0, 0)
                    task.wait(0.03)
                    OWNER.Character.HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(-4, 0, 0)
                end
                Play_(186130717)
                NeckgrabFunctions["Interval"] = false
                spawn(function()
                    repeat task.wait()
                        Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 30, -150), CFrame.Angles(0, 0, 0))
                    until NeckgrabFunctions["Interval"] == true
                end)
                task.wait(.1)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.RightUpperArm.CFrame = CFrame.new(0, -1200, 0)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.LeftUpperArm.CFrame = CFrame.new(0, -1200, 0)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.RightUpperLeg.CFrame = CFrame.new(0, -1200, 0)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.LeftUpperLeg.CFrame = CFrame.new(0, -1200, 0)
                task.wait(.3)
                ReplicatedStorage.MainEvent:FireServer("Grabbing")
                Destroy("UpperTorso")
            end)
        else
            DestroyTools("Combo")
        end
    end
})

-- Finisher
Group.Neckgrab:AddToggle('FinisherToggle', {
    Text = 'Finisher',
    Default = false,
    Callback = function(v)
        if v then
            CreateTools("Finisher", function()
                if OWNER.Character.BodyEffects.Grabbed.Value == nil then 
                    api:notify("No Grabbed Found", 1) 
                    return 
                end
                NeckgrabFunctions["Interval"] = true
                task.wait()
                NeckgrabFunctions["Interval"] = false
                spawn(function()
                    repeat task.wait()
                        Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 0, -10), CFrame.Angles(0, math.pi, 0))
                    until NeckgrabFunctions["Interval"] == true
                end)
                task.wait(.6)
                AnimPlay(2788292075, 1.4)
                task.wait(.2)
                Play_(186130717)
                task.wait(.2)
                Play(558640653)
                local gyat = TweenService:Create(OWNER.Character.HumanoidRootPart, TweenInfo.new(0.1), {CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -20)})
                gyat:Play()
                gyat.Completed:Wait()
                NeckgrabFunctions["Interval"] = false
                spawn(function()
                    repeat task.wait()
                        Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 100, -270), CFrame.Angles(math.pi * -.2, math.pi, 0))
                    until NeckgrabFunctions["Interval"] == true
                end)
                task.wait(.2)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.RightUpperArm.CFrame = CFrame.new(0, -1200, 0)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.LeftUpperArm.CFrame = CFrame.new(0, -1200, 0)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.RightUpperLeg.CFrame = CFrame.new(0, -1200, 0)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.LeftUpperLeg.CFrame = CFrame.new(0, -1200, 0)
                task.wait(.3)
                ReplicatedStorage.MainEvent:FireServer("Grabbing")
                Destroy("UpperTorso")
            end)
        else
            DestroyTools("Finisher")
        end
    end
})

-- Judgement
Group.Neckgrab:AddToggle('JudgementToggle', {
    Text = 'Judgement',
    Default = false,
    Callback = function(v)
        if v then
            CreateTools("Judgement", function()
                if OWNER.Character.BodyEffects.Grabbed.Value == nil then 
                    api:notify("No Grabbed Found", 1)
                    return
                end
                
                local knife = OWNER.Backpack:FindFirstChild("[Knife]") or OWNER.Character:FindFirstChild("[Knife]")
                if not knife then
                    api:notify("You need a knife!", 1)
                    return
                end
                
                local originalGripPos = knife.GripPos
                local originalGripRight = knife.GripRight
                
                NeckgrabFunctions["Interval"] = true
                task.wait()
                NeckgrabFunctions["Interval"] = false
                
                spawn(function()
                    repeat task.wait()
                        Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 0, -10), CFrame.Angles(0, math.pi, 0))
                    until NeckgrabFunctions["Interval"] == true
                end)
                task.wait(0.6)
                
                NeckgrabFunctions["Interval"] = true
                knife.Parent = OWNER.Character
                
                AnimPlay(3096047107, 0.15)
                knife.GripPos = Vector3.new(0, 0, 0)
                knife.GripRight = Vector3.new(0, 0, -1)
                task.wait(0.5)
                
                AnimPlay(3096047107, 1.5)
                Play(6515725987) 
                
                for i = 1, 15 do
                    knife.GripPos = Vector3.new(0.5 * i, 0, 0)
                    task.wait(0.05)
                    knife.GripPos = Vector3.new(0.5 * i, 0, -0.5)
                    task.wait(0.05)
                end
                
                knife.GripPos = Vector3.new(10, 0, -5)
                task.wait(0.3)
                
                NeckgrabFunctions["Interval"] = false
                spawn(function()
                    repeat task.wait()
                        Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 50, -150), CFrame.Angles(math.pi/-2, math.pi, 0))
                    until NeckgrabFunctions["Interval"] == true
                end)
                
                task.wait(0.5)
                knife.GripPos = originalGripPos
                knife.GripRight = originalGripRight
                knife.Parent = OWNER.Backpack
                
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.UpperTorso.CFrame = CFrame.new(0, -1200, 0)
                task.wait(0.3)
                ReplicatedStorage.MainEvent:FireServer("Grabbing")
                Destroy("UpperTorso")
            end)
        else
            DestroyTools("Judgement")
        end
    end
})

-- Almighty Push
Group.Neckgrab:AddToggle('AlmightyPushToggle', {
    Text = 'Almighty Push',
    Default = false,
    Callback = function(v)
        if v then
            CreateTools("Almighty Push", function()
                if OWNER.Character.BodyEffects.Grabbed.Value == nil then 
                    api:notify("No Grabbed Found", 1) 
                    return 
                end
                NeckgrabFunctions["Interval"] = true
                task.wait()
                NeckgrabFunctions["Interval"] = false
                spawn(function()
                    repeat task.wait()
                        Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 0, -10), CFrame.Angles(0, math.pi, 0))
                    until NeckgrabFunctions["Interval"] == true
                end)
                task.wait(.6)
                AnimPlay(10714164866, 1.1)
                local Hut = api:add_connection(RunService.Heartbeat:Connect(function()
                    OWNER.Character.HumanoidRootPart.Velocity = Vector3.new(0, 15, 0)
                end))
                task.wait(2)
                Hut:Disconnect()
                AnimPlay(10714164866, 0, 1.7)
                Play_(6949501706)
                task.wait(2.6)
                AnimStop(10714164866, .5)
                Play_(4798341571)
                spawn(function()
                    repeat task.wait()
                        Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 0, -200), CFrame.Angles(math.pi * -.2, math.pi, 0))
                    until NeckgrabFunctions["Interval"] == true
                end)
                NeckgrabFunctions["Interval"] = false
                task.wait(.2)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.RightUpperArm.CFrame = CFrame.new(0, -1200, 0)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.LeftUpperArm.CFrame = CFrame.new(0, -1200, 0)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.RightUpperLeg.CFrame = CFrame.new(0, -1200, 0)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.LeftUpperLeg.CFrame = CFrame.new(0, -1200, 0)
                task.wait(.3)
                ReplicatedStorage.MainEvent:FireServer("Grabbing")
                Destroy("UpperTorso")
            end)
        else
            DestroyTools("Almighty Push")
        end
    end
})


Group.Neckgrab:AddToggle('ControlToggle', {
    Text = 'Control',
    Default = false,
    Callback = function(v)
        if v then
            CreateTools("Control", function()
                if OWNER.Character.BodyEffects.Grabbed.Value == nil then 
                    api:notify("No Grabbed Found", 1) 
                    return 
                end
                NeckgrabFunctions["Interval"] = true
                task.wait()
                NeckgrabFunctions["Interval"] = false
                NeckgrabFunctions["ClonedCharacter"] = CloneCharacter(NeckgrabFunctions["GrabbedCharacter"])
                workspace.CurrentCamera.CameraSubject = NeckgrabFunctions["ClonedCharacter"]
                
                local ControlLoop = api:add_connection(RunService.Heartbeat:Connect(function()
                    for i, v in pairs(OWNER.Character:FindFirstChild("Humanoid"):GetPlayingAnimationTracks()) do v:Stop() end
                    OWNER.Character.HumanoidRootPart.CFrame = NeckgrabFunctions["ClonedCharacter"].HumanoidRootPart.CFrame * CFrame.new(0, -20, 0) * CFrame.Angles(math.pi * 0.5, 0, 0)
                    ZeroVelocity___(OWNER.Character.HumanoidRootPart)
                    
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].Head, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("Head"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].HumanoidRootPart, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("HumanoidRootPart"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].UpperTorso, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("UpperTorso"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LowerTorso, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LowerTorso"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftUpperArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftUpperArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftLowerArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftLowerArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightUpperArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightUpperArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightLowerArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightLowerArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftHand, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftHand"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightHand, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightHand"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftUpperLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftUpperLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftLowerLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftLowerLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightUpperLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightUpperLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightLowerLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightLowerLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftFoot, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftFoot"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightFoot, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightFoot"), CFrame.new(0, 0, 0))
                    
                    CloneAnimPlayWStop(3152375249)
                    CloneAnimPlayWStop(3152378852)
                    CloneAnimPlayWStop(3189773368)
                    CloneAnimPlayWStop(3189776546)
                    CloneAnimPlayWStop(3189777795)
                    CloneAnimPlayWStop(3189779152)
                    CloneAnimPlayWStop(3487719500)
                    CloneAnimPlayWStop(11710529975)
                    CloneAnimPlayWStop(11710524717)
                    CloneAnimPlayWStop(11710527244)
                    CloneAnimPlayWStop(11710529220)
                    CloneAnimPlayWStop(11710524200)
                    CloneAnimPlayWStop(11710541744)
                    
                    for i, v in pairs(NeckgrabFunctions["ClonedCharacter"].Humanoid:GetPlayingAnimationTracks()) do
                        if (v.Animation.AnimationId:match("rbxassetid://3152394906")) then
                            if NeckgrabFunctions["ClonedCharacter"].Humanoid.MoveDirection.magnitude > 0 then
                                v:AdjustSpeed(1)
                            else
                                v:AdjustSpeed(0)
                            end
                        end
                    end
                    
                    NeckgrabFunctions["ClonedCharacter"].Humanoid.Jump = OWNER.Character.Humanoid.Jump
                    NeckgrabFunctions["ClonedCharacter"].Humanoid:Move(OWNER.Character.Humanoid.MoveDirection, false)
                end))
                
                repeat task.wait() until OWNER.Character.BodyEffects.Grabbed.Value == nil or NeckgrabFunctions["Interval"] == true
                
                OWNER.Character.HumanoidRootPart.CFrame = NeckgrabFunctions["ClonedCharacter"].HumanoidRootPart.CFrame
                ZeroVelocity___(OWNER.Character.HumanoidRootPart)
                workspace.CurrentCamera.CameraSubject = OWNER.Character.Humanoid
                NeckgrabFunctions["ClonedCharacter"]:Destroy()
                
                for _, Stuff in pairs(NeckgrabFunctions["GrabbedCharacter"]:GetDescendants()) do
                    if Stuff:IsA("BodyPosition") then
                        Stuff:Destroy()
                    end
                end
                
                ControlLoop:Disconnect()
                
                NeckgrabFunctions["GrabbedCharacter"].LeftHand:FindFirstChildOfClass("Motor6D").Enabled = true
                NeckgrabFunctions["GrabbedCharacter"].RightHand:FindFirstChildOfClass("Motor6D").Enabled = true
                NeckgrabFunctions["GrabbedCharacter"].LeftFoot:FindFirstChildOfClass("Motor6D").Enabled = true
                NeckgrabFunctions["GrabbedCharacter"].RightFoot:FindFirstChildOfClass("Motor6D").Enabled = true
            end)
        else
            DestroyTools("Control")
        end
    end
})

-- Sex (FIXED)
Group.Neckgrab:AddToggle('SexToggle', {
    Text = 'Sex',
    Default = false,
    Callback = function(v)
        if v then
            CreateTools("Sex", function()
                if OWNER.Character.BodyEffects.Grabbed.Value == nil then 
                    api:notify("No Grabbed Found", 1) 
                    return 
                end
                NeckgrabFunctions["Interval"] = true
                task.wait()
                NeckgrabFunctions["Interval"] = false
                AnimPlay(4784557631)
                AnimPlay(3119980985, .9)
                Play(6814463121)
                repeat task.wait()
                    for _, Stuff in pairs(NeckgrabFunctions["GrabbedCharacter"]:GetDescendants()) do
                        if Stuff:IsA("BasePart") or Stuff:IsA("MeshPart") or Stuff:IsA("Part") then
                            Stuff.Velocity = Vector3.zero
                            Stuff.AssemblyAngularVelocity = Vector3.zero
                            Stuff.AssemblyLinearVelocity = Vector3.zero
                            Stuff.CanCollide = false
                        end
                    end
                    Align(10000, 175, "UpperTorso", "HumanoidRootPart", CFrame.new(0, -0.3, -2 + .5 * math.sin(tick() * 60 / NeckgrabFunctions["SexSine"])), CFrame.Angles(math.pi * -.3, 0, 0))
                until OWNER.Character.BodyEffects.Grabbed.Value == nil or NeckgrabFunctions["Interval"] == true
                Destroy("UpperTorso")
                AnimStop(4784557631)
                AnimStop(3119980985, .5)
            end)
        else
            DestroyTools("Sex")
        end
    end
})

Group.Neckgrab:AddSlider('SexSpeedSlider', {
    Text = 'Sex Speed',
    Default = 8,
    Min = 0.1,
    Max = 8,
    Rounding = 1,
    Compact = false,
    Callback = function(v)
        NeckgrabFunctions["SexSine"] = v
    end
})

-- Cowgirl (FIXED)
Group.Neckgrab:AddToggle('CowgirlToggle', {
    Text = 'Cowgirl',
    Default = false,
    Callback = function(v)
        if v then
            CreateTools("Cowgirl", function()
                if OWNER.Character.BodyEffects.Grabbed.Value == nil then 
                    api:notify("No Grabbed Found", 1) 
                    return 
                end
                NeckgrabFunctions["Interval"] = true
                task.wait()
                NeckgrabFunctions["Interval"] = false
                NeckgrabFunctions["ClonedCharacter"] = CloneCharacter(NeckgrabFunctions["GrabbedCharacter"])
                
                local CowgirlLoop = api:add_connection(RunService.Heartbeat:Connect(function()
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].Head, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("Head"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].HumanoidRootPart, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("HumanoidRootPart"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].UpperTorso, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("UpperTorso"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LowerTorso, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LowerTorso"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftUpperArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftUpperArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftLowerArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftLowerArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightUpperArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightUpperArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightLowerArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightLowerArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftHand, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftHand"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightHand, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightHand"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftUpperLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftUpperLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftLowerLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftLowerLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightUpperLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightUpperLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightLowerLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightLowerLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftFoot, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftFoot"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightFoot, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightFoot"), CFrame.new(0, 0, 0))
                    
                    NeckgrabFunctions["GrabbedCharacter"].Head.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].UpperTorso.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].LowerTorso.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].LeftUpperArm.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].LeftLowerArm.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].LeftHand.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].RightUpperArm.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].RightLowerArm.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].RightHand.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].LeftUpperLeg.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].LeftLowerLeg.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].LeftFoot.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].RightUpperLeg.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].RightLowerLeg.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].RightFoot.CanCollide = false
                    
                    CloneAnimPlayWStop(3152375249)
                    CloneAnimPlayWStop(3152378852)
                    CloneAnimPlayWStop(3189773368)
                    CloneAnimPlayWStop(3189776546)
                    CloneAnimPlayWStop(3189777795)
                    CloneAnimPlayWStop(3189779152)
                    CloneAnimPlayWStop(3487719500)
                    CloneAnimPlayWStop(11710529975)
                    CloneAnimPlayWStop(11710524717)
                    CloneAnimPlayWStop(11710527244)
                    CloneAnimPlayWStop(11710529220)
                    CloneAnimPlayWStop(11710524200)
                    CloneAnimPlayWStop(11710541744)
                    
                    for i, v in pairs(NeckgrabFunctions["ClonedCharacter"].Humanoid:GetPlayingAnimationTracks()) do
                        if (v.Animation.AnimationId:match("rbxassetid://3152394906")) then
                            if NeckgrabFunctions["ClonedCharacter"].Humanoid.MoveDirection.magnitude > 0 then
                                v:AdjustSpeed(1)
                            else
                                v:AdjustSpeed(0)
                            end
                        end
                    end
                    
                    NeckgrabFunctions["ClonedCharacter"].Humanoid.Jump = OWNER.Character.Humanoid.Jump
                    NeckgrabFunctions["ClonedCharacter"].HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(0, 2 + 0.5 * math.sin(tick() * 133.33 / NeckgrabFunctions["CowgirlSine"]), -.9) * CFrame.Angles(0, math.rad(180), 0)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].HumanoidRootPart)
                end))
                
                CloneAnimPlay(10714390497, 0, 2)
                AnimPlay(15549124879, 0, 4)
                AnimPlay(3119980985, 2)
                Play(6814463121)
                
                repeat task.wait() until OWNER.Character.BodyEffects.Grabbed.Value == nil or NeckgrabFunctions["Interval"] == true
                
                AnimStop(4784557631)
                AnimStop(3119980985)
                AnimStop(15549124879)
                ZeroVelocity___(OWNER.Character.HumanoidRootPart)
                workspace.CurrentCamera.CameraSubject = OWNER.Character.Humanoid
                NeckgrabFunctions["ClonedCharacter"]:Destroy()
                
                for _, Stuff in pairs(NeckgrabFunctions["GrabbedCharacter"]:GetDescendants()) do
                    if Stuff:IsA("BodyPosition") then
                        Stuff:Destroy()
                    end
                end
                
                CowgirlLoop:Disconnect()
                
                NeckgrabFunctions["GrabbedCharacter"].LeftHand:FindFirstChildOfClass("Motor6D").Enabled = true
                NeckgrabFunctions["GrabbedCharacter"].RightHand:FindFirstChildOfClass("Motor6D").Enabled = true
                NeckgrabFunctions["GrabbedCharacter"].LeftFoot:FindFirstChildOfClass("Motor6D").Enabled = true
                NeckgrabFunctions["GrabbedCharacter"].RightFoot:FindFirstChildOfClass("Motor6D").Enabled = true
            end)
        else
            DestroyTools("Cowgirl")
        end
    end
})

Group.Neckgrab:AddSlider('CowgirlSpeedSlider', {
    Text = 'Cowgirl Speed',
    Default = 8,
    Min = 0.1,
    Max = 8,
    Rounding = 1,
    Compact = false,
    Callback = function(v)
        NeckgrabFunctions["CowgirlSine"] = v
    end
})

-- Dick Sucker (FIXED)
Group.Neckgrab:AddToggle('DickSuckerToggle', {
    Text = 'Dick Sucker',
    Default = false,
    Callback = function(v)
        if v then
            CreateTools("Dick Sucker", function()
                if OWNER.Character.BodyEffects.Grabbed.Value == nil then 
                    api:notify("No Grabbed Found", 1) 
                    return 
                end
                NeckgrabFunctions["Interval"] = true
                task.wait()
                NeckgrabFunctions["Interval"] = false
                NeckgrabFunctions["ClonedCharacter"] = CloneCharacter(NeckgrabFunctions["GrabbedCharacter"])
                
                local DickSuckerLoop = api:add_connection(RunService.Heartbeat:Connect(function()
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].Head, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("Head"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].HumanoidRootPart, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("HumanoidRootPart"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].UpperTorso, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("UpperTorso"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LowerTorso, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LowerTorso"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftUpperArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftUpperArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftLowerArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftLowerArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightUpperArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightUpperArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightLowerArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightLowerArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftHand, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftHand"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightHand, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightHand"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftUpperLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftUpperLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftLowerLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftLowerLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightUpperLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightUpperLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightLowerLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightLowerLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftFoot, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftFoot"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightFoot, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightFoot"), CFrame.new(0, 0, 0))
                    
                    NeckgrabFunctions["GrabbedCharacter"].Head.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].UpperTorso.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].LowerTorso.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].LeftUpperArm.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].LeftLowerArm.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].LeftHand.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].RightUpperArm.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].RightLowerArm.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].RightHand.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].LeftUpperLeg.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].LeftLowerLeg.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].LeftFoot.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].RightUpperLeg.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].RightLowerLeg.CanCollide = false
                    NeckgrabFunctions["GrabbedCharacter"].RightFoot.CanCollide = false
                    
                    CloneAnimPlayWStop(3152375249)
                    CloneAnimPlayWStop(3152378852)
                    CloneAnimPlayWStop(3189773368)
                    CloneAnimPlayWStop(3189776546)
                    CloneAnimPlayWStop(3189777795)
                    CloneAnimPlayWStop(3189779152)
                    CloneAnimPlayWStop(3487719500)
                    CloneAnimPlayWStop(11710529975)
                    CloneAnimPlayWStop(11710524717)
                    CloneAnimPlayWStop(11710527244)
                    CloneAnimPlayWStop(11710529220)
                    CloneAnimPlayWStop(11710524200)
                    CloneAnimPlayWStop(11710541744)
                    
                    for i, v in pairs(NeckgrabFunctions["ClonedCharacter"].Humanoid:GetPlayingAnimationTracks()) do
                        if (v.Animation.AnimationId:match("rbxassetid://3152394906")) then
                            if NeckgrabFunctions["ClonedCharacter"].Humanoid.MoveDirection.magnitude > 0 then
                                v:AdjustSpeed(1)
                            else
                                v:AdjustSpeed(0)
                            end
                        end
                    end
                    
                    NeckgrabFunctions["ClonedCharacter"].Humanoid.Jump = OWNER.Character.Humanoid.Jump
                    NeckgrabFunctions["ClonedCharacter"].HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(0, -1, -1) * CFrame.Angles(0, math.rad(180), 0)
                    
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].HumanoidRootPart)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].Head)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].UpperTorso)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].LowerTorso)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].LeftUpperArm)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].LeftLowerArm)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].LeftHand)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].RightUpperArm)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].RightLowerArm)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].RightHand)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].LeftUpperLeg)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].LeftLowerLeg)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].LeftFoot)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].RightUpperLeg)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].RightLowerLeg)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].RightFoot)
                end))
                
                spawn(function()
                    repeat task.wait(0.1)
                        AnimPlay(698251653, 1, .4)
                    until OWNER.Character.BodyEffects.Grabbed.Value == nil or NeckgrabFunctions["Interval"] == true
                end)
                
                CloneAnimPlay(3487719500, 0, 3)
                CloneAnimPlay(3119980985, 3)
                Play(6814463121)
                
                repeat task.wait() until OWNER.Character.BodyEffects.Grabbed.Value == nil or NeckgrabFunctions["Interval"] == true
                
                AnimStop(698251653)
                AnimStop(4784557631)
                AnimStop(3119980985)
                AnimStop(15549124879)
                ZeroVelocity___(OWNER.Character.HumanoidRootPart)
                NeckgrabFunctions["ClonedCharacter"]:Destroy()
                
                for _, Stuff in pairs(NeckgrabFunctions["GrabbedCharacter"]:GetDescendants()) do
                    if Stuff:IsA("BodyPosition") then
                        Stuff:Destroy()
                    end
                end
                
                DickSuckerLoop:Disconnect()
                
                NeckgrabFunctions["GrabbedCharacter"].LeftHand:FindFirstChildOfClass("Motor6D").Enabled = true
                NeckgrabFunctions["GrabbedCharacter"].RightHand:FindFirstChildOfClass("Motor6D").Enabled = true
                NeckgrabFunctions["GrabbedCharacter"].LeftFoot:FindFirstChildOfClass("Motor6D").Enabled = true
                NeckgrabFunctions["GrabbedCharacter"].RightFoot:FindFirstChildOfClass("Motor6D").Enabled = true
            end)
        else
            DestroyTools("Dick Sucker")
        end
    end
})

-- Extra Neckgrabs (Void, Fling, Spin, Ragdoll, Slam, Orbit)
Group.Neckgrab:AddToggle('VoidToggle', {
    Text = 'Void',
    Default = false,
    Callback = function(v)
        if v then
            CreateTools("Void", function()
                if OWNER.Character.BodyEffects.Grabbed.Value == nil then 
                    api:notify("No Grabbed Found", 1) 
                    return 
                end
                NeckgrabFunctions["Interval"] = true
                task.wait()
                NeckgrabFunctions["Interval"] = false
                
                spawn(function()
                    repeat task.wait()
                        Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, 0, -10), CFrame.Angles(0, 0, 0))
                    until NeckgrabFunctions["Interval"] == true
                end)
                task.wait(.6)
                
                AnimPlay(2788292075, 1.4)
                task.wait(.3)
                Play_(186130717)
                
                NeckgrabFunctions["Interval"] = false
                spawn(function()
                    repeat task.wait()
                        Align(8000, 800, "UpperTorso", "HumanoidRootPart", CFrame.new(0, -500, 0), CFrame.Angles(0, 0, 0))
                    until NeckgrabFunctions["Interval"] == true
                end)
                
                task.wait(1)
                ReplicatedStorage.MainEvent:FireServer("Grabbing")
                Destroy("UpperTorso")
            end)
        else
            DestroyTools("Void")
        end
    end
})

Group.Neckgrab:AddToggle('FlingToggle', {
    Text = 'Fling',
    Default = false,
    Callback = function(v)
        if v then
            CreateTools("Fling", function()
                if OWNER.Character.BodyEffects.Grabbed.Value == nil then 
                    api:notify("No Grabbed Found", 1) 
                    return 
                end
                NeckgrabFunctions["Interval"] = true
                task.wait()
                NeckgrabFunctions["Interval"] = false
                
                spawn(function()
                    for i = 1, 20 do
                        if NeckgrabFunctions["Interval"] == true then break end
                        Align(8000, 800, "UpperTorso", "HumanoidRootPart", 
                            CFrame.new(0, 3, -8), 
                            CFrame.Angles(0, math.rad(i * 18), 0))
                        task.wait(0.05)
                    end
                end)
                
                task.wait(1)
                AnimPlay(2788292075, 1.4)
                Play(558640653)
                
                NeckgrabFunctions["Interval"] = false
                spawn(function()
                    repeat task.wait()
                        Align(8000, 800, "UpperTorso", "HumanoidRootPart", 
                            CFrame.new(0, 200, -300), 
                            CFrame.Angles(math.pi * 2, math.pi, 0))
                    until NeckgrabFunctions["Interval"] == true
                end)
                
                task.wait(.5)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.RightUpperArm.CFrame = CFrame.new(0, -1200, 0)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.LeftUpperArm.CFrame = CFrame.new(0, -1200, 0)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.RightUpperLeg.CFrame = CFrame.new(0, -1200, 0)
                game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.LeftUpperLeg.CFrame = CFrame.new(0, -1200, 0)
                task.wait(.3)
                ReplicatedStorage.MainEvent:FireServer("Grabbing")
                Destroy("UpperTorso")
            end)
        else
            DestroyTools("Fling")
        end
    end
})

-- Puppet Master
Group.Neckgrab:AddToggle('PuppetMasterToggle', {
    Text = 'Puppet Master',
    Default = false,
    Callback = function(v)
        if v then
            CreateTools("Puppet Master", function()
                if OWNER.Character.BodyEffects.Grabbed.Value == nil then 
                    api:notify("No Grabbed Found", 1) 
                    return 
                end
                NeckgrabFunctions["Interval"] = true
                task.wait()
                NeckgrabFunctions["Interval"] = false
                NeckgrabFunctions["ClonedCharacter"] = CloneCharacter(NeckgrabFunctions["GrabbedCharacter"])
                
                local danceAnims = {3189773368, 3189776546, 3189777795, 3189779152}
                
                local PuppetLoop = api:add_connection(RunService.Heartbeat:Connect(function()
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].Head, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("Head"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].HumanoidRootPart, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("HumanoidRootPart"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].UpperTorso, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("UpperTorso"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LowerTorso, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LowerTorso"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftUpperArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftUpperArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftLowerArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftLowerArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightUpperArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightUpperArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightLowerArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightLowerArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftHand, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftHand"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightHand, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightHand"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftUpperLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftUpperLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftLowerLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftLowerLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightUpperLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightUpperLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightLowerLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightLowerLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftFoot, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftFoot"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightFoot, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightFoot"), CFrame.new(0, 0, 0))
                    
                    NeckgrabFunctions["ClonedCharacter"].HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].HumanoidRootPart)
                end))
                
                spawn(function()
                    for i = 1, 4 do
                        if OWNER.Character.BodyEffects.Grabbed.Value == nil then break end
                        CloneAnimPlay(danceAnims[i], 1)
                        task.wait(2)
                    end
                end)
                
                Play(6814463121)
                
                repeat task.wait() until OWNER.Character.BodyEffects.Grabbed.Value == nil or NeckgrabFunctions["Interval"] == true
                
                PuppetLoop:Disconnect()
                NeckgrabFunctions["ClonedCharacter"]:Destroy()
                
                for _, Stuff in pairs(NeckgrabFunctions["GrabbedCharacter"]:GetDescendants()) do
                    if Stuff:IsA("BodyPosition") then
                        Stuff:Destroy()
                    end
                end
                
                NeckgrabFunctions["GrabbedCharacter"].LeftHand:FindFirstChildOfClass("Motor6D").Enabled = true
                NeckgrabFunctions["GrabbedCharacter"].RightHand:FindFirstChildOfClass("Motor6D").Enabled = true
                NeckgrabFunctions["GrabbedCharacter"].LeftFoot:FindFirstChildOfClass("Motor6D").Enabled = true
                NeckgrabFunctions["GrabbedCharacter"].RightFoot:FindFirstChildOfClass("Motor6D").Enabled = true
            end)
        else
            DestroyTools("Puppet Master")
        end
    end
})

-- Minion - They walk beside you and copy all your animations
Group.Neckgrab:AddToggle('MinionToggle', {
    Text = 'Minion',
    Default = false,
    Callback = function(v)
        if v then
            CreateTools("Minion", function()
                if OWNER.Character.BodyEffects.Grabbed.Value == nil then 
                    api:notify("No Grabbed Found", 1) 
                    return 
                end
                NeckgrabFunctions["Interval"] = true
                task.wait()
                NeckgrabFunctions["Interval"] = false
                NeckgrabFunctions["ClonedCharacter"] = CloneCharacter(NeckgrabFunctions["GrabbedCharacter"])
                
                local MinionLoop = api:add_connection(RunService.Heartbeat:Connect(function()
                    -- Align victim to clone
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].Head, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("Head"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].HumanoidRootPart, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("HumanoidRootPart"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].UpperTorso, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("UpperTorso"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LowerTorso, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LowerTorso"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftUpperArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftUpperArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftLowerArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftLowerArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightUpperArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightUpperArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightLowerArm, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightLowerArm"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftHand, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftHand"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightHand, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightHand"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftUpperLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftUpperLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftLowerLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftLowerLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightUpperLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightUpperLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightLowerLeg, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightLowerLeg"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].LeftFoot, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("LeftFoot"), CFrame.new(0, 0, 0))
                    ControlAlign(NeckgrabFunctions["GrabbedCharacter"].RightFoot, NeckgrabFunctions["ClonedCharacter"]:FindFirstChild("RightFoot"), CFrame.new(0, 0, 0))
                    
                    -- Position clone beside you (to your right)
                    NeckgrabFunctions["ClonedCharacter"].HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(5, 0, 0)
                    ZeroVelocity___(NeckgrabFunctions["ClonedCharacter"].HumanoidRootPart)
                    
                    -- Copy ALL your animations
                    for _, yourAnim in pairs(OWNER.Character.Humanoid:GetPlayingAnimationTracks()) do
                        local animId = yourAnim.Animation.AnimationId:match("%d+")
                        
                        -- Check if clone is already playing this animation
                        local alreadyPlaying = false
                        for _, cloneAnim in pairs(NeckgrabFunctions["ClonedCharacter"].Humanoid:GetPlayingAnimationTracks()) do
                            if cloneAnim.Animation.AnimationId:match(animId) then
                                alreadyPlaying = true
                                -- Sync speed and time
                                cloneAnim:AdjustSpeed(yourAnim.Speed)
                                cloneAnim.TimePosition = yourAnim.TimePosition
                                break
                            end
                        end
                        
                        -- If not playing, start it
                        if not alreadyPlaying then
                            local newAnim = Instance.new('Animation')
                            newAnim.AnimationId = yourAnim.Animation.AnimationId
                            local cloneTrack = NeckgrabFunctions["ClonedCharacter"].Humanoid:LoadAnimation(newAnim)
                            cloneTrack.Priority = yourAnim.Priority
                            cloneTrack:Play()
                            cloneTrack:AdjustSpeed(yourAnim.Speed)
                            cloneTrack.TimePosition = yourAnim.TimePosition
                            newAnim:Destroy()
                        end
                    end
                    
                    -- Stop animations you're not playing
                    for _, cloneAnim in pairs(NeckgrabFunctions["ClonedCharacter"].Humanoid:GetPlayingAnimationTracks()) do
                        local cloneAnimId = cloneAnim.Animation.AnimationId:match("%d+")
                        local yourePlaying = false
                        
                        for _, yourAnim in pairs(OWNER.Character.Humanoid:GetPlayingAnimationTracks()) do
                            if yourAnim.Animation.AnimationId:match(cloneAnimId) then
                                yourePlaying = true
                                break
                            end
                        end
                        
                        if not yourePlaying then
                            cloneAnim:Stop()
                        end
                    end
                    
                    -- Copy jump
                    NeckgrabFunctions["ClonedCharacter"].Humanoid.Jump = OWNER.Character.Humanoid.Jump
                end))
                
                repeat task.wait() until OWNER.Character.BodyEffects.Grabbed.Value == nil or NeckgrabFunctions["Interval"] == true
                
                MinionLoop:Disconnect()
                NeckgrabFunctions["ClonedCharacter"]:Destroy()
                
                for _, Stuff in pairs(NeckgrabFunctions["GrabbedCharacter"]:GetDescendants()) do
                    if Stuff:IsA("BodyPosition") then
                        Stuff:Destroy()
                    end
                end
                
                NeckgrabFunctions["GrabbedCharacter"].LeftHand:FindFirstChildOfClass("Motor6D").Enabled = true
                NeckgrabFunctions["GrabbedCharacter"].RightHand:FindFirstChildOfClass("Motor6D").Enabled = true
                NeckgrabFunctions["GrabbedCharacter"].LeftFoot:FindFirstChildOfClass("Motor6D").Enabled = true
                NeckgrabFunctions["GrabbedCharacter"].RightFoot:FindFirstChildOfClass("Motor6D").Enabled = true
            end)
        else
            DestroyTools("Minion")
        end
    end
})

-- Custom Poser - Fully customize their limb positions
Group.Neckgrab:AddToggle('CustomPoserToggle', {
    Text = 'Custom Poser',
    Default = false,
    Callback = function(v)
        if v then
            CreateTools("Custom Poser", function()
                if OWNER.Character.BodyEffects.Grabbed.Value == nil then 
                    api:notify("No Grabbed Found", 1) 
                    return 
                end
                NeckgrabFunctions["Interval"] = true
                task.wait()
                NeckgrabFunctions["Interval"] = false
                
                -- Keep them in place
                spawn(function()
                    repeat task.wait()
                        Align(8000, 800, "UpperTorso", "HumanoidRootPart", 
                            CFrame.new(0, 0, -5), 
                            CFrame.Angles(0, 0, 0))
                    until NeckgrabFunctions["Interval"] == true
                end)
                
                api:notify("Custom Poser Active - Use sliders to pose!", 2)
            end)
        else
            DestroyTools("Custom Poser")
            NeckgrabFunctions["Interval"] = true
        end
    end
})

-- Limb Position Sliders for Custom Poser
local LimbPositions = {
    Head = {X = 0, Y = 0, Z = 0, RotX = 0, RotY = 0, RotZ = 0},
    LeftArm = {X = 0, Y = 0, Z = 0, RotX = 0, RotY = 0, RotZ = 0},
    RightArm = {X = 0, Y = 0, Z = 0, RotX = 0, RotY = 0, RotZ = 0},
    LeftLeg = {X = 0, Y = 0, Z = 0, RotX = 0, RotY = 0, RotZ = 0},
    RightLeg = {X = 0, Y = 0, Z = 0, RotX = 0, RotY = 0, RotZ = 0}
}

-- Create a second groupbox for limb controls
local LimbGroup = tabs.script:AddRightGroupbox("Limb Poser")

LimbGroup:AddLabel('Head Position'):AddSlider('HeadX', {Text = 'Head X', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v) LimbPositions.Head.X = v end})
LimbGroup:AddSlider('HeadY', {Text = 'Head Y', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v) LimbPositions.Head.Y = v end})
LimbGroup:AddSlider('HeadZ', {Text = 'Head Z', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v) LimbPositions.Head.Z = v end})
LimbGroup:AddSlider('HeadRotX', {Text = 'Head Rot X', Default = 0, Min = -180, Max = 180, Rounding = 1, Callback = function(v) LimbPositions.Head.RotX = v end})
LimbGroup:AddSlider('HeadRotY', {Text = 'Head Rot Y', Default = 0, Min = -180, Max = 180, Rounding = 1, Callback = function(v) LimbPositions.Head.RotY = v end})
LimbGroup:AddSlider('HeadRotZ', {Text = 'Head Rot Z', Default = 0, Min = -180, Max = 180, Rounding = 1, Callback = function(v) LimbPositions.Head.RotZ = v end})

LimbGroup:AddLabel('Left Arm'):AddSlider('LeftArmX', {Text = 'L Arm X', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v) LimbPositions.LeftArm.X = v end})
LimbGroup:AddSlider('LeftArmY', {Text = 'L Arm Y', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v) LimbPositions.LeftArm.Y = v end})
LimbGroup:AddSlider('LeftArmZ', {Text = 'L Arm Z', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v) LimbPositions.LeftArm.Z = v end})
LimbGroup:AddSlider('LeftArmRotX', {Text = 'L Arm Rot X', Default = 0, Min = -180, Max = 180, Rounding = 1, Callback = function(v) LimbPositions.LeftArm.RotX = v end})
LimbGroup:AddSlider('LeftArmRotY', {Text = 'L Arm Rot Y', Default = 0, Min = -180, Max = 180, Rounding = 1, Callback = function(v) LimbPositions.LeftArm.RotY = v end})
LimbGroup:AddSlider('LeftArmRotZ', {Text = 'L Arm Rot Z', Default = 0, Min = -180, Max = 180, Rounding = 1, Callback = function(v) LimbPositions.LeftArm.RotZ = v end})

LimbGroup:AddLabel('Right Arm'):AddSlider('RightArmX', {Text = 'R Arm X', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v) LimbPositions.RightArm.X = v end})
LimbGroup:AddSlider('RightArmY', {Text = 'R Arm Y', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v) LimbPositions.RightArm.Y = v end})
LimbGroup:AddSlider('RightArmZ', {Text = 'R Arm Z', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v) LimbPositions.RightArm.Z = v end})
LimbGroup:AddSlider('RightArmRotX', {Text = 'R Arm Rot X', Default = 0, Min = -180, Max = 180, Rounding = 1, Callback = function(v) LimbPositions.RightArm.RotX = v end})
LimbGroup:AddSlider('RightArmRotY', {Text = 'R Arm Rot Y', Default = 0, Min = -180, Max = 180, Rounding = 1, Callback = function(v) LimbPositions.RightArm.RotY = v end})
LimbGroup:AddSlider('RightArmRotZ', {Text = 'R Arm Rot Z', Default = 0, Min = -180, Max = 180, Rounding = 1, Callback = function(v) LimbPositions.RightArm.RotZ = v end})

LimbGroup:AddLabel('Left Leg'):AddSlider('LeftLegX', {Text = 'L Leg X', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v) LimbPositions.LeftLeg.X = v end})
LimbGroup:AddSlider('LeftLegY', {Text = 'L Leg Y', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v) LimbPositions.LeftLeg.Y = v end})
LimbGroup:AddSlider('LeftLegZ', {Text = 'L Leg Z', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v) LimbPositions.LeftLeg.Z = v end})
LimbGroup:AddSlider('LeftLegRotX', {Text = 'L Leg Rot X', Default = 0, Min = -180, Max = 180, Rounding = 1, Callback = function(v) LimbPositions.LeftLeg.RotX = v end})
LimbGroup:AddSlider('LeftLegRotY', {Text = 'L Leg Rot Y', Default = 0, Min = -180, Max = 180, Rounding = 1, Callback = function(v) LimbPositions.LeftLeg.RotY = v end})
LimbGroup:AddSlider('LeftLegRotZ', {Text = 'L Leg Rot Z', Default = 0, Min = -180, Max = 180, Rounding = 1, Callback = function(v) LimbPositions.LeftLeg.RotZ = v end})

LimbGroup:AddLabel('Right Leg'):AddSlider('RightLegX', {Text = 'R Leg X', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v) LimbPositions.RightLeg.X = v end})
LimbGroup:AddSlider('RightLegY', {Text = 'R Leg Y', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v) LimbPositions.RightLeg.Y = v end})
LimbGroup:AddSlider('RightLegZ', {Text = 'R Leg Z', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v) LimbPositions.RightLeg.Z = v end})
LimbGroup:AddSlider('RightLegRotX', {Text = 'R Leg Rot X', Default = 0, Min = -180, Max = 180, Rounding = 1, Callback = function(v) LimbPositions.RightLeg.RotX = v end})
LimbGroup:AddSlider('RightLegRotY', {Text = 'R Leg Rot Y', Default = 0, Min = -180, Max = 180, Rounding = 1, Callback = function(v) LimbPositions.RightLeg.RotY = v end})
LimbGroup:AddSlider('RightLegRotZ', {Text = 'R Leg Rot Z', Default = 0, Min = -180, Max = 180, Rounding = 1, Callback = function(v) LimbPositions.RightLeg.RotZ = v end})

LimbGroup:AddButton({
    Text = 'Reset All Limbs',
    Func = function()
        for limb, _ in pairs(LimbPositions) do
            LimbPositions[limb] = {X = 0, Y = 0, Z = 0, RotX = 0, RotY = 0, RotZ = 0}
        end
        api:notify("All limbs reset!", 1)
    end,
})

LimbGroup:AddButton({
    Text = 'Apply Pose',
    Func = function()
        if OWNER.Character.BodyEffects.Grabbed.Value then
            local victim = game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character
            
            -- Create BodyPosition and BodyGyro for each limb
            local function PoseLimb(limb, pos)
                if victim:FindFirstChild(limb) then
                    -- Remove old ones
                    for _, v in pairs(victim[limb]:GetChildren()) do
                        if v:IsA("BodyPosition") or v:IsA("BodyGyro") then
                            v:Destroy()
                        end
                    end
                    
                    local BP = Instance.new("BodyPosition", victim[limb])
                    BP.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    BP.P = 8000
                    BP.D = 800
                    BP.Position = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(pos.X, pos.Y, pos.Z - 5).Position
                    
                    local BG = Instance.new("BodyGyro", victim[limb])
                    BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
                    BG.P = 10000
                    BG.CFrame = CFrame.Angles(math.rad(pos.RotX), math.rad(pos.RotY), math.rad(pos.RotZ))
                end
            end
            
            PoseLimb("Head", LimbPositions.Head)
            PoseLimb("LeftUpperArm", LimbPositions.LeftArm)
            PoseLimb("RightUpperArm", LimbPositions.RightArm)
            PoseLimb("LeftUpperLeg", LimbPositions.LeftLeg)
            PoseLimb("RightUpperLeg", LimbPositions.RightLeg)
            
            api:notify("Pose applied!", 1)
        else
            api:notify("No one grabbed!", 1)
        end
    end,
})


-- Dismember Buttons
Group.Neckgrabs:AddButton({
    Text = 'Left arm',
    Func = function()
        if OWNER.Character.BodyEffects.Grabbed.Value then
            game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.LeftUpperArm.CFrame = CFrame.new(0, -600, 0)
        end
    end,
})

Group.Neckgrabs:AddButton({
    Text = 'Bottom of left arm',
    Func = function()
        if OWNER.Character.BodyEffects.Grabbed.Value then
            game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.LeftLowerArm.CFrame = CFrame.new(0, -600, 0)
        end
    end,
})

Group.Neckgrabs:AddButton({
    Text = 'Right arm',
    Func = function()
        if OWNER.Character.BodyEffects.Grabbed.Value then
            game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.RightUpperArm.CFrame = CFrame.new(0, -600, 0)
        end
    end,
})

Group.Neckgrabs:AddButton({
    Text = 'Bottom of right arm',
    Func = function()
        if OWNER.Character.BodyEffects.Grabbed.Value then
            game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.RightLowerArm.CFrame = CFrame.new(0, -600, 0)
        end
    end,
})

Group.Neckgrabs:AddButton({
    Text = 'Left leg',
    Func = function()
        if OWNER.Character.BodyEffects.Grabbed.Value then
            game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.LeftUpperLeg.CFrame = CFrame.new(0, -600, 0)
        end
    end,
})

Group.Neckgrabs:AddButton({
    Text = 'Bottom of left leg',
    Func = function()
        if OWNER.Character.BodyEffects.Grabbed.Value then
            game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.LeftLowerLeg.CFrame = CFrame.new(0, -600, 0)
        end
    end,
})

Group.Neckgrabs:AddButton({
    Text = 'Right leg',
    Func = function()
        if OWNER.Character.BodyEffects.Grabbed.Value then
            game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.RightUpperLeg.CFrame = CFrame.new(0, -600, 0)
        end
    end,
})

Group.Neckgrabs:AddButton({
    Text = 'Bottom of right leg',
    Func = function()
        if OWNER.Character.BodyEffects.Grabbed.Value then
            game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.RightLowerLeg.CFrame = CFrame.new(0, -600, 0)
        end
    end,
})

Group.Neckgrabs:AddButton({
    Text = 'Lowerbody',
    Func = function()
        if OWNER.Character.BodyEffects.Grabbed.Value then
            game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character.LowerTorso.CFrame = CFrame.new(0, -600, 0)
        end
    end,
})

Group.Neckgrabs:AddButton({
    Text = 'Remove Entire Body',
    Func = function()
        if OWNER.Character.BodyEffects.Grabbed.Value then
            local victim = game.Players[tostring(OWNER.Character.BodyEffects.Grabbed.Value)].Character
            victim.LeftUpperArm.CFrame = CFrame.new(0, -600, 0)
            victim.RightUpperArm.CFrame = CFrame.new(0, -600, 0)
            victim.LeftUpperLeg.CFrame = CFrame.new(0, -600, 0)
            victim.RightUpperLeg.CFrame = CFrame.new(0, -600, 0)
            victim.LeftLowerArm.CFrame = CFrame.new(0, -600, 0)
            victim.RightLowerArm.CFrame = CFrame.new(0, -600, 0)
            victim.LeftLowerLeg.CFrame = CFrame.new(0, -600, 0)
            victim.RightLowerLeg.CFrame = CFrame.new(0, -600, 0)
            victim.LowerTorso.CFrame = CFrame.new(0, -600, 0)
        end
    end,
})


