-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Handler for connection management
local Handler = {}
Handler.Connections = {}

function Handler:AddConnection(name, connection)
    if not self.Connections[name] then
        self.Connections[name] = {}
    end
    table.insert(self.Connections[name], api.addconnection(connection))
end

function Handler:Connected(names)
    for _, name in pairs(names) do
        if self.Connections[name] and #self.Connections[name] > 0 then
            return true
        end
    end
    return false
end

function Handler:Disconnect(names)
    for _, name in pairs(names) do
        if self.Connections[name] then
            for _, connection in pairs(self.Connections[name]) do
                if connection and connection.Disconnect then
                    connection:Disconnect()
                end
            end
            self.Connections[name] = {}
        end
    end
end

function Handler:Is_KO(player)
    local status = api.getstatuscache(player)
    return status and status["K.O"] and {Value = status["K.O"]} or {Value = false}
end

-- Set addon name
api.setluaname("Cart Car")

-- Get or create lua tab, then create/get main groupbox
local tabs = {}
tabs.lua = api.AddTab("lua")
local Main = tabs.lua:AddLeftGroupbox("Cart Car")

-- Add sliders
Main:AddSlider("Speed", {
    Text = "Speed",
    Default = 50,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Compact = false
})

Main:AddSlider("Rotate", {
    Text = "Rotation Speed",
    Default = 3,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Compact = false
})

-- Add main toggle with keybind
Main:AddToggle("CartEnabled", {
    Text = "Cart Car",
    Default = false,

    Callback = function(Value)
        if Handler:Connected({"Cart", "KeyDown", "KeyUp"}) and not Value then
            Handler:Disconnect({"Cart", "KeyDown", "KeyUp"})
        end
    end
}):AddKeyPicker("CartKeypicker", {
    Default = "P",
    Mode = "Toggle",
    Text = "Cart Car",
    NoUI = false,

    Callback = function(Value)
        if Toggles and Toggles["CartEnabled"] and Toggles["CartEnabled"].Value then
            local success, Seat = pcall(function()
                return workspace:FindFirstChild("OldVehicles")[`{LocalPlayer.Name}BIKE`]:FindFirstChild("Seat")
            end)
            
            if not success or not Seat then
                api.notify("Cart not found!", 3)
                return
            end

            if Value then
                Handler:Disconnect({"Cart", "KeyDown", "KeyUp"})
                
                local BodyVelocity = Instance.new("BodyVelocity")
                BodyVelocity.Name = "Move"
                BodyVelocity.MaxForce = Vector3.new(99e99, 0, 99e99)
                BodyVelocity.Velocity = Vector3.zero
                BodyVelocity.Parent = Seat
        
                local BodyAngularVelocity = Instance.new("BodyAngularVelocity")
                BodyAngularVelocity.Name = "Rotate"
                BodyAngularVelocity.MaxTorque = Vector3.new(0, 99e99, 0)
                BodyAngularVelocity.AngularVelocity = Vector3.zero
                BodyAngularVelocity.Parent = Seat
        
                local BodyGyro = Instance.new("BodyGyro")
                BodyGyro.Name = "Stabilizer"
                BodyGyro.MaxTorque = Vector3.new(99e99, 0, 99e99)
                BodyGyro.P = 10000
                BodyGyro.D = 1000
                BodyGyro.CFrame = Seat.CFrame
                BodyGyro.Parent = Seat
        
                local W, S, A, D = false, false, false, false
        
                Handler:AddConnection("Cart", RunService.Heartbeat:Connect(function()
                    if not (LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character:FindFirstChild("LowerTorso") and LocalPlayer.Character:FindFirstChild("BodyEffects") and LocalPlayer.Character.BodyEffects:FindFirstChild("Armor") and LocalPlayer.Character:FindFirstChild("FULLY_LOADED_CHAR")) or (Handler:Is_KO(LocalPlayer) and Handler:Is_KO(LocalPlayer).Value) then
                        return
                    end

                    if not Seat:FindFirstChild("Move") or not Seat:FindFirstChild("SeatWeld") then
                        return
                    end
        
                    local LookVector = Seat.CFrame.LookVector
                    local Position = Seat.Position
                    local Unit = Vector3.new(LookVector.X, 0, LookVector.Z).Unit
        
                    Seat.CustomPhysicalProperties = PhysicalProperties.new(0.1, 0.1, 0.1, 0.1, 0.1)
        
                    BodyVelocity.Velocity = (W and Vector3.new(LookVector.X, 0, LookVector.Z) * Options["Speed"].Value) or (S and Vector3.new(-LookVector.X, 0, -LookVector.Z) * Options["Speed"].Value) or Vector3.zero
                    BodyAngularVelocity.AngularVelocity = (A and Vector3.new(0, Options["Rotate"].Value, 0)) or (D and Vector3.new(0, -Options["Rotate"].Value, 0)) or Vector3.zero
                    BodyGyro.CFrame = CFrame.new(Position, Position + Unit)
                end))
        
                Handler:AddConnection("KeyDown", UserInputService.InputBegan:Connect(function(Input, Locked)
                    if Locked then
                        return
                    end
        
                    if Input.KeyCode == Enum.KeyCode.W then
                        W = true
                    elseif Input.KeyCode == Enum.KeyCode.S then
                        S = true
                    elseif Input.KeyCode == Enum.KeyCode.A then
                        A = true
                    elseif Input.KeyCode == Enum.KeyCode.D then
                        D = true
                    end
                end))
        
                Handler:AddConnection("KeyUp", UserInputService.InputEnded:Connect(function(Input)
                    if Input.KeyCode == Enum.KeyCode.W then
                        W = false
                    elseif Input.KeyCode == Enum.KeyCode.S then
                        S = false
                    elseif Input.KeyCode == Enum.KeyCode.A then
                        A = false
                    elseif Input.KeyCode == Enum.KeyCode.D then
                        D = false
                    end
                end))
            else
                Handler:Disconnect({"Cart", "KeyDown", "KeyUp"})
        
                for Index, Instances in pairs({"Move", "Rotate", "Stabilizer"}) do
                    if Seat:FindFirstChild(Instances) then 
                        Seat:FindFirstChild(Instances):Destroy()
                    end
                end
            end
        end
    end
})

Main:AddLabel("Controls: WASD"):AddDependency(Toggles.CartEnabled)

-- Unload handler
api.onevent("unload", function()
    Handler:Disconnect({"Cart", "KeyDown", "KeyUp"})
    api.notify("Cart Car unloaded", 2)
end)

api.notify("Cart Car loaded!", 3)
