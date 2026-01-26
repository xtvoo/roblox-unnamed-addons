local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'LT2 Car Killer - Antigravity',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Main = Window:AddTab('Main'),
    Player = Window:AddTab('Local Player'),
    Tools = Window:AddTab('Tools'),
    Settings = Window:AddTab('Settings'),
}

local LeftGroupBox = Tabs.Main:AddLeftGroupbox('Target Selection')
local RightGroupBox = Tabs.Main:AddRightGroupbox('Controls')

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local Settings = {
    Target = nil,
    OffsetX = 0,
    OffsetY = 0,
    OffsetZ = 0,
    LoopKill = false,
    CheckSeat = true, 
}

local function GetVehicle()
    local Character = LocalPlayer.Character
    if not Character then return nil end
    
    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid then return nil end
    
    local SeatPart = Humanoid.SeatPart
    if not SeatPart then return nil end
    
    local Vehicle = SeatPart.Parent
    if Vehicle:IsA("Model") and Vehicle.PrimaryPart then
        return Vehicle
    end

    if Vehicle.Parent:IsA("Model") and Vehicle.Parent.PrimaryPart then
        return Vehicle.Parent
    end

    return Vehicle
end

local function TeleportVehicle(targetCFrame, ignoreOffsets)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then return false, "No Humanoid" end
    
    local seat = LocalPlayer.Character.Humanoid.SeatPart
    if not seat then 
        if Settings.CheckSeat then return false, "Not Seated" end
    end
    
    local finalCFrame = targetCFrame
    if not ignoreOffsets then
        finalCFrame = targetCFrame * CFrame.new(Settings.OffsetX, Settings.OffsetY, Settings.OffsetZ)
    end

    local vehicleModel = GetVehicle()
    if vehicleModel and vehicleModel.PrimaryPart then
        vehicleModel:SetPrimaryPartCFrame(finalCFrame)
        vehicleModel.PrimaryPart.Velocity = Vector3.new(0,0,0)
        vehicleModel.PrimaryPart.RotVelocity = Vector3.new(0,0,0)
        return true
    elseif not Settings.CheckSeat and LocalPlayer.Character.PrimaryPart then
        LocalPlayer.Character:SetPrimaryPartCFrame(finalCFrame)
        return true
    end
    return false, "No Vehicle/Model"
end

local function IsSeated()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.SeatPart ~= nil
end

local function GetPlayerNames()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(names, player.Name)
        end
    end
    return names
end

local TargetDropdown = LeftGroupBox:AddDropdown('MyDropdown', {
    Values = GetPlayerNames(),
    Default = 1, 
    Multi = false,
    Text = 'Select Target',
    Tooltip = 'Player to teleport to',
})

TargetDropdown:OnChanged(function()
    Settings.Target = Players:FindFirstChild(TargetDropdown.Value)
end)

LeftGroupBox:AddButton('Refresh Players', function()
    local names = GetPlayerNames()
    TargetDropdown.Values = names
    TargetDropdown:SetValues()
    if #names > 0 then
        TargetDropdown:SetValue(names[1])
    end
end)

RightGroupBox:AddToggle('CheckSeat', {
    Text = 'Require Seat Check',
    Default = true,
    Tooltip = 'Only teleport if you are in a seat',
})

Toggles.CheckSeat:OnChanged(function()
    Settings.CheckSeat = Toggles.CheckSeat.Value
end)

RightGroupBox:AddLabel('Offsets')

RightGroupBox:AddSlider('OffsetX', { Text = 'Offset X', Default = -1.7, Min = -50, Max = 50, Rounding = 1, Compact = false })
RightGroupBox:AddSlider('OffsetY', { Text = 'Offset Y', Default = -4.3, Min = -50, Max = 50, Rounding = 1, Compact = false })
RightGroupBox:AddSlider('OffsetZ', { Text = 'Offset Z', Default = 1.7, Min = -50, Max = 50, Rounding = 1, Compact = false })

Options.OffsetX:OnChanged(function() Settings.OffsetX = Options.OffsetX.Value end)
Options.OffsetY:OnChanged(function() Settings.OffsetY = Options.OffsetY.Value end)
Options.OffsetZ:OnChanged(function() Settings.OffsetZ = Options.OffsetZ.Value end)

Settings.OffsetX = Options.OffsetX.Value
Settings.OffsetY = Options.OffsetY.Value
Settings.OffsetZ = Options.OffsetZ.Value

local function SpawnTruck()
    local PlayerModels = workspace:WaitForChild("PlayerModels")
    for _, model in ipairs(PlayerModels:GetChildren()) do
        local ownerValue = model:FindFirstChild("Owner")
        local isOwner = false
        if ownerValue and (tostring(ownerValue.Value) == LocalPlayer.Name or tostring(ownerValue) == LocalPlayer.Name) then isOwner = true end
        if ownerValue and ownerValue:FindFirstChild("OwnerString") and tostring(ownerValue.OwnerString.Value) == LocalPlayer.Name then isOwner = true end
        
        if isOwner then
            local spawnButton = model:FindFirstChild("ButtonRemote_SpawnButton") or model:FindFirstChild("SpawnButton")
            
            if spawnButton then
                local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Interaction")
                if remote then
                    remote = remote:FindFirstChild("RemoteProxy")
                    if remote then
                        local args = { spawnButton }
                        remote:FireServer(unpack(args))
                        Library:Notify("Attempted to Spawn Truck!", 3)
                        return true
                    end
                end
            end
        end
    end
    Library:Notify("Could not find your Plot/SpawnButton", 5)
    return false
end

RightGroupBox:AddButton({
    Text = 'Spawn Truck',
    Func = function() SpawnTruck() end,
    DoubleClick = false,
    Tooltip = 'Auto-buy/Spawn Utility Truck if missing'
})

local Destinations = Tabs.Main:AddRightGroupbox('Kill Zones')

local KillZones = {
    ['None'] = nil,
    ['Volcano'] = CFrame.new(-1672, 176, 1322), 
    ['Ocean'] = CFrame.new(2039, -4, -3268),
    ['End Times Cave'] = CFrame.new(113, -213, -951),
    ['End Times Tree'] = CFrame.new(-47, -200, -1344),
    ['Death Barrier'] = CFrame.new(217, -300, -940),
    ['Custom Bring Pos'] = nil
}

local KillZoneDropdown = Destinations:AddDropdown('KillZone', {
    Values = {'None', 'Volcano', 'Ocean', 'End Times Cave', 'End Times Tree', 'Death Barrier', 'Custom Bring Pos'},
    Default = 1,
    Multi = false,
    Text = 'Select Zone',
    Tooltip = 'Where to take them (Requires Car)'
})

KillZoneDropdown:OnChanged(function() Settings.SelectedZone = KillZones[KillZoneDropdown.Value] end)

Destinations:AddButton('Set Bring Pos (Here)', function()
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
        KillZones['Custom Bring Pos'] = LocalPlayer.Character.PrimaryPart.CFrame
        Library:Notify("Set Custom Bring Pos!", 3)
        if KillZoneDropdown.Value == 'Custom Bring Pos' then
            Settings.SelectedZone = KillZones['Custom Bring Pos']
        end
    else
        Library:Notify("Character not found", 3)
    end
end)

Destinations:AddButton('Preview Selected Zone', function()
    if Settings.SelectedZone and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
        LocalPlayer.Character:SetPrimaryPartCFrame(Settings.SelectedZone + Vector3.new(0, 10, 0))
        Library:Notify("Previewing: " .. (KillZoneDropdown.Value or "Zone"), 3)
    else
        Library:Notify("Select a zone first!", 2)
    end
end)

local ZoneEditor = Tabs.Main:AddLeftGroupbox('Zone Editor')
local CustomZoneX, CustomZoneY, CustomZoneZ = 0, -300, 0

ZoneEditor:AddSlider('ZoneX', { Text = 'Zone X', Default = 0, Min = -5000, Max = 5000, Rounding = 0, Callback = function(Value) 
    CustomZoneX = Value 
    KillZones['Custom Bring Pos'] = CFrame.new(CustomZoneX, CustomZoneY, CustomZoneZ)
    if KillZoneDropdown.Value == 'Custom Bring Pos' then Settings.SelectedZone = KillZones['Custom Bring Pos'] end
end })

ZoneEditor:AddSlider('ZoneY', { Text = 'Zone Y', Default = -300, Min = -1000, Max = 1000, Rounding = 0, Callback = function(Value) 
    CustomZoneY = Value 
    KillZones['Custom Bring Pos'] = CFrame.new(CustomZoneX, CustomZoneY, CustomZoneZ)
    if KillZoneDropdown.Value == 'Custom Bring Pos' then Settings.SelectedZone = KillZones['Custom Bring Pos'] end
end })

ZoneEditor:AddSlider('ZoneZ', { Text = 'Zone Z', Default = 0, Min = -5000, Max = 5000, Rounding = 0, Callback = function(Value) 
    CustomZoneZ = Value 
    KillZones['Custom Bring Pos'] = CFrame.new(CustomZoneX, CustomZoneY, CustomZoneZ)
    if KillZoneDropdown.Value == 'Custom Bring Pos' then Settings.SelectedZone = KillZones['Custom Bring Pos'] end
end })

ZoneEditor:AddButton('Apply Custom Zone', function()
    KillZones['Custom Bring Pos'] = CFrame.new(CustomZoneX, CustomZoneY, CustomZoneZ)
    KillZoneDropdown:SetValue('Custom Bring Pos')
    Settings.SelectedZone = KillZones['Custom Bring Pos']
    Library:Notify("Custom Zone Set: " .. CustomZoneX .. ", " .. CustomZoneY .. ", " .. CustomZoneZ, 3)
end)

ZoneEditor:AddButton('Copy Current Pos to Sliders', function()
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
        local pos = LocalPlayer.Character.PrimaryPart.Position
        CustomZoneX, CustomZoneY, CustomZoneZ = math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z)
        Options.ZoneX:SetValue(CustomZoneX)
        Options.ZoneY:SetValue(CustomZoneY)
        Options.ZoneZ:SetValue(CustomZoneZ)
        Library:Notify("Copied your position to sliders!", 2)
    end
end)

Destinations:AddToggle('StayAtDropoff', {
    Text = 'Tp Me To Dropoff',
    Default = false,
    Tooltip = 'If enabled, you stay at the dropoff location instead of TPing to Base'
})
Toggles.StayAtDropoff:OnChanged(function() Settings.StayAtDropoff = Toggles.StayAtDropoff.Value end)

local MyButton = RightGroupBox:AddButton({
    Text = 'Teleport Once',
    Func = function()
        if not Settings.Target or not Settings.Target.Character then
            Library:Notify('Invalid Target', 3)
            return
        end
        local success, msg = TeleportVehicle(Settings.Target.Character.PrimaryPart.CFrame)
        if not success then Library:Notify('Teleport Failed: ' .. (msg or "Unknown"), 3) end
    end,
    DoubleClick = false,
    Tooltip = 'Teleport to target once'
})

RightGroupBox:AddToggle('LoopKill', {
    Text = 'Car Killer (Toggle)',
    Default = false,
    Tooltip = 'Continuously teleport to target (The "Killer")',
}):AddKeyPicker('LoopKillKey', { Default = 'T', NoUI = true, Text = 'Car Killer' })

local MenuGroup = Tabs.Settings:AddLeftGroupbox('Menu')
MenuGroup:AddToggle('MenuKeybindToggle', {
    Text = 'Menu Visibility',
    Default = true,
    Tooltip = 'Toggle UI Visibility Control'
}):AddKeyPicker('MenuKeybind', { Default = 'RightControl', NoUI = true, Text = 'Menu Switch' })

Library.ToggleKeybind = Options.MenuKeybind

Toggles.LoopKill:OnChanged(function()
    Settings.LoopKill = Toggles.LoopKill.Value
    if Settings.LoopKill and Settings.CheckSeat and not IsSeated() then
        Library:Notify('Warning: You are not seated!', 5)
    end
end)

local function FindOwnTruck()
    local PlayerModels = workspace:WaitForChild("PlayerModels")
    for _, model in ipairs(PlayerModels:GetChildren()) do
        local ownerValue = model:FindFirstChild("Owner")
        local isOwner = false
        if ownerValue and (tostring(ownerValue.Value) == LocalPlayer.Name or tostring(ownerValue) == LocalPlayer.Name) then isOwner = true end
        if ownerValue and ownerValue:FindFirstChild("OwnerString") and tostring(ownerValue.OwnerString.Value) == LocalPlayer.Name then isOwner = true end

        if isOwner then
            if model:FindFirstChild("DriveSeat") or model:FindFirstChild("Drive") or model:FindFirstChild("VehicleSeat") or model:FindFirstChild("UtilityTruck") then
                return model
            end
        end
    end
    return nil
end

local function GetBasePosition()
    local PlayerModels = workspace:WaitForChild("Properties", 5) 
    if PlayerModels then
        for _, property in ipairs(PlayerModels:GetChildren()) do
            local owner = property:FindFirstChild("Owner")
            if owner and (tostring(owner.Value) == LocalPlayer.Name or tostring(owner) == LocalPlayer.Name) then
                if property:FindFirstChild("OriginSquare") then
                    return property.OriginSquare.CFrame + Vector3.new(0, 5, 0)
                end
            end
        end
    end
    local Spawn = workspace:FindFirstChild("SpawnLocation")
    if Spawn then return Spawn.CFrame + Vector3.new(0, 5, 0) end
    return CFrame.new(0, 50, 0)
end

local function AttemptSitInTruck(truck)
    local seat = truck:FindFirstChild("DriveSeat")
    if not seat then seat = truck:FindFirstChild("Drive") or truck:FindFirstChild("VehicleSeat") end
    
    if seat then
        local myChar = LocalPlayer.Character
        local humanoid = myChar and myChar:FindFirstChild("Humanoid")
        local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if humanoid and hrp then
            hrp.CFrame = seat.CFrame + Vector3.new(0, 2, 0)
            seat:Sit(humanoid)
        end
    end
end

local SafetyGroup = Tabs.Settings:AddLeftGroupbox('Safety & Logic')
SafetyGroup:AddToggle('VoidOnDead', {
    Text = 'Void if Dead',
    Default = true,
    Tooltip = 'Teleport car to void if target dies (Prevents glitching)',
})
Toggles.VoidOnDead:OnChanged(function() Settings.VoidOnDead = Toggles.VoidOnDead.Value end)
Settings.VoidOnDead = true

local function RemoveLava()
    local volcano = workspace:FindFirstChild("Region_Volcano")
    if volcano then
        local lava = volcano:FindFirstChild("Lava")
        if lava then
            lava:Destroy()
            Library:Notify("Deleted Volcano Lava", 3)
        end
    end
end
RemoveLava()

workspace.FallenPartsDestroyHeight = -math.huge
Library:Notify("Anti-Void Enabled!", 2)

local ServiceLoop = nil
local function Unload()
    if ServiceLoop then ServiceLoop:Disconnect() end
    Library:Notify('Unloading Script...', 3)
    task.wait(0.5)
    Library:Unload()
end

local ScriptsGroup = Tabs.Settings:AddLeftGroupbox('Script Control')
ScriptsGroup:AddButton('Unload Script', Unload)
ScriptsGroup:AddButton('Remove Lava Manual', RemoveLava)

local ModeOptions = {'Single Target', 'Multi Target', 'Server Wipe'}
RightGroupBox:AddDropdown('KillerMode', {
    Values = ModeOptions,
    Default = 1,
    Multi = false,
    Text = 'Killer Mode',
    Tooltip = 'Select logic type'
})
Settings.KillerMode = 'Single Target'
Options.KillerMode:OnChanged(function() Settings.KillerMode = Options.KillerMode.Value end)

local MultiTargetDropdown = RightGroupBox:AddDropdown('MultiTargets', {
    Values = GetPlayerNames(),
    Default = {},
    Multi = true,
    Text = 'Select Multi Targets',
    Tooltip = 'Select specific players to hunt sequentially'
})

local BringGroup = Tabs.Main:AddRightGroupbox('Quick Bring')
local BringDropdown = BringGroup:AddDropdown('BringTarget', {
    Values = GetPlayerNames(),
    Default = 1,
    Multi = false,
    Text = 'Player to Bring',
    Tooltip = 'Who to bring here?'
})

BringGroup:AddButton('Bring THEM Here', function()
    local targetName = BringDropdown.Value
    local targetPl = Players:FindFirstChild(targetName)
    if not targetPl then return Library:Notify("Target not found!", 2) end
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return Library:Notify("You have no character/HRP!", 2) end

    local myPos = LocalPlayer.Character.PrimaryPart.CFrame
    KillZones['Custom Bring Pos'] = myPos
    
    Settings.SelectedZone = myPos
    Settings.Target = targetPl
    Settings.KillerMode = 'Single Target'
    Settings.StayAtDropoff = true
    
    Options.KillerMode:SetValue('Single Target')
    TargetDropdown:SetValue(targetName)
    Toggles.StayAtDropoff:SetValue(true)
    
    if not Settings.LoopKill then Toggles.LoopKill:SetValue(true) end
    Library:Notify("Bringing " .. targetName .. " to you...", 3)
end)

local TargetQueue = {}
local CurrentTargetName = nil
local waitingForDeath = false 
local deathWaitStart = 0
local processedTrap = false
local lastActionTime = 0
local ActiveVictimChar = nil 

local function PopulateServerQueue()
    TargetQueue = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then table.insert(TargetQueue, pl) end
    end
    Library:Notify("Server Queue Populated: " .. #TargetQueue, 3)
end

local function PopulateMultiQueue()
    TargetQueue = {}
    for name, selected in pairs(Options.MultiTargets.Value) do
        if selected then
            local pl = Players:FindFirstChild(name)
            if pl then table.insert(TargetQueue, pl) end
        end
    end
    Library:Notify("Multi Queue Populated: " .. #TargetQueue, 3)
end

Toggles.LoopKill:OnChanged(function()
    Settings.LoopKill = Toggles.LoopKill.Value
    if Settings.LoopKill then
        if Settings.KillerMode == 'Server Wipe' then
            PopulateServerQueue()
            Settings.Target = nil
        elseif Settings.KillerMode == 'Multi Target' then
            PopulateMultiQueue()
            Settings.Target = nil
        else
            Settings.Target = Players:FindFirstChild(TargetDropdown.Value)
            if not Settings.Target then
                Library:Notify("Select a Single Target first!", 3)
                Toggles.LoopKill:SetValue(false)
            end
        end
    else
        TargetQueue = {}
        waitingForDeath = false
        ActiveVictimChar = nil
    end
end)

ServiceLoop = RunService.RenderStepped:Connect(function()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    if Settings.LoopKill and (Settings.KillerMode == 'Server Wipe' or Settings.KillerMode == 'Multi Target') then
        if not Settings.Target and #TargetQueue > 0 then
            Settings.Target = table.remove(TargetQueue, 1)
            CurrentTargetName = Settings.Target.Name
            Library:Notify("Next Target: " .. CurrentTargetName, 3)
            processedTrap = false
            waitingForDeath = false
            ActiveVictimChar = nil
        end
    end

    if Settings.LoopKill and Settings.Target then
        if not Settings.Target.Parent then Settings.Target = nil return end
        local targetChar = Settings.Target.Character
        
        if waitingForDeath then
            local isDeadOrGone = false
            if not targetChar then isDeadOrGone = true
            elseif ActiveVictimChar and targetChar ~= ActiveVictimChar then isDeadOrGone = true -- Respawned
            else
                local hum = targetChar:FindFirstChild("Humanoid")
                if hum and hum.Health <= 0 then isDeadOrGone = true end
            end

            if Settings.StayAtDropoff and (tick() - deathWaitStart > 2) then isDeadOrGone = true end 

            if isDeadOrGone then
                Library:Notify(Settings.StayAtDropoff and "Dropoff Complete!" or "Target Eliminated!", 2)
                waitingForDeath = false
                ActiveVictimChar = nil
                Settings.Target = nil 
                lastActionTime = tick() + 1
                
                task.spawn(function()
                    SpawnTruck() 
                    if Settings.StayAtDropoff and Settings.SelectedZone then
                        task.wait(1.5)
                        if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                            LocalPlayer.Character:SetPrimaryPartCFrame(Settings.SelectedZone + Vector3.new(0,5,0))
                            task.wait(0.1)
                            LocalPlayer.Character:SetPrimaryPartCFrame(Settings.SelectedZone + Vector3.new(0,5,0))
                        end
                    end
                end)
                return
            elseif tick() - deathWaitStart > 15 then
                Library:Notify("Kill Timeout - Moving Next", 2)
                waitingForDeath = false
                ActiveVictimChar = nil
                Settings.Target = nil
                task.spawn(function()
                    SpawnTruck()
                    if Settings.StayAtDropoff and Settings.SelectedZone then
                        task.wait(1.5)
                        if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
                            LocalPlayer.Character:SetPrimaryPartCFrame(Settings.SelectedZone + Vector3.new(0,5,0))
                        end
                    end
                end)
                return
            end
            return
        end
        
        if not targetChar then return end
        local targetHRP = targetChar:FindFirstChild("HumanoidRootPart") or targetChar.PrimaryPart
        local targetHumanoid = targetChar:FindFirstChild("Humanoid")

        if targetHRP and targetHumanoid then
            if tick() - lastActionTime < 0.05 then return end

            local myTruck = GetVehicle()
            if not myTruck then
                local foundTruck = FindOwnTruck()
                if not foundTruck then
                    SpawnTruck()
                    lastActionTime = tick() + 0.1
                    return 
                else
                    AttemptSitInTruck(foundTruck)
                    lastActionTime = tick()
                    return
                end
            end
            
            local targetSeat = targetHumanoid.SeatPart
            local targetInMyTruck = false
            if targetSeat and targetSeat:IsDescendantOf(myTruck) then 
                targetInMyTruck = true 
            else 
                processedTrap = false
            end

            if targetInMyTruck and Settings.SelectedZone and not processedTrap then
                processedTrap = true
                Library:Notify("Target Trapped! DROPPING OFF!", 2)
                TeleportVehicle(Settings.SelectedZone, true)
                
                local myChar = LocalPlayer.Character
                if myChar and myChar:FindFirstChild("Humanoid") then myChar.Humanoid.Sit = false end
                
                task.wait(0.2)
                
                local basePos = GetBasePosition()
                if myChar and myChar.PrimaryPart then
                    myChar:SetPrimaryPartCFrame(basePos)
                    task.wait(0.1)
                    myChar:SetPrimaryPartCFrame(basePos)
                end
                
                SpawnTruck()
                
                waitingForDeath = true
                deathWaitStart = tick()
                ActiveVictimChar = targetChar
                Library:Notify("Waiting for confirm kill...", 2)
                lastActionTime = tick() + 1
                return
            elseif targetInMyTruck then
            else
                TeleportVehicle(targetHRP.CFrame)
            end
        end
    end
end)

local PlrGroup = Tabs.Player:AddLeftGroupbox('Player Stats')
PlrGroup:AddSlider('WalkSpeed', {
    Text = 'Walk Speed', Default = 16, Min = 16, Max = 500, Rounding = 0,
    Callback = function(Value) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = Value end end
})
PlrGroup:AddSlider('JumpPower', {
    Text = 'Jump Power', Default = 50, Min = 50, Max = 500, Rounding = 0,
    Callback = function(Value) if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.UseJumpPower = true LocalPlayer.Character.Humanoid.JumpPower = Value end end
})

local OriginalFallHeight = workspace.FallenPartsDestroyHeight
PlrGroup:AddToggle('AntiVoid', {
    Text = 'Anti-Void (Remove Void Kill)', Default = false,
    Tooltip = 'Sets FallenPartsDestroyHeight to -math.huge (no void death)',
    Callback = function(Value)
        if Value then
            workspace.FallenPartsDestroyHeight = -math.huge
            Library:Notify("Anti-Void: Void kill removed!", 2)
        else
            workspace.FallenPartsDestroyHeight = OriginalFallHeight
            Library:Notify("Anti-Void: Void kill restored", 2)
        end
    end
})

local FlightGroup = Tabs.Player:AddRightGroupbox('Flight')
local FlightEnabled = false
local FlightSpeed = 50
FlightGroup:AddToggle('FlightToggle', {
    Text = 'Enable Flight', Default = false,
    Callback = function(Value)
        FlightEnabled = Value
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if Value then
            task.spawn(function()
                local bv = Instance.new("BodyVelocity")
                bv.Velocity = Vector3.new(0,0,0)
                bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bv.Parent = hrp
                
                local bg = Instance.new("BodyGyro")
                bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bg.P = 10000 
                bg.D = 50
                bg.Parent = hrp
                
                if hum then hum.PlatformStand = true end
                
                while FlightEnabled and char.Parent do
                    local cam = workspace.CurrentCamera
                    local moveDir = Vector3.new(0,0,0)
                    local uis = game:GetService("UserInputService")
                    
                    if uis:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
                    if uis:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
                    if uis:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
                    if uis:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
                    
                    if uis:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
                    if uis:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0,1,0) end
                    
                    bv.Velocity = moveDir.Unit * FlightSpeed 
                    if moveDir.Magnitude < 0.1 then bv.Velocity = Vector3.new(0,0,0) end 
                    
                    bg.CFrame = cam.CFrame
                    
                    task.wait()
                end
                
                bv:Destroy()
                bg:Destroy()
                if hum then hum.PlatformStand = false end
            end)
        else
            if hum then hum.PlatformStand = false end
            if hrp then
                for _, v in pairs(hrp:GetChildren()) do
                    if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
                end
            end
        end
    end
}):AddKeyPicker('FlightKey', { Default = 'X', SyncToggleState = true, Mode = 'Toggle', Text = 'Flight Toggle', NoUI = false })
FlightGroup:AddSlider('FlightSpeed', { Text = 'Flight Speed', Default = 50, Min = 10, Max = 300, Rounding = 1, Callback = function(Value) FlightSpeed = Value end })

local DragGroup = Tabs.Tools:AddLeftGroupbox('Dragger Mods')

local DraggerEnabled = false
DragGroup:AddToggle('HardDragger', {
    Text = 'Hard Dragger / Max Force', Default = false, Tooltip = 'Boosts dragging force',
    Callback = function(Value)
        DraggerEnabled = Value
        if Value then
            Library:Notify("Dragger Boost Active", 3)
                    task.spawn(function()
                        while DraggerEnabled do
                            pcall(function()
                                if LocalPlayer.Character then
                                    for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                                        if v:IsA("BodyPosition") then
                                            v.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                            v.P = 100000; v.D = 1000
                                        elseif v:IsA("BodyGyro") then
                                            v.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                                            v.P = 100000; v.D = 1000
                                        end
                                    end
                                end
                                
                                local mouse = LocalPlayer:GetMouse()
                                if mouse and mouse.Target then
                                    local tgt = mouse.Target
                                    if tgt:FindFirstChild("BodyPosition") then
                                        tgt.BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                        tgt.BodyPosition.P = 100000; tgt.BodyPosition.D = 1000
                                    end
                                    if tgt:FindFirstChild("BodyGyro") then
                                        tgt.BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                                        tgt.BodyGyro.P = 100000; tgt.BodyGyro.D = 1000
                                    end
                                    
                                    if tgt.Parent and tgt.Parent:IsA("Model") then
                                        for _, v in pairs(tgt.Parent:GetChildren()) do
                                            if v:IsA("BodyPosition") then
                                                v.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                                                v.P = 100000; v.D = 1000
                                            elseif v:IsA("BodyGyro") then
                                                v.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                                                v.P = 100000; v.D = 1000
                                            end
                                        end
                                    end
                                end
                            end)
                            task.wait(0) 
                        end
                    end)
        end
    end
})

DragGroup:AddButton('Boost Drag Force (Manual)', function()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "BodyPosition" then obj.MaxForce = Vector3.new(math.huge, math.huge, math.huge) end
    end
    Library:Notify("Boosted all BodyPositions!", 3)
end)

DragGroup:AddButton('Teleport Wood to Me', function()
    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then return end
    local myPos = LocalPlayer.Character.PrimaryPart.CFrame
    local count = 0
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "Wood" and v:FindFirstChild("Owner") and tostring(v.Owner.Value) == LocalPlayer.Name then
            if v:IsA("Model") and v.PrimaryPart then v:SetPrimaryPartCFrame(myPos) count = count + 1
            elseif v:IsA("BasePart") then v.CFrame = myPos count = count + 1 end
        end
    end
    Library:Notify("Moved " .. count .. " wood pieces", 3)
end)

Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('AntigravityLT2')
SaveManager:SetFolder('AntigravityLT2/configs')
if SaveManager.BuildConfigSection then SaveManager:BuildConfigSection(Tabs.Settings) end
ThemeManager:ApplyToTab(Tabs.Settings)
Library:Notify('Enhanced LT2 Car Killer Loaded!', 5)
