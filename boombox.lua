return function(api)
    -- static name for configs
    api:set_lua_name("steal_boombox_ringtone")

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    -- simple notify wrapper
    local function notify(msg, time)
        api:notify(msg, time or 3)
    end

    -- get sound id from torso child
    local function get_sound_id(player, sound_name)
        if not player then return end
        local character = player.Character
        if not character then return end

        local torso = character:FindFirstChild("LowerTorso")
        if not torso then return end

        local sound = torso:FindFirstChild(sound_name)
        if not sound or not sound:IsA("Sound") then return end

        local str = tostring(sound.SoundId)
        local split = string.split(str, "//")
        return split[2]
    end

    -- unified target resolver: ragebot / aimbot / silent / dropdown
    local function get_target_player()
        -- prefer ragebot target
        local rageTarget = api:get_target("ragebot")
        if rageTarget then
            return rageTarget
        end

        -- then aimbot
        local aimbotTarget = api:get_target("aimbot")
        if aimbotTarget then
            return aimbotTarget
        end

        -- then silent
        local silentTarget = api:get_target("silent")
        if silentTarget then
            return silentTarget
        end

        -- finally, dropdown selection
        local selectedName = api:get_flag("bb_target_dropdown")
        if selectedName and selectedName ~= "" then
            return Players:FindFirstChild(selectedName)
        end
    end

    local function copy_id(kind)
        local target = get_target_player()
        if not target then
            notify("No target (rage/aim/silent/dropdown)!", 3)
            return
        end

        local soundName = (kind == "boombox") and "BOOMBOXSOUND" or "PhoneRing"
        local id = get_sound_id(target, soundName)

        if not id then
            if kind == "boombox" then
                notify("No boombox found on target!", 3)
            else
                notify("No ringtone found on target!", 3)
            end
        else
            setclipboard(id)
            if kind == "boombox" then
                notify("Copied Boombox ID", 1)
            else
                notify("Copied Ringtone ID", 1)
            end
        end
    end

    -- MAIN tab + groupbox (docs style)
    local tabs = {
        main = api:GetTab("misc") or api:AddTab("misc");
    }

    local groupbox = tabs.main:AddLeftGroupbox("Boombox / Ringtone Stealer")

    -- target dropdown
    local targetDropdown = groupbox:AddDropdown("bb_target_dropdown", {
        Text = "Target selector";
        Values = {};
        Default = "";
        Multi = false;
    })

    -- boombox button
    groupbox:AddButton({
        Text = "Copy Boombox ID";
        Func = function()
            copy_id("boombox")
        end;
    })

    -- ringtone button
    groupbox:AddButton({
        Text = "Copy Ringtone ID";
        Func = function()
            copy_id("ringtone")
        end;
    })

    -- refresh dropdown with players
    local function refresh_dropdown()
        local values = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                table.insert(values, plr.Name)
            end
        end
        targetDropdown:SetValues(values)
    end

    local heartbeatConn = api:add_connection(RunService.Heartbeat:Connect(refresh_dropdown))

    -- unload handler (docs style)
    api:on_event("unload", function()
        if heartbeatConn then
            heartbeatConn:Disconnect()
        end
        api:notify("steal_boombox_ringtone unloaded", 2)
    end)
end
