-- Check for API
if not api then
    warn("Unnamed API not found! Execute this script within the Unnamed environment.")
    return
end

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- SETTINGS
local TOGGLE_LOGGER = false
local TOGGLE_BEAMS = false
local TOGGLE_WEAPON_ONLY = true -- Fix for "Wrong Way Around" confusion
local RAY_DISTANCE = 100

-- Variables
local BeamCache = {} -- Cache beams to reuse/destroy
local LoggerDebounce = {} -- Prevent console spam (print once per sec per pair)

-- --- UI SETUP ---
local Tab = api:AddTab("Kitten Saver Debug")
local Group = Tab:AddLeftGroupbox("Aim Detection")

Group:AddToggle("EnableLogger", {
    Text = "Enable Aim Logger",
    Default = false,
    Callback = function(Val)
        TOGGLE_LOGGER = Val
    end
})

Group:AddToggle("ShowBeams", {
    Text = "Show Visual Beams",
    Default = false,
    Callback = function(Val)
        TOGGLE_BEAMS = Val
        if not Val then
            -- Cleanup beams instantly
            for _, beamParts in pairs(BeamCache) do
                if beamParts.Part then beamParts.Part:Destroy() end
            end
            BeamCache = {}
        end
    end
})

Group:AddToggle("ReqWeapon", {
    Text = "Require Weapon Equipped",
    Default = true, -- Default to TRUE to solve user confusion
    Callback = function(Val)
        TOGGLE_WEAPON_ONLY = Val
    end
})

Group:AddSlider("RayDist", {
    Text = "Ray Distance",
    Default = 100,
    Min = 10,
    Max = 500,
    Rounding = 0,
    Callback = function(Val)
        RAY_DISTANCE = Val
    end
})


-- --- CORE LOGIC ---
local function CleanupBeams()
    -- Remove beams for players no longer aiming
    -- This is complex to sync with RenderStep, so we'll just clear cache every frame or manage state?
    -- Better: Clear all beams at start of frame, redraw active ones.
    for _, beamParts in pairs(BeamCache) do
        -- We'll mark them dirty? Or just destroy. 
        -- Destroying/Creating every frame is bad for performance but easiest for debug code.
        -- Let's use a "LastUpdate" frame tick.
    end
end

RunService.RenderStepped:Connect(function()
    if not TOGGLE_LOGGER and not TOGGLE_BEAMS then return end
    
    -- Cleanup old beams that weren't updated this frame
    for plrName, beamData in pairs(BeamCache) do
        beamData.Active = false
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Head") then
            -- Tool Check
            local hasWeapon = player.Character:FindFirstChildOfClass("Tool")
            if not TOGGLE_WEAPON_ONLY or hasWeapon then
                
                local head = player.Character.Head
                -- Stable Origin: Head
                local origin = head.Position
                local direction = head.CFrame.LookVector * RAY_DISTANCE

                -- IMPROVED: Check for Da Hood's Replicated Mouse Position
                -- Da Hood often replicates aim via BodyEffects.MousePos (Vector3Value)
                local bodyEffects = player.Character:FindFirstChild("BodyEffects")
                if bodyEffects then
                    local mousePosVal = bodyEffects:FindFirstChild("MousePos")
                    if mousePosVal and mousePosVal:IsA("Vector3Value") then
                        -- Calculate direction from Head to MousePos
                        local targetPos = mousePosVal.Value
                        direction = (targetPos - origin).Unit * RAY_DISTANCE
                    end
                end

                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {player.Character}
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                raycastParams.IgnoreWater = true
                
                -- Cast Ray
                local result = Workspace:Raycast(origin, direction, raycastParams)
                
                local hitCharacter = nil
                local hitPlayer = nil
                local hitPos = origin + direction -- Default endpoint
                
                if result then
                    hitPos = result.Position
                    if result.Instance then
                        local model = result.Instance:FindFirstAncestorOfClass("Model")
                        if model and model:FindFirstChild("Humanoid") then
                            hitCharacter = model
                            hitPlayer = Players:GetPlayerFromCharacter(model)
                        end
                    end
                end
                
                -- LOGIC: Hit a player
                if hitPlayer then
                    local victimName = hitPlayer.Name
                    
                    if TOGGLE_LOGGER then
                        -- Debounce Key: Source->Target
                        local key = player.Name .. "->" .. victimName
                        local last = LoggerDebounce[key] or 0
                        if tick() - last > 1 then -- Log once per second
                            print(string.format("[AIM DEBUG] %s is Aiming at %s", player.Name, victimName))
                            if not hasWeapon then
                                print("   (Note: No Weapon Equipped)")
                            end
                            LoggerDebounce[key] = tick()
                        end
                        
                        -- On-Screen Notify (Optional, maybe too spammy)
                        -- api:notify(player.Name .. " aiming at " .. victimName, 1)
                    end
                end
                
                -- VISUAL: Beam
                if TOGGLE_BEAMS then
                   -- Draw Beam
                   local beamId = player.Name
                   
                   -- Color logic: Red if hitting player, Green if nothing
                   local color = hitCharacter and Color3.new(1, 0, 0) or Color3.new(0, 1, 0)
                   
                   if not BeamCache[beamId] then
                       local p = Instance.new("Part")
                       p.Name = "DebugBeam_"..player.Name
                       p.Anchored = true
                       p.CanCollide = false
                       p.Material = Enum.Material.Neon
                       p.Parent = Workspace
                       BeamCache[beamId] = {Part = p}
                   end
                   
                   local part = BeamCache[beamId].Part
                   BeamCache[beamId].Active = true
                   
                   -- Size/CFrame math for beam
                   local dist = (origin - hitPos).Magnitude
                   part.Size = Vector3.new(0.2, 0.2, dist)
                   part.CFrame = CFrame.lookAt(origin, hitPos) * CFrame.new(0, 0, -dist/2)
                   part.Color = color
                   part.Transparency = 0.5
                end
            end
        end
    end
    
    -- Clear inactive beams
    for id, data in pairs(BeamCache) do
        if not data.Active then
            if data.Part then data.Part:Destroy() end
            BeamCache[id] = nil
        end
    end
end)
