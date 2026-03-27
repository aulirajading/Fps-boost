--[[
    CVAI COMPLETE - All Features FIXED
    - ESP: HANYA MUSUH (team sendiri TIDAK muncul)
    - Freecam (J) + Freeze Karakter + Teleport Klik Kiri
    - Teleport ALT + Klik Kanan (tanpa freecam)
    - Zoom 400 (Z)
]]

-- Services
local Players = game:GetService("Players")
local UserInput = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Konfigurasi
local CONFIG = {
    Freecam = {
        MoveSpeed = 1,
        SprintMultiplier = 3,
        Sensitivity = 0.017,
        MaxLookAngle = 90
    },
    Teleport = {
        MaxDistance = 1000,
        GroundOffset = 3
    },
    Zoom = {
        Enabled = false,
        MaxZoom = 400,
        MinZoom = 10,
        CurrentZoom = 70,
        Sensitivity = 5
    }
}

-- State
local state = {
    freecamActive = false,
    espActive = true,
    zoomActive = false,
    renderConnection = nil,
    character = nil,
    humanoid = nil,
    rootPart = nil,
    originalFieldOfView = nil,
    wasPlatformStand = false,
    originalWalkSpeed = nil,
    originalJumpPower = nil
}

-- References
local spawns = {}
pcall(function()
    spawns.vehicles = workspace:FindFirstChild("SpawnedVehicles")
    if not spawns.vehicles then
        spawns.vehicles = Instance.new("Folder")
        spawns.vehicles.Name = "SpawnedVehicles"
        spawns.vehicles.Parent = workspace
    end
end)

pcall(function()
    spawns.players = workspace:FindFirstChild("SpawnedPlayers")
    if not spawns.players then
        spawns.players = Instance.new("Folder")
        spawns.players.Name = "SpawnedPlayers"
        spawns.players.Parent = workspace
    end
end)

-- Update karakter
local function updateCharacter()
    pcall(function()
        state.character = LocalPlayer.Character
        if state.character then
            state.humanoid = state.character:FindFirstChildOfClass("Humanoid")
            state.rootPart = state.character:FindFirstChild("HumanoidRootPart") or state.character:FindFirstChild("Torso")
            
            if state.humanoid and state.originalWalkSpeed == nil then
                state.originalWalkSpeed = state.humanoid.WalkSpeed
                state.originalJumpPower = state.humanoid.JumpPower
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    updateCharacter()
    if state.freecamActive then freezeCharacter() end
end)
updateCharacter()

-- ========== FREEZE CHARACTER ==========
local function freezeCharacter()
    pcall(function()
        if not state.character or not state.humanoid then
            updateCharacter()
            if not state.humanoid then return end
        end
        
        if state.originalWalkSpeed == nil then
            state.originalWalkSpeed = state.humanoid.WalkSpeed
            state.originalJumpPower = state.humanoid.JumpPower
        end
        
        state.wasPlatformStand = state.humanoid.PlatformStand
        state.humanoid.PlatformStand = true
        state.humanoid.WalkSpeed = 0
        state.humanoid.JumpPower = 0
        pcall(function() state.humanoid.AutoRotate = false end)
    end)
end

local function unfreezeCharacter()
    pcall(function()
        if not state.character or not state.humanoid then
            updateCharacter()
            if not state.humanoid then return end
        end
        
        state.humanoid.WalkSpeed = state.originalWalkSpeed or 16
        state.humanoid.JumpPower = state.originalJumpPower or 50
        state.humanoid.PlatformStand = state.wasPlatformStand or false
        pcall(function() state.humanoid.AutoRotate = true end)
    end)
end

-- ========== UTILITY ==========
-- Fungsi untuk cek apakah team musuh
local function isEnemyTeam(teamColor)
    if not teamColor then return true end
    if not LocalPlayer.TeamColor then return true end
    return teamColor ~= LocalPlayer.TeamColor
end

-- Cek apakah kendaraan dikendarai musuh
local function isVehicleOccupiedByEnemy(vehicle)
    pcall(function()
        for _, seat in ipairs(vehicle:GetDescendants()) do
            if (seat:IsA("VehicleSeat") or seat:IsA("Seat")) and seat.Occupant then
                local character = seat.Occupant.Parent
                local player = Players:GetPlayerFromCharacter(character)
                if player and player ~= LocalPlayer then
                    if isEnemyTeam(player.TeamColor) then
                        return true
                    end
                end
            end
        end
    end)
    return false
end

-- Dapatkan team kendaraan
local function getVehicleTeam(vehicle)
    local result = nil
    pcall(function()
        -- Cek atribut Team
        local success, teamAttr = pcall(function() return vehicle:GetAttribute("Team") end)
        if success and teamAttr then 
            result = teamAttr
            return
        end
        
        -- Cek dari warna part
        for _, part in ipairs(vehicle:GetDescendants()) do
            if part:IsA("BasePart") and part.BrickColor ~= BrickColor.new("White") then
                local color = part.BrickColor.Color
                for _, player in ipairs(Players:GetPlayers()) do
                    if player.TeamColor and player.TeamColor.Color == color then
                        result = player.TeamColor
                        return
                    end
                end
            end
        end
    end)
    return result
end

-- Cek apakah kendaraan milik tim sendiri
local function isVehicleEnemy(vehicle)
    local team = getVehicleTeam(vehicle)
    return isEnemyTeam(team)
end

-- ========== ESP OUTLINE ONLY ==========
local espHighlights = {}

local function getOrCreateOutline(obj, color)
    pcall(function()
        local hl = obj:FindFirstChild("CVAI_ESP")
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "CVAI_ESP"
            hl.FillTransparency = 1  -- Outline only
            hl.OutlineTransparency = 0
            hl.Parent = obj
            espHighlights[obj] = hl
        end
        
        if hl.OutlineColor ~= color then
            hl.OutlineColor = color
        end
    end)
end

local function removeOutline(obj)
    pcall(function()
        local hl = obj:FindFirstChild("CVAI_ESP")
        if hl then
            hl:Destroy()
            espHighlights[obj] = nil
        end
    end)
end

-- UPDATE ESP - HANYA MUSUH
local function updateESP()
    if not state.espActive then 
        for obj, _ in pairs(espHighlights) do
            removeOutline(obj)
        end
        return 
    end
    
    local currentObjects = {}
    
    -- VEHICLE ESP - HANYA KENDARAAN MUSUH
    pcall(function()
        if spawns.vehicles then
            for _, vehicle in ipairs(spawns.vehicles:GetChildren()) do
                if vehicle and vehicle.Name ~= "DONOT" then
                    currentObjects[vehicle] = true
                    
                    -- Cek apakah kendaraan milik musuh
                    if isVehicleEnemy(vehicle) then
                        local occupied = isVehicleOccupiedByEnemy(vehicle)
                        -- MERAH = dikendarai musuh, ORANGE = kosong tapi milik musuh
                        local color = occupied and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 165, 0)
                        getOrCreateOutline(vehicle, color)
                    else
                        -- Kendaraan tim sendiri -> TIDAK ADA ESP
                        removeOutline(vehicle)
                    end
                end
            end
        end
    end)
    
    -- PLAYER ESP - HANYA PLAYER MUSUH
    pcall(function()
        if spawns.players then
            for _, playerObj in ipairs(spawns.players:GetChildren()) do
                if playerObj and playerObj.Name ~= "DONOT" and playerObj.Name ~= LocalPlayer.Name then
                    currentObjects[playerObj] = true
                    
                    local player = Players:FindFirstChild(playerObj.Name)
                    if player then
                        -- Cek apakah player musuh
                        if isEnemyTeam(player.TeamColor) then
                            -- Cek apakah player sedang di kendaraan
                            local humanoid = playerObj:FindFirstChildOfClass("Humanoid")
                            local inVehicle = false
                            if humanoid and humanoid.SeatPart then
                                inVehicle = humanoid.SeatPart:IsDescendantOf(spawns.vehicles)
                            end
                            
                            -- Player musuh yang TIDAK di kendaraan -> HIJAU
                            if not inVehicle then
                                getOrCreateOutline(playerObj, Color3.fromRGB(0, 255, 0))
                            else
                                -- Player di kendaraan, ESP-nya lewat kendaraan saja
                                removeOutline(playerObj)
                            end
                        else
                            -- Player tim sendiri -> TIDAK ADA ESP
                            removeOutline(playerObj)
                        end
                    else
                        removeOutline(playerObj)
                    end
                end
            end
        end
    end)
    
    -- Bersihkan highlight untuk object yang sudah tidak ada
    for obj, _ in pairs(espHighlights) do
        if not currentObjects[obj] or not obj.Parent then
            removeOutline(obj)
        end
    end
end

-- Event-based update
local espUpdateNeeded = false
local function scheduleESPUpdate()
    if espUpdateNeeded then return end
    espUpdateNeeded = true
    task.defer(function()
        if state.espActive then
            pcall(updateESP)
        end
        espUpdateNeeded = false
    end)
end

if spawns.vehicles then
    spawns.vehicles.ChildAdded:Connect(scheduleESPUpdate)
    spawns.vehicles.ChildRemoved:Connect(scheduleESPUpdate)
end
if spawns.players then
    spawns.players.ChildAdded:Connect(scheduleESPUpdate)
    spawns.players.ChildRemoved:Connect(scheduleESPUpdate)
end

task.wait(2)
scheduleESPUpdate()

local function toggleESP()
    state.espActive = not state.espActive
    if not state.espActive then
        for obj, _ in pairs(espHighlights) do
            removeOutline(obj)
        end
    else
        scheduleESPUpdate()
    end
    print("[CVAI] ESP " .. (state.espActive and "ON" or "OFF"))
end

-- ========== ZOOM SYSTEM ==========
local function updateZoom()
    if state.zoomActive then
        pcall(function() Camera.FieldOfView = CONFIG.Zoom.CurrentZoom end)
    end
end

local function toggleZoom()
    state.zoomActive = not state.zoomActive
    if state.zoomActive then
        state.originalFieldOfView = Camera.FieldOfView
        CONFIG.Zoom.CurrentZoom = math.clamp(CONFIG.Zoom.CurrentZoom, CONFIG.Zoom.MinZoom, CONFIG.Zoom.MaxZoom)
        updateZoom()
        print("[CVAI] Zoom ACTIVE - Max: 400")
    else
        pcall(function() Camera.FieldOfView = state.originalFieldOfView or 70 end)
        print("[CVAI] Zoom OFF")
    end
end

-- ========== TELEPORT SYSTEM ==========
local function getGroundFromCursor(mouseX, mouseY)
    local result = nil
    pcall(function()
        local ray = Camera:ScreenPointToRay(mouseX, mouseY)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        
        if state.character then
            local ignoreList = {}
            for _, v in ipairs(state.character:GetDescendants()) do
                if v:IsA("BasePart") then
                    table.insert(ignoreList, v)
                end
            end
            params.FilterDescendantsInstances = ignoreList
        end
        params.IgnoreWater = true
        
        local raycastResult = workspace:Raycast(ray.Origin, ray.Direction * CONFIG.Teleport.MaxDistance, params)
        if raycastResult then
            result = raycastResult.Position
        end
    end)
    return result
end

local function teleport(position)
    pcall(function()
        if not state.rootPart then
            updateCharacter()
            if not state.rootPart then return end
        end
        
        if state.humanoid then
            state.humanoid.PlatformStand = true
        end
        state.rootPart.CFrame = CFrame.new(position)
        if state.humanoid then
            task.wait(0.05)
            state.humanoid:MoveTo(position)
            task.wait(0.1)
            if state.freecamActive then
                state.humanoid.PlatformStand = true
                state.humanoid.WalkSpeed = 0
                state.humanoid.JumpPower = 0
            else
                state.humanoid.PlatformStand = false
            end
        end
    end)
    return true
end

-- TELEPORT SAAT FREECAM (Klik Kiri)
local function teleportFromFreecam()
    if not state.freecamActive then
        print("[CVAI] Aktifkan freecam dulu (J) untuk teleport klik kiri!")
        return false
    end
    
    local mousePos = UserInput:GetMouseLocation()
    local groundPos = getGroundFromCursor(mousePos.X, mousePos.Y)
    
    if groundPos then
        local finalPos = groundPos + Vector3.new(0, CONFIG.Teleport.GroundOffset, 0)
        teleport(finalPos)
        print("[CVAI] Teleported from freecam")
        return true
    end
    print("[CVAI] No valid ground target")
    return false
end

-- TELEPORT TANPA FREECAM (ALT + Klik Kanan)
local function teleportQuick()
    local mousePos = UserInput:GetMouseLocation()
    local groundPos = getGroundFromCursor(mousePos.X, mousePos.Y)
    
    if groundPos then
        local finalPos = groundPos + Vector3.new(0, CONFIG.Teleport.GroundOffset, 0)
        teleport(finalPos)
        print("[CVAI] Quick teleport")
        return true
    end
    print("[CVAI] No valid ground target")
    return false
end

-- ========== FREECAM SYSTEM ==========
local freecam = {
    rot = Vector2.new(),
    pos = Vector3.new(),
    moveVec = Vector3.new(),
    speed = CONFIG.Freecam.MoveSpeed
}

local function handleFreecamInput()
    freecam.moveVec = Vector3.new()
    if UserInput:IsKeyDown(Enum.KeyCode.W) then freecam.moveVec = freecam.moveVec + Vector3.new(0, 0, -1) end
    if UserInput:IsKeyDown(Enum.KeyCode.S) then freecam.moveVec = freecam.moveVec + Vector3.new(0, 0, 1) end
    if UserInput:IsKeyDown(Enum.KeyCode.A) then freecam.moveVec = freecam.moveVec + Vector3.new(-1, 0, 0) end
    if UserInput:IsKeyDown(Enum.KeyCode.D) then freecam.moveVec = freecam.moveVec + Vector3.new(1, 0, 0) end
    if UserInput:IsKeyDown(Enum.KeyCode.E) then freecam.moveVec = freecam.moveVec + Vector3.new(0, 1, 0) end
    if UserInput:IsKeyDown(Enum.KeyCode.Q) then freecam.moveVec = freecam.moveVec + Vector3.new(0, -1, 0) end
    
    if freecam.moveVec.Magnitude > 0 then
        freecam.moveVec = freecam.moveVec.Unit
    end
    
    local currentSpeed = freecam.speed
    if UserInput:IsKeyDown(Enum.KeyCode.LeftShift) or UserInput:IsKeyDown(Enum.KeyCode.RightShift) then
        currentSpeed = currentSpeed * CONFIG.Freecam.SprintMultiplier
    end
    freecam.moveVec = freecam.moveVec * currentSpeed
end

local function updateFreecam(dt)
    dt = dt or 0.016
    
    local delta = UserInput:GetMouseDelta() * CONFIG.Freecam.Sensitivity
    freecam.rot = freecam.rot + Vector2.new(-delta.Y, -delta.X)
    freecam.rot = Vector2.new(
        math.clamp(freecam.rot.X, math.rad(-CONFIG.Freecam.MaxLookAngle), math.rad(CONFIG.Freecam.MaxLookAngle)),
        freecam.rot.Y
    )
    
    local rotCF = CFrame.Angles(0, freecam.rot.Y, 0) * CFrame.Angles(freecam.rot.X, 0, 0)
    local movement = rotCF:VectorToWorldSpace(freecam.moveVec) * dt * 60
    
    freecam.pos = freecam.pos + movement
    Camera.CFrame = CFrame.new(freecam.pos) * rotCF
end

local freecamStep
freecamStep = function(dt)
    handleFreecamInput()
    updateFreecam(dt)
end

local function startFreecam()
    if state.freecamActive then return end
    freezeCharacter()
    freecam.rot = Vector2.new()
    freecam.pos = Camera.CFrame.Position
    freecam.moveVec = Vector3.new()
    Camera.CameraType = Enum.CameraType.Scriptable
    pcall(function() UserInput.MouseBehavior = Enum.MouseBehavior.LockCenter end)
    state.renderConnection = RunService.RenderStepped:Connect(freecamStep)
    state.freecamActive = true
    print("[CVAI] Freecam ON - Klik Kiri untuk teleport")
end

local function stopFreecam()
    if not state.freecamActive then return end
    unfreezeCharacter()
    if state.renderConnection then
        state.renderConnection:Disconnect()
        state.renderConnection = nil
    end
    Camera.CameraType = Enum.CameraType.Custom
    pcall(function() UserInput.MouseBehavior = Enum.MouseBehavior.Default end)
    state.freecamActive = false
    print("[CVAI] Freecam OFF")
end

-- ========== INPUT HANDLING ==========
-- Toggle Freecam (J)
UserInput.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if input.KeyCode == Enum.KeyCode.J then
        if state.freecamActive then stopFreecam() else startFreecam() end
    end
    
    if input.KeyCode == Enum.KeyCode.L then
        toggleESP()
    end
    
    if input.KeyCode == Enum.KeyCode.Z then
        toggleZoom()
    end
end)

-- Zoom dengan scroll
UserInput.InputChanged:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseWheel and state.zoomActive then
        local newZoom = CONFIG.Zoom.CurrentZoom - (input.Position.Z * CONFIG.Zoom.Sensitivity)
        CONFIG.Zoom.CurrentZoom = math.clamp(newZoom, CONFIG.Zoom.MinZoom, CONFIG.Zoom.MaxZoom)
        updateZoom()
    end
end)

-- TELEPORT Klik Kiri (saat freecam aktif)
UserInput.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if state.freecamActive then
            teleportFromFreecam()
        end
    end
end)

-- TELEPORT ALT + Klik Kanan (tanpa freecam)
UserInput.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        local altPressed = UserInput:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInput:IsKeyDown(Enum.KeyCode.RightAlt)
        if altPressed then
            teleportQuick()
        end
    end
end)

-- Update karakter periodik
task.spawn(function()
    while task.wait(10) do
        pcall(updateCharacter)
    end
end)

print("[CVAI] ========== COMPLETE VERSION FIXED ==========")
print("[CVAI] J = Freecam (Klik Kiri Teleport)")
print("[CVAI] L = ESP (HANYA MUSUH - Team sendiri TIDAK muncul)")
print("[CVAI] Z = Zoom 400")
print("[CVAI] ALT + Klik Kanan = Quick Teleport (tanpa freecam)")
print("[CVAI] ESP Rules:")
print("[CVAI]   • Player Musuh = HIJAU")
print("[CVAI]   • Tank Musuh (dikendarai) = MERAH")
print("[CVAI]   • Tank Musuh (kosong) = ORANGE")
print("[CVAI]   • Team sendiri = TIDAK ADA ESP")