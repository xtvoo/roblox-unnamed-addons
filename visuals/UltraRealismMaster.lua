--[[ 
    ULTRA REALISM MASTER SCRIPT (v1.1 - FIXED)
    Combines: Realistic Graphics, Cinematic Camera, Surreal FX, Heavy Rain, & Volumetric God Rays
    
    KEYBINDS:
    [P] - Toggle between "Heavy Storm" and "Golden Hour God Rays"
    [J] - Cycle RTX Shader Presets
    [K] / [L] - Enable / Disable Glossy Map (Reflections)
    [X] - Panic Reset (Fixes white screen)
]]

-- 1. SERVICES
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Terrain = Workspace.Terrain

local Camera = Workspace.CurrentCamera
local Player = Players.LocalPlayer

print("LOADING ULTRA REALISM MASTER SCRIPT...")

-- 2. ASSET CLEANUP
for _, child in pairs(Lighting:GetChildren()) do
    if child.Name:find("Cinematic") or child.Name:find("Volumetric") or child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
        child:Destroy()
    end
end
if CoreGui:FindFirstChild("SurrealFX") then CoreGui.SurrealFX:Destroy() end
if CoreGui:FindFirstChild("VignetteGUI") then CoreGui.VignetteGUI:Destroy() end

-- 3. GRAPHICS SETUP
Lighting.GlobalShadows = true
Lighting.GeographicLatitude = 41.7
Lighting.ShadowSoftness = 0.2
pcall(function() sethiddenproperty(Lighting, "Technology", Enum.Technology.Future) end)

-- Post Processing
local Bloom = Instance.new("BloomEffect", Lighting)
Bloom.Name = "CinematicBloom"
Bloom.Intensity = 1.2
Bloom.Size = 25
Bloom.Threshold = 1.8

local CC = Instance.new("ColorCorrectionEffect", Lighting)
CC.Name = "CinematicCC"
CC.Brightness = 0.05
CC.Contrast = 0.2
CC.Saturation = 0.2
CC.TintColor = Color3.fromRGB(255, 248, 240)

local SunRays = Instance.new("SunRaysEffect", Lighting)
SunRays.Name = "VolumetricRays"

local DOF = Instance.new("DepthOfFieldEffect", Lighting)
DOF.Name = "CinematicDOF"
DOF.FarIntensity = 0.5
DOF.NearIntensity = 0.1

local Blur = Instance.new("BlurEffect", Lighting)
Blur.Name = "MotionBlur"
Blur.Size = 0

-- Atmosphere
local Atmosphere = Instance.new("Atmosphere", Lighting)
Atmosphere.Density = 0.35
Atmosphere.Offset = 0

-- Rain Assets
local RainSound = Instance.new("Sound", Lighting)
RainSound.SoundId = "rbxassetid://9117364664" -- Verified Rain Ambiance
RainSound.Volume = 0
RainSound.Looped = true
RainSound:Play()

local Clouds = Instance.new("Clouds", Terrain)
Clouds.Name = "StormClouds"
Clouds.Cover = 1
Clouds.Density = 0.8
Clouds.Color = Color3.fromRGB(100, 100, 120)

-- Rain Particles
local RainEmitter = Instance.new("Part", Workspace)
RainEmitter.Name = "RainEmitter"
RainEmitter.Transparency = 1
RainEmitter.CanCollide = false
RainEmitter.Anchored = true
RainEmitter.Size = Vector3.new(200, 1, 200)

local RainParticle = Instance.new("ParticleEmitter", RainEmitter)
RainParticle.Texture = "rbxassetid://9962890663"
RainParticle.Rate = 0
RainParticle.Speed = NumberRange.new(80, 100)
RainParticle.Lifetime = NumberRange.new(1, 1.5)
RainParticle.Size = NumberSequence.new(0.5, 0.5)
RainParticle.Transparency = NumberSequence.new(0.5, 0.8)
RainParticle.SpreadAngle = Vector2.new(0, 0)
RainParticle.Acceleration = Vector3.new(0, -50, 0)
RainParticle.Color = ColorSequence.new(Color3.fromRGB(200, 200, 255))
RainParticle.Enabled = false

-- 4. GUI OVERLAYS
local FXGui = Instance.new("ScreenGui", CoreGui)
FXGui.Name = "SurrealFX"
FXGui.IgnoreGuiInset = true
FXGui.ResetOnSpawn = false

-- Chromatic Aberration
local CA = Instance.new("ImageLabel", FXGui)
CA.Name = "ChromaticAberration"
CA.Size = UDim2.new(1.02, 0, 1.02, 0)
CA.Position = UDim2.new(-0.01, 0, -0.01, 0)
CA.BackgroundTransparency = 1
CA.Image = "rbxassetid://499687787"
CA.ImageTransparency = 0.85
CA.ScaleType = Enum.ScaleType.Stretch

-- Film Grain
local Grain = Instance.new("ImageLabel", FXGui)
Grain.Name = "FilmGrain"
Grain.Size = UDim2.new(1, 0, 1, 0)
Grain.BackgroundTransparency = 1
Grain.Image = "rbxassetid://10952089880"
Grain.ImageTransparency = 0.92
Grain.TileSize = UDim2.new(0, 512, 0, 512)
Grain.ScaleType = Enum.ScaleType.Tile

-- Vignette
local VignetteImg = Instance.new("ImageLabel", FXGui)
VignetteImg.Name = "Vignette"
VignetteImg.Size = UDim2.new(1, 0, 1, 0)
VignetteImg.BackgroundTransparency = 1
VignetteImg.Image = "rbxassetid://7148843234"
VignetteImg.ImageTransparency = 0.3

-- 5. WEATHER LOGIC
local isStormy = true
local weatherDebounce = false

local function setSunMode()
    isStormy = false
    local t = TweenInfo.new(3, Enum.EasingStyle.Sine)
    
    -- Lighting (Reduced Exposure)
    TweenService:Create(Lighting, t, {
        ClockTime = 6.8, Brightness = 1.5, ExposureCompensation = 0,
        EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1
    }):Play()
    
    -- Atmosphere (Safe Levels)
    TweenService:Create(Atmosphere, t, {
        Density = 0.3, Haze = 0.5, Glare = 0.25,
        Decay = Color3.fromRGB(255, 200, 150), Color = Color3.fromRGB(180, 180, 200)
    }):Play()
    
    TweenService:Create(SunRays, t, {Intensity = 0.3, Spread = 0.8}):Play()
    
    TweenService:Create(Clouds, t, {Cover = 0}):Play()
    TweenService:Create(RainSound, t, {Volume = 0}):Play()
    TweenService:Create(Terrain, t, {WaterWaveSize = 0, WaterTransparency = 1}):Play()
    
    RainParticle.Enabled = false
end

local function setStormMode()
    isStormy = true
    local t = TweenInfo.new(3, Enum.EasingStyle.Sine)
    
    TweenService:Create(Lighting, t, {
        ClockTime = 0, Brightness = 0, ExposureCompensation = 0,
        EnvironmentDiffuseScale = 0.2, EnvironmentSpecularScale = 0.2
    }):Play()
    
    TweenService:Create(Atmosphere, t, {
        Density = 0.45, Haze = 2, Glare = 0,
        Color = Color3.fromRGB(100, 100, 110)
    }):Play()
    
    TweenService:Create(SunRays, t, {Intensity = 0}):Play()
    
    TweenService:Create(Clouds, t, {Cover = 1}):Play()
    TweenService:Create(RainSound, t, {Volume = 0.5}):Play()
    
    Terrain.WaterWaveSize = 0.1
    Terrain.WaterWaveSpeed = 10
    Terrain.WaterReflectance = 1
    Terrain.WaterTransparency = 0.2
    
    RainParticle.Enabled = true
    RainParticle.Rate = 2000
end

-- 6. RTX SHADER PRESETS
local Shaders = {
    [1] = {Name = "Standard", Saturation = 0.2, Contrast = 0.2, Tint = Color3.fromRGB(255, 248, 240)},
    [2] = {Name = "VIBRANT RTX", Saturation = 0.6, Contrast = 0.4, Tint = Color3.fromRGB(255, 255, 255)},
    [3] = {Name = "Cold Cinema", Saturation = -0.1, Contrast = 0.3, Tint = Color3.fromRGB(200, 220, 255)},
    [4] = {Name = "Noir", Saturation = -1, Contrast = 0.5, Tint = Color3.fromRGB(255, 255, 255)}
}
local currentShaderIndex = 1

local function applyShader(index)
    local data = Shaders[index]
    print("SWITCHING SHADER TO: "..data.Name)
    local t = TweenInfo.new(1)
    TweenService:Create(CC, t, {
        Saturation = data.Saturation, Contrast = data.Contrast, TintColor = data.Tint
    }):Play()
end

local function toggleGlossyMap(enable)
    print(enable and "ENABLING GLOSSY MAP" or "DISABLING GLOSSY MAP")
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsDescendantOf(Player.Character) then
            if enable then
                if obj.Material == Enum.Material.Plastic or obj.Material == Enum.Material.Concrete or obj.Material == Enum.Material.Asphalt then
                    obj.Reflectance = 0.2 
                    obj.Material = Enum.Material.SmoothPlastic
                end
            else
                obj.Reflectance = 0
            end
        end
    end
end

-- 7. RUN LOOPS
local lastFocus = 10
local lastCamCF = Camera.CFrame
local bobX, bobY = 0, 0
local seed = 0

RunService.RenderStepped:Connect(function(dt)
    -- Rain Follow
    if Player.Character and Player.Character:FindFirstChild("Head") then
        RainEmitter.Position = Player.Character.Head.Position + Vector3.new(0, 50, 0)
    end
    
    -- Film Grain
    seed = seed + 1
    if seed % 2 == 0 then
        Grain.Position = UDim2.new(0, math.random(-50, 50), 0, math.random(-50, 50))
    end
    
    -- Autofocus
    local rayOrigin = Camera.CFrame.Position
    local rayDir = Camera.CFrame.LookVector * 500
    local params = RaycastParams.new()
    if Player.Character then params.FilterDescendantsInstances = {Player.Character} end
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    local res = Workspace:Raycast(rayOrigin, rayDir, params)
    local targetDist = res and (res.Position - rayOrigin).Magnitude or 50
    lastFocus = lastFocus + (targetDist - lastFocus) * 0.15
    DOF.FocusDistance = lastFocus
    
    -- Motion Blur
    local deltaRot = Camera.CFrame.Rotation * lastCamCF.Rotation:Inverse()
    local rx, ry, rz = deltaRot:ToEulerAnglesXYZ()
    local rotMag = math.abs(rx) + math.abs(ry) + math.abs(rz)
    Blur.Size = Blur.Size + ((math.clamp(rotMag * 150, 0, 15) - Blur.Size) * 0.2)
    lastCamCF = Camera.CFrame
    
    -- Head Bob
    if Player.Character and Player.Character:FindFirstChild("Humanoid") then
        local vel = Player.Character.PrimaryPart and Player.Character.PrimaryPart.Velocity or Vector3.new()
        local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
        
        if speed > 0.1 then
            local t = tick()
            bobY = math.sin(t * 14) * 0.4 * (speed / 16)
            bobX = math.cos(t * 7) * 0.4 * (speed / 16)
            Camera.CFrame = Camera.CFrame * CFrame.new(bobX*0.1, bobY*0.1, 0) * CFrame.Angles(0, 0, math.rad(bobX * 0.05 * speed))
        else
            Camera.CFrame = Camera.CFrame * CFrame.new(0, math.sin(tick() * 1.5) * 0.05, 0)
        end
    end
end)

-- 8. INPUTS
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.KeyCode == Enum.KeyCode.P then
        if weatherDebounce then return end
        weatherDebounce = true
        if isStormy then setSunMode() else setStormMode() end
        wait(3)
        weatherDebounce = false
    end
    
    if input.KeyCode == Enum.KeyCode.J then
        currentShaderIndex = currentShaderIndex + 1
        if currentShaderIndex > #Shaders then currentShaderIndex = 1 end
        applyShader(currentShaderIndex)
    end
    
    if input.KeyCode == Enum.KeyCode.K then toggleGlossyMap(true) end
    if input.KeyCode == Enum.KeyCode.L then toggleGlossyMap(false) end

    if input.KeyCode == Enum.KeyCode.X then
        Lighting.Brightness = 1
        Lighting.ExposureCompensation = 0
        Atmosphere.Haze = 0
        Atmosphere.Glare = 0
        CC.TintColor = Color3.new(1,1,1)
        CC.Saturation = 0
        CC.Contrast = 0
    end
end)

-- INITIALIZE
if Lighting.ClockTime > 6 and Lighting.ClockTime < 18 then
    setSunMode()
else
    setStormMode()
end

print("ULTRA REALISM MASTER SCRIPT (v1.1 FIXED) LOADED")
