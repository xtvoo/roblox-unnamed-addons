--[[
    🌸 DESYNC VISUALS STANDALONE 🌸
    "Clean" Server Position Indicator
    
    Features:
    - Ghost Chams (Highlight) at real server position
    - Floating Icon (BillboardGui)
    - Fully Customizable
]]

if not api then
    warn("API not found. Please inject 'unnamed'.")
    return
end

api:set_lua_name("Desync Visuals")

-- [1. SERVICES]
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- [2. CONFIG]
local cfg = {
    enabled = true,
    
    -- Chams
    chams_enabled = true,
    chams_color = Color3.fromRGB(255, 0, 255), -- Hot Pink
    chams_transparency = 0.5,
    chams_outline_color = Color3.new(1,1,1),
    chams_outline_transparency = 0,
    
    -- Icon
    icon_enabled = true,
    icon_id = "10723415903", -- Default icon ID string
}

local state = {
    ghost_model = nil,
    connection = nil
}

-- [3. UI CONSTRUCTION]
local tab = api:GetTab("visuals") or api:AddTab("visuals")
local box = tab:AddLeftTabbox("Desync Indicators")
local main = box:AddTab("Main")

main:AddToggle("vis_en", {
    Text = "Enable Master Switch",
    Default = true,
    Callback = function(v) cfg.enabled = v end
})

main:AddDivider()

main:AddToggle("vis_chams", {
    Text = "Ghost Chams",
    Default = true,
    Callback = function(v) cfg.chams_enabled = v end
})

main:AddLabel("Chams Color"):AddColorPicker("vis_color", {
    Default = cfg.chams_color,
    Title = "Chams Color",
    Callback = function(v) cfg.chams_color = v end
})

main:AddSlider("vis_trans", {
    Text = "Fill Transparency",
    Min = 0, Max = 1,
    Default = 0.5,
    Rounding = 2,
    Callback = function(v) cfg.chams_transparency = v end
})

main:AddDivider()

main:AddToggle("vis_icon", {
    Text = "Floating Icon",
    Default = true,
    Callback = function(v) cfg.icon_enabled = v end
})

main:AddInput("vis_icon_id", {
    Text = "Custom Icon ID",
    Default = "10723415903",
    Placeholder = "Asset ID...",
    Numeric = true,
    Finished = true,
    Callback = function(v) 
        cfg.icon_id = v 
        -- Live update if exists
        if state.ghost_model and state.ghost_model.PrimaryPart then
            local icon = state.ghost_model.PrimaryPart:FindFirstChild("IconBB")
            if icon then
                local img = icon:FindFirstChild("Img")
                if img then img.Image = "rbxassetid://" .. v end
            end
        end
    end
})

-- [4. LOGIC]

local function CreateGhost()
    -- We must CLONE the character to get a proper shape for Highlight
    if not LocalPlayer.Character then return nil end
    
    -- Create Archivable clone
    LocalPlayer.Character.Archivable = true
    local ghost = LocalPlayer.Character:Clone()
    LocalPlayer.Character.Archivable = false
    
    ghost.Name = "DesyncGhost"
    
    -- Cleanup: Remove scripts, tools, ui, and anchor everything
    for _, v in pairs(ghost:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Sound") or v:IsA("BillboardGui") or v:IsA("Tool") then
            v:Destroy()
        elseif v:IsA("BasePart") then
            v.Anchored = true
            v.CanCollide = false
            v.CastShadow = false
            -- Reset transparency so Highlight fills it solidly if desired
            if v.Name ~= "HumanoidRootPart" then
                v.Transparency = 0 
                v.Material = Enum.Material.SmoothPlastic
                v.Color = Color3.new(1,1,1) -- Reset color
            else
                v.Transparency = 1 -- Root part hide
            end
        end
    end
    
    -- Visual: Highlight
    local hl = Instance.new("Highlight")
    hl.Name = "FX"
    hl.FillColor = cfg.chams_color
    hl.OutlineColor = cfg.chams_outline_color
    hl.FillTransparency = cfg.chams_transparency
    hl.OutlineTransparency = cfg.chams_outline_transparency
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = ghost
    
    -- Visual: Icon
    local root = ghost:WaitForChild("HumanoidRootPart", 1)
    if root then
        local bb = Instance.new("BillboardGui")
        bb.Name = "IconBB"
        bb.Size = UDim2.new(0, 50, 0, 50)
        bb.StudsOffset = Vector3.new(0, 4.5, 0)
        bb.AlwaysOnTop = true
        
        local img = Instance.new("ImageLabel")
        img.Name = "Img"
        img.BackgroundTransparency = 1
        img.Size = UDim2.new(1,0,1,0)
        img.Image = "rbxassetid://" .. cfg.icon_id
        img.ImageColor3 = Color3.new(1,1,1)
        img.Parent = bb
        
        bb.Parent = root
    end
    
    ghost.Parent = Workspace
    return ghost
end

state.connection = api:add_connection(RunService.Heartbeat:Connect(function()
    if not cfg.enabled then
        if state.ghost_model then state.ghost_model:Destroy(); state.ghost_model = nil end
        return
    end
    
    -- Visuals: Update Ghost
    local targetCF = nil
    if api.get_desync_cframe then
        targetCF = api:get_desync_cframe()
    end
    
    -- Fallback if API returns nil or not available
    if not targetCF and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
        targetCF = LocalPlayer.Character.PrimaryPart.CFrame
    end
    
    if targetCF then
        if not state.ghost_model then
            state.ghost_model = CreateGhost()
        end
        
        -- Force Ghost to Ground (Visual Only) if enabled
        -- We'll just define it here or add a config option if you want
        -- For "Clean" look, let's auto-ground it if it's flying
        local finalCF = targetCF
        if true then -- You can add cfg.force_ground toggle later
             local params = RaycastParams.new()
             params.FilterType = Enum.RaycastFilterType.Exclude
             params.FilterDescendantsInstances = {LocalPlayer.Character, state.ghost_model}
             
             local res = Workspace:Raycast(targetCF.Position + Vector3.new(0, 5, 0), Vector3.new(0, -100, 0), params)
             if res then
                 -- Keep Rotation, Snap Y to Hit
                 local y = res.Position.Y + 3 -- HipHeight approx for R6/R15
                 -- Actually, we should get HipHeight from Humanoid
                 local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                 if hum then y = res.Position.Y + hum.HipHeight end
                 
                 finalCF = CFrame.new(targetCF.Position.X, y, targetCF.Position.Z) * targetCF.Rotation
             end
        end

        state.ghost_model:SetPrimaryPartCFrame(finalCF)
        
        -- Update Visuals
        local hl = state.ghost_model:FindFirstChild("FX")
        if hl then
            hl.Enabled = cfg.chams_enabled
            hl.FillColor = cfg.chams_color
            hl.FillTransparency = cfg.chams_transparency
        end
        
        local bb = state.ghost_model.PrimaryPart:FindFirstChild("IconBB")
        if bb then
            bb.Enabled = cfg.icon_enabled
        end
        
    else
        if state.ghost_model then state.ghost_model:Destroy(); state.ghost_model = nil end
    end
end))

api:on_event("unload", function()
    if state.ghost_model then state.ghost_model:Destroy() end
end)

api:notify("Visuals Script Loaded", 3)
