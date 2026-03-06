local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()

local Window = OrionLib:MakeWindow({Name = "AFK Farm", HidePremium = false, SaveConfig = false, ConfigFolder = "AFKFarm"})

local Tab = Window:MakeTab({
	Name = "Main",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local Section = Tab:AddSection({
	Name = "AFK Options"
})

local isFarming = false
local farmSpeed = 0.1

-- Target Part
local targetPlotName = "5587308965Plot"
-- Safe access to the part
local function getTargetPart()
    local main = workspace:FindFirstChild("Main")
    if not main then return nil end
    local plots = main:FindFirstChild("Plots")
    if not plots then return nil end
    local plot = plots:FindFirstChild(targetPlotName)
    if not plot then return nil end
    return plot:FindFirstChild("AFKPart")
end

Tab:AddToggle({
	Name = "Enable AFK Farm",
	Default = false,
	Callback = function(Value)
		isFarming = Value
		
		if isFarming then
            task.spawn(function()
                while isFarming do
                    local part = getTargetPart()
                    local player = game.Players.LocalPlayer
                    local character = player.Character
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

                    if part and rootPart then
                        -- firetouchinterest(Part, BodyPart, 0 for touch/1 for untouch)
                        -- Some executors handle this differently, but this is the standard API.
                        firetouchinterest(part, rootPart, 0)
                        task.wait()
                        firetouchinterest(part, rootPart, 1)
                    end
                    task.wait(farmSpeed)
                end
            end)
        end
	end    
})

Tab:AddSlider({
	Name = "Speed (Seconds)",
	Min = 0,
	Max = 2,
	Default = 0.1,
	Color = Color3.fromRGB(255,255,255),
	Increment = 0.05,
	ValueName = "s",
	Callback = function(Value)
		farmSpeed = Value
	end    
})

OrionLib:Init()
