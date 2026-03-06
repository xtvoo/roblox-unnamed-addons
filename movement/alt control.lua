local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localplayer = Players.LocalPlayer

api:set_lua_name("target_logger")

local webhook = "https://discord.com/api/webhooks/1457422658349175029/1gwru943cXU3fdU5LXkyWrkiNzRuBQRtAPjjiGFFwNEPJ9iR97yYkIDL11a7UByAoCkW"

local function send_to_webhook(title, desc)
    -- local debug so you can see when it would send
    print("[WEBHOOK]", title, desc)

    local data = {
        embeds = {{
            title = title,
            description = desc,
            color = 16711680,
        }}
    }

    local ok, err = pcall(function()
        return syn.request({
            Url = webhook,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(data)
        })
    end)

    if not ok then
        warn("Webhook error:", err)
    end
end

local function safe_get_target_cache(kind)
    local ok, res = pcall(function()
        return api:get_target_cache(kind)  -- "ragebot" | "aimbot" | "silent"[file:1]
    end)
    if ok then
        return res
    end
    return nil
end

local function safe_is_crew(p1, p2)
    local ok, res = pcall(function()
        return api:is_crew_player(p1, p2)  -- boolean[file:1]
    end)
    if ok then
        return res
    end
    return false
end

local prev_silent, prev_rage = nil, nil

-- silent via targetchanged event (from docs)
api:on_event("targetchanged", function(target)  -- fires with new target or nil[file:1]
    if not target or not target.Parent then
        return
    end

    local plr = Players:GetPlayerFromCharacter(target.Parent)
    if not plr or plr == localplayer then
        return
    end

    if safe_is_crew(localplayer, plr) then
        return
    end

    local msg = plr.Name .. " | Part: " .. target.Name
    if msg ~= prev_silent then
        prev_silent = msg
        send_to_webhook("Silent aim target", msg)
    end
end)

-- ragebot via polling
local hb_conn = RunService.Heartbeat:Connect(function()
    if not api:is_ragebot() then  -- returns true if ragebotting[file:1]
        return
    end

    local status, data = api:get_ragebot_status()  -- (string, any?)[file:1]

    if status == "killing" and data and data.Parent then
        local plr = Players:GetPlayerFromCharacter(data.Parent)
        if plr and plr ~= localplayer and not safe_is_crew(localplayer, plr) then
            local msg = plr.Name .. " | Part: " .. (data.Name or "Unknown")
            if msg ~= prev_rage then
                prev_rage = msg
                send_to_webhook("Ragebot target", msg)
            end
        end
    elseif status == "no target" and (prev_silent or prev_rage) then
        prev_silent, prev_rage = nil, nil
        send_to_webhook("Targets cleared", "No current silent or ragebot target")
    end
end)

api:on_event("unload", function()
    if hb_conn then
        hb_conn:Disconnect()
        hb_conn = nil
    end
    api:notify("Target logger unloaded", 3)
end)

api:notify("Target logger loaded", 3)
