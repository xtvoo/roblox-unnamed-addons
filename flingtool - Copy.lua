-- Dependencies
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Create a toggle for the addon
api.create_toggle("sticky_enabled", {
    name = "Sticky Enabled",
    default = false,
})

-- Main loop
RunService.Heartbeat:Connect(function()
    if api.get_flag("sticky_enabled") then
        local Target = api:gettarget("silent")

        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if Target and Target.Character and Target.Character:FindFirstChild("HumanoidRootPart") then
                local TargetPart = Target.Character.HumanoidRootPart
                local RootPart = LocalPlayer.Character.HumanoidRootPart

                -- Override server cframe to strafe around silent aim target
                api:set_server_cframe(CFrame.new(TargetPart.Position + Vector3.new(0, 5, 0)) * CFrame.Angles(-math.pi / 2, 0, 0))
            end
        end
    end
end)
