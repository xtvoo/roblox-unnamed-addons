-- BOMBASTIC – Unnamed addon

---------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------

api:set_lua_name("bombastic_addon")

api:on_event("unload", function()
    api:notify("Bombastic addon unloaded", 2)
end)

---------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------

local UnanchoredPart
local OWNER = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Whitelist = {}
local OriginalVelocity = {}
local Mode = "Target"
local Activated = false
local Active = false
local TARGET
local Random = false
local Prediction = 0.8
local Distance = 50
local speed = 5
local axes = {x = 8, y = 8, z = 8}
local Force = Vector3.new(-10000,-10000,-10000)
local old
local PhoneCall = true
local hbConnection

---------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------

local function Notify(msg, duration)
    api:notify(msg or "", duration or 1)
end

for _, v in pairs(workspace.MAP:GetChildren()) do
    if v:IsA("Part") and not v.Anchored then
        print(v:GetFullName())
        UnanchoredPart = v
        v.Transparency = 0
        Notify("Part Found", 1)
    end
end

if not UnanchoredPart then 
    Notify("No Part Found.", 1)
    return 
end

local function Play_(ID)
    if PhoneCall then
        ReplicatedStorage.MainEvent:FireServer("RingTone", ID)
        local Tool = nil
        if OWNER.Character:FindFirstChildWhichIsA("Tool") then
            Tool = OWNER.Character:FindFirstChildWhichIsA("Tool")
            OWNER.Character:FindFirstChildWhichIsA("Tool").Parent = OWNER.Backpack
        end
        if OWNER.Backpack:FindFirstChild("[Phone]") then
            OWNER.Backpack["[Phone]"].Parent = OWNER.Character
        end
        if OWNER.Character:FindFirstChild("[Phone]") then
            OWNER.Character["[Phone]"].Parent = OWNER.Backpack
        end
        if Tool then
            Tool.Parent = OWNER.Character
        end
    end
end

local function grange()
    local Body = {}
    table.foreach(game:GetService("Players"):GetPlayers(), function(_, v)
        if v.Character 
            and v ~= OWNER 
            and not table.find(Whitelist, v.Name) 
            and v.Character:FindFirstChild("BodyEffects") 
            and v.Character.BodyEffects:FindFirstChild("K.O") 
            and v.Character.BodyEffects["K.O"].Value == true
            and v.Character:FindFirstChild("UpperTorso") 
            and v:FindFirstChild("DataFolder") 
            and v.DataFolder:FindFirstChild("Information") 
            and ((v.DataFolder.Information:FindFirstChild("Crew") 
            and v.DataFolder.Information.Crew.Value ~= OWNER.DataFolder.Information.Crew.Value) 
            or not v.DataFolder.Information:FindFirstChild("Crew")) 
            and (v.Character.UpperTorso.Position - OWNER.Character.HumanoidRootPart.Position).Magnitude <= Distance
            and math.abs(v.Character.UpperTorso.AssemblyAngularVelocity.Magnitude) < 75 then
            table.insert(Body, v)
        end
    end)

    table.sort(Body, function(a, b)
        return (a.Character.UpperTorso.Position - OWNER.Character.HumanoidRootPart.Position).Magnitude < (b.Character.UpperTorso.Position - OWNER.Character.HumanoidRootPart.Position).Magnitude
    end)

    return #Body > 0 and Body[1].Character.UpperTorso.Position or nil
end

local function gnearest()
    local Body = nil
    local distancee = Distance
    for _, v in pairs(game:GetService("Players"):GetPlayers()) do
        if v ~= OWNER and not table.find(Whitelist, v.Name) and v.Character and v.Character:FindFirstChild("BodyEffects") and v.Character:FindFirstChild("BodyEffects"):FindFirstChild("K.O") and v.Character:FindFirstChild("Humanoid").Sit == false then
            if OWNER:DistanceFromCharacter(v.Character.UpperTorso.Position) < distancee then
                Body = v
                distancee = OWNER:DistanceFromCharacter(v.Character.UpperTorso.Position)
            end
        end
    end
    return Body
end

local function gplr(String)
    local Body
    for _, v in pairs(game:GetService("Players"):GetPlayers()) do
        if v.Name:lower():sub(1, #String) == String:lower() or v.DisplayName:lower():sub(1, #String) == String:lower() then
            if v ~= OWNER and v.Character:FindFirstChild("Humanoid").Sit == false then
                Body = v
            end
        end
    end
    return Body
end

local function Velocity(Plr)
    if Plr.Character and Plr.Character:FindFirstChild("Humanoid") then
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
    if not OWNER.Character or not OWNER.Character:FindFirstChild("UpperTorso") then
        return
    end
    
    local bp = UnanchoredPart:FindFirstChildWhichIsA("BodyPosition")
    if not bp then
        bp = Instance.new("BodyPosition", UnanchoredPart)
    end
    
    local bt = UnanchoredPart:FindFirstChildWhichIsA("BodyThrust")
    if not bt then
        bt = Instance.new("BodyThrust", UnanchoredPart)
    end
    
    if Random then
        bp.Position = OWNER.Character.UpperTorso.Position + Vector3.new(math.random(-axes.x, axes.x), math.random(-axes.y, axes.y), math.random(-axes.z, axes.z))
    else
        bp.Position = OWNER.Character.UpperTorso.Position + Vector3.new(0, axes.y, 0)
    end
    bt.Location = OWNER.Character.UpperTorso.Position
end

local function DestroyIsA(typeof)
    if UnanchoredPart:FindFirstChildWhichIsA(typeof) then
        UnanchoredPart:FindFirstChildWhichIsA(typeof):Destroy()
    end
end

local function updatestate(index, state)
    pcall(function()
        if sethiddenproperty then
            sethiddenproperty(index, "BackendAccoutrementState", state)
        elseif setscriptable then
            setscriptable(index, "BackendAccoutrementState", true)
            index.BackendAccoutrementState = state
        else
            index.BackendAccoutrementState = state
        end
    end)
end

-- Try to update state (will silently fail if not an accessory)
updatestate(UnanchoredPart, 4)
task.wait(0.4)
local lock = UnanchoredPart.Changed:Connect(function(p)
    if p == "BackendAccoutrementState" then
        updatestate(UnanchoredPart, 0)
    end
end)
updatestate(UnanchoredPart, 2)
task.wait(1)
lock:Disconnect()
updatestate(UnanchoredPart, 4)

-- Pre-create BodyPosition and BodyThrust
if not UnanchoredPart:FindFirstChildWhichIsA("BodyPosition") then
    local bp = Instance.new("BodyPosition", UnanchoredPart)
    bp.MaxForce = Vector3.new(0, 0, 0)
end
if not UnanchoredPart:FindFirstChildWhichIsA("BodyThrust") then
    Instance.new("BodyThrust", UnanchoredPart)
end

---------------------------------------------------------------------
-- UI
---------------------------------------------------------------------

local tabs = {
    lua = api:GetTab("ragebot") or api:AddTab("ragebot")
}

do
    local groupbox = tabs.lua:AddLeftGroupbox("Part Fling")

    -- Mode dropdown
    groupbox:AddDropdown("bomb_mode", {
        Text = "Mode",
        Default = "Target",
        Values = {"Target", "Nearest", "KO", "Key", "Constant"}
    }):OnChanged(function(v)
        Mode = v
        Notify("Current Mode: " .. v, 1)
    end)

    -- Start toggle
    groupbox:AddToggle("bomb_active", {
        Text = "Start",
        Default = false
    }):OnChanged(function(v)
        Active = v
        if Active and UnanchoredPart and UnanchoredPart.CanCollide then
            if hbConnection then
                hbConnection:Disconnect()
            end

            hbConnection = api:add_connection(
                game:GetService("RunService").Heartbeat:Connect(function()
                    UnanchoredPart.CanCollide = false
                    UnanchoredPart.CanTouch = false
                    pcall(function()
                        sethiddenproperty(OWNER, "SimulationRadius", math.huge)
                        UnanchoredPart.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
                    end)

                    if not UnanchoredPart:FindFirstChildWhichIsA("BodyPosition") then
                        Instance.new("BodyPosition", UnanchoredPart)
                    end
                    if not UnanchoredPart:FindFirstChildWhichIsA("BodyThrust") then
                        Instance.new("BodyThrust", UnanchoredPart)
                    end
                    if not UnanchoredPart:FindFirstChildWhichIsA("Highlight") then
                        Instance.new("Highlight", UnanchoredPart)
                    end

                    UnanchoredPart.BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    UnanchoredPart.BodyPosition.P = 10000
                    UnanchoredPart.BodyPosition.D = 175
                    UnanchoredPart.Velocity = Vector3.new(0, -87, 0)

                    local hl = UnanchoredPart:FindFirstChildWhichIsA("Highlight")
                    if hl then
                        local hsv = tick() % 5 / 5
                        hl.OutlineTransparency = 0
                        hl.FillTransparency = 0
                        hl.OutlineColor = Color3.fromHSV(hsv, 1, 1)
                        hl.FillColor = Color3.fromHSV(hsv, 1, 1)
                    end

                    if OWNER.Character and OWNER.Character:FindFirstChild("BodyEffects") 
                        and OWNER.Character.BodyEffects:FindFirstChild("K.O")
                        and OWNER.Character.BodyEffects["K.O"].Value == false then
                        if Mode == "Target" then
                            if Activated == false then
                                Spawn()
                            else
                                if TARGET then
                                    UnanchoredPart.BodyThrust.Force = Force
                                    UnanchoredPart.BodyPosition.Position = TARGET.Character.HumanoidRootPart.Position + (OriginalVelocity[1] * Prediction)
                                    UnanchoredPart.BodyThrust.Location = TARGET.Character.HumanoidRootPart.Position
                                else
                                    Spawn()
                                end
                            end
                        elseif Mode == "Nearest" then
                            TARGET = gnearest()
                            if TARGET == nil then
                                Spawn()
                            else
                                if TARGET.Character:FindFirstChild("BodyEffects"):FindFirstChild("K.O").Value == true then
                                    UnanchoredPart.BodyThrust.Force = Force
                                    UnanchoredPart.BodyPosition.Position = TARGET.Character.UpperTorso.Position
                                    UnanchoredPart.BodyThrust.Location = TARGET.Character.UpperTorso.Position
                                else
                                    UnanchoredPart.BodyThrust.Force = Force
                                    UnanchoredPart.BodyPosition.Position = TARGET.Character.HumanoidRootPart.Position + (OriginalVelocity[1] * Prediction)
                                    UnanchoredPart.BodyThrust.Location = TARGET.Character.HumanoidRootPart.Position
                                end
                            end
                        elseif Mode == "KO" then
                            TARGET = grange()
                            if TARGET == nil then
                                Spawn()
                            else
                                UnanchoredPart.BodyThrust.Force = Force
                                UnanchoredPart.BodyPosition.Position = TARGET
                                UnanchoredPart.BodyThrust.Location = TARGET
                            end
                        elseif Mode == "Key" then
                            if Activated == false then
                                Spawn()
                            else
                                UnanchoredPart.BodyThrust.Force = Force
                                UnanchoredPart.BodyPosition.Position = OWNER:GetMouse().Hit.p
                                UnanchoredPart.BodyThrust.Location = OWNER.Character.HumanoidRootPart.Position
                            end
                        elseif Mode == "Constant" then
                            Spawn()
                        end
                    else
                        DestroyIsA("BodyThrust")
                        UnanchoredPart.Velocity = Vector3.zero
                        UnanchoredPart.AssemblyAngularVelocity = Vector3.zero
                        UnanchoredPart.AssemblyLinearVelocity = Vector3.zero
                        UnanchoredPart.CanCollide = false
                        if UnanchoredPart:FindFirstChildWhichIsA("BodyPosition") then
                            UnanchoredPart.BodyPosition.Position = Vector3.new(0, 100, 0)
                        end
                    end
                end)
            )
        else
            if hbConnection then
                hbConnection:Disconnect()
                hbConnection = nil
            end
            DestroyIsA("BodyPosition")
            DestroyIsA("BodyThrust")
            UnanchoredPart.Velocity = Vector3.zero
            UnanchoredPart.AssemblyAngularVelocity = Vector3.zero
            UnanchoredPart.AssemblyLinearVelocity = Vector3.zero
            UnanchoredPart.CanCollide = true
            UnanchoredPart.Position = Vector3.new(0, 100, 0)
        end
    end)

    -- Random toggle
    groupbox:AddToggle("bomb_random", {
        Text = "Random",
        Default = false
    }):OnChanged(function(v)
        Random = v
    end)

    -- Prediction slider
    groupbox:AddSlider("bomb_prediction", {
        Text = "Prediction",
        Default = Prediction * 100,
        Min = 0,
        Max = 100,
        Rounding = 1,
    }):OnChanged(function(v)
        Prediction = v / 100
    end)

    groupbox:AddSlider("bomb_distance", {
        Text = "Distance",
        Default = Distance,
        Min = 0,
        Max = 100,
        Rounding = 0,
    }):OnChanged(function(v)
        Distance = v
    end)

    groupbox:AddSlider("bomb_speed", {
        Text = "Speed",
        Default = speed,
        Min = 0,
        Max = 10,
        Rounding = 1,
    }):OnChanged(function(v)
        speed = v
    end)

    for axis, def in pairs(axes) do
        groupbox:AddSlider("bomb_axis_" .. axis, {
            Text = axis:upper(),
            Default = def,
            Min = -100,
            Max = 100,
            Rounding = 0,
        }):OnChanged(function(v)
            axes[axis] = v
        end)
    end

    groupbox:AddButton("Network to Part", function()
        for _, v in pairs(workspace.MAP:GetChildren()) do
            if v:IsA("Part") and not v.Anchored then
                old = OWNER.Character.HumanoidRootPart.CFrame
                OWNER.Character.HumanoidRootPart.CFrame = v.CFrame
                task.wait(0.1)
                OWNER.Character.HumanoidRootPart.CFrame = old
                old = nil
                Notify("Network Refreshed", 1)
            end
        end
    end)

    groupbox:AddButton("Tp to Part", function()
        for _, v in pairs(workspace.MAP:GetChildren()) do
            if v:IsA("Part") and not v.Anchored then
                OWNER.Character.HumanoidRootPart.CFrame = v.CFrame
            end
        end
    end)
end

---------------------------------------------------------------------
-- CHAT / INPUT / VELOCITY CONNECTIONS
---------------------------------------------------------------------

api:add_connection(OWNER.Chatted:Connect(function(message)
    local args = message:split(" ")
    if args[1] == ":smite" then
        if #args > 1 then
            TARGET = gplr(args[2])
            if TARGET and Active and Mode == "Target" then
                Activated = false
                Activated = true
                Play_(75276138090264)
                task.wait(1)
                Activated = false
            end
        end
    elseif args[1] == ":w" then
        if #args > 1 then
            TARGET = gplr(args[2])
            if TARGET and not table.find(Whitelist, TARGET.Name) then
                table.insert(Whitelist, TARGET.Name)
                Notify("Whitelisted: " .. TARGET.Name, 1)
            end
        end
    elseif args[1] == ":uw" then
        if #args > 1 then
            TARGET = gplr(args[2])
            if TARGET then
                local index = table.find(Whitelist, TARGET.Name)
                if index then
                    table.remove(Whitelist, index)
                    Notify("Unwhitelisted: " .. TARGET.Name, 1)
                end
            end
        end
    end
end))

api:add_connection(game:GetService("UserInputService").InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.E and Active and Mode == "Key" then
        Activated = false
        Activated = true
        Play_(8053992294)
        task.wait(0.3)
        Activated = false
    elseif input.KeyCode == Enum.KeyCode.Z then
        Play_(6336173728)
        task.wait(0.15)
        OWNER.Character.HumanoidRootPart.CFrame = OWNER.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -25)
    end
end))

api:add_connection(game:GetService("RunService").Heartbeat:Connect(function()
    if TARGET and typeof(TARGET) == "Instance" then
        OriginalVelocity[1] = Velocity(TARGET)
    end
end))
