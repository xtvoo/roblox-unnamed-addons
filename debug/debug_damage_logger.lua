local Players = game:GetService("Players")

print("------------------------------------------------")
print("[DEBUG] Damage Logger Started - Check Console (F9)")
print("------------------------------------------------")

local monitored = {}

local function monitor_humanoid(player, humanoid)
    if monitored[humanoid] then return end
    monitored[humanoid] = true

    local last_health = humanoid.Health

    humanoid.HealthChanged:Connect(function(new_health)
        if new_health < last_health then
            print(string.format("\n[DAMAGE] %s took damage! (%.1f -> %.1f)", player.Name, last_health, new_health))
            
            -- Search for Creator Tag
            local found_tag = false
            for _, child in ipairs(humanoid:GetChildren()) do
                if child.Name:lower() == "creator" then
                    found_tag = true
                    print(string.format("   + FOUND CREATOR TAG: Name='%s' | Value='%s' | Type='%s'", child.Name, tostring(child.Value), child.ClassName))
                elseif child:IsA("ObjectValue") and child.Value and child.Value:IsA("Player") then
                    print(string.format("   ? Possible Tag: Name='%s' | Value='%s'", child.Name, tostring(child.Value)))
                end
            end
            
            if not found_tag then
                print("   ! No 'creator' tag found.")
            end
        end
        last_health = new_health
    end)
end

local function setup_player(player)
    if player.Character then
        local hum = player.Character:FindFirstChild("Humanoid")
        if hum then monitor_humanoid(player, hum) end
    end
    player.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then monitor_humanoid(player, hum) end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    setup_player(p)
end

Players.PlayerAdded:Connect(setup_player)
