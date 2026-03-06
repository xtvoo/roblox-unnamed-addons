--[[
    Unnamed Addon: Anti-Aim Protection v2.0
    Simple & Clean - Detect aim via mouse position, add to ragebot, remove when knocked
]]

api:set_lua_name("AntiAimProtection")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Ragebot target list
getgenv().RagebotTargetList = getgenv().RagebotTargetList or {}
getgenv().AntiAimWhitelist = getgenv().AntiAimWhitelist or {}

-- UI
local tabs = { Combat = api:GetTab("combat") or api:AddTab("combat") }
local sec = tabs.Combat:AddLeftGroupbox("Anti-Aim Protection")

local Enable = sec:AddToggle("AAP_Enable", { Text = "Enable", Default = false })
local IgnoreCrew = sec:AddToggle("AAP_IgnoreCrew", { Text = "Ignore Crew", Default = true })
local IgnoreFriends = sec:AddToggle("AAP_IgnoreFriends", { Text = "Ignore Friends", Default = true })
local AimDist = sec:AddSlider("AAP_AimDist", { Text = "Detection Range", Default = 150, Min = 10, Max = 300, Rounding = 0 })
local AimThreshold = sec:AddSlider("AAP_Threshold", { Text = "Aim Precision", Default = 5, Min = 1, Max = 20, Rounding = 1, Tooltip = "How close to you their mouse needs to be (studs)" })

-- Whitelist
local sec2 = tabs.Combat:AddRightGroupbox("Whitelist")
local WLInput = sec2:AddInput("AAP_WL", { Text = "Username", Default = "" })
sec2:AddButton({ Text = "Add", Func = function()
    local n = WLInput.Value
    if n ~= "" then
        getgenv().AntiAimWhitelist[n:lower()] = true
        api:notify("Added " .. n, 2)
        WLInput:SetValue("")
    end
end })
sec2:AddButton({ Text = "Remove", Func = function()
    local n = WLInput.Value
    if n ~= "" then
        getgenv().AntiAimWhitelist[n:lower()] = nil
        api:notify("Removed " .. n, 2)
        WLInput:SetValue("")
    end
end })
sec2:AddButton({ Text = "Clear All", Func = function()
    getgenv().AntiAimWhitelist = {}
    api:notify("Whitelist cleared", 2)
end })

-- Helpers
local function isKnocked(p)
    local status = api:get_status_cache(p)
    if status and status["K.O"] then return true end
    local c = p.Character
    if not c then return true end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return true end
    local ko = c:FindFirstChild("BodyEffects") and c.BodyEffects:FindFirstChild("KO")
    if ko and ko.Value then return true end
    return false
end

local function hasGun(p)
    local c = p.Character
    if not c then return false end
    local tool = c:FindFirstChildOfClass("Tool")
    if not tool then return false end
    
    local gunNames = {"glock", "revolver", "ak", "ar", "shotgun", "smg", "rifle", "deagle", 
                      "uzi", "mac", "mp", "double", "silencer", "tec", "draco", "rpg",
                      "tactical", "combat", "golden", "laser"}
    local name = tool.Name:lower()
    for _, g in ipairs(gunNames) do
        if name:find(g) then return true end
    end
    
    -- Check for gun handle
    local handle = tool:FindFirstChild("Handle")
    if handle then
        -- Most guns have specific sounds or effects
        if tool:FindFirstChild("Fire") or tool:FindFirstChild("Shoot") or 
           tool:FindFirstChild("GunSound") or tool:FindFirstChild("ShootSound") then
            return true
        end
    end
    
    return false
end

local function isInCrew(p)
    local myData = LocalPlayer:FindFirstChild("DataFolder")
    local theirData = p:FindFirstChild("DataFolder")
    if myData and theirData then
        local myCrew = myData:FindFirstChild("Information") and myData.Information:FindFirstChild("Crew")
        local theirCrew = theirData:FindFirstChild("Information") and theirData.Information:FindFirstChild("Crew")
        if myCrew and theirCrew and myCrew.Value ~= "" and myCrew.Value == theirCrew.Value then
            return true
        end
    end
    return false
end

local function isFriend(p)
    local ok, res = pcall(function() return LocalPlayer:IsFriendsWith(p.UserId) end)
    return ok and res
end

local function isWhitelisted(p)
    return getgenv().AntiAimWhitelist[p.Name:lower()] or getgenv().AntiAimWhitelist[p.DisplayName:lower()]
end

local function shouldIgnore(p)
    if p == LocalPlayer then return true end
    if isWhitelisted(p) then return true end
    if IgnoreCrew.Value and isInCrew(p) then return true end
    if IgnoreFriends.Value and isFriend(p) then return true end
    return false
end

local function getMouseTarget(p)
    -- Get their mouse position from character
    local c = p.Character
    if not c then return nil end
    
    local head = c:FindFirstChild("Head")
    if not head then return nil end
    
    -- Use the direction their head/camera is facing
    local lookDir = head.CFrame.LookVector
    local origin = head.Position
    
    -- Raycast to see what they're aiming at
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {c}
    
    local ray = workspace:Raycast(origin, lookDir * 500, rayParams)
    if ray then
        return ray.Position
    end
    return origin + lookDir * 500
end

local function isAimingAtMe(p)
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return false end
    
    local theirChar = p.Character
    local theirHead = theirChar and theirChar:FindFirstChild("Head")
    local theirHRP = theirChar and theirChar:FindFirstChild("HumanoidRootPart")
    if not theirHead or not theirHRP then return false end
    
    -- Distance check
    local dist = (myHRP.Position - theirHRP.Position).Magnitude
    if dist > AimDist.Value then return false end
    
    -- Get their aim direction
    local lookDir = theirHead.CFrame.LookVector
    local toMe = (myHRP.Position - theirHead.Position)
    local toMeUnit = toMe.Unit
    
    -- Calculate how close their aim is to pointing at me
    local dot = lookDir:Dot(toMeUnit)
    
    -- Also calculate actual distance from their aim line to my position
    -- This gives us a stud-based threshold
    local aimPoint = theirHead.Position + lookDir * toMe.Magnitude
    local missDistance = (aimPoint - myHRP.Position).Magnitude
    
    -- They're aiming at me if:
    -- 1. They're looking in my general direction (dot > 0.8)
    -- 2. Their aim line passes within threshold studs of me
    return dot > 0.8 and missDistance < AimThreshold.Value
end

local function addToRagebot(p)
    if getgenv().RagebotTargetList[p.UserId] then return end
    
    getgenv().RagebotTargetList[p.UserId] = {
        player = p,
        addedAt = tick()
    }
    
    -- Set as primary target for ragebot
    local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        -- Unnamed API integration
        if api.set_target then
            pcall(function() api:set_target(hrp) end)
        end
        if api.add_ragebot_target then
            pcall(function() api:add_ragebot_target(p) end)
        end
    end
    
    -- Global vars for other scripts
    getgenv().RagebotTarget = p
    _G.RagebotTarget = p
    
    -- China Hat integration
    if getgenv().AddChinaHatThreat then
        getgenv().AddChinaHatThreat(p)
    end
    if getgenv().SetChinaHatRagebotTarget then
        getgenv().SetChinaHatRagebotTarget(p)
    end
    
    api:notify("⚠ " .. p.DisplayName .. " added to ragebot", 2)
end

local function removeFromRagebot(p)
    if not getgenv().RagebotTargetList[p.UserId] then return end
    
    getgenv().RagebotTargetList[p.UserId] = nil
    
    -- Remove from China Hat
    if getgenv().RemoveChinaHatThreat then
        getgenv().RemoveChinaHatThreat(p)
    end
    
    -- Clear if was primary target
    if getgenv().RagebotTarget == p then
        getgenv().RagebotTarget = nil
        _G.RagebotTarget = nil
    end
end

-- Main loop
local conn = nil

local function check()
    if not Enable.Value then return end
    
    local myChar = LocalPlayer.Character
    if not myChar or isKnocked(LocalPlayer) then return end
    
    for _, p in ipairs(Players:GetPlayers()) do
        if shouldIgnore(p) then continue end
        
        -- Remove from ragebot if knocked
        if isKnocked(p) then
            removeFromRagebot(p)
            continue
        end
        
        -- Only check players with guns
        if not hasGun(p) then
            removeFromRagebot(p)
            continue
        end
        
        -- Check if aiming at me
        if isAimingAtMe(p) then
            addToRagebot(p)
        else
            -- Remove if no longer aiming (with small delay to prevent flicker)
            local data = getgenv().RagebotTargetList[p.UserId]
            if data and tick() - data.addedAt > 1 then
                removeFromRagebot(p)
            end
        end
    end
    
    -- Get closest threat as primary target
    local closest = nil
    local closestDist = math.huge
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    
    if myHRP then
        for uid, data in pairs(getgenv().RagebotTargetList) do
            local p = data.player
            if p and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (myHRP.Position - hrp.Position).Magnitude
                    if d < closestDist then
                        closestDist = d
                        closest = p
                    end
                end
            end
        end
        
        if closest then
            getgenv().RagebotTarget = closest
            _G.RagebotTarget = closest
            local hrp = closest.Character and closest.Character:FindFirstChild("HumanoidRootPart")
            if hrp and api.set_target then
                pcall(function() api:set_target(hrp) end)
            end
        end
    end
end

Enable:OnChanged(function()
    if Enable.Value then
        if not conn then
            conn = RunService.Heartbeat:Connect(check)
            api:add_connection(conn)
        end
        api:notify("Anti-Aim Protection ON", 2)
    else
        getgenv().RagebotTargetList = {}
        api:notify("Anti-Aim Protection OFF", 2)
    end
end)

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(p)
    getgenv().RagebotTargetList[p.UserId] = nil
end)

-- Cleanup on unload
api:on_event("unload", function()
    getgenv().RagebotTargetList = {}
    api:notify("Anti-Aim Protection Unloaded", 2)
end)

api:notify("Anti-Aim Protection v2.0 Loaded!", 3)
