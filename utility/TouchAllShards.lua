-- TouchAllShards.lua
-- Runs one time to touch all "Shards" in workspace.Shards

local lp = game.Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

local shardsFolder = workspace:FindFirstChild("Shards")

if shardsFolder then
    print("Found Shards folder, processing...")
    local count = 0
    for _, descendant in pairs(shardsFolder:GetDescendants()) do
        -- Check for TouchInterest (which handles the touch event)
        if descendant:IsA("TouchTransmitter") then
            -- The Parent of the TouchTransmitter is the Part that needs to be touched
            local part = descendant.Parent
            if part and part:IsA("BasePart") then
                -- Fire touch interest: (PartToTouch, BodyPart, 0=Start/1=End)
                firetouchinterest(root, part, 0) -- Begin touch
                firetouchinterest(root, part, 1) -- End touch
                count = count + 1
            end
        end
    end
    print("Touched " .. count .. " shards.")
else
    warn("workspace.Shards folder not found!")
end
