local messanger = game:GetService("Players")
local joinserver = {}
local leaveserver = {}
local murders = {}
local assasinations = {}
local laststompxoxo
local tobeornottobe = {}
local amijfk = false
-- femboy antiskid v3
api:on_event("localplayer_hit_player", function(vic, part, dmg, gun, org, pos)
    task.spawn(function()
        task.wait(1)
        local plr = messanger:FindFirstChild(vic)
        if not plr then return end

        local ok, stat = pcall(function()
            return api:get_status_cache(plr)
        end)
        if not ok or not stat then return end

        local isded = stat.Dead or stat["K.O"] or stat["SDeath"] or stat["SDead"]
        local wasded = tobeornottobe[vic] or false

        if isded and not wasded then
            tobeornottobe[vic] = true
            murders[vic] = (murders[vic] or 0) + 1
            if refreshScore then refreshScore() end

            local k = murders[vic]
            local d = assasinations[vic] or 0
            local disp = plr and plr.DisplayName or vic

            api:notify("you - " .. k .. " v " .. d .. " " .. disp)

            task.spawn(function()
                while tobeornottobe[vic] do
                    task.wait(1)
                    local ok2, stat2 = pcall(function()
                        return api:get_status_cache(plr)
                    end)
                    if not ok2 or not stat2 then break end

                    local stillded = stat2.Dead or stat2["K.O"] or stat2["SDeath"] or stat2["SDead"]
                    if not stillded then
                        tobeornottobe[vic] = false
                        break
                    end
                end
            end)
        end
    end)
end)

api:on_event("player_got_shot", function(vic, shooter)
    local me = messanger.LocalPlayer
    if vic == me.Name then
        laststompxoxo = shooter
    end
end)

api:on_event("localplayer_died", function()
    if laststompxoxo and not amijfk then
        assasinations[laststompxoxo] = (assasinations[laststompxoxo] or 0) + 1
        amijfk = true

        local k = murders[laststompxoxo] or 0
        local d = assasinations[laststompxoxo]
        if refreshScore then refreshScore() end

        local plr = messanger:FindFirstChild(laststompxoxo)
        local disp = plr and plr.DisplayName or laststompxoxo
        api:notify("you - " .. k .. " v " .. d .. " " .. disp)
	task.wait(1)
	api:notify("you suck ass gah dayum")
    end
    laststompxoxo = nil
end)

api:on_event("localplayer_spawned", function()
    amijfk = false
end)

messanger.PlayerAdded:Connect(function(p)
    local t = os.clock()
    if joinserver[p.Name] and (t - joinserver[p.Name] < 1) then return end
    joinserver[p.Name] = t
    api:notify(p.DisplayName .. " joined")
end)

messanger.PlayerRemoving:Connect(function(p)
    local t = os.clock()
    if leaveserver[p.Name] and (t - leaveserver[p.Name] < 1) then return end
    leaveserver[p.Name] = t

    local function chk(p2)
        local types = {"ragebot", "aimbot", "silent"}
        for _, t in ipairs(types) do
            local ok, tar = pcall(function()
                return api:get_target(t)
            end)
            if ok and tar and tar.Name == p2.Name then
                return true
            end
        end
        return false
    end

    local disp = p.DisplayName
    if chk(p) then
        api:notify("lmao" .. disp .. " logged")
    else
        api:notify(disp .. " left the server")
    end
end)

local misctab = api:GetTab("misc") or api:AddTab("misc")
local scoregrp = misctab:AddLeftGroupbox("score")
local scorelabl = scoregrp:AddLabel("", true)

local function doscore()
    local lines = {}
    for nm, k in pairs(murders) do
        local d = assasinations[nm] or 0
        local p = messanger:FindFirstChild(nm)
        local disp = p and p.DisplayName or nm
        table.insert(lines, "you " .. k .. " - " .. d .. " " .. disp)
    end

    table.sort(lines)
    local txt = ""
    if #lines > 0 then
        txt = table.concat(lines, "\n")
    end

    pcall(function()
        if scorelabl.SetText then
            scorelabl:SetText(txt)
        elseif scorelabl.SetValue then
            scorelabl:SetValue(txt)
        end
    end)
end

refreshScore = doscore

scoregrp:AddButton("clear", function()
    murders = {}
    assasinations = {}
    doscore()
end)
-- made by eset.security
