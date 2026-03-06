--[[
    Unnamed Addon: Simple China Hat ESP
    Lightweight solid cone hat - no wireframe, saves FPS
]]

api:set_lua_name("SimpleChinaHat")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- UI
local tabs = { Visuals = api:GetTab("visuals") or api:AddTab("visuals") }
local sec = tabs.Visuals:AddLeftGroupbox("Simple China Hat")

local Enable = sec:AddToggle("SCH_Enable", { Text = "Enable", Default = false })
local TargetMode = sec:AddDropdown("SCH_Target", { Text = "Target", Default = "Self", Values = {"Self", "Silent Aim", "Ragebot", "All Players"} })
local HatRadius = sec:AddSlider("SCH_Radius", { Text = "Radius", Default = 20, Min = 5, Max = 50, Rounding = 0 })
local HatHeight = sec:AddSlider("SCH_Height", { Text = "Height", Default = 40, Min = 10, Max = 80, Rounding = 0 })
local HatColor = sec:AddLabel("Hat Color"):AddColorPicker("SCH_Color", { Default = Color3.fromRGB(255, 0, 100) })
local HatTransparency = sec:AddSlider("SCH_Trans", { Text = "Transparency", Default = 0.3, Min = 0, Max = 0.9, Rounding = 2 })

-- Hat storage per player
local Hats = {}

local function createHat(id)
    if Hats[id] then return Hats[id] end
    
    -- Single filled triangle for each side of cone (8 sides)
    local hat = { triangles = {} }
    for i = 1, 8 do
        local tri = Drawing.new("Triangle")
        tri.Filled = true
        tri.Visible = false
        tri.Thickness = 0
        tri.ZIndex = 1
        table.insert(hat.triangles, tri)
    end
    
    -- Base circle (filled)
    hat.base = Drawing.new("Circle")
    hat.base.Filled = true
    hat.base.Visible = false
    hat.base.NumSides = 16
    hat.base.ZIndex = 0
    
    Hats[id] = hat
    return hat
end

local function destroyHat(id)
    local hat = Hats[id]
    if not hat then return end
    for _, tri in pairs(hat.triangles) do pcall(function() tri:Remove() end) end
    if hat.base then pcall(function() hat.base:Remove() end) end
    Hats[id] = nil
end

local function destroyAll()
    for id in pairs(Hats) do destroyHat(id) end
end

local function getTargets()
    local targets = {}
    local mode = TargetMode.Value
    
    if mode == "Self" then
        table.insert(targets, LocalPlayer)
    elseif mode == "Silent Aim" then
        local t = api:get_target("silent")
        if t then
            local p = Players:GetPlayerFromCharacter(t.Parent) or Players:GetPlayerFromCharacter(t)
            if p then table.insert(targets, p) end
        end
    elseif mode == "Ragebot" then
        local t = api:get_target("ragebot")
        if t then
            local p = Players:GetPlayerFromCharacter(t.Parent) or Players:GetPlayerFromCharacter(t)
            if p then table.insert(targets, p) end
        end
    elseif mode == "All Players" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                table.insert(targets, p)
            end
        end
    end
    
    return targets
end

local function updateHat(player, hat)
    local char = player.Character
    local head = char and char:FindFirstChild("Head")
    if not head then
        for _, tri in pairs(hat.triangles) do tri.Visible = false end
        hat.base.Visible = false
        return
    end
    
    local headPos = head.Position + Vector3.new(0, 0.5, 0)
    local tipPos = headPos + Vector3.new(0, HatHeight.Value / 20, 0)
    local radius = HatRadius.Value / 20
    
    local screenTip, onScreen = Camera:WorldToViewportPoint(tipPos)
    if not onScreen or screenTip.Z <= 0 then
        for _, tri in pairs(hat.triangles) do tri.Visible = false end
        hat.base.Visible = false
        return
    end
    
    local color = HatColor.Value
    local trans = HatTransparency.Value
    local sides = #hat.triangles
    
    -- Calculate base points
    local basePoints = {}
    for i = 1, sides do
        local angle = (i / sides) * math.pi * 2
        local worldPos = headPos + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
        local screen = Camera:WorldToViewportPoint(worldPos)
        basePoints[i] = Vector2.new(screen.X, screen.Y)
    end
    
    local tipScreen = Vector2.new(screenTip.X, screenTip.Y)
    
    -- Draw triangles from base to tip
    for i = 1, sides do
        local tri = hat.triangles[i]
        local next = i % sides + 1
        
        tri.PointA = tipScreen
        tri.PointB = basePoints[i]
        tri.PointC = basePoints[next]
        tri.Color = color
        tri.Transparency = trans
        tri.Visible = true
    end
    
    -- Base circle
    local baseScreen = Camera:WorldToViewportPoint(headPos)
    local edgeScreen = Camera:WorldToViewportPoint(headPos + Vector3.new(radius, 0, 0))
    local screenRadius = math.abs(edgeScreen.X - baseScreen.X)
    
    hat.base.Position = Vector2.new(baseScreen.X, baseScreen.Y)
    hat.base.Radius = screenRadius
    hat.base.Color = color
    hat.base.Transparency = trans + 0.1
    hat.base.Visible = true
end

-- Main loop
local conn = nil

local function Update()
    if not Enable.Value then
        destroyAll()
        return
    end
    
    local targets = getTargets()
    local activeIds = {}
    
    for _, player in ipairs(targets) do
        local id = player.UserId
        activeIds[id] = true
        local hat = createHat(id)
        updateHat(player, hat)
    end
    
    -- Remove hats for players no longer targeted
    for id in pairs(Hats) do
        if not activeIds[id] then
            destroyHat(id)
        end
    end
end

Enable:OnChanged(function()
    if Enable.Value then
        if not conn then
            conn = RunService.RenderStepped:Connect(Update)
            api:add_connection(conn)
        end
    else
        destroyAll()
    end
end)

Players.PlayerRemoving:Connect(function(p)
    destroyHat(p.UserId)
end)

api:on_event("unload", function()
    destroyAll()
end)

api:notify("Simple China Hat ESP Loaded!", 3)
