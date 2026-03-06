--[[
    Vehicle God Mode Experiments (Unnamed API Version)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Unnamed API UI Setup
local Tab = api:GetTab("Vehicle God") or api:AddTab("Vehicle God")
local MainBox = Tab:AddLeftGroupbox("Methods")

-- Buy Vehicle Section
local BuyBox = Tab:AddRightGroupbox("Vehicle Shop")

BuyBox:AddButton({
    Text = 'Buy [Bike] ($400)',
    Func = function()
        -- Attempt to find shop item in Workspace
        -- Unlike guns, vehicles might be in a different folder or use the same shop logic.
        -- We will try assuming they are in Workspace.Ignored.Shop first.
        
        local targetName = "[Bike] - $400" -- Common format
        local shopItem = Workspace.Ignored.Shop:FindFirstChild(targetName)
        
        -- Fallback search if exact name differs
        if not shopItem then
             for _, child in pairs(Workspace.Ignored.Shop:GetChildren()) do
                 if child.Name:find("Bike") then
                     shopItem = child
                     break
                 end
             end
        end

        if shopItem and shopItem:FindFirstChild("Head") and shopItem:FindFirstChild("ClickDetector") then
             local oldPos = LocalPlayer.Character.HumanoidRootPart.CFrame
             -- TP to buy
             if api.teleport then
                 api.teleport(shopItem.Head.CFrame)
             else
                 LocalPlayer.Character.HumanoidRootPart.CFrame = shopItem.Head.CFrame
             end
             task.wait(0.5)
             fireclickdetector(shopItem.ClickDetector)
             task.wait(0.5)
             if api.teleport then
                 api.teleport(oldPos)
             else
                 LocalPlayer.Character.HumanoidRootPart.CFrame = oldPos
             end
             api:notify("Attempted to buy Bike.")
        else
             api:notify("Shop item not found!", 3)
        end
    end,
})

BuyBox:AddButton({
    Text = 'Teleport to Car Dealership',
    Func = function()
        -- Approximate location of Car Dealership
        local dealershipPos = CFrame.new(-185, 48, 860) -- Rough coords based on map knowledge
        if api.teleport then
             api.teleport(dealershipPos)
        else
             LocalPlayer.Character.HumanoidRootPart.CFrame = dealershipPos
        end
    end,
})

MainBox:AddButton({
    Text = 'Method 1: Local Null',
    Func = function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart then
            print("Attempting Method 1 (Local Null)...")
            char.Parent = nil -- Hide locally
            api:notify("Method 1 Applied: Local Null")
        else
            api:notify("Sit in a vehicle first!", 3)
        end
    end,
})

MainBox:AddButton({
    Text = 'Method 2: Void Car',
    Func = function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.SeatPart then
            local seat = char.Humanoid.SeatPart
            local vehicle = seat.Parent
            if vehicle then
                api:notify("Method 2 Applied: Void Car")
                 if sethiddenproperty then
                     sethiddenproperty(seat, "CFrame", CFrame.new(0, -900, 0)) 
                 else
                     vehicle:PivotTo(CFrame.new(0, -900, 0))
                 end
            end
        else
            api:notify("Sit in a vehicle first!", 3)
        end
    end,
})

MainBox:AddButton({
    Text = 'Method 3: State Glitch',
    Func = function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
            char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
            char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            api:notify("Method 3 Applied: State Glitch")
        end
    end,
})

-- Info
local InfoBox = Tab:AddRightGroupbox("Info")
InfoBox:AddLabel("Method 1: Makes you invisible/invincible locally.")
InfoBox:AddLabel("Method 2: Teleports car to void.")
InfoBox:AddLabel("Method 3: Forces physics state.")
