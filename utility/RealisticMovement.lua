-- RealisticMovement.lua
-- Adds procedural Head Bob and Camera Sway for realistic walking feel

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Settings
local BOB_SPEED = 14
local BOB_INTENSITY = 0.4
local SWAY_INTENSITY = 0.4
local TILT_INTENSITY = 0.05

local bobX = 0
local bobY = 0

RunService.RenderStepped:Connect(function(dt)
    if not Character or not Humanoid then
        Character = Player.Character
        Humanoid = Character:FindFirstChild("Humanoid")
        return
    end

    local velocity = Character.PrimaryPart.Velocity
    local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
    
    if speed > 0.1 and Humanoid.MoveDirection.Magnitude > 0.1 then
        -- Calculate Bob
        local t = tick()
        bobY = math.sin(t * BOB_SPEED) * BOB_INTENSITY * (speed / 16) -- Vertical bob
        bobX = math.cos(t * BOB_SPEED / 2) * BOB_INTENSITY * (speed / 16) -- Horizontal sway
        
        -- Apply to Camera Offset (does not break aim usually)
        local bobVector = Vector3.new(bobX, bobY, 0) * 0.5
        
        -- Tilt (leaning into turns)
        local tilt = 0 
        -- (Complex CFrame math omitted for stability, focusing on bob)
        
        -- Apply Rotation Bump
        local currentCF = Camera.CFrame
        Camera.CFrame = currentCF * CFrame.new(bobX * 0.1, bobY * 0.1, 0)
                                  * CFrame.Angles(0, 0, math.rad(bobX * TILT_INTENSITY * speed))
    else
        -- Breathing idle
        local t = tick()
        local breathY = math.sin(t * 1.5) * 0.05
        Camera.CFrame = Camera.CFrame * CFrame.new(0, breathY, 0)
    end
end)

print("REALISTIC MOVEMENT LOADED: Head Bob & Sway")
