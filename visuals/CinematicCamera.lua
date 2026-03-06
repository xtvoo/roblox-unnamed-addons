-- CinematicCamera.lua
-- Adds Autobofocus Depth of Field, Motion Blur, and Vignette

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- 1. Setup Depth of Field (Autofocus)
local DOF = Lighting:FindFirstChild("CinematicDOF") or Instance.new("DepthOfFieldEffect")
DOF.Name = "CinematicDOF"
DOF.FarIntensity = 0.5 -- Blurry background
DOF.NearIntensity = 0.1 -- Slight blur near camera
DOF.FocusDistance = 10
DOF.InFocusRadius = 25 -- How much area is sharp
DOF.Parent = Lighting

-- 2. Setup Motion Blur (Simulated)
local Blur = Lighting:FindFirstChild("MotionBlur") or Instance.new("BlurEffect")
Blur.Name = "MotionBlur"
Blur.Size = 0
Blur.Parent = Lighting

-- 3. Vignette (Dark corners)
local VignetteGUI = Instance.new("ScreenGui")
VignetteGUI.Name = "VignetteGUI"
VignetteGUI.IgnoreGuiInset = true
VignetteGUI.ResetOnSpawn = false
VignetteGUI.Parent = game.CoreGui -- Or PlayerGui if CoreGui is restricted

local VignetteImage = Instance.new("ImageLabel")
VignetteImage.Size = UDim2.new(1, 0, 1, 0)
VignetteImage.BackgroundTransparency = 1
VignetteImage.Image = "rbxassetid://7148843234" -- Soft black vignette texture
VignetteImage.ImageTransparency = 0.3
VignetteImage.Parent = VignetteGUI

-- 4. Autofocus Logic
local lastFocusDistance = 10
local focusSpeed = 0.15 -- Slower = more cinematic/heavy lens feel

-- 5. Motion Blur Logic
local lastCamCFrame = Camera.CFrame
local blurIntensity = 0

RunService.RenderStepped:Connect(function(dt)
    -- A. Autofocus Raycast
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = Camera.CFrame.LookVector * 500 -- Look 500 studs ahead
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {Players.LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local rayResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    local targetDistance = 50 -- Default infinite focus if sky
    if rayResult then
        targetDistance = (rayResult.Position - rayOrigin).Magnitude
    end

    -- Smoothly interpolate focus
    lastFocusDistance = lastFocusDistance + (targetDistance - lastFocusDistance) * focusSpeed
    DOF.FocusDistance = lastFocusDistance

    -- B. Dynamic Motion Blur based on Camera Rotation speed
    local currentCamCFrame = Camera.CFrame
    local rotationDelta = (currentCamCFrame.Rotation * lastCamCFrame.Rotation:Inverse())
    local x, y, z = rotationDelta:ToEulerAnglesXYZ()
    local rotationMagnitude = math.abs(x) + math.abs(y) + math.abs(z)
    
    -- Amplify rotation for blur size
    local targetBlur = math.clamp(rotationMagnitude * 150, 0, 15) 
    Blur.Size = Blur.Size + (targetBlur - Blur.Size) * 0.2 -- Smooth blur transition
    
    lastCamCFrame = currentCamCFrame
end)

print("CINEMATIC CAMERA: Autofocus & Motion Blur Enabled")
