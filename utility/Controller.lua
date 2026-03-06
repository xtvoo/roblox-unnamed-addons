-- Controller.lua
-- Run this on your MAIN account to control the bot
-- Communicates via workspace/unnamed_bot_comm.json

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Communication File
local COMM_FILE = "unnamed_bot_comm.json"

-- Helper function to send commands
local function SendCommand(cmd, args)
    local data = {
        req_id = os.clock(), -- Use high-precision timestamp as ID
        command = cmd,
        args = args or {},
        sender = LocalPlayer.Name
    }
    
    local encoded = HttpService:JSONEncode(data)
    writefile(COMM_FILE, encoded)
    
    -- Visual feedback
    api:notify("Sent: " .. cmd, 1)
end

-- UI Setup (Matches Unnamed API style)
api:set_lua_name("StandController")

local ControllerTab = api:AddTab("Stand Controller")

-- Groups
local MainGroup = ControllerTab:AddLeftGroupbox("Target Control")
local ActionGroup = ControllerTab:AddLeftGroupbox("Actions")
local SettingsGroup = ControllerTab:AddRightGroupbox("Settings")
local PlayerListGroup = ControllerTab:AddRightGroupbox("Player List")

-- Target Input
MainGroup:AddInput("target_input", {
    Default = "",
    Numeric = false,
    Finished = false,
    Text = "Target Name",
    Tooltip = "Enter player name to target",
    Placeholder = "Player name..."
})

MainGroup:AddButton({
    Text = "ADD Target (.add)",
    Func = function()
        local name = Options.target_input.Value
        if name ~= "" then
            SendCommand("add", {name})
            Options.target_input:SetValue("")
        end
    end
})

MainGroup:AddButton({
    Text = "REMOVE Target (.remove)",
    Func = function()
        local name = Options.target_input.Value
        if name ~= "" then
            SendCommand("remove", {name})
            Options.target_input:SetValue("")
        end
    end
})

MainGroup:AddDivider()

MainGroup:AddButton({
    Text = "Clear All Targets (.clear)",
    Func = function()
        SendCommand("clear")
    end
})

-- Actions
ActionGroup:AddButton({
    Text = "Bring Target",
    Func = function()
        local name = Options.target_input.Value
        if name ~= "" then
            SendCommand("bring_target", {name})
        else
            api:notify("Enter a target name first!", 2)
        end
    end
})

ActionGroup:AddButton({
    Text = "Knock Target",
    Func = function()
        local name = Options.target_input.Value
        if name ~= "" then
            SendCommand("knock", {name})
        end
    end
})

ActionGroup:AddButton({
    Text = "Stomp Target",
    Func = function()
        local name = Options.target_input.Value
        if name ~= "" then
            SendCommand("stomp", {name})
        end
    end
})

ActionGroup:AddDivider()

-- Toggles sent as commands
ActionGroup:AddToggle("rage_toggle", {
    Text = "Ragebot Enabled",
    Default = false,
    Callback = function(value)
        SendCommand("rage", {tostring(value)})
    end
})

ActionGroup:AddToggle("void_prot_toggle", {
    Text = "Void Protection (Bot)",
    Default = false,
    Callback = function(value)
        SendCommand("void_prot", {tostring(value)})
    end
})

ActionGroup:AddToggle("fake_lag_toggle", {
    Text = "Fake Lag/Pos",
    Default = false,
    Callback = function(value)
        SendCommand("fake", {tostring(value)})
    end
})

-- Settings
SettingsGroup:AddLabel("Controller Status: Active")
SettingsGroup:AddLabel("File: " .. COMM_FILE)

SettingsGroup:AddButton({
    Text = "Summon Bot",
    Func = function()
        SendCommand("summon")
    end
})

SettingsGroup:AddButton({
    Text = "STOP BOT (Emergency)",
    Func = function()
        SendCommand("stop")
    end
})

-- Player List (Simplified)
PlayerListGroup:AddLabel("Click to Add Target")

local function RefreshPlayerList()
    -- This would ideally use a proper implementation to clear/re-add children
    -- But Unnamed API limitations might make dynamic lists hard.
    -- For now, we'll just provide a simple refreshable dropdown
    
    local playerNames = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(playerNames, p.Name)
        end
    end
    
    if Options.player_dropdown then
        Options.player_dropdown:SetValues(playerNames)
    end
end

PlayerListGroup:AddDropdown("player_dropdown", {
    Values = {},
    Default = 1,
    Multi = false,
    Text = "Select Player",
    Tooltip = "Select a player from the server",
})

PlayerListGroup:AddButton({
    Text = "Add Selected",
    Func = function()
        local name = Options.player_dropdown.Value
        if name then
            SendCommand("add", {name})
        end
    end
})

PlayerListGroup:AddButton({
    Text = "Refresh List",
    Func = function()
        RefreshPlayerList()
    end
})

PlayerListGroup:AddDivider()

PlayerListGroup:AddButton({
    Text = "Give Selector Tool",
    Func = function()
        local tool = Instance.new("Tool")
        tool.RequiresHandle = false
        tool.Name = "[TARGET SELECTOR]"
        
        tool.Activated:Connect(function()
            local mouse = LocalPlayer:GetMouse()
            local target = mouse.Target
            if target then
                local character = target.Parent
                if character and character:FindFirstChild("Humanoid") then
                    local player = Players:GetPlayerFromCharacter(character)
                    if player and player ~= LocalPlayer then
                         -- Send SPECIAL command: add_selection
                         -- This command adds to target list but DOES NOT auto-enable rage
                         SendCommand("add_selection", {player.Name})
                         
                         -- Visual confirm
                         local highlight = Instance.new("Highlight")
                         highlight.Parent = character
                         highlight.FillColor = Color3.fromRGB(255, 0, 0)
                         highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                         game:GetService("Debris"):AddItem(highlight, 1)
                    end
                end
            end
        end)
        
        tool.Parent = LocalPlayer.Backpack
        api:notify("Check Backpack for Selector", 2)
    end
})

-- Init
RefreshPlayerList()
api:notify("Controller Loaded", 2)

-- CHAT RELAY SYSTEM (Owner -> File -> Bot)
local TextChatService = game:GetService("TextChatService")

local function ProcessChat(message)
    -- Check for prefix "."
    if string.sub(message, 1, 1) ~= "." then return end
    
    local prefix = "."
    local command = message:match("^" .. prefix .. "(%S+)")
    local argString = message:match("^" .. prefix .. "%S+%s+(.+)") or ""
    
    if not command then return end
    
    command = string.lower(command)
    
    local args = {}
    for arg in argString:gmatch("[^,%s]+") do
        table.insert(args, arg)
    end
    
    -- Send all arguments including the raw string as the last arg (useful for 'say' command)
    -- But SendCommand expects a list of args.
    
    api:notify("Relaying: ." .. command, 1)
    SendCommand(command, args)
end

-- Hook into TextChatService (Modern)
if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    local textChannels = TextChatService:WaitForChild("TextChannels", 2)
    if textChannels then
        local general = textChannels:WaitForChild("RBXGeneral", 2)
        if general then
            general.MessageReceived:Connect(function(msgObj)
                if msgObj.TextSource and msgObj.TextSource.UserId == LocalPlayer.UserId then
                    ProcessChat(msgObj.Text)
                end
            end)
        end
    end
end

-- Hook into Legacy Chat (Fallback)
LocalPlayer.Chatted:Connect(function(msg)
    ProcessChat(msg)
end)
