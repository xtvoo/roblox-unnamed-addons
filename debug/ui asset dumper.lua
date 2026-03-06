--[[
    Unnamed Addon: UI Asset Dumper
    Finds all images in your MainScreenGui and prints their IDs to console (F9)
]]

api:set_lua_name("UIAssetDumper")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

api:notify("Dumping UI Assets to Console (F9)...", 3)

local function dumpAssets(parent)
    local output = "UI ASSET DUMP\n==========================\n"
    
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            if obj.Image and obj.Image ~= "" then
                output = output .. "--------------------------------\n"
                output = output .. "Name: " .. obj.Name .. "\n"
                output = output .. "Type: " .. obj.ClassName .. "\n"
                output = output .. "Image ID: " .. obj.Image .. "\n"
                output = output .. "Parent: " .. obj.Parent.Name .. "\n"
                
                local pos = obj.AbsolutePosition
                output = output .. "Position: " .. math.floor(pos.X) .. ", " .. math.floor(pos.Y) .. "\n"
            end
        end
    end
    
    return output
end

local gui = PlayerGui:FindFirstChild("MainScreenGui")
if gui then
    local content = dumpAssets(gui)
    writefile("DaHood_UI_Dump.txt", content)
    api:notify("Saved to workspace/DaHood_UI_Dump.txt", 5)
else
    api:notify("MainScreenGui not found!", 3)
end
