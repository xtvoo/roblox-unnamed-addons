--[[
    Unnamed Addon: Avatar Cloner (Morph System)
    User list + Headless & Korblox visual overrides
]]

api:set_lua_name("AvatarCloner")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- UI Setup
local tabs = { Visuals = api:GetTab("visuals") or api:AddTab("visuals") }
local sec = tabs.Visuals:AddRightGroupbox("Avatar Cloner")

-- Pre-defined users
local users = {
    {UserId = 5587308965, UserName = "Hayden"},
    {UserId = 523759874, UserName = "Ooo"},
    {UserId = 2395613299, UserName = "Bullet"},
    {UserId = 8208385845, UserName = "amir"},
    {UserId = 22782710, UserName = "cat"},
    {UserId = 140383551, UserName = "ender"},
    {UserId = 3759059, UserName = "noobslayer2010"},
    {UserId = 9013721214, UserName = "Fatal"},
}

local HasHeadLess = false 
local HasKorblox = false 

-- Helper Function: Morph
-- Uses GetCharacterAppearanceAsync (Standard Roblox API) logic
local function Morph(UserId)
    local player = LocalPlayer
    if not player or not player.Character then return end
    
    api:notify("Fetching appearance for ID: " .. UserId, 2)
    local appearance = nil
    local s, err = pcall(function()
        appearance = Players:GetCharacterAppearanceAsync(UserId)
    end)
    
    if not s or not appearance then 
        api:notify("Failed to fetch appearance!", 3)
        return 
    end

    local char = player.Character

    -- clear
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("CharacterMesh") or v:IsA("BodyColors") then
            v:Destroy()
        end
    end
    if char.Head:FindFirstChild("face") then
        char.Head.face:Destroy()
    end

    -- apply
    for _, v in pairs(appearance:GetChildren()) do
        if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
            v.Parent = char
        elseif v:IsA("Accessory") then
            char.Humanoid:AddAccessory(v)
        elseif v:IsA("CharacterMesh") then
            if char.Humanoid.RigType == Enum.HumanoidRigType.R6 then
                v.Parent = char
            end
        end
    end

    if appearance:FindFirstChild("face") then
        appearance.face.Parent = char.Head
    else
        local face = Instance.new("Decal")
        face.Face = Enum.NormalId.Front
        face.Name = "face"
        face.Texture = "rbxasset://textures/face.png"
        face.Transparency = 0
        face.Parent = char.Head
    end
    
    -- Refresh char
    local parent = char.Parent
    char.Parent = nil
    char.Parent = parent
    
    -- Re-apply special stuffs if needed
    if HasHeadLess and char:FindFirstChild("Head") then
         -- Simple headless (Transparency/Mesh size method or specific mesh)
         -- User provided headless toggle separately, but we can enforce it after morph
         -- If using specific mesh for headless:
         -- char.Head.MeshId = "rbxassetid://..." (Wait, Head mesh is special)
         
         -- The provided script logic: 
         -- char.Head.MeshId = 6686307858 (Only works if MeshPart?)
         -- For R6 (Da Hood defaults), usually we transparency the head and clone a fake face, BUT
         -- User code snippet implies MeshId method. 
         
         -- We will run the Toggles Logic again just in case
    end
end

-- Toggles
local HeadlessToggle = sec:AddToggle("AC_Headless", { Text = "Enable Headless", Default = false })
local KorbloxToggle = sec:AddToggle("AC_Korblox", { Text = "Enable Korblox", Default = false })

HeadlessToggle:OnChanged(function()
    HasHeadLess = HeadlessToggle.Value
    if HasHeadLess and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
        local head = LocalPlayer.Character.Head
        -- Da Hood Headless trick (Transparency or small mesh)
        -- User snippet suggests: MeshId = 6686307858
        -- But R6 heads are SpecialMesh usually.
        local mesh = head:FindFirstChildOfClass("SpecialMesh")
        if mesh then
            mesh.MeshId = "rbxassetid://20329976" -- Default head? No, headless is usually just hiding it.
            mesh.Scale = Vector3.new(0,0,0) -- Tiny head trick
        end
        head.Transparency = 1
        if head:FindFirstChild("face") then head.face.Transparency = 1 end
    end
end)

KorbloxToggle:OnChanged(function()
    HasKorblox = KorbloxToggle.Value
    local char = LocalPlayer.Character
    if HasKorblox and char then
       -- R6 Logic for Da Hood
       if char:FindFirstChild("Right Leg") then
           local leg = char["Right Leg"]
           
           -- 1. Remove existing meshes on the part
           for _, v in pairs(leg:GetChildren()) do
               if v:IsA("DataModelMesh") then v:Destroy() end
           end
           
           -- 2. Remove CharacterMasks/Meshes that override the leg
           for _, v in pairs(char:GetChildren()) do
               if v:IsA("CharacterMesh") and v.BodyPart == Enum.BodyPart.RightLeg then
                   v:Destroy()
               end
           end
           
           -- 3. Apply Korblox Mesh
           local mesh = Instance.new("SpecialMesh", leg)
           mesh.Name = "KorbloxMesh"
           mesh.MeshId = "rbxassetid://902942093"
           mesh.TextureId = "rbxassetid://902843398"
           mesh.Scale = Vector3.new(1, 1, 1) -- Standard Scale
           -- Sometimes slightly larger looks better: Vector3.new(1.1, 1.1, 1.1)
       end
    end
end)

-- User Dropdown
local userNames = {}
for _, u in ipairs(users) do table.insert(userNames, u.UserName) end

local UserDropdown = sec:AddDropdown("AC_UserSelect", { Text = "Select Morph", Default = "", Values = userNames, AllowNull = true })

UserDropdown:OnChanged(function()
    if UserDropdown.Value and UserDropdown.Value ~= "" then
        local sel = UserDropdown.Value
        for _, u in ipairs(users) do
            if u.UserName == sel then
                Morph(u.UserId)
                
                -- Re-apply visual hacks
                if HasHeadLess then
                     local char = LocalPlayer.Character
                     if char and char:FindFirstChild("Head") then
                         char.Head.Transparency = 1
                         if char.Head:FindFirstChild("face") then char.Head.face.Transparency = 1 end
                     end
                end
                break
            end
        end
    end
end)

-- Textbox for custom ID (optional, kept from before?) removed for cleaner UI matching user request.
sec:AddButton({Text = "Refresh Character (Fix)", Func = function()
    local char = LocalPlayer.Character
    if char then 
        local p = char.Parent 
        char.Parent = nil 
        char.Parent = p 
    end
end})
