
--[[ 
    China Hat V3 - Ultra Edition
    Includes: ESP, Rainbow, Pulse, Health Color, Head Tilt, Wireframe, Bounce
]]

if not api then return end -- Unnamed API Check
api:set_lua_name("ChinaHat_V3")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- --- UI SETUP ---
local Tab = api:AddTab("Visuals V3")
local Section = Tab:AddLeftGroupbox("China Hat ESP")

-- Toggles & Modes
local Enabled = Section:AddToggle("CH_Enabled", { Text = "Enable Master Switch", Default = false })
local RenderTarget = Section:AddDropdown("CH_Target", { Values = {"LocalPlayer", "All Players", "Others Only"}, Default = "LocalPlayer", Multi = false, Text = "Render Target" })

-- Advanced Visuals
local Rainbow = Section:AddToggle("CH_Rainbow", { Text = "Rainbow Mode", Default = false })
local HealthColor = Section:AddToggle("CH_HealthColor", { Text = "Health Based Color", Default = false })
local Pulse = Section:AddToggle("CH_Pulse", { Text = "Pulse Effect", Default = false })
local Bounce = Section:AddToggle("CH_Bounce", { Text = "Bounce Effect", Default = false })
local Tilt = Section:AddToggle("CH_Tilt", { Text = "Tilt with Head", Default = true })
local Wireframe = Section:AddToggle("CH_Wireframe", { Text = "Wireframe Only", Default = false })

-- Colors
local Colors = {}
Colors[1] = Section:AddLabel("Color 1"):AddColorPicker("C1", { Default = Color3.fromRGB(255, 0, 0) })
Colors[2] = Section:AddLabel("Color 2"):AddColorPicker("C2", { Default = Color3.fromRGB(0, 255, 0) })

-- Sliders
local Radius = Section:AddSlider("CH_Radius", { Text = "Radius", Default = 2.5, Min = 1, Max = 10, Rounding = 1 })
local Height = Section:AddSlider("CH_Height", { Text = "Height", Default = 1, Min = 0.1, Max = 5, Rounding = 1 })
local OffsetY = Section:AddSlider("CH_OffsetY", { Text = "Y Offset", Default = 0.5, Min = -2, Max = 5, Rounding = 1 })
local Speed = Section:AddSlider("CH_Speed", { Text = "Spin Speed", Default = 1, Min = 0, Max = 5, Rounding = 1 })
local Transparency = Section:AddSlider("CH_Trans", { Text = "Transparency", Default = 0.5, Min = 0, Max = 1, Rounding = 1 })
local Sides = Section:AddSlider("CH_Sides", { Text = "Polygon Sides", Default = 20, Min = 3, Max = 50, Rounding = 0 })

-- --- RENDERER LOGIC ---

local HatCache = {} 

local function CleanupPlayer(plr)
    if HatCache[plr] then
        for _, d in ipairs(HatCache[plr].Drawings) do
            if d[1] then d[1]:Remove() end
            if d[2] then d[2]:Remove() end
        end
        HatCache[plr] = nil
    end
end

local function GetDrawings(plr, requiredSides)
    if not HatCache[plr] then
        HatCache[plr] = { Drawings = {}, LastSides = 0 }
    end
    
    local data = HatCache[plr]
    
    if data.LastSides ~= requiredSides then
        for _, d in ipairs(data.Drawings) do
            if d[1] then d[1]:Remove() end
            if d[2] then d[2]:Remove() end
        end
        table.clear(data.Drawings)
        
        for i = 1, requiredSides do
            local line = Drawing.new("Line")
            line.Thickness = 1
            line.ZIndex = 2
            
            local tri = Drawing.new("Triangle")
            tri.Filled = true
            tri.ZIndex = 1
            
            table.insert(data.Drawings, {line, tri})
        end
        data.LastSides = requiredSides
    end
    
    return data.Drawings
end

local function LerpColor(c1, c2, t)
    return Color3.new(c1.R + (c2.R - c1.R)*t, c1.G + (c2.G - c1.G)*t, c1.B + (c2.B - c1.B)*t)
end

RunService.RenderStepped:Connect(function()
    if not Enabled.Value then
        for plr, _ in pairs(HatCache) do CleanupPlayer(plr) end
        return
    end
    
    local targets = {}
    local mode = RenderTarget.Value
    
    if mode == "LocalPlayer" then
        table.insert(targets, LocalPlayer)
    elseif mode == "All Players" then
        targets = Players:GetPlayers()
    elseif mode == "Others Only" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(targets, p) end
        end
    end
    
    -- Cleanup Invalid
    for plr, _ in pairs(HatCache) do
        if not table.find(targets, plr) or not plr.Parent then
            CleanupPlayer(plr)
        end
    end
    
    local time = tick()
    local spd = Speed.Value
    local baseRad = Radius.Value
    local baseOffY = OffsetY.Value
    
    -- Global Effects
    if Pulse.Value then
        baseRad = baseRad + math.sin(time * 3) * 0.5
    end
    if Bounce.Value then
        baseOffY = baseOffY + math.sin(time * 2) * 0.5
    end
    
    local mainColor = Colors[1].Value
    local secColor = Colors[2].Value
    if Rainbow.Value and not HealthColor.Value then
        mainColor = Color3.fromHSV(time % 1, 1, 1)
        secColor = Color3.fromHSV((time + 0.5) % 1, 1, 1)
    end
    
    for _, plr in ipairs(targets) do
        local char = plr.Character
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChild("Humanoid")
        
        if head and hum and hum.Health > 0 then
            
            -- LOD
            local dist = (Camera.CFrame.Position - head.Position).Magnitude
            local renderSides = Sides.Value
            if dist > 100 then renderSides = math.max(3, math.floor(renderSides / 2)) end
            if dist > 300 then renderSides = 4 end 
            
            local drawings = GetDrawings(plr, renderSides)
            local fullCircle = math.pi * 2
            
            -- Override Color if Health Based
            local c1 = mainColor
            local c2 = secColor
            if HealthColor.Value then
                local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                -- Green (0.33) -> Red (0)
                local hpColor = Color3.fromHSV(hp * 0.33, 1, 1)
                c1 = hpColor
                c2 = hpColor
            end

            -- Coordinate System
            local headCF = head.CFrame
            local centerPos = headCF.Position + Vector3.new(0, baseOffY, 0)
            
            -- Axis setup
            local upAxis = Vector3.new(0, 1, 0)
            local rightAxis = Vector3.new(1, 0, 0)
            local fwdAxis = Vector3.new(0, 0, 1)
            
            if Tilt.Value then
                -- Use Head's local vectors
                -- Fix: Ensure visual up aligns with head up
                upAxis = headCF.UpVector
                rightAxis = headCF.RightVector
                fwdAxis = headCF.LookVector
                
                -- Recalculate center based on tilted UpVector
                centerPos = headCF.Position + (upAxis * baseOffY)
            end
            
            local topPos = centerPos + (upAxis * Height.Value)
            local headScreen, onScreen = Camera:WorldToViewportPoint(head.Position)
            
            if onScreen then
                 local topScreen = Camera:WorldToViewportPoint(topPos) 
                 
                 for i = 1, renderSides do
                    local objs = drawings[i]
                    local line, tri = objs[1], objs[2]
                    
                    if line then
                        local p1 = i / renderSides
                        local p2 = (i % renderSides + 1) / renderSides
                        
                        -- Spin
                        local a1 = (p1 + time * spd) * fullCircle
                        local a2 = (p2 + time * spd) * fullCircle
                        
                        -- Point Math: Center + (Right * cos) + (Fwd * sin)
                        local w1 = centerPos + (rightAxis * math.cos(a1) * baseRad) + (fwdAxis * math.sin(a1) * baseRad)
                        local w2 = centerPos + (rightAxis * math.cos(a2) * baseRad) + (fwdAxis * math.sin(a2) * baseRad)
                        
                        local s1 = Camera:WorldToViewportPoint(w1)
                        local s2 = Camera:WorldToViewportPoint(w2)
                        
                        local currColor = LerpColor(c1, c2, p1)
                        local alpha = 1 - Transparency.Value
                        
                        -- Line
                        line.From = Vector2.new(s1.X, s1.Y)
                        line.To = Vector2.new(s2.X, s2.Y)
                        line.Color = currColor
                        line.Transparency = alpha
                        line.Visible = true
                        
                        -- Triangle (Wireframe check)
                        if Wireframe.Value then
                            tri.Visible = false
                        else
                            tri.PointA = Vector2.new(topScreen.X, topScreen.Y)
                            tri.PointB = line.From
                            tri.PointC = line.To
                            tri.Color = currColor
                            tri.Transparency = alpha - 0.2
                            tri.Filled = true
                            tri.Visible = true
                        end
                    end
                 end
            else
                -- Off screen
                for _, d in ipairs(drawings) do
                    d[1].Visible = false
                    d[2].Visible = false
                end
            end
        else
            CleanupPlayer(plr)
        end
    end
end)

api:on_event("unload", function()
    for plr, _ in pairs(HatCache) do CleanupPlayer(plr) end
end)
