api:set_lua_name("dynamic_menu_test")

local Tab = api:AddTab("Dynamic UI")
local Group = Tab:AddLeftGroupbox("Dynamic Features")

-- 1. Create the Main Toggle
local MainToggle = Group:AddToggle("MasterSwitch", {
    Text = "Enable Advanced Mode",
    Default = false,
    Callback = function(Value)
        -- Logic to handle main toggle
        print("Master Switch: " .. tostring(Value))
    end
})

-- 2. Create the features that should be HIDDEN initially
-- We store them in variables so we can control them
local SubFeature1 = Group:AddToggle("SubFeature1", {
    Text = "Hidden Feature A",
    Default = false,
})

local SubFeature2 = Group:AddSlider("SubFeature2", {
    Text = "Hidden Slider B",
    Default = 50,
    Min = 0, 
    Max = 100, 
    Rounding = 0,
})

local SubFeature3 = Group:AddDropdown("SubFeature3", {
    Values = {"Option 1", "Option 2"},
    Default = 1,
    Text = "Hidden Dropdown C"
})

-- 3. Define a function to update visibility
local function UpdateVisibility()
    local isEnabled = Toggles.MasterSwitch.Value
    
    -- Library specific visibility control
    -- Note: Most UI libraries (Linoria/wally) support .Visible property on the element
    
    if SubFeature1.SetVisible then
        SubFeature1:SetVisible(isEnabled)
        SubFeature2:SetVisible(isEnabled)
        SubFeature3:SetVisible(isEnabled)
    else
        -- Fallback if SetVisible isn't supported directly (UI Lib dependent)
        -- You might need to check your specific UI library documentation
        print("Note: Your UI library needs to support :SetVisible()")
    end
end

-- 4. Hook the update function to the main toggle
Toggles.MasterSwitch:OnChanged(function()
    UpdateVisibility()
end)

-- 5. Initialize
UpdateVisibility()

api:notify("Dynamic Menu Loaded - Toggle 'Enable Advanced Mode' to see hidden options!", 5)
