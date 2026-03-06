local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua'))()
local ThemeManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'Random Game Script',
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Main = Window:AddTab('Main'),
    UI = Window:AddTab('UI Settings'),
}

local Groupbox = Tabs.Main:AddLeftGroupbox('Automation')
local ExploitBox = Tabs.Main:AddRightGroupbox('Exploits')

-- Toggles
local AutoPower = false
local AutoGems = false
local AutoClick = false
local AutoWin = false
local SkipEgg = false

Groupbox:AddToggle('AutoPower', {
    Text = 'Auto Power (Touch Interests)',
    Default = false,
    Tooltip = 'Fires all touch interests in workspace.PowerHolder',
    Callback = function(Value)
        AutoPower = Value
        local processed = {}
        while AutoPower do
            task.wait()
            pcall(function()
                local powerHolder = workspace:FindFirstChild("PowerHolder")
                if powerHolder then
                    for _, part in ipairs(powerHolder:GetChildren()) do
                        if part:IsA("BasePart") and not processed[part] then
                             -- 0 = start touch, 1 = end touch. usually firing 0 then 1 simulates a touch.
                             -- however, for simple collection, sometimes just 0 works or 0 and 1.
                             -- we'll do both to be safe.
                            firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, part, 0)
                            firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, part, 1)
                            processed[part] = true
                        end
                    end
                end
            end)
        end
    end
})

Groupbox:AddToggle('AutoGems', {
    Text = 'Auto Gems (Touch Interests)',
    Default = false,
    Tooltip = 'Fires all touch interests in workspace.GemHolder',
    Callback = function(Value)
        AutoGems = Value
        local processed = {}
        while AutoGems do
            task.wait()
            pcall(function()
                local gemHolder = workspace:FindFirstChild("GemHolder")
                if gemHolder then
                    for _, part in ipairs(gemHolder:GetChildren()) do
                        if part:IsA("BasePart") and not processed[part] then
                            firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, part, 0)
                            firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, part, 1)
                            processed[part] = true
                        end
                    end
                end
            end)
        end
    end
})

Groupbox:AddToggle('AutoClick', {
    Text = 'Auto Click (Charge)',
    Default = false,
    Tooltip = 'Fires the Charge remote',
    Callback = function(Value)
        AutoClick = Value
        while AutoClick do
            task.wait()
            pcall(function()
                game:GetService("Players").LocalPlayer:WaitForChild("Charge"):FireServer()
            end)
        end
    end
})

Groupbox:AddToggle('AutoWin', {
    Text = 'Auto Win Race',
    Default = false,
    Tooltip = 'Fires WinTheRace remote',
    Callback = function(Value)
        AutoWin = Value
        while AutoWin do
            task.wait(0.1) -- Little delay to prevent crash/kick
            pcall(function()
                local args = {
                    "true",
                    0
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("WinTheRace"):FireServer(unpack(args))
            end)
        end
    end
})

Groupbox:AddToggle('SkipEgg', {
    Text = 'Skip Egg Hatch Animation',
    Default = false,
    Tooltip = 'Auto fires remote to skip egg opening',
    Callback = function(Value)
        SkipEgg = Value
        while SkipEgg do
            task.wait(0.1)
            pcall(function()
                local args = {
                    {
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                        { button_path = "EggOpening.Frame", button_name = "Frame" },
                    }
                }
                game:GetService("ReplicatedStorage"):WaitForChild("BloxbizRemotes"):WaitForChild("OnSendGuiImpressions"):FireServer(unpack(args))
            end)
        end
    end
})

-- Exploit Section
ExploitBox:AddInput('StatName', {
    Default = 'Money',
    Numeric = false,
    Finished = false,
    Text = 'Target Stat Name',
    Placeholder = 'e.g. Money, Cash, Wins',
})

ExploitBox:AddInput('StatValue', {
    Default = '999999',
    Numeric = false, -- Keep false to allow strings/bools if needed
    Finished = false,
    Text = 'New Value',
    Placeholder = 'Value',
})

ExploitBox:AddButton('Attempt Change Stat', function()
    local statName = Options.StatName.Value
    local statValue = Options.StatValue.Value
    
    -- Try to convert to number if possible
    if tonumber(statValue) then
        statValue = tonumber(statValue)
    end
    
    api:notify("Attempting to change " .. statName .. " to " .. tostring(statValue), 3)
    
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Admin") and game:GetService("ReplicatedStorage").Admin:FindFirstChild("ChangeStat")
    
    if remote then
        remote:FireServer(statName, statValue)
        api:notify("Fired!", 2)
    else
        api:notify("❌ Remote not found!", 3)
    end
end)

ExploitBox:AddButton('Test Common Stats', function()
    local common = {"Money", "Cash", "Coins", "Gems", "Wins", "Rebirths", "Strength", "Points"}
    local val = 1000000
    
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Admin") and game:GetService("ReplicatedStorage").Admin:FindFirstChild("ChangeStat")
    
    if not remote then 
        api:notify("❌ Remote not found!", 3)
        return
    end
    
    api:notify("Testing common stats...", 3)
    for _, stat in ipairs(common) do
        remote:FireServer(stat, val)
        task.wait(0.1)
    end
    api:notify("Done testing!", 2)
end)

-- UI Settings
local MenuGroup = Tabs.UI:AddLeftGroupbox('Menu')
Library:SetWatermarkVisibility(true)

MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu Keybind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu Keybind' }) 
Library.ToggleKeybind = Options.MenuKeybind 

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager.IgnoreThemeSettings = false 
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' }) 
ThemeManager:SetFolder('MyScriptHub')
SaveManager:SetFolder('MyScriptHub/RandomGame')
ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:BuildConfigSection(Tabs.UI) 

api:notify("Random Game Script Loaded", 2)
