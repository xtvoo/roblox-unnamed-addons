api:set_lua_name("wanted-list")

-- Use an existing tab; change "lua" to whatever tab name you already have
local tab = api:GetTab("lua") or api:AddTab("lua")
local listGroup = tab:AddLeftGroupbox("Wanted List")

listGroup:AddLabel("Players sorted by Wanted (top = highest)")

local updating = false
local labelPool = {}      -- reused labels
local maxLabels = 20      -- max rows shown; change if you want more

local function get_sorted_wanted()
    local players = game:GetService("Players")
    local list = {}

    for _, plr in ipairs(players:GetPlayers()) do
        local ok, wanted_value = pcall(function()
            local ls = plr:FindFirstChild("leaderstats")
            if not ls then return 0 end

            local wanted = ls:FindFirstChild("Wanted")
            if not wanted then return 0 end

            return wanted.Value
        end)

        if ok and type(wanted_value) == "number" then
            table.insert(list, { name = plr.Name, wanted = wanted_value })
        end
    end

    table.sort(list, function(a, b)
        return a.wanted > b.wanted
    end)

    return list
end

-- ensure we have a pool of label UI objects
local function ensure_labels()
    if #labelPool > 0 then return end
    for i = 1, maxLabels do
        labelPool[i] = listGroup:AddLabel("") -- empty initially
    end
end

local function update_ui_once()
    ensure_labels()

    local sorted = get_sorted_wanted()

    -- write rows into existing labels
    for i = 1, maxLabels do
        local data = sorted[i]
        local text
        if data then
            text = ("%d) %s - %s Wanted"):format(i, data.name, tostring(data.wanted))
        else
            text = "" -- clear leftover rows
        end
        labelPool[i]:SetText(text)
    end
end

listGroup:AddToggle("wanted_auto_update", {
    Text = "Auto Update (2s)",
    Default = false,
    Callback = function(value)
        updating = value
        if value then
            task.spawn(function()
                while updating do
                    update_ui_once()
                    task.wait(2)
                end
            end)
        end
    end
})

listGroup:AddButton({
    Text = "Refresh Now",
    Func = update_ui_once,
    Tooltip = "Update the list once"
})

api:on_event("unload", function()
    updating = false
    api:notify("Wanted List unloaded", 2)
end)

api:notify("Wanted List loaded on existing tab/groupbox.", 3)
