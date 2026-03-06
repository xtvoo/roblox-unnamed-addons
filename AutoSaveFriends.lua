local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MainEvent = ReplicatedStorage:WaitForChild("MainEvent", 10)

api:set_lua_name("AutoSaveFriends")

local Tab = api:GetTab("Friend Saver") or api:AddTab("Friend Saver")
local MainGroup = Tab:AddLeftGroupbox("Settings")

local Enabled = MainGroup:AddToggle("Enabled", { Text = "Enable Auto Save" })
    :AddKeyPicker("AutoSaveKey", { Default = "None", Text = "Toggle Auto Save", Mode = "Toggle", SyncToggleState = true })
local AutoDrop = MainGroup:AddToggle("AutoDrop", { Text = "Auto Drop", Default = false })
local MinDist = MainGroup:AddSlider("MinDist", { Text = "Min Distance", Default = 50, Min = 0, Max = 500, Rounding = 0 })
local MaxDist = MainGroup:AddSlider("MaxDist", { Text = "Max Distance", Default = 1000, Min = 100, Max = 10000, Rounding = 0 })
local StatusLabel = MainGroup:AddLabel("Status: Idle")

local PlayerDropdown = MainGroup:AddDropdown("FriendSelector", {
    Values = {},
    Default = {},
    Multi = true,
    Text = "Select Friends to Save"
})

MainGroup:AddButton("Refresh Players", function()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    table.sort(names)
    PlayerDropdown:SetValues(names)
end)

local function InitDropdown()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    table.sort(names)
    PlayerDropdown:SetValues(names)
end
InitDropdown()

local IsSaving = false

local function Notify(msg)
    api:notify(msg, 3)
end

local function GetKnockedTarget()
    local selected = PlayerDropdown.Value
    if not selected or type(selected) ~= "table" then return nil end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for name, isSelected in pairs(selected) do
        if isSelected then
            local p = Players:FindFirstChild(name)
            if p and p.Character then
                local tRoot = p.Character:FindFirstChild("HumanoidRootPart")
                if tRoot then
                    local dist = (tRoot.Position - myRoot.Position).Magnitude
                    if dist >= MinDist.Value and dist <= MaxDist.Value then
                        local be = p.Character:FindFirstChild("BodyEffects")
                        local ko = be and be:FindFirstChild("K.O")
                        local grabbed = p.Character:FindFirstChild("GRABBING_CONSTRAINT")

                        if ko and ko.Value == true and not grabbed then
                             return p
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function AutoSaveRoutine()
    local keybindState = false
    if Options.AutoSaveKey then
        keybindState = Options.AutoSaveKey:GetState()
    end

    if not Enabled.Value and not keybindState then 
        StatusLabel:SetText("Status: Disabled")
        return 
    end
    if IsSaving then return end

    local target = GetKnockedTarget()
    if target then
        IsSaving = true
        StatusLabel:SetText("Status: Saving " .. target.Name)
        Notify("Attempting to save: " .. target.Name)

        local character = target.Character
        local desync_active = true

        task.spawn(function()
            while desync_active and character and character:FindFirstChild("LowerTorso") do
                local position = character.LowerTorso.Position + Vector3.new(0, 3, 0)
                if api.set_desync_cframe then
                    api:set_desync_cframe(CFrame.new(position))
                elseif api.set_fake then
                    api:set_fake(true, CFrame.new(position)) 
                else
                    api:set_server_cframe(CFrame.new(position))
                end
                task.wait()
            end
             if api.set_desync_cframe then
                api:set_desync_cframe(nil)
             end
             if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                 api:set_server_cframe(LocalPlayer.Character.HumanoidRootPart.CFrame)
             end
        end)

        local timeout_start = tick()
        local grabbed = false
        
        while (tick() - timeout_start < 3) and not grabbed and character.Parent do
             if character:FindFirstChild("GRABBING_CONSTRAINT") then
                 grabbed = true
                 break
             end
             if MainEvent then
                 MainEvent:FireServer('Grabbing', false)
             end
             task.wait(0.2)
        end

        task.wait(0.2)
        desync_active = false
        
        task.wait(0.1)
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            api:set_server_cframe(LocalPlayer.Character.HumanoidRootPart.CFrame)
        end
        
        if AutoDrop.Value then
            task.wait(0.2)
            if MainEvent then
                MainEvent:FireServer('Grabbing', false) 
            end
        end
        
        Notify("Save Sequence Finished")
        IsSaving = false
        StatusLabel:SetText("Status: Idle")
    else
        StatusLabel:SetText("Status: Scanning...")
    end
end

task.spawn(function()
    while true do
        task.wait(0.1)
        pcall(AutoSaveRoutine)
    end
end)

api:notify("AutoSaveFriends Loaded", 3)
