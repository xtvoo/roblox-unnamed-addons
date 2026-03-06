-- SurrealFX.lua
-- Adds static overlay effects: Lens Dirt, Film Grain, and Chromatic Aberration simulation

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local FXGui = Instance.new("ScreenGui")
FXGui.Name = "SurrealFX"
FXGui.IgnoreGuiInset = true
FXGui.ResetOnSpawn = false
FXGui.Parent = CoreGui -- or Players.LocalPlayer:WaitForChild("PlayerGui")

Lens Dirt (Static texture that catches light)
local LensDirt = Instance.new("ImageLabel")
LensDirt.Name = "LensDirt"
LensDirt.BackgroundTransparency = 1
LensDirt.Size = UDim2.new(1, 0, 1, 0)
LensDirt.Image = "rbxassetid://8139665943" -- Dirty lens bokeh texture
LensDirt.ImageTransparency = 0.95 -- Much more subtle (Fixed from 0.8)
LensDirt.ImageColor3 = Color3.fromRGB(255, 255, 255) -- Neutral color
LensDirt.Parent = FXGui

-- 2. Chromatic Aberration (Fake Overlay - efficient)
-- A high quality CA overlay texture
local CA_Overlay = Instance.new("ImageLabel")
CA_Overlay.Name = "ChromaticAberration"
CA_Overlay.BackgroundTransparency = 1
CA_Overlay.Size = UDim2.new(1.02, 0, 1.02, 0) -- Slightly larger to cover edges
CA_Overlay.Position = UDim2.new(-0.01, 0, -0.01, 0)
CA_Overlay.Image = "rbxassetid://499687787" -- RGB split overlay
CA_Overlay.ImageTransparency = 0.85 -- Subtle color fringing
CA_Overlay.ScaleType = Enum.ScaleType.Stretch
CA_Overlay.Parent = FXGui

-- 3. Film Grain (Moving noise)
local GrainButton = Instance.new("ImageLabel")
GrainButton.Name = "FilmGrain"
GrainButton.BackgroundTransparency = 1
GrainButton.Size = UDim2.new(1, 0, 1, 0)
GrainButton.Image = "rbxassetid://10952089880" -- Noise texture
GrainButton.ImageTransparency = 0.92
GrainButton.TileSize = UDim2.new(0, 512, 0, 512)
GrainButton.ScaleType = Enum.ScaleType.Tile
GrainButton.Parent = FXGui

-- Animate Grain
local seed = 0
RunService.RenderStepped:Connect(function()
    seed = seed + 1
    if seed % 2 == 0 then -- Update every other frame to feel like 24fps film
        local x = math.random(-100, 100)
        local y = math.random(-100, 100)
        GrainButton.Position = UDim2.new(0, x, 0, y)
    end
end)

print("SURREAL FX LOADED: Lens Dirt, CA, Grain")
