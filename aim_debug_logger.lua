local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local RAY_DISTANCE = 100 -- How far to check for aiming
local DEBUG_MODE = true -- Print to console

-- Function to check if a ray hits a character
local function getTargetFromRay(originPart)
    local origin = originPart.Position
    local direction = originPart.CFrame.LookVector * RAY_DISTANCE

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {originPart.Parent} -- Ignore the aimer themselves
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, raycastParams)

    if result and result.Instance then
        -- Check if we hit a Character
        local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
        if hitModel and hitModel:FindFirstChild("Humanoid") then
            -- It's a player/NPC
            local victim = Players:GetPlayerFromCharacter(hitModel)
            return victim, hitModel
        end
    end
    return nil, nil
end

-- Main Loop
RunService.Heartbeat:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        -- Skip checking ourselves if we only care about OTHERS aiming at us
        -- But user asked for "if player aims at anyone", so checking everyone.
        
        if player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            
            -- Optional: Check Tool instead if equipped?
            -- Da Hood players aim with mouse, so Head look vector is usually accurate 
            -- unless using shift lock, but it's a good approximation.
            
            local victimPlayer, victimChar = getTargetFromRay(head)
            
            if victimChar then
                local victimName = victimPlayer and victimPlayer.Name or victimChar.Name
                if DEBUG_MODE then
                    -- Debounce or simple print? 
                    -- Simple print spams console, so we might want to throttle it.
                    -- For now, formatted print.
                    print(string.format("[AIM DEBUG] %s is aiming at %s", player.Name, victimName))
                end
            end
        end
    end
end)

print("Aim Debug Logger Started...")
