-- GripForceTest.lua
-- Run this to check if ANY grip modification works
-- It should move your gun WAY UP (10 studs)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("--- STARTING GRIP FORCE TEST ---")

RunService:BindToRenderStep("ForceGripDebug", 1, function()
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildWhichIsA("Tool")
    if tool then
        -- Force a massive noticeable offset
        tool.Grip = CFrame.new(0, 10, 0)
        
        -- Also try Motor6D
        local arm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
        if arm and arm:FindFirstChild("RightGrip") then
            arm.RightGrip.C1 = CFrame.new(0, 10, 0)
        end
    end
end)

api:notify("DEBUG: Forcing Grip UP by 10 studs", 5)
