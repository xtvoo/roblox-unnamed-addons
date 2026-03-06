api:set_lua_name("fake_cosmetics")

local tab = api:GetTab("character") or api:AddTab("character")
local group = tab:AddLeftGroupbox("Fake Cosmetics")

group:AddToggle("fake_korblox_toggle", {
    Text = "Fake Korblox",
    Default = false
})

group:AddToggle("fake_headless_toggle", {
    Text = "Fake Headless",
    Default = false
})

local function apply_korblox(character, enabled)
    if not character then return end

    local rf  = character:FindFirstChild("RightFoot")
    local rll = character:FindFirstChild("RightLowerLeg")
    local rul = character:FindFirstChild("RightUpperLeg")

    if not (rf and rll and rul) then return end

    if enabled then
        rf.MeshId        = "http://www.roblox.com/asset/?id=902942089"
        rf.Transparency  = 1

        rll.MeshId       = "http://www.roblox.com/asset/?id=902942093"
        rll.Transparency = 1

        rul.MeshId       = "http://www.roblox.com/asset/?id=902942096"
        rul.TextureID    = "http://roblox.com/asset/?id=902843398"
    else
        rf.MeshId        = ""
        rf.Transparency  = 0

        rll.MeshId       = ""
        rll.Transparency = 0

        rul.MeshId       = ""
        rul.TextureID    = ""
    end
end

local function apply_headless(character, enabled)
    if not character then return end

    local head = character:FindFirstChild("Head")
    if not head then return end

    if enabled then
        head.Transparency = 1

        local face = head:FindFirstChild("face")
        if face then face:Destroy() end
    else
        head.Transparency = 0

        if not head:FindFirstChild("face") then
            local new_face  = Instance.new("Decal")
            new_face.Name   = "face"
            new_face.Texture= "rbxasset://textures/face.png"
            new_face.Face   = Enum.NormalId.Front
            new_face.Parent = head
        end
    end
end

local runservice = game:GetService("RunService")
local players = game:GetService("Players")
local localplayer = players.LocalPlayer

api:add_connection(runservice.Heartbeat:Connect(function()
    local char = localplayer.Character
    if not char then return end

    local kor  = api:get_ui_object("fake_korblox_toggle"):GetValue()
    local head = api:get_ui_object("fake_headless_toggle"):GetValue()

    if kor then
        apply_korblox(char, true)
    end

    if head then
        apply_headless(char, true)
    end
end))

api:on_event("unload", function()
    local char = localplayer.Character
    apply_korblox(char, false)
    apply_headless(char, false)
end)
