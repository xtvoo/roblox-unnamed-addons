api:set_lua_name("color_esp");

local Players     = game:GetService("Players");
local RunService  = game:GetService("RunService");
local LocalPlayer = Players.LocalPlayer;

-- change this RGB window to whatever you want
local function IsInColorRange(color: Color3): boolean
    local r = math.floor(color.R * 255);
    local g = math.floor(color.G * 255);
    local b = math.floor(color.B * 255);

    return
        (r >= 90 and r < 130) and
        (g >= 45 and g < 80) and
        (b < 55);
end;

local function GetHeadColor3(character: Model?): Color3?
    if (not character) then
        return nil;
    end;

    local bodyColors = character:FindFirstChildOfClass("BodyColors");
    if (not bodyColors) then
        return nil;
    end;

    return bodyColors.HeadColor3;
end;

-- hook your actual ESP drawing here (your ESP(player) function)
local function ColorESP(player: Player)
    -- ESP(player);
end;

local function UpdateColorESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if (plr ~= LocalPlayer) then
            local char = plr.Character;
            local col  = GetHeadColor3(char);

            if (col and IsInColorRange(col)) then
                ColorESP(plr);
            end;
        end;
    end;
end;

local hbConnection = api:add_connection(
    RunService.Heartbeat:Connect(UpdateColorESP)
);

api:on_event("unload", function()
    if (hbConnection) then
        hbConnection:Disconnect();
    end;
end);
