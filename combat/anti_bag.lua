-- Anti Bag Addon for Unnamed
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local VoidCFrame = CFrame.new(0/0, 0/0, 0/0)

-- Unnamed Addon UI setup
local tabs = {
    antibag = api:AddTab("Anti Bag");
}

local groupbox = tabs.antibag:AddLeftGroupbox("Anti Bag Settings")

groupbox:AddToggle('AntiBagEnabled', {
    Text = "Enable Anti Bag",
    Default = false
})

groupbox:AddSlider('AntiBagDistance', {
    Text = 'Detection Distance',
    Default = 25,
    Min = 5,
    Max = 100,
    Rounding = 0,
    Suffix = " studs",
    HideMax = false,
    Compact = false,
})

local function checkAntiBag()
    if not (Toggles and Toggles.AntiBagEnabled and Toggles.AntiBagEnabled.Value) then
        return
    end

    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then 
        return 
    end

    local workspacePlayers = Workspace:FindFirstChild("Players")
    if not workspacePlayers then return end

    local voided = false

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            -- Da Hood targets are in workspace.Players
            local char = workspacePlayers:FindFirstChild(player.Name) or player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                
                -- Check if holding brown bag
                local holdingBag = char:FindFirstChild("[BrownBag]")
                
                if holdingBag then
                    local dist = (char.HumanoidRootPart.Position - myChar.HumanoidRootPart.Position).Magnitude
                    
                    if dist <= (Options.AntiBagDistance and Options.AntiBagDistance.Value or 25) then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            for _, track in pairs(hum:GetPlayingAnimationTracks()) do
                                if track.Animation and string.find(tostring(track.Animation.AnimationId), "3493406987") then
                                    voided = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        if voided then break end
    end

    if voided then
        api:set_server_cframe(VoidCFrame)
    end
end

RunService.Heartbeat:Connect(checkAntiBag)

api:notify("Anti Bag Addon Loaded!")
