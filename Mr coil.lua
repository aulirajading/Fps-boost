--[[
    CVAI COMPLETE - All Features + Vehicle Teleport
    Fitur LENGKAP:
    - Freecam (J) + Freeze Karakter + Teleport Klik Kiri
    - Teleport Karakter (ALT + Klik Kanan)
    - Teleport Kendaraan (ALT + Klik Kiri) - Saat mengemudi
    - ESP HANYA MUSUH (Player HIJAU | Tank Dikendarai MERAH | Tank Kosong ORANGE)
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
        GroundOffset = 3,
        VehicleOffset = 0
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
    -- Untuk freeze karakter
    originalWalkSpeed = nil,
    originalJumpPower = nil,
    originalPlatformStand = nil,
    originalAutoRotate = nil,
    originalBodyVelocity = nil,
    originalCFrame = nil,
    -- Untuk kendaraan
    currentVehicle = nil,
    isDriving = false
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

-- Update karakter dan cek kendaraan
local function updateCharacter()
    pcall(function()
        state.character = LocalPlayer.Character
        if state.character then
            state.humanoid = state.character:FindFirstChildOfClass("Humanoid")
            state.rootPart = state.character:FindFirstChild("HumanoidRootPart") or state.character:FindFirstChild("Torso")
            
            -- Simpan nilai asli
            if state.humanoid and state.originalWalkSpeed == nil then
                state.originalWalkSpeed = state.humanoid.WalkSpeed
                state.originalJumpPower = state.humanoid.JumpPower
                state.originalPlatformStand = state.humanoid.PlatformStand
                state.originalAutoRotate = state.humanoid.AutoRotate
            end
            
            -- Cek apakah sedang mengemudi kendaraan
            if state.humanoid and state.humanoid.SeatPart then
                local seat = state.humanoid.SeatPart
                local vehicle = seat.Parent
                while vehicle and not vehicle:IsA("Model") do
                    vehicle = vehicle.Parent
                end
                if vehicle and vehicle:IsDescendantOf(spawns.vehicles) then
                    state.currentVehicle = vehicle
                    state.isDriving = true
                else
                    state.currentVehicle = nil
                    state.isDriving = false
                end
            else
                state.currentVehicle = nil
                state.isDriving = false
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    updateCharacter()
    if state.freecamActive then
        freezeCharacterPerfect()
    end
end)

-- Update karakter setiap detik untuk cek kendaraan
task.spawn(function()
    while task.wait(1) do
        pcall(updateCharacter)
    end
end)

updateCharacter()

-- ========== PERFECT FREEZE ==========
local function freezeCharacterPerfect()
    pcall(function()
        if not state.character or not state.humanoid then
            updateCharacter()
            if not state.humanoid then return end
        end
        
        if state.originalWalkSpeed == nil then
            state.originalWalkSpeed = state.humanoid.WalkSpeed
            state.originalJumpPower = state.humanoid.JumpPower
            state.originalPlatformStand = state.humanoid.PlatformStand
            state.originalAutoRotate = state.humanoid.AutoRotate
        end
        
        state.humanoid.PlatformStand = true
        state.humanoid.WalkSpeed = 0
        state.humanoid.JumpPower = 0
        state.humanoid.AutoRotate = false
        
        if state.rootPart then
            for _, v in ipairs(state.rootPart:GetChildren()) do
                if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyGyro") then
                    v:Destroy()
                end
            end
            
            local bodyVel = Instance.new("BodyVelocity")
            bodyVel.Velocity = Vector3.new(0, 0, 0)
            bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVel.Parent = state.rootPart
            state.originalBodyVelocity = bodyVel
        end
    end)
end

local function unfreezeCharacterPerfect()
    pcall(function()
        if not state.character or not state.humanoid then
            updateCharacter()
            if not state.humanoid then return end
        end
        
        state.humanoid.PlatformStand = state.originalPlatformStand or false
        state.humanoid.WalkSpeed = state.originalWalkSpeed or 16
        state.humanoid.JumpPower = state.originalJumpPower or 50
        state.humanoid.AutoRotate = state.originalAutoRotate or true
        
        if state.originalBodyVelocity then
            state.originalBodyVelocity:Destroy()
            state.originalBodyVelocity = nil
        end
        
        if state.rootPart then
            for _, v in ipairs(state.rootPart:GetChildren()) do
                if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyGyro") then
                    v:Destroy()
                end
            end
        end
    end)
end

local function saveOriginalPosition()
    pcall(function()
        if state.rootPart then
            state.originalCFrame = state.rootPart.CFrame
        end
    end)
end

-- ========== UTILITY ==========
local function isEnemyTeam(teamColor)
    if not teamColor then return true end
    if not LocalPlayer.TeamColor then return true end
    return teamColor ~= LocalPlayer.TeamColor
end

local function isVehicleOccupiedByEnemy(vehicle)
    local result = false
    pcall(function()
        for _, seat in ipairs(vehicle:GetDescendants()) do
            if (seat:IsA("VehicleSeat") or seat:IsA("Seat")) and seat.Occupant then
                local character = seat.Occupant.Parent
                local player = Players:GetPlayerFromCharacter(character)
                if player and player ~= LocalPlayer then
                    if isEnemyTeam(player.TeamColor) then
                        result = true
                        return
                    end
                end
            end
        end
    end)
    return result
end

local function getVehicleTeam(vehicle)
    local result = nil
    pcall(function()
        local success, teamAttr = pcall(function() return vehicle:GetAttribute("Team") end)
        if success and teamAttr then 
            result = teamAttr
            return
        end
        
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
            hl.FillTransparency = 1
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

local function updateESP()
    if not state.espActive then 
        for obj, _ in pairs(espHighlights) do
            removeOutline(obj)
        end
        return 
    end
    
    local currentObjects = {}
    
    -- VEHICLE ESP
    pcall(function()
        if spawns.vehicles then
            for _, vehicle in ipairs(spawns.vehicles:GetChildren()) do
                if vehicle and vehicle.Name ~= "DONOT" then
                    currentObjects[vehicle] = true
                    
                    if isVehicleEnemy(vehicle) then
                        local occupied = isVehicleOccupiedByEnemy(vehicle)
                        local color = occupied and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 165, 0)
                        getOrCreateOutline(vehicle, color)
                    else
                        removeOutline(vehicle)
                    end
                end
            end
        end
    end)
    
    -- PLAYER ESP
    pcall(function()
        if spawns.players then
            for _, playerObj in ipairs(spawns.players:GetChildren()) do
                if playerObj and playerObj.Name ~= "DONOT" and playerObj.Name ~= LocalPlayer.Name then
                    currentObjects[playerObj] = true
                    
                    local player = Players:FindFirstChild(playerObj.Name)
                    if player and isEnemyTeam(player.TeamColor) then
                        local humanoid = playerObj:FindFirstChildOfClass("Humanoid")
                        local inVehicle = false
                        if humanoid and humanoid.SeatPart then
                            inVehicle = humanoid.SeatPart:IsDescendantOf(spawns.vehicles)
                        end
                        
                        if not inVehicle then
                            getOrCreateOutline(playerObj, Color3.fromRGB(0, 255, 0))
                        else
                            removeOutline(playerObj)
                        end
                    else
                        removeOutline(playerObj)
                    end
                end
            end
        end
    end)
    
    for obj, _ in pairs(espHighlights) do
        if not currentObjects[obj] or not obj.Parent then
            removeOutline(obj)
        end
    end
end

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

-- Teleport Karakter
local function teleportCharacter(position)
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
                state.humanoid.AutoRotate = false
            else
                state.humanoid.PlatformStand = false
            end
        end
    end)
    return true
end

-- Teleport Kendaraan
local function teleportVehicle(vehicle, position)
    pcall(function()
        if not vehicle then return end
        
        -- Cari primary part atau root part kendaraan
        local primaryPart = vehicle:FindFirstChild("HumanoidRootPart") or 
                           vehicle:FindFirstChild("PrimaryPart") or
                           vehicle:FindFirstChildWhichIsA("BasePart")
        
        if primaryPart then
            -- Simpan penumpang sebelum teleport
            local occupants = {}
            for _, seat in ipairs(vehicle:GetDescendants()) do
                if (seat:IsA("VehicleSeat") or seat:IsA("Seat")) and seat.Occupant then
                    table.insert(occupants, seat.Occupant)
                end
            end
            
            -- Teleport kendaraan
            local oldCFrame = primaryPart.CFrame
            primaryPart.CFrame = CFrame.new(position)
            
            -- Efek visual
            local effect = Instance.new("Part")
            effect.Size = Vector3.new(5, 5, 5)
            effect.Position = position
            effect.Anchored = true
            effect.CanCollide = false
            effect.Material = Enum.Material.Neon
            effect.BrickColor = BrickColor.new("Bright blue")
            effect.Transparency = 0.5
            effect.Parent = workspace
            game:GetService("Debris"):AddItem(effect, 0.5)
            
            print("[CVAI] Vehicle teleported to: " .. tostring(position))
        end
    end)
end

-- Teleport dari freecam (Klik Kiri)
local function teleportFromFreecam()
    if not state.freecamActive then
        print("[CVAI] Aktifkan freecam dulu (J) untuk teleport klik kiri!")
        return false
    end
    
    local mousePos = UserInput:GetMouseLocation()
    local groundPos = getGroundFromCursor(mousePos.X, mousePos.Y)
    
    if groundPos then
        local finalPos = groundPos + Vector3.new(0, CONFIG.Teleport.GroundOffset, 0)
        teleportCharacter(finalPos)
        print("[CVAI] Teleported from freecam")
        return true
    end
    return false
end

-- Teleport karakter cepat (ALT + Klik Kanan)
local function teleportCharacterQuick()
    local mousePos = UserInput:GetMouseLocation()
    local groundPos = getGroundFromCursor(mousePos.X, mousePos.Y)
    
    if groundPos then
        local finalPos = groundPos + Vector3.new(0, CONFIG.Teleport.GroundOffset, 0)
        teleportCharacter(finalPos)
        print("[CVAI] Quick character teleport")
        return true
    end
    return false
end

-- Teleport kendaraan (ALT + Klik Kiri)
local function teleportVehicleQuick()
    -- Update status kendaraan dulu
    updateCharacter()
    
    if not state.isDriving or not state.currentVehicle then
        print("[CVAI] Anda tidak sedang mengemudikan kendaraan!")
        return false
    end
    
    local mousePos = UserInput:GetMouseLocation()
    local groundPos = getGroundFromCursor(mousePos.X, mousePos.Y)
    
    if groundPos then
        local finalPos = groundPos + Vector3.new(0, CONFIG.Teleport.VehicleOffset, 0)
        teleportVehicle(state.currentVehicle, finalPos)
        print("[CVAI] Vehicle teleported while driving!")
        return true
    end
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
    
    saveOriginalPosition()
    freezeCharacterPerfect()
    
    freecam.rot = Vector2.new()
    freecam.pos = Camera.CFrame.Position
    freecam.moveVec = Vector3.new()
    Camera.CameraType = Enum.CameraType.Scriptable
    pcall(function() UserInput.MouseBehavior = Enum.MouseBehavior.LockCenter end)
    state.renderConnection = RunService.RenderStepped:Connect(freecamStep)
    state.freecamActive = true
    print("[CVAI] Freecam ON - Character FROZEN")
end

local function stopFreecam()
    if not state.freecamActive then return end
    
    unfreezeCharacterPerfect()
    
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

-- Teleport Klik Kiri (saat freecam aktif)
UserInput.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if state.freecamActive then
            teleportFromFreecam()
        end
    end
end)

-- Teleport Kombinasi ALT:
-- ALT + Klik Kanan = Teleport Karakter
-- ALT + Klik Kiri = Teleport Kendaraan (saat mengemudi)
UserInput.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    local altPressed = UserInput:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInput:IsKeyDown(Enum.KeyCode.RightAlt)
    
    if altPressed then
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            -- ALT + Klik Kanan = Teleport Karakter
            teleportCharacterQuick()
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- ALT + Klik Kiri = Teleport Kendaraan
            teleportVehicleQuick()
        end
    end
end)

print("[CVAI] ========== COMPLETE VERSION ==========")
print("[CVAI] J = Freecam (Klik Kiri Teleport)")
print("[CVAI] L = ESP (HANYA MUSUH)")
print("[CVAI] Z = Zoom 400")
print("[CVAI] ========== TELEPORT ==========")
print("[CVAI] ALT + Klik Kanan = Teleport Karakter")
print("[CVAI] ALT + Klik Kiri = Teleport Kendaraan (Saat mengemudi)")
print("[CVAI] Klik Kiri = Teleport (Saat freecam)")
print("[CVAI] ========== ESP RULES ==========")
print("[CVAI] Player Musuh = HIJAU")
print("[CVAI] Tank Musuh (dikendarai) = MERAH")
print("[CVAI] Tank Musuh (kosong) = ORANGE")
print("[CVAI] Team sendiri = TIDAK ADA ESP")