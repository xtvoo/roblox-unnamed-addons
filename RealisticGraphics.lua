-- RealisticGraphics.lua
-- Overwrites game lighting to be "Super Realistic"

local Lighting = game:GetService("Lighting")
local MaterialService = game:GetService("MaterialService")

-- 1. clear existing post-processing to avoid conflicts
for _, child in pairs(Lighting:GetChildren()) do
    if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") then
        child:Destroy()
    end
end

-- 2. General Lighting Settings
Lighting.GlobalShadows = true
Lighting.Ambient = Color3.fromRGB(50, 50, 50) -- Darker ambient for contrast
Lighting.OutdoorAmbient = Color3.fromRGB(80, 80, 80) -- Realistic gray outdoor lighting
Lighting.Brightness = 2 -- Bright sun
Lighting.EnvironmentDiffuseScale = 1 -- Full environment reflection (Diffuse)
Lighting.EnvironmentSpecularScale = 1 -- Full environment reflection (Specular)
Lighting.ExposureCompensation = 0.5 -- Slight overexposure for realism
Lighting.GeographicLatitude = 41.7
Lighting.ShadowSoftness = 0.1 -- Sharp, realistic shadows (if legacy tech used)

-- Force Future lighting if possible (usually read-only in scripts, but valid in Studio/Executors)
pcall(function()
    sethiddenproperty(Lighting, "Technology", Enum.Technology.Future)
end)

-- 3. Atmosphere (Volumetric Fog feel)
local Atmosphere = Instance.new("Atmosphere")
Atmosphere.Density = 0.35
Atmosphere.Offset = 0
Atmosphere.Color = Color3.fromRGB(199, 199, 199)
Atmosphere.Decay = Color3.fromRGB(106, 112, 125)
Atmosphere.Glare = 0.6
Atmosphere.Haze = 2
Atmosphere.Parent = Lighting

-- 4. Bloom (Glow)
local Bloom = Instance.new("BloomEffect")
Bloom.Intensity = 1.2
Bloom.Size = 25
Bloom.Threshold = 1.8
Bloom.Parent = Lighting

-- 5. Color Correction (Tone Mapping)
local CC = Instance.new("ColorCorrectionEffect")
CC.Brightness = 0.05
CC.Contrast = 0.2 -- Higher contrast for cinematic look
CC.Saturation = 0.2 -- Slightly vibrant
CC.TintColor = Color3.fromRGB(255, 248, 240) -- Warm sunlight tint
CC.Parent = Lighting

-- 6. Sun Rays (God Rays)
local SunRays = Instance.new("SunRaysEffect")
SunRays.Intensity = 0.15
SunRays.Spread = 0.8
SunRays.Parent = Lighting

-- 7. Depth Of Field (Cinematic focus)
local DOF = Instance.new("DepthOfFieldEffect")
DOF.FarIntensity = 0.15
DOF.FocusDistance = 25
DOF.InFocusRadius = 25
DOF.NearIntensity = 0.1
DOF.Parent = Lighting

-- 8. Material Overrides (Cleaner textures)
if MaterialService then
    MaterialService.Use2022Materials = true -- Force new materials
end

print("SUPER REALISTIC GRAPHICS LOADED")
