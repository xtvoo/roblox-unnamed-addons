--[[
    Unnamed Addon: Custom HUD v3
    - Multi-Theme Support (Pink / Standard)
    - Draggable UI
    - Toggle Support
]]

api:set_lua_name("CustomHUD_v3")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Assets
local HELLO_KITTY_URL = "https://raw.githubusercontent.com/xtvoo/assets/main/hello%20kitty.webp"
local ICONS = {
    Heart = "rbxassetid://6031068420", -- Generic Heart
    Shield = "rbxassetid://6031068421", -- Generic Shield
    Lightning = "rbxassetid://6031068422", -- Generic Lightning
    -- Fallbacks or specific ones can be swapped if needed
    -- Using simple box shapes with icons for the 'Standard' look
}

-- Ensure Hello Kitty Asset
local HELLO_KITTY_ASSET = "rbxassetid://14237608829"
task.spawn(function()
    pcall(function()
        if not isfile("hello_kitty_hud_2.webp") then
            writefile("hello_kitty_hud_2.webp", game:HttpGet(HELLO_KITTY_URL))
        end
        HELLO_KITTY_ASSET = getcustomasset("hello_kitty_hud_2.webp")
    end)
end)

-- UI Setup
-- Customization UI
local fonts = {}
for _, f in pairs(Enum.Font:GetEnumItems()) do table.insert(fonts, f.Name) end

local tabs = { Visuals = api:GetTab("visuals") or api:AddTab("visuals") }
local Group = tabs.Visuals:AddRightGroupbox("Custom HUD Settings")

local Enabled = Group:AddToggle("CHUD_Enable", { Text = "Enable Custom HUD", Default = true })
-- Split Styles
local BarStyle = Group:AddDropdown("CHUD_BarStyle", { Text = "Bar Style", Default = "Pink Hello Kitty", Values = {"Pink Hello Kitty", "Standard", "None (Default)"} })
local MoneyStyle = Group:AddDropdown("CHUD_MoneyStyle", { Text = "Money Style", Default = "Pink Hello Kitty", Values = {"Pink Hello Kitty", "Standard", "None (Default)"} })
local CustomFont = Group:AddDropdown("CHUD_Font", { Text = "Font", Default = "FredokaOne", Values = fonts })

Group:AddLabel("Colors"):AddColorPicker("CHUD_HealthColor", { Default = Color3.fromRGB(255, 20, 147), Title = "Health Color" })
Group:AddLabel("Colors"):AddColorPicker("CHUD_ArmorColor", { Default = Color3.fromRGB(255, 20, 147), Title = "Armor Color" })
Group:AddLabel("Colors"):AddColorPicker("CHUD_EnergyColor", { Default = Color3.fromRGB(255, 20, 147), Title = "Energy Color" })
Group:AddLabel("Colors"):AddColorPicker("CHUD_MoneyColor", { Default = Color3.fromRGB(255, 20, 147), Title = "Money Color" })

local ShowMoney = Group:AddToggle("CHUD_Money", { Text = "Show Custom Money", Default = true })

-- State
local HudScreen = nil
local BarsFrame = nil
local MoneyFrame = nil

-- Helpers
local function MakeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function() 
                if input.UserInputState == Enum.UserInputState.End then dragging = false end 
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Builders
local function CreatePinkBar(name, colorKey, parent)
    local color = Options[colorKey] and Options[colorKey].Value or Color3.fromRGB(255, 20, 147)
    
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = UDim2.new(0, 160, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.4
    
    local c = Instance.new("UICorner", frame); c.CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", frame); s.Color = Color3.new(0,0,0); s.Thickness = 2; s.Transparency = 0.2
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1,0,1,0)
    fill.BackgroundColor3 = color
    fill.Parent = frame
    local fc = Instance.new("UICorner", fill); fc.CornerRadius = UDim.new(0, 8)
    
    local txt = Instance.new("TextLabel")
    txt.Name = "Value"
    txt.Size = UDim2.new(1,0,1,0)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font[CustomFont.Value]
    txt.TextSize = 18
    txt.TextColor3 = Color3.new(1,1,1)
    txt.Text = "100 / 100"
    txt.Parent = frame
    
    frame.Parent = parent
    return frame, fill, txt
end

local function CreateStandardBar(name, colorKey, parent)
    -- Default Standard Colors if user hasn't touched picker, but we use picker value
    local color = Options[colorKey] and Options[colorKey].Value or Color3.fromRGB(0, 255, 0)

    local container = Instance.new("Frame")
    container.Name = name
    container.Size = UDim2.new(0, 200, 0, 26)
    container.BackgroundTransparency = 1
    
    local iconBox = Instance.new("Frame")
    iconBox.Size = UDim2.new(0, 26, 1, 0)
    iconBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    iconBox.BorderSizePixel = 1
    iconBox.BorderColor3 = Color3.new(0,0,0)
    iconBox.Parent = container
    
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0.8, 0, 0.8, 0)
    icon.Position = UDim2.new(0.1, 0, 0.1, 0)
    icon.BackgroundTransparency = 1
    if name == "Health" then icon.Image = "rbxassetid://18663673739"
    elseif name == "Armor" then icon.Image = "rbxassetid://18663673801"
    elseif name == "Energy" then icon.Image = "rbxassetid://18663673685"
    else icon.Image = "" end 
    icon.Parent = iconBox

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -30, 1, 0)
    barBg.Position = UDim2.new(0, 30, 0, 0)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    barBg.BorderSizePixel = 1
    barBg.BorderColor3 = Color3.new(0,0,0)
    barBg.Parent = container

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Parent = barBg
    
    local txt = Instance.new("TextLabel")
    txt.Name = "Value"
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font[CustomFont.Value] or Enum.Font.GothamBold
    txt.TextSize = 14
    txt.TextColor3 = Color3.new(1,1,1)
    txt.TextStrokeTransparency = 0
    txt.Text = name
    txt.Parent = barBg
    
    container.Parent = parent
    return container, fill, txt
end


local function Rebuild()
    if HudScreen then HudScreen:Destroy() end
    HudScreen = Instance.new("ScreenGui")
    HudScreen.Name = "CustomHUD_v3"
    HudScreen.Parent = PlayerGui
    HudScreen.ResetOnSpawn = false
    
    local bStyle = BarStyle.Value
    local mStyle = MoneyStyle.Value
    
    -- === Bars ===
    if bStyle ~= "None (Default)" then
        BarsFrame = Instance.new("Frame")
        BarsFrame.Name = "Bars"
        BarsFrame.BackgroundTransparency = 1
        
        if bStyle == "Pink Hello Kitty" then
            BarsFrame.Size = UDim2.new(0, 500, 0, 40)
            BarsFrame.Position = UDim2.new(0.5, -250, 0.9, 0)
        else
            BarsFrame.Size = UDim2.new(0, 620, 0, 30)
            BarsFrame.Position = UDim2.new(0.5, -310, 0.92, 0)
        end
        
        BarsFrame.Parent = HudScreen
        MakeDraggable(BarsFrame)
        
        local list = Instance.new("UIListLayout")
        list.FillDirection = Enum.FillDirection.Horizontal
        list.Padding = UDim.new(0, 10)
        list.HorizontalAlignment = Enum.HorizontalAlignment.Center
        list.Parent = BarsFrame
        
        if bStyle == "Pink Hello Kitty" then
            CreatePinkBar("Health", "CHUD_HealthColor", BarsFrame)
            CreatePinkBar("Armor", "CHUD_ArmorColor", BarsFrame)
            CreatePinkBar("Energy", "CHUD_EnergyColor", BarsFrame)
        else
            CreateStandardBar("Energy", "CHUD_EnergyColor", BarsFrame)
            CreateStandardBar("Health", "CHUD_HealthColor", BarsFrame)
            CreateStandardBar("Armor", "CHUD_ArmorColor", BarsFrame)
        end
    end
    
    -- === Money ===
    if mStyle ~= "None (Default)" then
        MoneyFrame = Instance.new("Frame")
        MoneyFrame.Name = "Money"
        MoneyFrame.Size = UDim2.new(0, 0, 0, 50)
        MoneyFrame.AutomaticSize = Enum.AutomaticSize.X
        MoneyFrame.Position = UDim2.new(0, 20, 0.85, 0)
        MoneyFrame.BackgroundTransparency = 1
        MoneyFrame.Visible = ShowMoney.Value
        MoneyFrame.Parent = HudScreen
        MakeDraggable(MoneyFrame)
        
        local ml = Instance.new("UIListLayout")
        ml.FillDirection = Enum.FillDirection.Horizontal
        ml.VerticalAlignment = Enum.VerticalAlignment.Center
        ml.Padding = UDim.new(0, 5)
        ml.SortOrder = Enum.SortOrder.LayoutOrder
        ml.Parent = MoneyFrame
        
        local moneyColor = Options.CHUD_MoneyColor and Options.CHUD_MoneyColor.Value or Color3.fromRGB(255, 20, 147)

        if mStyle == "Pink Hello Kitty" then
            local ico = Instance.new("ImageLabel")
            ico.Name = "Icon"
            ico.LayoutOrder = 1
            ico.Size = UDim2.new(0,40,0,40)
            ico.BackgroundTransparency=1
            ico.Image=HELLO_KITTY_ASSET
            ico.Parent=MoneyFrame
            
            local t = Instance.new("TextLabel")
            t.Name="Amt"
            t.LayoutOrder = 2
            t.Size=UDim2.new(0,0,1,0)
            t.AutomaticSize = Enum.AutomaticSize.X
            t.BackgroundTransparency=1
            t.TextColor3 = moneyColor
            t.Font = Enum.Font[CustomFont.Value] or Enum.Font.FredokaOne
            t.TextSize=24
            t.TextXAlignment=Enum.TextXAlignment.Left
            t.Text = "$0"
            t.Parent=MoneyFrame
        else
            local t = Instance.new("TextLabel")
            t.Name="Amt"
            t.Size=UDim2.new(0,150,1,0)
            t.BackgroundTransparency=1
            t.TextColor3 = moneyColor
            t.Font = Enum.Font[CustomFont.Value] or Enum.Font.GothamBold
            t.TextSize=22
            t.TextXAlignment=Enum.TextXAlignment.Left
            t.TextStrokeTransparency=0
            t.Text = "$0"
            t.Parent=MoneyFrame
        end
    end
    
    if Enabled.Value then
        task.delay(0.1, function() if MoneyFrame then MoneyFrame.Visible = true end end)
    end
end

local function Update()
    if not Enabled.Value then return end
    if not HudScreen then Rebuild() return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    local be = char:FindFirstChild("BodyEffects")
    local df = LocalPlayer:FindFirstChild("DataFolder")
    
    -- 1. Health
    local hp = 0; local maxHp = 100
    if hum then hp = math.floor(hum.Health); maxHp = math.floor(hum.MaxHealth) end
    if maxHp <= 0 then maxHp = 100 end

    if BarsFrame then
        local hpFrame = BarsFrame:FindFirstChild("Health")
        if hpFrame then
            hpFrame.Fill.Size = UDim2.new(math.clamp(hp/maxHp, 0, 1), 0, 1, 0)
            local txt = hpFrame:FindFirstChild("Value", true)
            if txt then
                 if BarStyle.Value == "Pink Hello Kitty" then txt.Text = hp .. " / " .. maxHp
                 else txt.Text = "Health: " .. hp end
            end
        end
    end
    
    -- 2. Armor
    local arm = 0
    if be then local ao = be:FindFirstChild("Armor"); if ao then arm = math.floor(ao.Value) end end
    local maxArm = (arm > 100) and arm or 100

    if BarsFrame then
        local armFrame = BarsFrame:FindFirstChild("Armor")
        if armFrame then
            armFrame.Fill.Size = UDim2.new(math.clamp(arm/maxArm, 0, 1), 0, 1, 0)
            local txt = armFrame:FindFirstChild("Value", true)
            if txt then
                if BarStyle.Value == "Pink Hello Kitty" then txt.Text = arm .. " / " .. maxArm
                else txt.Text = "Armor: " .. arm end
            end
        end
    end
    
    -- 3. Energy
    local en = 0
    if be then local p = be:FindFirstChild("Power") or be:FindFirstChild("Energy"); if p then en = math.floor(p.Value) end end
    if en == 0 and df and df:FindFirstChild("Energy") then en = math.floor(df.Energy.Value) end
    local maxEn = (en > 100) and en or 100

    if BarsFrame then
        local enFrame = BarsFrame:FindFirstChild("Energy")
        if enFrame then
            enFrame.Fill.Size = UDim2.new(math.clamp(en/maxEn, 0, 1), 0, 1, 0)
            local txt = enFrame:FindFirstChild("Value", true)
            if txt then
                if BarStyle.Value == "Pink Hello Kitty" then txt.Text = en .. " / " .. maxEn
                else txt.Text = "Energy: " .. en end
            end
        end
    end
    
    -- Money
    local cash = 0
    if df and df:FindFirstChild("Currency") then cash = df.Currency.Value end
    local cashStr = tostring(cash):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
    
    if MoneyFrame then
        local mt = MoneyFrame:FindFirstChild("Amt")
        if mt then mt.Text = "$" .. cashStr end
    end
    
    -- Smart Hider: Only hide what we replaced
    local mg = PlayerGui:FindFirstChild("MainScreenGui")
    if mg then
        local hideBars = (BarStyle.Value ~= "None (Default)")
        local hideMoney = (MoneyStyle.Value ~= "None (Default)")
        
        for _,c in pairs(mg:GetChildren()) do
            if hideBars and c.Name:match("Bar") then c.Visible = false end
            if hideMoney and c.Name:match("Money") then c.Visible = false end
            
            -- If we are NOT hiding them, ensure they are visible (in case they were hidden before)
            if not hideBars and c.Name:match("Bar") then c.Visible = true end
            if not hideMoney and c.Name:match("Money") then c.Visible = true end
        end
    end
end

-- Events
Enabled:OnChanged(function() if Enabled.Value then Rebuild() else if HudScreen then HudScreen:Destroy() HudScreen=nil end end end)
BarStyle:OnChanged(function() if Enabled.Value then Rebuild() end end)
MoneyStyle:OnChanged(function() if Enabled.Value then Rebuild() end end)
CustomFont:OnChanged(function() if Enabled.Value then Rebuild() end end)
ShowMoney:OnChanged(function() if MoneyFrame then MoneyFrame.Visible = ShowMoney.Value end end)

-- Color Listeners
Options.CHUD_HealthColor:OnChanged(function() if Enabled.Value then Rebuild() end end)
Options.CHUD_ArmorColor:OnChanged(function() if Enabled.Value then Rebuild() end end)
Options.CHUD_EnergyColor:OnChanged(function() if Enabled.Value then Rebuild() end end)
Options.CHUD_MoneyColor:OnChanged(function() if Enabled.Value then Rebuild() end end)

api:add_connection(RunService.RenderStepped:Connect(Update))
api:on_event("unload", function() 
    if HudScreen then HudScreen:Destroy() end
    local mg = PlayerGui:FindFirstChild("MainScreenGui")
    if mg then for _,c in pairs(mg:GetChildren()) do c.Visible = true end end
end)
