-- GRENADE TP – Unnamed addon

---------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------

api:set_lua_name("grenade_tp")

api:on_event("unload", function()
    api:notify("Grenade TP unloaded", 2)
end)

---------------------------------------------------------------------
-- STATE
---------------------------------------------------------------------

local OWNER = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

local Active = false
local hbConnection
local ProcessedGrenades = {}
local GrenadeAttachments = {} -- New table to store attachments

---------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------

local function Notify(msg, duration)
    api:notify(msg or "", duration or 1)
end

local function has_character(plr)
    return plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
end

---------------------------------------------------------------------
-- GRENADE TP LOGIC
---------------------------------------------------------------------

local function setup_grenade(grenade)
    if ProcessedGrenades[grenade] then return end
    ProcessedGrenades[grenade] = true
    
    -- Network ownership
    pcall(function()
        sethiddenproperty(OWNER, "SimulationRadius", math.huge)
    end)
    
    -- Destroy all physics constraints
    for _, v in pairs(grenade:GetChildren()) do
        if v:IsA("BodyMover") or v:IsA("Constraint") then
            v:Destroy()
        end
    end
    
    -- Set the grenade properties
    grenade.Anchored = false
    grenade.CanCollide = false
    grenade.CanTouch = false
    grenade.Massless = true
    
    pcall(function()
        -- Fix density warning (0 -> 0.01)
        grenade.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0)
    end)
    
    -- Add BodyPosition (User requested)
    local bp = Instance.new("BodyPosition", grenade)
    bp.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bp.P = 100000 -- High P for responsiveness
    bp.D = 1000   -- Damping
    bp.Position = grenade.Position -- Initial pos
    
    -- Add BodyGyro to stop spinning
    local bg = Instance.new("BodyGyro", grenade)
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.P = 100000
    bg.CFrame = grenade.CFrame
    
    -- Store BodyPosition for updating
    GrenadeAttachments[grenade] = bp
    
    -- Add highlight
    if not grenade:FindFirstChildWhichIsA("Highlight") then
        local hl = Instance.new("Highlight", grenade)
        hl.OutlineColor = Color3.fromRGB(255, 0, 0)
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.FillTransparency = 0.3
    end
    
    -- Cleanup when destroyed
    grenade.Destroying:Connect(function()
        ProcessedGrenades[grenade] = nil
        GrenadeAttachments[grenade] = nil
    end)
end

local function teleport_grenades()
    if not has_character(OWNER) then return end
    
    -- Get silent aim target
    local TARGET = api:get_target("silent")
    if not TARGET then
        local cache = api:get_target_cache("silent")
        if cache and cache.player then 
            TARGET = cache.player 
        end
    end

    if not TARGET then 
        return 
    end
    if not has_character(TARGET) then return end
    
    local target_hrp = TARGET.Character.HumanoidRootPart
    
    -- Find and teleport grenades
    for _, obj in pairs(workspace.Ignored:GetChildren()) do
        if obj:IsA("BasePart") and not obj.Anchored then
            -- Check if it's a grenade
            local name_lower = obj.Name:lower()
            local is_grenade = not (name_lower:find("snow") or name_lower:find("ball") or name_lower:find("rocket") or name_lower:find("ammo"))
            
            if is_grenade then
                -- print("Found grenade: " .. obj.Name)
                -- Setup grenade on first detection
                if not ProcessedGrenades[obj] then
                    setup_grenade(obj)
                end
                
                -- Update BodyPosition
                local bp = GrenadeAttachments[obj]
                if bp then
                    bp.Position = target_hrp.Position
                end
                
                -- Sticky Physics
                pcall(function()
                    sethiddenproperty(obj, "PhysicsRepRootPart", target_hrp)
                end)

                -- Also directly set properties as backup
                obj.Velocity = Vector3.new(0, 0, 0)
                obj.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                obj.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                obj.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
    
    -- Cleanup destroyed grenades
    for grenade, _ in pairs(ProcessedGrenades) do
        if not grenade or not grenade.Parent then
            ProcessedGrenades[grenade] = nil
            GrenadeAttachments[grenade] = nil
        end
    end
end

---------------------------------------------------------------------
-- UI
---------------------------------------------------------------------

local tabs = {
    lua = api:GetTab("ragebot") or api:AddTab("ragebot")
}

do
    local groupbox = tabs.lua:AddLeftGroupbox("Grenade TP")

    -- Start toggle
    groupbox:AddToggle("grenade_active", {
        Text = "Grenade TP (Stick)",
        Default = false
    }):OnChanged(function(v)
        Active = v
        
        if Active then
            ProcessedGrenades = {}
            
            if hbConnection then
                hbConnection:Disconnect()
            end

            hbConnection = api:add_connection(
                RunService.Heartbeat:Connect(function()
                    teleport_grenades()
                end)
            )
            
            Notify("Grenade TP Enabled - Sticks to Silent Target", 2)
        else
            if hbConnection then
                hbConnection:Disconnect()
                hbConnection = nil
            end
            
            ProcessedGrenades = {}
            Notify("Grenade TP Disabled", 2)
        end
    end)
    
    groupbox:AddButton("Buy Grenade", function()
        task.spawn(function()
            repeat task.wait(0.1) until api:can_desync()
            pcall(function()
                api:buy_item("[Grenade] - $788", false, false)
            end)
            Notify("Bought Grenade", 1)
        end)
    end)
    
    groupbox:AddButton("Throw All Grenades", function()
        task.spawn(function()
            local count = 0
            
            for _, tool in ipairs(OWNER.Backpack:GetChildren()) do
                if tool.Name == "[Grenade]" or tool.Name == "Grenade" then
                    count += 1
                end
            end
            
            if count == 0 then
                Notify("No grenades!", 1)
                return
            end
            
            Notify("Throwing " .. count .. " grenades!", 2)
            
            for _, tool in ipairs(OWNER.Backpack:GetChildren()) do
                if tool.Name == "[Grenade]" or tool.Name == "Grenade" then
                    tool.Parent = OWNER.Character
                    task.wait(0.05)
                    tool:Activate()
                    task.wait(0.05)
                    tool:Activate()
                    task.wait(0.02)
                end
            end
            
            Notify("💣 Grenades Deployed! 💣", 2)
        end)
    end)
end

Notify("Grenade TP Loaded", 2)
