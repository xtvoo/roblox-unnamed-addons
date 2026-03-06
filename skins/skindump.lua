api:set_lua_name("skin_dump_all")
api:on_event("unload", function()
    api:notify("unloaded", 2)
end)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- global accumulator: [category][skin_name] = total_amount across all players
local all_skins = {}

local function add_player_skins(plr)
    local ok, err = pcall(function()
        local skins_value = plr.DataFolder.Skins.Value  -- JSON string

        -- decode JSON: { ["[Mask]"] = { ["Ski Mask"] = 4, ... }, ... }
        local decoded = HttpService:JSONDecode(skins_value)

        for category, skins in pairs(decoded) do
            all_skins[category] = all_skins[category] or {}
            local cat_tbl = all_skins[category]

            for skin_name, amount in pairs(skins) do
                local num = tonumber(amount) or 0
                cat_tbl[skin_name] = (cat_tbl[skin_name] or 0) + num
            end
        end
    end)

    if not ok then
        -- optional debug
        -- api:notify("skins fail "..plr.Name..": "..tostring(err), 2)
    end
end

-- process every current player
for _, plr in ipairs(Players:GetPlayers()) do
    add_player_skins(plr)
end

-- build output: only skins, grouped by category
local lines = {}

for category, skins in pairs(all_skins) do
    table.insert(lines, category .. ":")
    for skin_name, total in pairs(skins) do
        table.insert(lines, ("  %s = %s"):format(skin_name, tostring(total)))
    end
    table.insert(lines, "")
end

local output = table.concat(lines, "\n")
local file_name = "Unnamed_AllSkinsDump.txt"

local ok, err = pcall(function()
    if writefile then
        writefile(file_name, output)
    else
        print(output)
    end
end)

if not ok then
    api:notify("Failed to save skins: " .. tostring(err), 5)
else
    api:notify("All skins dump saved to: " .. file_name, 5)
end
