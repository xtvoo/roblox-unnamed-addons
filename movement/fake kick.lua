--[[
    Unnamed Addon: Fake Kick Screen
    Troll yourself or others (stream proofing) by faking a disconnect!
    Supports: Custom Image (from file) or Classic Roblox Style
]]

api:set_lua_name("FakeKick")

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- UI Setup
local tabs = { Visuals = api:GetTab("visuals") or api:AddTab("visuals") }
local sec = tabs.Visuals:AddRightGroupbox("Fake Kick")

--[[
    Unnamed Addon: Custom Kick Screen
    Automatically replaces the ugly Roblox disconnect screen with your custom image!
]]

api:set_lua_name("KickScreenCustomizer")

local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

-- UI Setup
local tabs = { Visuals = api:GetTab("visuals") or api:AddTab("visuals") }
local sec = tabs.Visuals:AddRightGroupbox("Kick Screen Replacement")

local Enabled = sec:AddToggle("KS_Enable", { Text = "Enable Custom Screen", Default = true })
local ImagePath = sec:AddInput("KS_ImgPath", { Text = "Image Path", Default = "assets/kick.png", Tooltip = "Place file in your workspace folder!" })

local TestBtn = sec:AddButton({ Text = "Test / Preview Screen", Func = function() 
    -- Preview Logic
    if _G.KickScreenPreview then _G.KickScreenPreview:Destroy() _G.KickScreenPreview = nil return end
    
    local path = ImagePath.Value
    if not isfile(path) then api:notify("File not found!", 3) return end
    
    local screen = Instance.new("ScreenGui")
    screen.Name = "KickScreenPreview"
    screen.IgnoreGuiInset = true
    screen.DisplayOrder = 100000
    screen.Parent = CoreGui
    
    local img = Instance.new("ImageLabel", screen)
    img.Size = UDim2.new(1,0,1,0)
    img.BackgroundColor3 = Color3.new(0,0,0)
    img.Image = getcustomasset(path)
    img.ScaleType = Enum.ScaleType.Stretch
    
    local btn = Instance.new("TextButton", screen)
    btn.Text = "CLICK TO CLOSE PREVIEW"
    btn.Size = UDim2.new(0, 200, 0, 50)
    btn.Position = UDim2.new(0.5, -100, 0.9, 0)
    btn.BackgroundColor3 = Color3.new(1,0,0)
    btn.MouseButton1Click:Connect(function() screen:Destroy() end)
    
    _G.KickScreenPreview = screen
end })

sec:AddButton({ Text = "Debug: Force Disconnect", Func = function()
    LocalPlayer:Kick("\n\nTesting Custom Kick Screen...\nYou should see your custom image now!")
end })

-- Logic to detect Kick/Error
local CustomScreen = nil

local function RemoveBlur()
    local lighting = game:GetService("Lighting")
    for _, v in pairs(lighting:GetChildren()) do
        if v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = false
        end
    end
}

local function ShowCustomScreen()
    if CustomScreen then return end
    
    local path = ImagePath.Value
    if not isfile(path) then return end
    
    -- Fix Blurriness: Remove annoying Roblox blur filter
    RemoveBlur()
    
    local screen = Instance.new("ScreenGui")
    screen.Name = "CustomDisconnect"
    screen.IgnoreGuiInset = true
    screen.DisplayOrder = 100001 -- Higher than Roblox
    screen.Parent = CoreGui
    
    local img = Instance.new("ImageLabel", screen)
    img.Size = UDim2.new(1,0,1,0)
    img.BackgroundColor3 = Color3.new(0,0,0)
    img.Image = getcustomasset(path)
    img.ScaleType = Enum.ScaleType.Stretch
    
    CustomScreen = screen
end

-- Monitor Roblox Error Prompt
RunService.RenderStepped:Connect(function()
    if not Enabled.Value then return end
    
    -- Continuously kill blur while screen is active
    if CustomScreen then RemoveBlur() end
    
    local prompt = CoreGui:FindFirstChild("RobloxPromptGui")
    if prompt then 
        local promptFrame = prompt:FindFirstChild("promptOverlay") 
        if promptFrame and promptFrame:FindFirstChild("ErrorPrompt") then
            -- Error Detected!
            if promptFrame.Visible then
                -- Hide Roblox UI
                prompt.Enabled = false 
                
                -- Show Ours
                ShowCustomScreen()
            end
        end
    end
    
    -- Also check GuiService error message
    local errMsg = GuiService:GetErrorMessage()
    if errMsg and errMsg ~= "" then
        ShowCustomScreen()
    end
end)

