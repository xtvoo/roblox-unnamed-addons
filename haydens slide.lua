api:set_lua_name("haydens slide")

local Handler = loadstring(game:HttpGet("https://raw.githubusercontent.com/XK5NG/XK5NG.github.io/main/Handler"))()
local Players = Handler:CloneRef("Players")
local RunService = Handler:CloneRef("RunService")
local Workspace = Handler:CloneRef("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ========== SLIDE STATE & LOGIC PREP ==========
local SlideState = {
    VelocityVector = false, 
    LastTick = tick(),
    IsSliding = false,
    OriginalHipHeight = 2,
    Debounce = false
}

local AnimationIds = {
    ["On Ass (Default)"] = "rbxassetid://15546944790",
    ["On Knees"] = "rbxassetid://16214400682"
}

local HipHeightSettings = {
    ["On Ass (Default)"] = 0.5,
    ["On Knees"] = 1.2
}

local LoadedAnim = nil
local LoadAnimation = nil -- Forward declaration

-- ========== UI SETUP ==========
local Tab = api:GetTab("character") or api:AddTab("character")
local Main = Tab:AddLeftGroupbox("Slide Glitch")

Main:AddToggle("EnableSlide", { 
    Text = "Enable Slide", 
    Default = true,
    Tooltip = "Allows sliding with the keybind." 
})

Main:AddSlider("SlideSpeed", { 
    Text = "Slide Speed", 
    Default = 70, 
    Min = 30, 
    Max = 200, 
    Rounding = 0, 
    Suffix = " studs/sec" 
})

Main:AddDropdown("SlideStyle", {
    Values = {"On Ass (Default)", "On Knees"},
    Default = 1,
    Text = "Slide Style",
    Tooltip = "Choose animation style",
    Callback = function(val)
        -- Reload on change
        if LoadAnimation then LoadAnimation() end
    end
})

Main:AddLabel("Keybind: Q (Default)")



local RayParams = RaycastParams.new()
RayParams.FilterDescendantsInstances = { Workspace.Ignored, Workspace.Players }
RayParams.FilterType = Enum.RaycastFilterType.Exclude

local BodyVel = Instance.new("BodyVelocity")
BodyVel:SetAttribute("AllowedBM", true)
BodyVel.Name = "IgnoredVelocity"
BodyVel.MaxForce = Vector3.new(1000000000, 0, 1000000000)

local SlideSound = Instance.new("Sound")
SlideSound.Name = "SlideSFX"
SlideSound.SoundId = "rbxassetid://16283904526"
SlideSound.Looped = true
SlideSound.RollOffMaxDistance = 10000
SlideSound.RollOffMinDistance = 10
SlideSound.RollOffMode = Enum.RollOffMode.InverseTapered
SlideSound.Volume = 0.2
SlideSound.PlaybackSpeed = 0.5
SlideSound.Parent = nil -- Parented when sliding


LoadAnimation = function()
    if not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Cleanup old
    if LoadedAnim then LoadedAnim:Stop() LoadedAnim = nil end
    
    local style = Options.SlideStyle and Options.SlideStyle.Value or "On Ass (Default)"
    local id = AnimationIds[style] or AnimationIds["On Ass (Default)"]
    
    local anim = Instance.new("Animation")
    anim.AnimationId = id
    LoadedAnim = humanoid:LoadAnimation(anim)
    LoadedAnim.Priority = Enum.AnimationPriority.Action4
end

local function TriggerSlide()
    if not (Toggles.EnableSlide and Toggles.EnableSlide.Value) then return end
    if SlideState.Debounce then return end
    
    if not LocalPlayer.Character then return end
    local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return end
    
    SlideState.Debounce = true
    task.delay(0.2, function() SlideState.Debounce = false end)
    
    -- Set Initial Velocity
    local speed = Options.SlideSpeed.Value
    SlideState.VelocityVector = root.CFrame.LookVector * speed
    SlideState.IsSliding = true
    
    -- Play Animation
    if not LoadedAnim then LoadAnimation() end
    if LoadedAnim then LoadedAnim:Play() end
    
    -- Play Sound
    SlideSound.Parent = root
    if not SlideSound.IsPlaying then SlideSound:Play() end
end

local function StopSlide()
    SlideState.IsSliding = false
    SlideState.VelocityVector = false
    BodyVel.Parent = nil
    if LoadedAnim then LoadedAnim:Stop() end
    
    -- Stop Sound
    if SlideSound.IsPlaying then SlideSound:Stop() end
    SlideSound.Parent = nil
    
    -- Restore HipHeight
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.HipHeight = SlideState.OriginalHipHeight
        end
    end
end

-- ========== MAIN LOOP ==========
api:add_connection(RunService.Heartbeat:Connect(function(dt)
    if not SlideState.IsSliding or not SlideState.VelocityVector then 
        if BodyVel.Parent then BodyVel.Parent = nil end
        return 
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then 
        -- Safety stop if died
        if SlideState.IsSliding then StopSlide() end
        return 
    end
    
    -- Anti-fling (NaN Check)
    if SlideState.VelocityVector then
        local v = SlideState.VelocityVector
        if v.X ~= v.X or v.Y ~= v.Y or v.Z ~= v.Z then
             SlideState.VelocityVector = Vector3.new(0,0,0)
             StopSlide()
             return
        end
    end

    -- Ground Check first
    local rayOrigin = root.Position
    local verticalRay = Vector3.new(0, -root.Size.Y * 2.5, 0) -- Increased ray length slightly for reliability
    local groundHit = Workspace:Raycast(rayOrigin, verticalRay, RayParams)
    
    if groundHit then
        -- === ON GROUND ===
        
        -- Apply Physics
        BodyVel.Velocity = SlideState.VelocityVector
        if BodyVel.Parent == nil then
            BodyVel.Parent = root
        end
        
        -- Apply Sound
        SlideSound.Parent = root
        if not SlideSound.IsPlaying then SlideSound:Play() end
        
        -- Apply Animation
        if LoadedAnim and not LoadedAnim.IsPlaying then
             LoadedAnim:Play()
        end
        
        -- Reduce HipHeight to "stick" to floor visually (but keep buffer to prevent clipping)
        local style = Options.SlideStyle and Options.SlideStyle.Value or "On Ass (Default)"
        local targetHeight = HipHeightSettings[style] or 0.5
        
        if humanoid.HipHeight ~= targetHeight then
             if humanoid.HipHeight > 1.5 then -- Only capture if it looks like a normal standing height
                  SlideState.OriginalHipHeight = humanoid.HipHeight
             end
             humanoid.HipHeight = targetHeight
        end
        
        -- Wall Check
        if Workspace:Raycast(rayOrigin, SlideState.VelocityVector.Unit * 3, RayParams) then
            SlideState.VelocityVector = SlideState.VelocityVector * 0.1
        end
        
        -- Friction
        local friction = 0.95
        if groundHit.Normal and groundHit.Normal:Dot(SlideState.VelocityVector.Unit) > 0 then
            local slopeFactor = friction + (1 - groundHit.Normal:Dot(Vector3.new(0, 1, 0))) * 0.4
            friction = math.clamp(slopeFactor, 0, 1)
        end
        
        -- Decay
        if tick() - SlideState.LastTick > 0.01 then
            SlideState.LastTick = tick()
            SlideState.VelocityVector = SlideState.VelocityVector * friction
        end
        
    else
        -- === IN AIR (PAUSE SLIDE EFFECTS) ===
        if BodyVel.Parent then BodyVel.Parent = nil end
        if SlideSound.IsPlaying then SlideSound:Stop() end
        if LoadedAnim and LoadedAnim.IsPlaying then LoadedAnim:Stop() end
        
        -- Restore HipHeight in air
        if humanoid.HipHeight <= 1.4 then
            humanoid.HipHeight = SlideState.OriginalHipHeight
        end
    end
    
    -- Dynamic Sound Adjustment (From Decompiled Source)
    -- "v16 = v14.magnitude / 10; Volume = math.clamp(v16, 0, 0.3)"
    -- "v18 = v14.magnitude / 10; PlaybackSpeed = math.clamp(v18, 0.5, 1)"
    local velocityMag = SlideState.VelocityVector.Magnitude
    local dynamicRatio = velocityMag / 100 -- Magnitude is huge (70-200), so /10 might be too loud. Checking source context.
    -- Wait, source max magnitude check is `v14.magnitude < 5`. 
    -- If speed is 70, 70/10 = 7. Volume clamped 0.3. Speed clamped 1.
    -- Let's stick to source math: / 10.
    
    local ratio = velocityMag / 10
    SlideSound.Volume = math.clamp(ratio, 0, 0.3)
    SlideSound.PlaybackSpeed = math.clamp(ratio, 0.5, 1)

    -- End Slide Condition
    if (typeof(SlideState.VelocityVector) == "Vector3" and SlideState.VelocityVector.Magnitude < 5) or humanoid.FloorMaterial == Enum.Material.Air then
         if SlideState.VelocityVector.Magnitude < 2 then
             StopSlide()
         end
    end
end))

-- ========== INPUT ==========
local UserInputService = game:GetService("UserInputService")
api:add_connection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        TriggerSlide()
    end
end))

api:add_connection(LocalPlayer.CharacterAdded:Connect(function()
    StopSlide()
    LoadedAnim = nil
    task.delay(1, LoadAnimation)
end))

LoadAnimation()

api:notify("Hayden's Slide Script Loaded!", 3)
print("[HaydenSlide] Script Loaded Successfully")
