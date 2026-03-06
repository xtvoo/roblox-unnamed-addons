--[[
    Auto Loader Script
    Checks if Game is Da Hood and User is NOT Blacklisted.
    Loads: Unnamed Cheats (Da Hood Only - Waits for ForceField removal) & Prompts for Infinite Yield (All Games)
]]

-- Wait for Game to Fully Load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId

local TargetGameId = 2788229376 -- Da Hood Place ID
local BlacklistedUser = "Haremelito"
local WebhookUrl = "https://discord.com/api/webhooks/1461931953073688678/uTTmJ97l_FWEhZzOhGSG5SiUY5-Ry8C-jRTR4QVadNAL5_vUA7csp0erKRWh93BK2F18"

local function LogToWebhook()
    if WebhookUrl == "" or WebhookUrl == "YOUR_WEBHOOK_HERE" then return end
    
    local http = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
    if not http then return end

    local data = {
        ["content"] = "",
        ["embeds"] = {{
            ["title"] = "Auto Loader Executed",
            ["description"] = "**User:** " .. LocalPlayer.Name .. " (" .. LocalPlayer.DisplayName .. ")\n**Status:** Script Initialized",
            ["color"] = 65280, -- Green
            ["fields"] = {
                {["name"] = "User ID", ["value"] = tostring(LocalPlayer.UserId), ["inline"] = true},
                {["name"] = "Game", ["value"] = tostring(game.PlaceId), ["inline"] = true},
                {["name"] = "Job ID", ["value"] = "```" .. game.JobId .. "```", ["inline"] = false}
            },
            ["footer"] = {
                ["text"] = "Unnamed Cheats Auto Loader"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    
    pcall(function()
        http({
            Url = WebhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = game:GetService("HttpService"):JSONEncode(data)
        })
    end)
end

local function SendNotification(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title;
            Text = text;
            Duration = 5;
        })
    end)
end

-- 1. Prompt Infinite Yield (GLOBAL - Any Game)
local function PromptInfiniteYield()
    local bindable = Instance.new("BindableFunction")
    
    bindable.OnInvoke = function(buttonName)
        if buttonName == "Yes" then
            SendNotification("Auto Loader", "Loading Infinite Yield...")
            task.spawn(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/xtvoo/inf-yeild/refs/heads/main/inf%20yeild"))()
            end)
        elseif buttonName == "No" then
            SendNotification("Auto Loader", "Skipped Infinite Yield.")
        end
    end

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Load Infinite Yield?";
            Text = "Do you want to load Infinite Yield?";
            Duration = 9e9; -- Persist until clicked
            Callback = bindable;
            Button1 = "Yes";
            Button2 = "No";
        })
    end)
end

task.spawn(PromptInfiniteYield) -- Run immediately
LogToWebhook() -- Log execution

-- 2. Prompt Unnamed Cheats (SPECIFIC - Da Hood Only)
if PlaceId == TargetGameId then
    if LocalPlayer.Name == BlacklistedUser then
        warn("AutoLoader: ABORTED. User '" .. BlacklistedUser .. "' is blacklisted from this script.")
        SendNotification("Auto Loader", "Access Denied: Blacklisted User")
    else
        local function PromptUnnamed()
            -- Wait for Character and ForceField first
            task.spawn(function()
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                
                if char:FindFirstChildOfClass("ForceField") then
                    SendNotification("Auto Loader", "Waiting for ForceField...")
                    repeat 
                        task.wait(1) 
                    until not char:FindFirstChildOfClass("ForceField")
                end
                
                -- Now prompt for Unnamed
                local bindable = Instance.new("BindableFunction")
                
                bindable.OnInvoke = function(buttonName)
                    if buttonName == "Yes" then
                        SendNotification("Auto Loader", "Loading Unnamed Cheats...")
                        task.spawn(function()
                            getgenv().script_key="vyinScQTGVpqarLGRVliPkSIimmozGZA"
                            loadstring(game:HttpGet("https://raw.githubusercontent.com/smi9/UnnamedCheats/refs/heads/main/loader.lua"))()
                        end)
                    elseif buttonName == "No" then
                        SendNotification("Auto Loader", "Skipped Unnamed Cheats.")
                    end
                end

                pcall(function()
                    StarterGui:SetCore("SendNotification", {
                        Title = "Load Unnamed Cheats?";
                        Text = "Da Hood detected. Load Unnamed?";
                        Duration = 9e9; -- Persist until clicked
                        Callback = bindable;
                        Button1 = "Yes";
                        Button2 = "No";
                    })
                end)
            end)
        end
        
        PromptUnnamed()
    end
else
    print("AutoLoader: Not Da Hood (ID: " .. tostring(PlaceId) .. "). Skipping Unnamed Cheats.")
end
