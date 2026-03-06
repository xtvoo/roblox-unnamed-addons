--[[
    Unnamed Addon: HUD Hider
    Toggles all game UI and Core UI visibility with a keybind/toggle
    useful for cinematic screenshots or clean gameplay
]]

api:set_lua_name("HUDHider")

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- UI
local tabs = { Misc = api:GetTab("misc") or api:AddTab("misc") }
local sec = tabs.Misc:AddRightGroupbox("HUD Hider")

local KeyDropdown = sec:AddDropdown("HUD_Key", { Text = "Toggle Key", Default = "RightControl", Values = {"RightControl", "RightShift", "H", "F1", "F8", "P", "Backquote"} })
local HideManual = sec:AddToggle("HUD_Hide", { Text = "Hide HUD Now", Default = false })
local HideCore = sec:AddToggle("HUD_Core", { Text = "Hide CoreGUI (Chat/Leaderboard)", Default = true })
local HidePlayer = sec:AddToggle("HUD_Player", { Text = "Hide PlayerGUI (Game UI)", Default = true })

-- State
local isHidden = false
local savedStates = {}

local function setCoreGui(enabled)
    -- Standard method
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, enabled)
    end)
    
    -- Force Topbar
    pcall(function()
        StarterGui:SetCore("TopbarEnabled", enabled)
    end)
    
    -- Aggressive method: Iterate ALL children of CoreGui
    for _, child in ipairs(CoreGui:GetChildren()) do
        if child:IsA("ScreenGui") or child:IsA("BillboardGui") then
            local name = child.Name
            
            -- Hitlist of stubborn UIs
            if name == "Chrome" or name == "TopBarApp" or name == "RobloxGui" or name == "InGameMenu" or name == "IGM" or child.Enabled then
                if not enabled then
                    if child.Enabled then
                        savedStates[child] = true
                        child.Enabled = false
                    end
                elseif enabled then
                    if savedStates[child] then
                        child.Enabled = true
                    end
                end
            end
        end
    end
    
    -- DOUBLE TAP: Explicitly find and disable RobloxGui to be absolutely sure
    local robloxGui = CoreGui:FindFirstChild("RobloxGui")
    if robloxGui and not enabled then
        robloxGui.Enabled = false
    end
end

local function toggleHUD(forceState)
    -- Determine target state
    if forceState ~= nil then
        isHidden = not forceState
    else
        isHidden = not isHidden
    end
    
    -- Sync Toggle UI if changed via Keybind
    if HideManual.Value ~= isHidden then
        HideManual:SetValue(isHidden)
    end
    
    if isHidden then
        -- HIDING
        
        -- 1. CoreGUI
        if HideCore.Value then
            setCoreGui(false)
        end
        
        -- 2. PlayerGUI
        if HidePlayer.Value then
            savedStates = {}
            local pg = LocalPlayer:FindFirstChild("PlayerGui")
            if pg then
                for _, layer in ipairs(pg:GetChildren()) do
                    if layer:IsA("ScreenGui") or layer:IsA("BillboardGui") then
                        -- Save state only if it was enabled (don't re-enable disabled stuff)
                        if layer.Enabled then
                            savedStates[layer] = true
                            layer.Enabled = false
                        end
                    end
                end
            end
        end
        
        -- 3. KeybindMenu (Unnamed Flag)
        if Toggles and Toggles.KeybindMenu then
            if Toggles.KeybindMenu.Value == true then
                savedStates["KeybindMenu_Flag"] = true
                Toggles.KeybindMenu:SetValue(false)
            end
        end

        -- 4. HudEnabled (Unnamed Flag)
        if Toggles and Toggles.HudEnabled then
            if Toggles.HudEnabled.Value == true then
                savedStates["HudEnabled_Flag"] = true
                Toggles.HudEnabled:SetValue(false)
            end
        end
        
        -- Also try to hide standard KeybindMenu GUI just in case
        local kbMenu = CoreGui:FindFirstChild("KeybindMenu") or (LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("KeybindMenu"))
        if kbMenu and kbMenu.Enabled then
            savedStates[kbMenu] = true
            kbMenu.Enabled = false
        end
        
        api:notify("HUD Hidden", 1)
    else
        -- SHOWING
        
        -- 1. CoreGUI
        setCoreGui(true)
        
        -- 2. Restore all saved layers
        for layer, wasEnabled in pairs(savedStates) do
            if layer == "KeybindMenu_Flag" then
                if Toggles and Toggles.KeybindMenu then
                    Toggles.KeybindMenu:SetValue(true)
                end
            elseif layer == "HudEnabled_Flag" then
                if Toggles and Toggles.HudEnabled then
                    Toggles.HudEnabled:SetValue(true)
                end
            elseif layer and layer.Parent then
                layer.Enabled = true
            end
        end
        savedStates = {}
        
        api:notify("HUD Visible", 1)
    end
end

-- Toggle Handler
HideManual:OnChanged(function()
    if HideManual.Value == isHidden then return end -- Already in state
    toggleHUD(not HideManual.Value) -- forceState = true (visible) if toggle is false
end)

-- Keybind Handler
local inputConn
inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local keyName = input.KeyCode.Name
    if keyName == KeyDropdown.Value then
        -- Toggle
        HideManual:SetValue(not HideManual.Value)
    end
end)

api:on_event("unload", function()
    if inputConn then inputConn:Disconnect() end
    -- Force restore on unload
    if isHidden then
        setCoreGui(true)
        for layer, _ in pairs(savedStates) do
            if layer and layer.Parent then
                layer.Enabled = true
            end
        end
    end
    api:notify("HUD Hider Unloaded", 2)
end)

api:notify("HUD Hider Loaded! Key: " .. KeyDropdown.Value, 3)
