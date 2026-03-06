-- Shape Addon with Customizable UI
-- Allows specific placement of items relative to the hand/torso

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Check for API
-- As a fallback, we assume 'api' and 'Options' are available globally if getgenv() fails or is empty
if not api and getgenv().api then
    getgenv().api = api
end

-- UI Setup
-- We access 'api' directly. passing it as a global.
local Tab = api:GetTab("Custom Shape") or api:AddTab("Custom Shape")

-- UI Elements
local ConfigGroup = Tab:AddRightGroupbox("Configuration")
local MenuGroup = Tab:AddLeftGroupbox("Menu")

-- Helper to find tools
local function GetTools(Name)
    local Tools = {}
    if LocalPlayer.Character then
        for _, Item in pairs(LocalPlayer.Character:GetChildren()) do
            if Item:IsA("Tool") and Item.Name == Name then
                table.insert(Tools, Item)
            end
        end
    end
    -- Fallback to Backpack if not equipped (optional, but Grip only matters when equipped)
    -- Actually, we usually want to edit them only when equipped or about to be.
    return Tools
end

-- --- Actions ---

-- --- Actions ---

MenuGroup:AddButton({
    Text = 'Buy Full Kit (2 of Each)',
    Func = function()
        local function Buy(Item, Price)
            local BoughtItem
            local Start = tick()
            repeat RunService.Heartbeat:Wait()
                local Shop = Workspace.Ignored.Shop:FindFirstChild(Item .. " - $" .. Price)
                if Shop and Shop:FindFirstChild("Head") and Shop:FindFirstChild("ClickDetector") then
                    api:set_server_cframe(Shop.Head.CFrame)
                    fireclickdetector(Shop.ClickDetector)
                end
                BoughtItem = LocalPlayer.Backpack:FindFirstChild(Item)
            until BoughtItem or tick() - Start > 2
            if BoughtItem then BoughtItem.Parent = LocalPlayer.Character end
        end

        Buy("[SledgeHammer]", 394)
        Buy("[SledgeHammer]", 394)
        Buy("[Shovel]", 360)
        Buy("[Shovel]", 360)
        Buy("[Bat]", 310)
        Buy("[Bat]", 310)
        Buy("[Pitchfork]", 360)
        Buy("[Pitchfork]", 360)
        Buy("[StopSign]", 338)
        Buy("[StopSign]", 338)
        
        -- Reset to backpack
        if LocalPlayer.Character then
             LocalPlayer.Character.Humanoid:UnequipTools()
        end
    end,
})

MenuGroup:AddButton({
    Text = 'Equip All Tools',
    Func = function()
        for _, Tool in pairs(LocalPlayer.Backpack:GetChildren()) do
             if Tool:IsA("Tool") then
                 Tool.Parent = LocalPlayer.Character
                 task.wait(0.25)
             end
        end
    end,
})

MenuGroup:AddToggle('LiveUpdate', {
    Text = 'Live Update Grips',
    Default = true,
})

-- --- Configuration Helpers ---

local ToolOptions = { "[StopSign]", "[Bat]", "[Shovel]", "[Pitchfork]", "[SledgeHammer]" }

local function CreateSlotConfig(Id, Label, DefaultTool, DefaultPos, DefaultRot)
    ConfigGroup:AddLabel(Label)
    
    ConfigGroup:AddDropdown(Id .. '_Tool', {
        Values = ToolOptions,
        Default = table.find(ToolOptions, DefaultTool) or 1,
        Multi = false,
        Text = 'Tool Type',
    })
    
    ConfigGroup:AddSlider(Id .. '_X', { Text = 'X', Default = DefaultPos.X, Min = -10, Max = 10, Rounding = 1 })
    ConfigGroup:AddSlider(Id .. '_Y', { Text = 'Y', Default = DefaultPos.Y, Min = -20, Max = 20, Rounding = 1 })
    ConfigGroup:AddSlider(Id .. '_Z', { Text = 'Z', Default = DefaultPos.Z, Min = -10, Max = 10, Rounding = 1 })
    
    ConfigGroup:AddSlider(Id .. '_RX', { Text = 'Rot X', Default = DefaultRot.X, Min = 0, Max = 360, Rounding = 0 })
    ConfigGroup:AddSlider(Id .. '_RY', { Text = 'Rot Y', Default = DefaultRot.Y, Min = 0, Max = 360, Rounding = 0 })
    ConfigGroup:AddSlider(Id .. '_RZ', { Text = 'Rot Z', Default = DefaultRot.Z, Min = 0, Max = 360, Rounding = 0 })
    
    ConfigGroup:AddDivider()
end

-- Define 5 Generic Slots (Defaults set to previous shape)
CreateSlotConfig('Slot1', 'Slot 1 (Base/Ball)', '[StopSign]', Vector3.new(1.5, 0, 0), Vector3.new(0, 90, 0))
CreateSlotConfig('Slot2', 'Slot 2 (Base/Ball)', '[StopSign]', Vector3.new(-1.5, 0, 0), Vector3.new(0, 90, 0))
CreateSlotConfig('Slot3', 'Slot 3 (Shaft)', '[Bat]', Vector3.new(0, -2.5, 0), Vector3.new(0, 0, 0))
CreateSlotConfig('Slot4', 'Slot 4 (Shaft)', '[Bat]', Vector3.new(0, -6.5, 0), Vector3.new(0, 0, 0))
CreateSlotConfig('Slot5', 'Slot 5 (Tip)', '[Shovel]', Vector3.new(0, 5.5, 0), Vector3.new(180, 0, 0))


-- --- Update Logic ---

local function GetConfigCFrame(Id)
    local Opts = getgenv().Options
    if not Opts then return CFrame.new() end

    local X = Opts[Id .. '_X'] and Opts[Id .. '_X'].Value or 0
    local Y = Opts[Id .. '_Y'] and Opts[Id .. '_Y'].Value or 0
    local Z = Opts[Id .. '_Z'] and Opts[Id .. '_Z'].Value or 0
    
    local RX = Opts[Id .. '_RX'] and Opts[Id .. '_RX'].Value or 0
    local RY = Opts[Id .. '_RY'] and Opts[Id .. '_RY'].Value or 0
    local RZ = Opts[Id .. '_RZ'] and Opts[Id .. '_RZ'].Value or 0
    
    return CFrame.new(X, Y, Z) * CFrame.Angles(math.rad(RX), math.rad(RY), math.rad(RZ))
end

RunService.RenderStepped:Connect(function()
    if not (getgenv().Toggles and getgenv().Toggles.LiveUpdate and getgenv().Toggles.LiveUpdate.Value) then return end
    
    local Opts = getgenv().Options
    if not Opts then return end
    
    local UsedTools = {}
    
    for i = 1, 5 do
        local SlotId = 'Slot' .. i
        local ToolName = Opts[SlotId .. '_Tool'] and Opts[SlotId .. '_Tool'].Value
        
        if ToolName and LocalPlayer.Character then
            -- Find an available tool of this type
            local FoundTool = nil
            for _, Tool in pairs(LocalPlayer.Character:GetChildren()) do
                if Tool:IsA("Tool") and Tool.Name == ToolName and not UsedTools[Tool] then
                    FoundTool = Tool
                    break
                end
            end
            
            if FoundTool then
                 FoundTool.Grip = GetConfigCFrame(SlotId)
                 UsedTools[FoundTool] = true
            end
        end
    end
end)
