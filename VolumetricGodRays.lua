-- VolumetricGodRays.lua
-- Adds extreme "God Rays" and allows toggling between Storm/Sun modes
-- Press 'P' to toggle between STORMY and SUNNY modes

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Build = game:GetService("RunService")
local Terrain = workspace:WaitForChild("Terrain")
local Camera = workspace.CurrentCamera

-- 1. Create SunRays if missing
local SunRays = Lighting:FindFirstChild("VolumetricRays") or Instance.new("SunRaysEffect")
SunRays.Name = "VolumetricRays"
SunRays.Parent = Lighting

-- 2. Create Attachment for Fake Volumetrics
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {Players.LocalPlayer.Character}

local isStormy = true -- Start in storm mode since we just enabled rain
local debounce = false

local function setSunMode()
    print("Switching to GOD RAY Mode (Sunny)")
    isStormy = false
    
    -- Animate to Sunny
    local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    
    -- A. Lighting & Sky
    TweenService:Create(Lighting, tweenInfo, {
        ClockTime = 6.8, -- Golden Hour morning
        Brightness = 3,
        ExposureCompensation = 0.2,
        ShadowSoftness = 0.2,
        EnvironmentDiffuseScale = 1,
        EnvironmentSpecularScale = 1
    }):Play()
    
    -- B. Atmosphere for Rays
    local Atmosphere = Lighting:FindFirstChildWhichIsA("Atmosphere")
    if Atmosphere then
        TweenService:Create(Atmosphere, tweenInfo, {
            Density = 0.3,
            Haze = 3, -- High haze for ray scattering
            Glare = 1, -- Max glare
            Decay = Color3.fromRGB(255, 200, 150),
            Color = Color3.fromRGB(180, 180, 200)
        }):Play()
    end
    
    -- C. SunRays Effect
    TweenService:Create(SunRays, tweenInfo, {
        Intensity = 0.5, -- High intensity
        Spread = 0.8
    }):Play()
    
    -- D. Disable Rain/Clouds
    local Clouds = Terrain:FindFirstChild("StormClouds")
    if Clouds then
        TweenService:Create(Clouds, tweenInfo, {Cover = 0}):Play()
    end
    
    local RainSound = Lighting:FindFirstChild("Sound")
    if RainSound then
        TweenService:Create(RainSound, tweenInfo, {Volume = 0}):Play()
    end
    
    -- Keep rain particles but make them invisible slowly? 
    -- (Assuming HeavyRain.lua manages particles, we can't easily stop them without IPC, 
    -- but we can change the physics)
end

local function setStormMode()
    print("Switching to STORM Mode")
    isStormy = true
    
    local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    
    -- A. Lighting & Sky
    TweenService:Create(Lighting, tweenInfo, {
        ClockTime = 0, -- Midnight
        Brightness = 0,
        ExposureCompensation = 0,
        EnvironmentDiffuseScale = 0.2,
        EnvironmentSpecularScale = 0.2
    }):Play()
    
    -- B. SunRays (Disabled)
    TweenService:Create(SunRays, tweenInfo, {
        Intensity = 0,
        Spread = 0
    }):Play()
    
    -- C. Enable Clounds
    local Clouds = Terrain:FindFirstChild("StormClouds")
    if Clouds then
        TweenService:Create(Clouds, tweenInfo, {Cover = 1}):Play()
    end
    
    local RainSound = Lighting:FindFirstChild("Sound")
    if RainSound then
        TweenService:Create(RainSound, tweenInfo, {Volume = 0.5}):Play()
    end
end

-- Input Toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P then
        if debounce then return end
        debounce = true
        
        if isStormy then
            setSunMode()
        else
            setStormMode()
        end
        
        wait(3)
        debounce = false
    end
end)

-- Initial State (Sync with current time?)
if Lighting.ClockTime > 6 and Lighting.ClockTime < 18 then
    setSunMode()
else
    setStormMode()
end

print("GOD RAYS SCRIPT LOADED. Press 'P' to toggle Rain/Sun.")
