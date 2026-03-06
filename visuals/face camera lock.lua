--[[
    Unnamed Addon: Face Camera Lock
    Locks camera to where your character is facing
]]

api:set_lua_name("FaceCameraLock")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- UI
local tabs = { Misc = api:GetTab("misc") or api:AddTab("misc") }
local sec = tabs.Misc:AddLeftGroupbox("Face Camera Lock")

local Enable = sec:AddToggle("FCL_Enable", { Text = "Enable", Default = false })
local LockToggle = sec:AddToggle("FCL_Lock", { Text = "Lock Camera", Default = false })
local CamMode = sec:AddDropdown("FCL_Mode", { Text = "Camera Mode", Default = "Head Direction", Values = {"Head Direction", "Front", "Behind", "Left", "Right"} })
local SmoothToggle = sec:AddToggle("FCL_Smooth", { Text = "Smooth Lock", Default = true })
local SmoothSpeed = sec:AddSlider("FCL_Speed", { Text = "Smooth Speed", Default = 10, Min = 1, Max = 50, Rounding = 0 })
local OffsetY = sec:AddSlider("FCL_OffsetY", { Text = "Vertical Offset", Default = 2, Min = -5, Max = 10, Rounding = 1 })
local Distance = sec:AddSlider("FCL_Dist", { Text = "Camera Distance", Default = 8, Min = 1, Max = 30, Rounding = 1 })

-- Get camera position based on mode
local function getCameraPosition()
    local char = LocalPlayer.Character
    if not char then return nil end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hrp or not head then return nil end
    
    local headPos = head.Position
    local headLookVector = head.CFrame.LookVector -- Direction head is facing
    local headRightVector = head.CFrame.RightVector
    local dist = Distance.Value
    local yOffset = OffsetY.Value
    
    local camPos
    local lookAt
    local mode = CamMode.Value
    
    if mode == "Head Direction" then
        -- Camera behind head, looking where head looks
        camPos = headPos - headLookVector * dist + Vector3.new(0, yOffset, 0)
        lookAt = headPos + headLookVector * 100
    elseif mode == "Front" then
        -- Camera in front, facing towards player
        camPos = headPos + headLookVector * dist + Vector3.new(0, yOffset, 0)
        lookAt = headPos
    elseif mode == "Behind" then
        -- Camera behind (body direction)
        local bodyLook = hrp.CFrame.LookVector
        camPos = headPos - bodyLook * dist + Vector3.new(0, yOffset, 0)
        lookAt = headPos
    elseif mode == "Left" then
        camPos = headPos - headRightVector * dist + Vector3.new(0, yOffset, 0)
        lookAt = headPos
    elseif mode == "Right" then
        camPos = headPos + headRightVector * dist + Vector3.new(0, yOffset, 0)
        lookAt = headPos
    end
    
    return CFrame.new(camPos, lookAt)
end

-- Main loop
local conn = nil

local function update()
    if not Enable.Value or not LockToggle.Value then return end
    
    local targetCF = getCameraPosition()
    if not targetCF then return end
    
    if SmoothToggle.Value then
        -- Smooth interpolation
        local current = Camera.CFrame
        local alpha = math.clamp(SmoothSpeed.Value * 0.016, 0, 1)
        Camera.CFrame = current:Lerp(targetCF, alpha)
    else
        Camera.CFrame = targetCF
    end
end

Enable:OnChanged(function()
    if Enable.Value then
        if not conn then
            conn = RunService.RenderStepped:Connect(update)
            api:add_connection(conn)
        end
    end
end)

api:on_event("unload", function()
    api:notify("Face Camera Lock Unloaded", 2)
end)

api:notify("Face Camera Lock Loaded!", 3)

