-- Load the UI Library specifically from our local file
local Library = loadstring(readfile("xtvo_lib.lua"))()

-- Optional: Load the API if you plan to use it (commented out by default)
-- local api = loadstring(readfile("xtvo_api.lua"))()

-- Configuration
local Config = {
    WindowName = "xtvo hub",
    Color = Color3.fromRGB(255, 128, 0), -- xtvo orange
    Keybind = Enum.KeyCode.RightControl
}

-- Create Window
local Window = Library:CreateWindow(Config, game.CoreGui)

-- Create Tabs
local MainTab = Window:CreateTab("Main")
local VisualsTab = Window:CreateTab("Visuals")
local SettingsTab = Window:CreateTab("Settings")

-- Main Tab
local MainSection = MainTab:CreateSection("Features")

MainSection:CreateLabel("Welcome to xtvo hub")

MainSection:CreateButton("Test Button", function()
    print("Button Pressed")
end)

MainSection:CreateToggle("Auto Farm", false, function(State)
    print("Auto Farm:", State)
end)

MainSection:CreateSlider("WalkSpeed", 16, 500, 16, true, function(Value)
    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end
end)

-- Visuals Tab
local VisualsSection = VisualsTab:CreateSection("ESP Settings")
VisualsSection:CreateToggle("Enable ESP", false, function(State)
    print("ESP:", State)
end)

-- Settings Tab
local UISection = SettingsTab:CreateSection("UI Settings")

UISection:CreateColorpicker("UI Color", function(Color)
    Window:ChangeColor(Color)
end)

UISection:CreateButton("Unload UI", function()
    Window:Toggle(false)
end)
