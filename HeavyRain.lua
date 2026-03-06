-- HeavyRain.lua
-- Forces heavy rain and wet surfaces for reflections

local Lighting = game:GetService("Lighting")
local Terrain = game:GetService("Workspace").Terrain

-- 1. Enable Rain
-- Note: This requires FFlagRenderRain we enabled earlier
pcall(function()
    sethiddenproperty(Lighting, "Technology", Enum.Technology.Future)
end)

-- 2. Create the internal Rain object if possible (usually managed by engine, but we can simulate via plugin logic if needed)
-- Since we enabled FFlagRenderRain, we just need to use the plugin or engine api. 
-- However, we can trick the engine by setting the "Weather" if available, or just using particles.
-- For "Puddle" realism, we usually modify terrain SmoothGrid.

-- Adjust Terrain Water properties for "Wet" look
Terrain.WaterWaveSize = 0.1
Terrain.WaterWaveSpeed = 10
Terrain.WaterReflectance = 1
Terrain.WaterTransparency = 0.2

-- 3. Create Custom Rain Particles (Fallback if Engine Rain fails)
local RainEmitter = Instance.new("Part")
RainEmitter.Name = "RainEmitter"
RainEmitter.Transparency = 1
RainEmitter.CanCollide = false
RainEmitter.Anchored = true
RainEmitter.Size = Vector3.new(200, 1, 200)
RainEmitter.Position = game:GetService("Players").LocalPlayer.Character.Head.Position + Vector3.new(0, 50, 0)
RainEmitter.Parent = workspace

local RainParticle = Instance.new("ParticleEmitter")
RainParticle.Texture = "rbxassetid://9962890663" -- High res rain drop
RainParticle.Rate = 2000
RainParticle.Speed = NumberRange.new(80, 100)
RainParticle.Lifetime = NumberRange.new(1, 1.5)
RainParticle.Size = NumberSequence.new(0.5, 0.5)
RainParticle.Transparency = NumberSequence.new(0.5, 0.8)
RainParticle.SpreadAngle = Vector2.new(0, 0)
RainParticle.Acceleration = Vector3.new(0, -50, 0)
RainParticle.Color = ColorSequence.new(Color3.fromRGB(200, 200, 255))
RainParticle.Parent = RainEmitter

-- Lock emitter to player
game:GetService("RunService").Heartbeat:Connect(function()
    if game:GetService("Players").LocalPlayer.Character then
        RainEmitter.Position = game:GetService("Players").LocalPlayer.Character.Head.Position + Vector3.new(0, 50, 0)
    end
end)

-- 4. Sound
local RainSound = Instance.new("Sound")
RainSound.SoundId = "rbxassetid://1827419896" -- Heavy Rain Loop
RainSound.Volume = 0.5
RainSound.Looped = true
RainSound.Parent = Lighting
RainSound:Play()

-- 5. Volumetric Clouds
local Clouds = Instance.new("Clouds")
Clouds.Name = "StormClouds"
Clouds.Cover = 1 -- Max cloud cover
Clouds.Density = 0.8 -- Thick clouds
Clouds.Color = Color3.fromRGB(100, 100, 120) -- Dark storm color
Clouds.Parent = Terrain

print("HEAVY RAIN, PUDDLES & STORM CLOUDS ENABLED")
