-- set a static lua name for configs etc
api:setluaname("hayden")

-- simple unload handler so unnamed doesn’t cry
api:onevent("unload", function()
    api:notify("bring/knock/stomp unloaded", 2)
end)

local Players      = game:GetService("Players")
local LocalPlayer  = Players.LocalPlayer
local RunService   = game:GetService("RunService")

-- state
local KnockActive  = false
local BringActive  = false
local StompActive  = false

-- small helpers
local function GetCharCache(player)
    return api:getcharactercache(player)
end

local function ValidLocal()
    local cache = GetCharCache(LocalPlayer)
    if not cache then return false end

    return cache.HumanoidRootPart
        and cache.Humanoid
        and cache.Head
        and cache.LowerTorso
end

local function GetRageTarget()
    return api:gettarget("ragebot")
end

local function SafeDisconnect(name)
    local ok = pcall(function()
        Handler:Disconnect(name)
    end)
    return ok
end

-- UI CREATION (unnamed-style)
-- you can change tab/section names/flags as you want
-- UI CREATION (unnamed-style)
local MainTab = api:GetTab("ragebot") or api:AddTab("ragebot")

local MainSection = MainTab:AddLeftGroupbox("Steal Helper")

local KnockButton = MainSection:AddButton({
    name = "Knock",
    flag = "hayden_knock_btn",
    callback = function()
        if not ValidLocal() then
            api:notify("no valid character (knock)", 2)
            return
        end

        if not (Toggles and Toggles["HudEnabled"] and Toggles["HudEnabled"].Value) then
            api:notify("hud disabled (knock)", 2)
            return
        end

        SafeDisconnect("KOED")

        local target = GetRageTarget()
        if KnockActive then
            -- turn off
            if LocalPlayer and (LocalPlayer.Character or LocalPlayer.Backpack) then
                Handler:Humanoid(LocalPlayer):UnequipTools()
            end

            if Options and Options["ragebot_targets"] then
                Options["ragebot_targets"]:SetValue("nil")
            end

            api:get_ui_object("ragebot_keybind"):OverrideState(false)
            api:set_ragebot(nil)
            KnockActive = false
            api:notify("knock disabled", 2)
            return
        end

        if not (target and target.Character) then
            api:notify("no ragebot target", 2)
            return
        end

        local tcache = GetCharCache(target)
        if not tcache or not tcache.HumanoidRootPart or not tcache.Humanoid then
            api:notify("target invalid", 2)
            return
        end

        if not (Handler:Is_KO(target) and not Handler:Is_KO(target).Value) then
            api:notify("target not knocked yet", 2)
            return
        end

        if Options and Options["ragebot_targets"] then
            if Options["ragebot_targets"].Value ~= target.Name then
                Options["ragebot_targets"]:SetValue(target.Name)
            end
        end

        api:notify(("knocking %s"):format(target.Name), 2)

        -- KO connection with safety + state checks
        Handler:AddConnection("KOED", RunService.Heartbeat:Connect(function()
            if not KnockActive then
                SafeDisconnect("KOED")
                return
            end

            if not (target and target.Character) then
                KnockActive = false
                SafeDisconnect("KOED")
                return
            end

            local isKO = Handler:Is_KO(target)
            if isKO and isKO.Value then
                api:notify(("knocked %s"):format(target.Name), 2)

                if LocalPlayer and (LocalPlayer.Character or LocalPlayer.Backpack) then
                    Handler:Humanoid(LocalPlayer):UnequipTools()
                end

                if Options and Options["ragebot_targets"] then
                    Options["ragebot_targets"]:SetValue("nil")
                end

                api:get_ui_object("ragebot_keybind"):OverrideState(false)
                api:set_ragebot(nil)
                KnockActive = false
                SafeDisconnect("KOED")
            end
        end))

        api:get_ui_object("ragebot_keybind"):OverrideState(true)
        api:set_ragebot(true)
        KnockActive = true
    end,
})

local BringButton = MainSection:AddButton({
    name = "Bring",
    flag = "hayden_bring_btn",
    callback = function()
        if not ValidLocal() then
            api:notify("no valid character (bring)", 2)
            return
        end

        if not (Toggles and Toggles["HudEnabled"] and Toggles["HudEnabled"].Value) then
            api:notify("hud disabled (bring)", 2)
            return
        end

        SafeDisconnect("KOED")

        local target = GetRageTarget()

        if BringActive then
            -- if already KO and we are meant to bring, start the bring loop
            if target and target.Character then
                local tcache = GetCharCache(target)
                if tcache and tcache.UpperTorso then
                    api:notify(("bringing %s"):format(target.Name), 2)

                    task.spawn(function()
                        while BringActive do
                            task.wait()
                            if not (target and target.Character) then break end
                            if not (Handler:Is_KO(target) and Handler:Is_KO(target).Value) then break end
                            if target.Character:FindFirstChild("GRABBING_CONSTRAINT") then break end

                            if Options and Options["ragebot_stomp_offset"] then
                                api:set_server_cframe(
                                    CFrame.new(tcache.UpperTorso.Position) *
                                    CFrame.new(0, Options["ragebot_stomp_offset"].Value, 0)
                                )
                            end
                        end
                        BringActive = false
                    end)

                    task.spawn(function()
                        while BringActive do
                            task.wait(0.1)
                            if not (target and target.Character) then break end
                            if not (Handler:Is_KO(target) and Handler:Is_KO(target).Value) then break end
                            if target.Character:FindFirstChild("GRABBING_CONSTRAINT") then break end

                            MainEvent:FireServer("Grabbing")
                            task.wait(0.3)
                        end

                        api:notify(("bringed %s"):format(target.Name), 2)
                        BringActive = false
                    end)

                    return
                end
            end

            -- otherwise, turn off
            if LocalPlayer and (LocalPlayer.Character or LocalPlayer.Backpack) then
                Handler:Humanoid(LocalPlayer):UnequipTools()
            end

            if Options and Options["ragebot_targets"] then
                Options["ragebot_targets"]:SetValue("nil")
            end

            api:get_ui_object("ragebot_keybind"):OverrideState(false)
            api:set_ragebot(nil)
            BringActive = false
            api:notify("bring disabled", 2)
            return
        end

        -- enabling bring logic
        if not (target and target.Character) then
            api:notify("no ragebot target", 2)
            return
        end

        local tcache = GetCharCache(target)
        if not tcache or not tcache.HumanoidRootPart or not tcache.Humanoid then
            api:notify("target invalid", 2)
            return
        end

        if Options and Options["ragebot_targets"] then
            if Options["ragebot_targets"].Value ~= target.Name then
                Options["ragebot_targets"]:SetValue(target.Name)
            end
        end

        if Handler:Is_KO(target) and not Handler:Is_KO(target).Value and not target.Character:FindFirstChild("GRABBING_CONSTRAINT") then
            api:notify(("knocking %s"):format(target.Name), 2)
            api:get_ui_object("ragebot_keybind"):OverrideState(true)
            api:set_ragebot(true)
        end

        BringActive = true

        -- wait until they are KO or we cancel
        task.spawn(function()
            while BringActive do
                task.wait()
                if not (target and target.Character) then break end
                if Handler:Is_KO(target) and Handler:Is_KO(target).Value then
                    break
                end
            end

            if not BringActive then
                return
            end

            api:notify(("bringing %s"):format(target.Name), 2)

            task.spawn(function()
                while BringActive do
                    task.wait()
                    if not (target and target.Character) then break end
                    if not (Handler:Is_KO(target) and Handler:Is_KO(target).Value) then break end
                    if target.Character:FindFirstChild("GRABBING_CONSTRAINT") then break end

                    if Options and Options["ragebot_stomp_offset"] and tcache and tcache.UpperTorso then
                        api:set_server_cframe(
                            CFrame.new(tcache.UpperTorso.Position) *
                            CFrame.new(0, Options["ragebot_stomp_offset"].Value, 0)
                        )
                    end
                end
                BringActive = false
            end)

            task.spawn(function()
                while BringActive do
                    task.wait(0.1)
                    if not (target and target.Character) then break end
                    if not (Handler:Is_KO(target) and Handler:Is_KO(target).Value) then break end
                    if target.Character:FindFirstChild("GRABBING_CONSTRAINT") then break end

                    MainEvent:FireServer("Grabbing")
                    task.wait(0.3)
                end

                api:notify(("bringed %s"):format(target.Name), 2)
                BringActive = false
            end)
        end)

        Handler:AddConnection("KOED", RunService.Heartbeat:Connect(function()
            if not BringActive then
                SafeDisconnect("KOED")
                return
            end

            if Handler:Is_KO(target) and Handler:Is_KO(target).Value then
                if LocalPlayer and (LocalPlayer.Character or LocalPlayer.Backpack) then
                    Handler:Humanoid(LocalPlayer):UnequipTools()
                end

                if Options and Options["ragebot_targets"] then
                    Options["ragebot_targets"]:SetValue("nil")
                end

                api:get_ui_object("ragebot_keybind"):OverrideState(false)
                api:set_ragebot(nil)
                SafeDisconnect("KOED")
            end
        end))
    end,
})

local StompButton = MainSection:AddButton({
    name = "Stomp",
    flag = "hayden_stomp_btn",
    callback = function()
        if not ValidLocal() then
            api:notify("no valid character (stomp)", 2)
            return
        end

        if not (Toggles and Toggles["HudEnabled"] and Toggles["HudEnabled"].Value) then
            api:notify("hud disabled (stomp)", 2)
            return
        end

        SafeDisconnect("DEAD")

        local target = GetRageTarget()

        if StompActive then
            if LocalPlayer and (LocalPlayer.Character or LocalPlayer.Backpack) then
                Handler:Humanoid(LocalPlayer):UnequipTools()
            end

            if Options and Options["ragebot_targets"] then
                Options["ragebot_targets"]:SetValue("nil")
            end

            api:get_ui_object("ragebot_keybind"):OverrideState(false)
            api:set_ragebot(nil)
            StompActive = false
            api:notify("stomp disabled", 2)
            return
        end

        if not (target and target.Character) then
            api:notify("no ragebot target", 2)
            return
        end

        local tcache = GetCharCache(target)
        if not tcache or not tcache.HumanoidRootPart or not tcache.Humanoid then
            api:notify("target invalid", 2)
            return
        end

        if Options and Options["ragebot_targets"] then
            if Options["ragebot_targets"].Value ~= target.Name then
                Options["ragebot_targets"]:SetValue(target.Name)
            end
        end

        if Handler:Is_KO(target) and not Handler:Is_KO(target).Value and not target.Character:FindFirstChild("GRABBING_CONSTRAINT") then
            api:notify(("knocking %s"):format(target.Name), 2)
        end

        if Handler:Is_Dead(target) and not Handler:Is_Dead(target).Value then
            api:get_ui_object("ragebot_keybind"):OverrideState(true)
            api:set_ragebot(true)
        end

        StompActive = true

        task.spawn(function()
            while StompActive do
                task.wait()
                if not (target and target.Character) then break end
                if Handler:Is_Dead(target) and Handler:Is_Dead(target).Value then
                    break
                end
            end
            StompActive = false
        end)

        Handler:AddConnection("DEAD", RunService.Heartbeat:Connect(function()
            if not StompActive then
                SafeDisconnect("DEAD")
                return
            end

            if not (target and target.Character) then
                StompActive = false
                SafeDisconnect("DEAD")
                return
            end

            if Handler:Is_Dead(target) and Handler:Is_Dead(target).Value then
                api:notify(("stomped %s"):format(target.Name), 2)

                if LocalPlayer and (LocalPlayer.Character or LocalPlayer.Backpack) then
                    Handler:Humanoid(LocalPlayer):UnequipTools()
                end

                if Options and Options["ragebot_targets"] then
                    Options["ragebot_targets"]:SetValue("nil")
                end

                api:get_ui_object("ragebot_keybind"):OverrideState(false)
                api:set_ragebot(nil)
                StompActive = false
                SafeDisconnect("DEAD")
            end
        end))
    end,
})
