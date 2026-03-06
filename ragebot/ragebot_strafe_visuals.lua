api:set_lua_name("ragebot_visuals")

local Handler = loadstring(game:HttpGet("https://raw.githubusercontent.com/XK5NG/XK5NG.github.io/main/Handler"))()
local Players = Handler:CloneRef("Players")
local RunService = Handler:CloneRef("RunService")
local CoreGui = Handler:CloneRef("CoreGui")
local LocalPlayer = Players.LocalPlayer

local Tab = api:GetTab("ragebot") or api:AddTab("ragebot")
local VisualsGroup = Tab:AddRightGroupbox("Rage Visuals")

-- Visual Indicator GUI
local IndicatorGui = Instance.new("ScreenGui")
IndicatorGui.Name = "RagebotStrafeIndicator"
IndicatorGui.Parent = CoreGui
IndicatorGui.IgnoreGuiInset = true
IndicatorGui.Enabled = false

local IndicatorFrame = Instance.new("Frame")
IndicatorFrame.Size = UDim2.new(0, 20, 0, 20)
IndicatorFrame.Position = UDim2.new(0.5, 200, 0.5, 0) -- Adjust position as needed
IndicatorFrame.BackgroundColor3 = Color3.fromRGB(170, 0, 255) -- Purple
IndicatorFrame.BorderSizePixel = 0
IndicatorFrame.Parent = IndicatorGui

local IndicatorStroke = Instance.new("UIStroke")
IndicatorStroke.Color = Color3.fromRGB(255, 255, 255)
IndicatorStroke.Thickness = 1
IndicatorStroke.Parent = IndicatorFrame

local IndicatorLabel = Instance.new("TextLabel")
IndicatorLabel.Size = UDim2.new(1, 0, 1, 0)
IndicatorLabel.BackgroundTransparency = 1
IndicatorLabel.Text = ""
IndicatorLabel.Parent = IndicatorFrame

-- Toggle
VisualsGroup:AddToggle("RagebotStrafe", {
    Text = "Ragebot Strafe",
    Default = false,
    Callback = function(Value)
        IndicatorGui.Enabled = Value
        
        if Value then
            api:notify("Ragebot Strafe Enabled", 2)
        else
            api:notify("Ragebot Strafe Disabled", 2)
        end
    end
}):AddColorPicker('StrafeColor', {
    Default = Color3.fromRGB(170, 0, 255),
    Title = 'Indicator Color',
    Transparency = 0,
    Callback = function(Value)
        IndicatorFrame.BackgroundColor3 = Value
    end
})

-- Position Slider (X)
VisualsGroup:AddSlider("IndicatorX", {
    Text = "Indicator X",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = true,
    Callback = function(Value)
        local screenWidth = workspace.CurrentCamera.ViewportSize.X
        IndicatorFrame.Position = UDim2.new(Value/100, 0, IndicatorFrame.Position.Y.Scale, 0)
    end
})

-- Position Slider (Y)
VisualsGroup:AddSlider("IndicatorY", {
    Text = "Indicator Y",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Compact = true,
    Callback = function(Value)
        local screenHeight = workspace.CurrentCamera.ViewportSize.Y
        IndicatorFrame.Position = UDim2.new(IndicatorFrame.Position.X.Scale, 0, Value/100, 0)
    end
})

-- Cleanup
api:on_event("unload", function()
    if IndicatorGui then IndicatorGui:Destroy() end
end)

api:notify("Ragebot Visuals Loaded", 3)
