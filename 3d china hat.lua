--[[
    Unnamed Addon: Customizable Pyramid Hat
    "Basically a pyramid on our head that is fully customizable"
    
    Features:
    - Shape: Pyramid (4 sides) to Cone (many sides)
    - Flatness: Adjust how flat/pointy it is
    - Texture: Full material support (Neon, Plastic, ForceField, etc)
    - Mode: Wireframe or Solid
    - Customization: Color, Transparency, Reflectance, Offset
]]

api:set_lua_name("PyramidHat")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- UI Setup
local tabs = { Visuals = api:GetTab("visuals") or api:AddTab("visuals") }
local sec = tabs.Visuals:AddLeftGroupbox("Custom Pyramid Hat")

-- Main Controls
local Enable = sec:AddToggle("PH_Enable", { Text = "Enable", Default = true })
local Wireframe = sec:AddToggle("PH_Wire", { Text = "Wireframe Only", Default = false })

-- Shape Controls
local Scale = sec:AddSlider("PH_Scale", { Text = "Scale", Default = 6, Min = 1, Max = 20, Rounding = 1, Tooltip = "Controls the overall size" })
local Flatness = sec:AddSlider("PH_Flat", { Text = "Height / Flatness", Default = 0.35, Min = 0.1, Max = 2, Rounding = 2, Tooltip = "Lower = Flatter (Rice Hat style)" })
local Sides = sec:AddSlider("PH_Sides", { Text = "Sides", Default = 4, Min = 3, Max = 32, Rounding = 0, Tooltip = "4 = Pyramid (like reference), 32 = Smooth Cone" })
local Offset = sec:AddSlider("PH_Offset", { Text = "Height Offset", Default = 0.5, Min = -2, Max = 5, Rounding = 1 })

-- Appearance Controls
local Material = sec:AddDropdown("PH_Mat", { Text = "Texture / Material", Default = "Neon", Values = {
    "Neon", "Plastic", "SmoothPlastic", "ForceField", "Glass", 
    "Metal", "Foil", "Fabric", "Grass", "Ice", "Brick", 
    "Granite", "Marble", "Wood", "Cobblestone", "Sand"
}})

local HatColor = sec:AddLabel("Hat Color"):AddColorPicker("PH_Color", { Default = Color3.fromRGB(170, 0, 255) }) -- Purple default like reference
local Transparency = sec:AddSlider("PH_Trans", { Text = "Transparency", Default = 0, Min = 0, Max = 1, Rounding = 2 })
local Reflectance = sec:AddSlider("PH_Reflect", { Text = "Reflectance", Default = 0, Min = 0, Max = 1, Rounding = 2 })

-- Extras
local Spin = sec:AddToggle("PH_Spin", { Text = "Spin Animation", Default = false })
local SpinSpeed = sec:AddSlider("PH_SpinSpeed", { Text = "Spin Speed", Default = 1, Min = 0.1, Max = 10, Rounding = 1 })

-- Script Logic
local Parts = {}
local rotAngle = 0

local MatEnum = {
    Neon = Enum.Material.Neon, Plastic = Enum.Material.Plastic, SmoothPlastic = Enum.Material.SmoothPlastic,
    ForceField = Enum.Material.ForceField, Glass = Enum.Material.Glass, Metal = Enum.Material.Metal,
    Foil = Enum.Material.Foil, Fabric = Enum.Material.Fabric, Grass = Enum.Material.Grass,
    Ice = Enum.Material.Ice, Brick = Enum.Material.Brick, Granite = Enum.Material.Granite,
    Marble = Enum.Material.Marble, Wood = Enum.Material.Wood, Cobblestone = Enum.Material.Cobblestone,
    Sand = Enum.Material.Sand
}

local function destroyHat()
    for _, p in pairs(Parts) do pcall(function() p:Destroy() end) end
    Parts = {}
end

local function updateHat()
    if not Enable.Value then
        if #Parts > 0 then destroyHat() end
        return
    end

    local char = LocalPlayer.Character
    local head = char and char:FindFirstChild("Head")
    if not head then return end

    -- Parameters
    local scale = Scale.Value
    local flatness = Flatness.Value
    local height = scale * flatness
    local radius = scale
    local sides = Sides.Value
    local isWireframe = Wireframe.Value
    local offset = Offset.Value
    local mat = MatEnum[Material.Value] or Enum.Material.Neon
    local col = HatColor.Value
    local trans = Transparency.Value
    local reflect = Reflectance.Value

    -- Spin Logic
    if Spin.Value then
        rotAngle = rotAngle + (SpinSpeed.Value * 0.02)
    end

    -- Positioning
    local baseCenter = head.Position + Vector3.new(0, offset, 0)
    local tipPos = baseCenter + Vector3.new(0, height, 0)

    -- Manage Parts
    local needed = isWireframe and (sides * 2) or sides
    
    -- Cleanup excess
    if #Parts > needed then
        for i = needed + 1, #Parts do
            Parts[i]:Destroy()
            Parts[i] = nil
        end
    end

    -- Create new
    while #Parts < needed do
        local p = Instance.new(isWireframe and "Part" or "WedgePart")
        p.Anchored = true
        p.CanCollide = false
        p.CastShadow = false
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        p.Parent = workspace
        table.insert(Parts, p)
    end

    -- Update Geometry
    for i = 1, sides do
        local angle1 = ((i - 1) / sides) * math.pi * 2 + rotAngle
        local angle2 = (i / sides) * math.pi * 2 + rotAngle

        local p1 = baseCenter + Vector3.new(math.cos(angle1) * radius, 0, math.sin(angle1) * radius)
        local p2 = baseCenter + Vector3.new(math.cos(angle2) * radius, 0, math.sin(angle2) * radius)

        if isWireframe then
            -- 1. Base Line
            local lineBase = Parts[i]
            local midBase = (p1 + p2) / 2
            local distBase = (p1 - p2).Magnitude
            lineBase.Size = Vector3.new(0.08, 0.08, distBase)
            lineBase.CFrame = CFrame.lookAt(midBase, p2)
            lineBase.Color = col; lineBase.Material = mat; lineBase.Transparency = trans; lineBase.Reflectance = reflect
            
            -- 2. Spine Line (Tip to Base Corner)
            local lineSpine = Parts[sides + i]
            local midSpine = (tipPos + p1) / 2
            local distSpine = (tipPos - p1).Magnitude
            lineSpine.Size = Vector3.new(0.08, 0.08, distSpine)
            lineSpine.CFrame = CFrame.lookAt(midSpine, p1)
            lineSpine.Color = col; lineSpine.Material = mat; lineSpine.Transparency = trans; lineSpine.Reflectance = reflect
        else
            -- Solid Faces (Wedges)
            local wedge = Parts[i]
            
            -- To make a pyramid face, we position the wedge at the chord between p1 and p2
            -- The wedge width matches the chord length
            -- The wedge height matches the hat height
            -- The wedge depth matches the distance from chord to center
            
            local chordLength = (p1 - p2).Magnitude
            local midChord = (p1 + p2) / 2
            local distToCenter = (midChord - baseCenter).Magnitude
            
            -- We construct the wedge
            wedge.Size = Vector3.new(chordLength, height, distToCenter)
            
            -- Position: The wedge center needs to be calculated carefully
            -- A wedge's position property is its geometric center.
            -- We want the vertical back face to be at the center of the hat? 
            -- No, standard WedgePart: Vertical Face is BACK. Slant is FRONT.
            -- We want the Back Face (Height x Width) to be at the center axis of the hat.
            -- The "Point" (thinnest part) should be at the perimeter? NO.
            
            -- Wait, if the Back Face is at the center, the Slant goes OUTWARD.
            -- This creates a shape that is THICK in the middle and THIN at the edge.
            -- That effectively makes a pyramid!
            -- Center = Tall. Edge = Short.
            -- Yes, this is correct for a solid pyramid.
            
            -- Wedge Orientation:
            -- We need the Back Face centered at `baseCenter` (horizontally).
            -- Vertical offset: The wedge origin Y is half-height.
            -- So Y position = baseCenter.Y + height/2.
            
            -- Horizontal Position:
            -- The Wedge's "Back" face is at Z = +Size.Z/2 relative to its CFrame center.
            -- We want the Back Face to be at the hat center (radius=0).
            -- So the Wedge Center needs to be pushed OUTwards by Size.Z/2.
            
            local angleMid = (angle1 + angle2) / 2
            
            -- Direction vector from center to edge
            local dir = (midChord - baseCenter).Unit
            
            -- Position the wedge center half-way along the depth vector
            local wedgePos = baseCenter + Vector3.new(0, height/2, 0) + (dir * (distToCenter / 2))
            
            -- Angle: The wedge needs to face outward.
            -- Standard Wedge: LookVector is Front (Slant).
            -- We want Slant facing OUT. Back facing IN.
            -- LookVector should point along `dir`.
            
            wedge.CFrame = CFrame.lookAt(wedgePos, wedgePos + dir)
            
            wedge.Color = col; wedge.Material = mat; wedge.Transparency = trans; wedge.Reflectance = reflect
        end
    end
end

-- Hook
local conn
Enable:OnChanged(function()
    if Enable.Value then
        if not conn then
            conn = RunService.RenderStepped:Connect(updateHat)
            api:add_connection(conn)
        end
    else
        destroyHat()
        if conn then conn:Disconnect() conn = nil end
    end
end)

api:on_event("unload", function() destroyHat() end)
api:notify("Custom Pyramid Hat Loaded!", 3)
