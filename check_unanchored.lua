
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Function to check if a part belongs to a player's character
local function isPlayerCharacter(part)
    local ancestor = part
    while ancestor and ancestor ~= Workspace do
        if ancestor:IsA("Model") then
             if Players:GetPlayerFromCharacter(ancestor) then
                return true
             end
        end
        ancestor = ancestor.Parent
    end
    return false
end

local outputLines = {}
table.insert(outputLines, "Scan started at: " .. os.date("%c"))
table.insert(outputLines, "Listing unanchored parts (excluding players):")
table.insert(outputLines, "---------------------------------------------")

local count = 0

-- Visuals Setup
local VisualsFolder = game:GetService("CoreGui"):FindFirstChild("UnanchoredVisuals")
if VisualsFolder then
    VisualsFolder:Destroy()
end

VisualsFolder = Instance.new("Folder")
VisualsFolder.Name = "UnanchoredVisuals"
VisualsFolder.Parent = game:GetService("CoreGui")

for _, descendant in ipairs(Workspace:GetDescendants()) do
    if descendant:IsA("BasePart") then
        if not descendant.Anchored then
            -- Check if it belongs to a player
            if not isPlayerCharacter(descendant) then
                table.insert(outputLines, descendant:GetFullName())
                count = count + 1
                
                -- Create Highlight
                local box = Instance.new("SelectionBox")
                box.Name = "UnanchoredHighlight"
                box.Adornee = descendant
                box.Color3 = Color3.new(1, 0, 0) -- Red
                box.LineThickness = 0.05
                box.SurfaceTransparency = 0.8
                box.Transparency = 0.3
                box.Parent = VisualsFolder

                -- Special Logic for Seats
                if descendant:IsA("Seat") or descendant:IsA("VehicleSeat") then
                    box.Color3 = Color3.new(0, 1, 0) -- Green for Seats
                end
            end
        end
    end
end

table.insert(outputLines, "---------------------------------------------")
table.insert(outputLines, "Total found: " .. count)

local fileContent = table.concat(outputLines, "\n")
local fileName = "unanchored_parts_dump.txt"

writefile(fileName, fileContent)

print("Scan complete.")
print("Found " .. count .. " unanchored parts.")
print("Saved to " .. fileName)

-- Bring Logic
local LocalPlayer = Players.LocalPlayer

local function BringAllUnanchored()
    print("Starting Bring Unanchored Sequence...")
    local originalCFrame = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.CFrame
    
    if not originalCFrame then
        warn("Character RootPart not found!")
        return
    end

    local broughtCount = 0
    local radius = 0 -- To stack them slightly apart or just pile them

    for _, descendant in ipairs(Workspace:GetDescendants()) do
        if descendant:IsA("BasePart") and not descendant.Anchored and not isPlayerCharacter(descendant) then
             local char = LocalPlayer.Character
             if char and char:FindFirstChild("HumanoidRootPart") then
                
                -- Attempt to claim network ownership
                pcall(function()
                    descendant:SetNetworkOwner(LocalPlayer)
                end)

                -- Bring
                descendant.CFrame = originalCFrame + Vector3.new(0, 0, -5) -- 5 studs in front
                descendant.Velocity = Vector3.new(0,0,0)
                descendant.RotVelocity = Vector3.new(0,0,0)
                descendant.CanCollide = false -- Prevent flinging
                
                broughtCount = broughtCount + 1
             end
        end
    end
    
    print("Brought " .. broughtCount .. " unanchored parts.")
end

-- Expose function to global environment for execution
getgenv().BringAllUnanchored = BringAllUnanchored

-- Auto-run scanning (Visuals)
-- The visual scanning part above runs automatically when script loads.

print("Heads up! Visual scan ran automatically.")
print("To BRING the parts, execute: BringAllUnanchored()")

