-- getgenv().SecureMode = true

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "S Deepmarian hb",
   Icon = 100448539355199, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Rayfield Interface",
   LoadingSubtitle = "by -",
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from warning when the script has a version mismatch with the interface

   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})

local Tab = Window:CreateTab("Tops", "anchor")

-- Membuat Section untuk metode teleport
local Section = Tab:CreateSection("TP Method", true) -- Section untuk metode teleport

-- Daftar nama tools
local items = {"Bat", "Crowbar", "Food", "Hammer", "Handgun", "Lantern", "Money", "Soda", "Shotgun", "Shells", "Bullets", "Medkit", "GPS"}

-- Variabel untuk menyimpan posisi awal, rotasi awal, dan status ProximityPrompt
local returnToOriginal = false -- Status toggle untuk kembali ke posisi awal
local autoTriggerPrompt = false -- Status toggle untuk auto-trigger ProximityPrompt
local autoDropHeldItem = false -- Status toggle untuk auto-drop item yang dipegang
local originalPosition = nil -- Posisi awal pemain (CFrame)
local defaultRotation = nil -- Rotasi default karakter
local excludeDistance = 20 -- Jarak awal untuk pengecualian (bisa diubah lewat slider)
local previewBeams = {} -- Tabel untuk menyimpan beam visualisasi
local isPreviewActive = false -- Status apakah preview aktif

-- Membuat Toggle untuk kembali ke posisi awal
Tab:CreateToggle({
    Name = "Auto Return to Position",
    CurrentValue = false,
    Flag = "ReturnToggle",
    Callback = function(Value)
        returnToOriginal = Value
    end,
})

-- Membuat Toggle untuk auto-trigger ProximityPrompt
Tab:CreateToggle({
    Name = "Auto pick items",
    CurrentValue = false,
    Flag = "AutoTriggerPromptToggle",
    Callback = function(Value)
        autoTriggerPrompt = Value
    end,
})

-- Membuat Toggle untuk auto-drop item yang dipegang
Tab:CreateToggle({
    Name = "Auto Drop Items",
    CurrentValue = false,
    Flag = "AutoDropHeldItemToggle",
    Callback = function(Value)
        autoDropHeldItem = Value
    end,
})
local Section = Tab:CreateSection("Teleport",true)
-- Fungsi untuk drop item yang sedang dipegang dengan delay
local function dropHeldItem()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()

    -- Cek tool di tangan pemain
    local heldTool = character:FindFirstChildOfClass("Tool")
    if not heldTool then
        print("No tool found.")
        return
    end

    -- Delay sebelum drop item
    task.wait(0.5) -- Ubah nilai ini untuk mengatur durasi delay

    -- Memanggil event DropItem dari ReplicatedStorage.Events
    local dropItemEvent = game:GetService("ReplicatedStorage").Events:FindFirstChild("DropItem")
    if dropItemEvent then
        dropItemEvent:FireServer(heldTool)
        print("Dropped:", heldTool.Name)
    else
        warn("DropItem event not found.")
    end
end

-- Fungsi untuk membuat preview lingkaran beam
local function createPreviewCircle()
    if #previewBeams > 0 then return end -- Jika sudah ada, jangan buat lagi

    -- Jumlah beam untuk membuat lingkaran (semakin banyak, semakin halus)
    local numBeams = 30
    local angleIncrement = (2 * math.pi) / numBeams

    for i = 1, numBeams do
        -- Buat part untuk beam
        local beamPart = Instance.new("Part")
        beamPart.Size = Vector3.new(0.2, 0.2, 0.2)
        beamPart.Transparency = 0.5
        beamPart.Color = Color3.new(1, 0, 0)
        beamPart.Anchored = true
        beamPart.CanCollide = false
        beamPart.Parent = workspace

        -- Simpan beam ke tabel
        table.insert(previewBeams, beamPart)
    end
end

-- Fungsi untuk menghapus preview lingkaran beam
local function destroyPreviewCircle()
    for _, beam in ipairs(previewBeams) do
        beam:Destroy()
    end
    previewBeams = {} -- Kosongkan tabel
end

-- Fungsi untuk memperbarui posisi beam setiap saat
local function updateBeams()
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then return end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local numBeams = #previewBeams
    local angleIncrement = (2 * math.pi) / numBeams

    for i, beam in ipairs(previewBeams) do
        -- Hitung posisi beam
        local angle = i * angleIncrement
        local x = math.cos(angle) * excludeDistance
        local z = math.sin(angle) * excludeDistance
        local beamPosition = humanoidRootPart.Position + Vector3.new(x, 0, z)

        -- Posisikan beam
        beam.CFrame = CFrame.new(beamPosition)
    end
end

-- Fungsi untuk memulai pembaruan beam secara real-time
local function startUpdatingBeams()
    game:GetService("RunService").Heartbeat:Connect(function()
        if isPreviewActive then
            updateBeams() -- Perbarui posisi beam setiap frame
        end
    end)
end

-- Toggle untuk mengaktifkan/menonaktifkan preview jarak
Tab:CreateToggle({
    Name = "Preview Distance",
    CurrentValue = false,
    Flag = "TogglePreviewDistance",
    Callback = function(Value)
        isPreviewActive = Value
        if Value then
            createPreviewCircle()
            startUpdatingBeams()
        else
            destroyPreviewCircle()
        end
    end,
})

-- Slider untuk mengatur jarak excludeDistance
Tab:CreateSlider({
    Name = "Exclude Distance",
    Range = {0, 20},
    Increment = 1,
    Suffix = " Studs",
    CurrentValue = excludeDistance,
    Flag = "ExcludeDistanceSlider",
    Callback = function(Value)
        excludeDistance = Value
        if isPreviewActive then
            updateBeams() -- Perbarui visualisasi beam
        end
    end,
})

-- Fungsi untuk mencari item terdekat di luar excludeDistance
local function findNearestItemOutsideExcludeDistance(itemName)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

    if not humanoidRootPart then
        warn("HumanoidRootPart not found.")
        return nil
    end

    -- Validasi folder Pickups
    local pickupsFolder = workspace:FindFirstChild("Pickups")
    if not pickupsFolder then
        warn("Pickups folder not found.")
        return nil
    end

    -- Cari item terdekat di luar excludeDistance
    local nearestItem = nil
    local nearestDistance = math.huge

    for _, item in ipairs(pickupsFolder:GetChildren()) do
        if item:IsA("MeshPart") and item.Name == itemName then
            local distance = (humanoidRootPart.Position - item.Position).Magnitude
            if distance > excludeDistance and distance < nearestDistance then
                nearestItem = item
                nearestDistance = distance
            end
        end
    end

    return nearestItem
end

-- Membuat tombol untuk setiap item
for _, item in ipairs(items) do
    Tab:CreateButton({
        Name = item .. " Teleport",
        Callback = function()
            -- Cari item terdekat di luar excludeDistance
            local nearestItem = findNearestItemOutsideExcludeDistance(item)

            if not nearestItem then
                warn("No " .. item .. " found outside exclude distance.")
                return
            end

            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

            -- Validasi keberadaan HumanoidRootPart
            if not humanoidRootPart then
                warn("HumanoidRootPart not found.")
                return
            end

            -- Simpan rotasi default jika belum disimpan
            if not defaultRotation then
                defaultRotation = humanoidRootPart.CFrame - humanoidRootPart.Position
            end

            -- Menyimpan posisi dan rotasi awal jika toggle aktif
            if returnToOriginal then
                originalPosition = humanoidRootPart.CFrame
                print("Original position and rotation saved.")
            end

            -- Teleportasi ke item terdekat
            humanoidRootPart.CFrame = nearestItem.CFrame
            print("Teleported to " .. nearestItem.Name)

            -- Tunggu 0.2 detik agar karakter sampai ke item
            task.wait(0.2)

            -- Hanya jalankan fireProximityPrompt jika autoTriggerPrompt aktif
            if autoTriggerPrompt then
                local promptsTriggered = 0
                for _, descendant in ipairs(workspace:GetDescendants()) do
                    if descendant:IsA("ProximityPrompt") then
                        local promptDistance = (humanoidRootPart.Position - descendant.Parent.Position).Magnitude
                        if promptDistance <= descendant.MaxActivationDistance then
                            fireproximityprompt(descendant, 0)
                            task.wait(0.1)
                            fireproximityprompt(descendant, 1)
                            promptsTriggered = promptsTriggered + 1
                            print("Triggered ProximityPrompt")
                        end
                    end
                end

                if promptsTriggered == 0 then
                    warn("No ProximityPrompts found or triggered around " .. nearestItem.Name)
                end
            end

            -- Kembalikan karakter ke posisi awal jika toggle aktif
            if returnToOriginal and originalPosition then
                task.wait(1) -- Tunggu 1 detik sebelum kembali
                humanoidRootPart.CFrame = originalPosition -- Kembalikan ke posisi awal
                print("Returned to original position.")

                -- Atur rotasi ke default (primary)
                task.wait(0.5) -- Tunggu 0.5 detik sebelum mengatur rotasi
                humanoidRootPart.CFrame = humanoidRootPart.CFrame * defaultRotation
                print("Rotation set to default.")
            end

            -- Drop item yang dipegang jika auto-drop aktif
            if autoDropHeldItem then
                dropHeldItem()
            end
        end,
    })
end

local autoTeleportToMoney = false
local autoReturn = false -- Status toggle untuk auto return ke posisi sebelum teleport
local autoReturnSavePos = false -- Status toggle untuk auto return ke posisi yang disimpan
local savedPosition = nil -- Posisi yang disimpan
local Label = Tab:CreateLabel("Saved Position: None") -- Label untuk menampilkan posisi

-- Membuat Toggle untuk auto-teleport ke Money
Tab:CreateToggle({
    Name = "Auto Get Money",
    CurrentValue = false,
    Flag = "AutoTeleportMoney",
    Callback = function(Value)
        autoTeleportToMoney = Value

        if autoTeleportToMoney then
            task.spawn(function()
                while autoTeleportToMoney do
                    local player = game.Players.LocalPlayer
                    local character = player.Character
                    local humanoid = character and character:FindFirstChild("Humanoid")

                    -- Hentikan jika health 0
                    if not humanoid or humanoid.Health <= 0 then
                        autoTeleportToMoney = false
                        break
                    end

                    -- Teleport dan trigger Money
                    teleportAndTriggerMoney()
                    task.wait(0.5) -- Delay untuk menghindari spam
                end
            end)
        end
    end,
})

-- Membuat Toggle untuk Auto Return (kembali ke posisi sebelum teleport)
Tab:CreateToggle({
    Name = "Auto Return",
    CurrentValue = false,
    Flag = "AutoReturn",
    Callback = function(Value)
        autoReturn = Value
    end,
})

-- Membuat Toggle untuk Auto Return to Saved Position
Tab:CreateToggle({
    Name = "Auto Return to Saved Position",
    CurrentValue = false,
    Flag = "AutoReturnSavePos",
    Callback = function(Value)
        autoReturnSavePos = Value
    end,
})

-- Fungsi untuk teleport ke Money dan memicu ProximityPrompt
function teleportAndTriggerMoney()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

    -- Validasi keberadaan HumanoidRootPart
    if not humanoidRootPart then
        return
    end

    -- Validasi folder Pickups
    local pickupsFolder = workspace:FindFirstChild("Pickups")
    if not pickupsFolder then
        return
    end

    -- Validasi keberadaan Money
    local moneyPart = pickupsFolder:FindFirstChild("Money")
    if not moneyPart or not moneyPart:IsA("MeshPart") then
        return
    end

    -- Simpan posisi awal sebelum teleport
    local originalPosition = humanoidRootPart.CFrame

    -- Teleportasi ke Money
    humanoidRootPart.CFrame = moneyPart.CFrame

    -- Tunggu sebentar agar karakter sampai ke Money
    task.wait(0.2)

    -- Memicu ProximityPrompt jika ada
    local proximityPrompt = moneyPart:FindFirstChildOfClass("ProximityPrompt")
    if proximityPrompt then
        -- Bypass jarak dan penghalang
        proximityPrompt.RequiresLineOfSight = false
        proximityPrompt.MaxActivationDistance = math.huge -- Set ke jarak tak terbatas

        fireproximityprompt(proximityPrompt, 0) -- Trigger prompt
        task.wait(0.1)
        fireproximityprompt(proximityPrompt, 1) -- Lepas trigger
    end

    -- Kembali ke posisi sesuai toggle
    if autoReturn then
        -- Kembali ke posisi sebelum teleport
        humanoidRootPart.CFrame = originalPosition
    elseif autoReturnSavePos and savedPosition then
        -- Kembali ke posisi yang disimpan
        humanoidRootPart.CFrame = savedPosition
    end
end

-- Membuat Button untuk mendapatkan posisi karakter
Tab:CreateButton({
    Name = "Save Current Position",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

        if humanoidRootPart then
            savedPosition = humanoidRootPart.CFrame
            local positionText = string.format(
                "X: %.2f, Y: %.2f, Z: %.2f",
                savedPosition.Position.X,
                savedPosition.Position.Y,
                savedPosition.Position.Z
            )
            Label:Set("Saved Position: " .. positionText)
            print("Saved Position:", savedPosition)
        else
            warn("HumanoidRootPart not found. Unable to save position.")
        end
    end,
})
local Section = Tab:CreateSection("Players")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

Tab:CreateButton({
    Name = "Teleport Random Player",
    Interact = "Click",
    Callback = function()
        -- Ambil daftar pemain
        local allPlayers = Players:GetPlayers()
        local localPlayer = Players.LocalPlayer

        -- Hapus diri sendiri dari daftar
        for i, player in ipairs(allPlayers) do
            if player == localPlayer then
                table.remove(allPlayers, i)
                break
            end
        end

        -- Filter pemain dengan health > 0
        local validPlayers = {}
        for _, player in ipairs(allPlayers) do
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                local health = player.Character.Humanoid.Health
                if health > 0 then
                    table.insert(validPlayers, player)
                end
            end
        end

        -- Jika tidak ada pemain yang valid, beri peringatan
        if #validPlayers == 0 then
            return
        end

        -- Pilih pemain secara acak
        local randomPlayer = validPlayers[math.random(1, #validPlayers)]

        -- Teleportasi ke posisi pemain yang dipilih
        if randomPlayer.Character and randomPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = randomPlayer.Character.HumanoidRootPart.Position
            localPlayer.Character:SetPrimaryPartCFrame(CFrame.new(targetPosition))
            print("Teleported to:", randomPlayer.Name)
        else
            warn("Failed Target player valid position.")
        end
    end,
})
local InfJumpEnabled = false
local Noclipping = nil
local Clip = true

-- Toggle untuk Infinite Jump
Tab:CreateToggle({
    Name = "InfJump",
    CurrentValue = false,
    Flag = "InfJumpToggle",
    Callback = function(Value)
        InfJumpEnabled = Value
        if InfJumpEnabled then
            print("Infinite Jump Enabled")
            local UserInputService = game:GetService("UserInputService")
            UserInputService.JumpRequest:Connect(function()
                if InfJumpEnabled then
                    local player = game.Players.LocalPlayer
                    local character = player.Character or player.CharacterAdded:Wait()
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        else
            print("Infinite Jump Disabled")
        end
    end,
})

local Noclipping = nil
local Clip = true

-- Toggle untuk Noclip
Tab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "NoclipToggle",
    Callback = function(Value)
        Clip = not Value -- Membalikkan status Clip
        if Value then
            print("Noclip Enabled")
            -- Loop untuk menonaktifkan CanCollide pada semua BasePart
            local function NoclipLoop()
                local speaker = game.Players.LocalPlayer
                local character = speaker.Character or speaker.CharacterAdded:Wait()
                for _, child in pairs(character:GetDescendants()) do
                    if child:IsA("BasePart") and child.CanCollide == true then
                        child.CanCollide = false
                    end
                end
            end

            -- Memulai loop Noclip
            Noclipping = game:GetService("RunService").Stepped:Connect(NoclipLoop)
        else
            print("Noclip Disabled")
            if Noclipping then
                Noclipping:Disconnect()
                Noclipping = nil
            end

            -- Hanya mengatur `CanCollide` ke true untuk bagian tertentu
            local speaker = game.Players.LocalPlayer
            local character = speaker.Character or speaker.CharacterAdded:Wait()
            for _, child in pairs(character:GetDescendants()) do
                if child:IsA("BasePart") then
                    if child.Name == "HumanoidRootPart" or child.Name == "UpperTorso" or child.Name == "LowerTorso" then
                        child.CanCollide = true
                    else
                        child.CanCollide = false
                    end
                end
            end
        end
    end,
})
local RunService = game:GetService("RunService")
local speaker = game.Players.LocalPlayer

-- Variabel untuk menyimpan status toggle dan kecepatan
local tpwalking = false
local selectedSpeedMultiplier = 2 -- Default ×2 speed
local speedBoostConnection -- Untuk menyimpan koneksi loop speed boost

-- Dropdown untuk memilih × speed
local Dropdown = Tab:CreateDropdown({
    Name = "Speed Multiplier",
    Options = {"×1", "×2", "×3", "×4", "×5", "×6", "×7"},
    CurrentOption = "×2", -- Default opsi
    MultiSelection = false, -- Nonaktifkan multi-pilihan
    Flag = "SpeedMultiplierDropdown", -- Flag unik untuk dropdown
    Callback = function(Option)
        -- Ambil angka dari opsi yang dipilih
        selectedSpeedMultiplier = tonumber(string.match(Option, "%d+"))
        print("Selected Speed Multiplier:", selectedSpeedMultiplier)

        -- Perbarui multiplier jika toggle aktif
        if tpwalking then
            deactivateSpeedBoost()
            activateSpeedBoost(selectedSpeedMultiplier)
        end
    end,
})

-- Toggle untuk mengaktifkan atau menonaktifkan fungsi × speed
local Toggle = Tab:CreateToggle({
    Name = "Enable Speed Boost",
    CurrentValue = false,
    Flag = "SpeedBoostToggle", -- Flag unik untuk toggle
    Callback = function(Value)
        tpwalking = Value
        if tpwalking then
            print("Speed boost enabled")
            activateSpeedBoost(selectedSpeedMultiplier)
        else
            print("Speed boost disabled")
            deactivateSpeedBoost()
        end
    end,
})

-- Fungsi untuk mengaktifkan × speed
function activateSpeedBoost(multiplier)
    -- Hentikan loop sebelumnya jika ada
    deactivateSpeedBoost()

    -- Mulai loop baru
    speedBoostConnection = RunService.Heartbeat:Connect(function(delta)
        local chr = speaker.Character
        local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
        
        -- Validasi karakter dan humanoid
        if not chr or not hum then
            warn("Character or Humanoid not found.")
            return
        end

        -- Percepat pergerakan jika ada input
        if hum.MoveDirection.Magnitude > 0 then
            chr:TranslateBy(hum.MoveDirection * multiplier * delta * 10)
        end
    end)
end

-- Fungsi untuk menghentikan × speed
function deactivateSpeedBoost()
    if speedBoostConnection then
        speedBoostConnection:Disconnect()
        speedBoostConnection = nil
    end
end
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Variabel untuk menyimpan status dan cahaya
local lightEnabled = false
local lightInstance = nil

-- Fungsi untuk membuat cahaya
local function createLight()
    if not lightInstance then
        lightInstance = Instance.new("PointLight")
        lightInstance.Name = "HeadLight"
        lightInstance.Color = Color3.new(1, 1, 1) -- Warna putih
        lightInstance.Enabled = true
    end
end

-- Fungsi untuk menyesuaikan intensitas cahaya berdasarkan waktu
local function adjustLightBrightness()
    if lightInstance then
        local isDay = ReplicatedStorage:FindFirstChild("ServerSettings") 
            and ReplicatedStorage.ServerSettings:FindFirstChild("Day") 
            and ReplicatedStorage.ServerSettings.Day.Value

        if isDay then
            lightInstance.Brightness = 2 -- Cahaya kecil saat siang
            lightInstance.Range = 300000 -- Jangkauan kecil
        else
            lightInstance.Brightness = 3 -- Cahaya terang saat malam
            lightInstance.Range = 300000 -- Jangkauan besar
        end
    end
end

-- Fungsi untuk menambahkan cahaya ke atas kepala
local function attachLightToHead()
    local character = LocalPlayer.Character
    local head = character and character:FindFirstChild("Head")
    if head and lightInstance then
        lightInstance.Parent = head
    else
        warn("Character or Head not found. Unable to attach light.")
    end
end

-- Fungsi untuk menghapus cahaya
local function removeLight()
    if lightInstance then
        lightInstance:Destroy()
        lightInstance = nil
    end
end

-- Toggle untuk mengaktifkan/mematikan cahaya
Tab:CreateToggle({
    Name = "smart Light",
    CurrentValue = false,
    Flag = "HeadLightToggle",
    Callback = function(value)
        lightEnabled = value
        if lightEnabled then
            createLight()
            attachLightToHead()
            adjustLightBrightness()
        else
            removeLight()
        end
    end,
})

-- Menangani perubahan waktu (Day/Night)
if ReplicatedStorage:FindFirstChild("ServerSettings") and ReplicatedStorage.ServerSettings:FindFirstChild("Day") then
    ReplicatedStorage.ServerSettings.Day:GetPropertyChangedSignal("Value"):Connect(function()
        if lightEnabled then
            adjustLightBrightness()
        end
    end)
end

-- Menangani respawn pemain (agar cahaya tetap ada setelah respawn)
LocalPlayer.CharacterAdded:Connect(function()
    if lightEnabled then
        task.wait(0.6) -- Tunggu karakter selesai dimuat
        attachLightToHead()
        adjustLightBrightness()
    end
end)
local Toggle = Tab:CreateToggle({
   Name = "fullbright",
   CurrentValue = false,
   Flag = "Togg99", -- Identifier unik
   Callback = function(Value)
       local lighting = game:GetService("Lighting")
       -- Variable untuk menyimpan koneksi event
       local fullBrightConnection

       if Value then
           -- Aktifkan full bright
           fullBrightConnection = lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
               -- Pastikan ClockTime tetap pada nilai terang
               lighting.Brightness = 3
               lighting.ClockTime = 14
               lighting.FogEnd = 1e10
               lighting.GlobalShadows = false
           end)

           -- Atur awal properti full bright
           lighting.Brightness = 2
           lighting.ClockTime = 14
           lighting.FogEnd = 1e10
           lighting.GlobalShadows = false

           -- Simpan koneksi agar bisa di-*disconnect* nanti
           Toggle.fullBrightConnection = fullBrightConnection
       else
           -- Matikan full bright dan reset properti ke nilai default
           if Toggle.fullBrightConnection then
               Toggle.fullBrightConnection:Disconnect()
               Toggle.fullBrightConnection = nil
           end

           lighting.Brightness = 1
           lighting.ClockTime = 12
           lighting.FogEnd = 1000
           lighting.GlobalShadows = true
       end
   end,
})
local autoSpawn = false -- Status toggle auto-spawn

-- Membuat Toggle untuk Auto-Spawn
Tab:CreateToggle({
    Name = "Auto-Spawn",
    CurrentValue = false,
    Flag = "AutoSpawnToggle",
    Callback = function(Value)
        autoSpawn = Value

        if autoSpawn then
            task.spawn(function()
                while autoSpawn do
                    local player = game.Players.LocalPlayer
                    local character = player.Character or player.CharacterAdded:Wait()
                    local humanoid = character:FindFirstChild("Humanoid")

                    -- Jika health pemain 0, respawn
                    if humanoid and humanoid.Health <= 0 then
                        game:GetService("ReplicatedStorage").Events.Spawn:FireServer()
                        print("you-Spawn")
                    end

                    task.wait(1) -- Delay untuk menghindari spam
                end
            end)
        end
    end,
})
-- Toggle status
local espActive = false
local displayName = false
local displayHealth = false
local displayDistance = false

-- Tabel untuk menyimpan ESP yang dibuat
local espElements = {}

-- Fungsi untuk memperbarui warna berdasarkan health
local function getHealthColor(health)
    if health <= 10 then
        return Color3.fromRGB(255, 0, 0) -- Merah
    elseif health <= 60 then
        return Color3.fromRGB(255, 165, 0) -- Orange
    else
        return Color3.fromRGB(0, 255, 0) -- Hijau
    end
end

-- Fungsi untuk membuat atau memperbarui ESP
local function createOrUpdateESP(player)
    if player == game.Players.LocalPlayer then return end -- Hindari ESP untuk pemain lokal

    local character = player.Character
    if not character then return end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoidRootPart or not humanoid then return end

    -- Jika ESP belum ada, buat BillboardGui baru
    if not espElements[player] then
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = humanoidRootPart
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.AlwaysOnTop = true
        billboard.Name = "PlayerESP"

        -- Tambahkan label untuk nama
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, 0, 0.3, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextScaled = true
        nameLabel.Parent = billboard

        -- Tambahkan label untuk health
        local healthLabel = Instance.new("TextLabel")
        healthLabel.Name = "HealthLabel"
        healthLabel.Size = UDim2.new(1, 0, 0.3, 0)
        healthLabel.Position = UDim2.new(0, 0, 0.3, 0)
        healthLabel.BackgroundTransparency = 1
        healthLabel.TextScaled = true
        healthLabel.Parent = billboard

        -- Tambahkan label untuk jarak
        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.Name = "DistanceLabel"
        distanceLabel.Size = UDim2.new(1, 0, 0.3, 0)
        distanceLabel.Position = UDim2.new(0, 0, 0.6, 0)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.TextScaled = true
        distanceLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
        distanceLabel.Parent = billboard

        billboard.Parent = humanoidRootPart
        espElements[player] = billboard
    end

    -- Perbarui konten ESP
    local billboard = espElements[player]
    if displayName and espActive then
        billboard.NameLabel.Text = player.Name
        billboard.NameLabel.Visible = true
    else
        billboard.NameLabel.Visible = false
    end

    if displayHealth and espActive then
        billboard.HealthLabel.Text = "Health: " .. math.floor(humanoid.Health)
        billboard.HealthLabel.TextColor3 = getHealthColor(humanoid.Health)
        billboard.HealthLabel.Visible = true
    else
        billboard.HealthLabel.Visible = false
    end

    if displayDistance and espActive then
        local localPlayer = game.Players.LocalPlayer
        local distance = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and 
                         (localPlayer.Character.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude or 0
        billboard.DistanceLabel.Text = "Distance: " .. math.floor(distance)
        billboard.DistanceLabel.Visible = true
    else
        billboard.DistanceLabel.Visible = false
    end
end

-- Tambahkan toggle untuk menampilkan inventory
local displayInventory = false

-- Fungsi untuk mendapatkan nilai inventory
local function getInventoryValue(player)
    local stats = workspace:FindFirstChild(player.Name) and workspace[player.Name]:FindFirstChild("Stats")
    local inventory = stats and stats:FindFirstChild("Inventory")
    return inventory and inventory.Value or "N/A"
end

-- Modifikasi fungsi untuk membuat atau memperbarui ESP
local function createOrUpdateESP(player)
    if player == game.Players.LocalPlayer then return end -- Hindari ESP untuk pemain lokal

    local character = player.Character
    if not character then return end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoidRootPart or not humanoid then return end

    -- Jika ESP belum ada, buat BillboardGui baru
    if not espElements[player] then
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = humanoidRootPart
        billboard.Size = UDim2.new(0, 200, 0, 70) -- Perbesar ukuran untuk inventory
        billboard.AlwaysOnTop = true
        billboard.Name = "PlayerESP"

        -- Tambahkan label untuk nama
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, 0, 0.2, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextScaled = true
        nameLabel.Parent = billboard

        -- Tambahkan label untuk health
        local healthLabel = Instance.new("TextLabel")
        healthLabel.Name = "HealthLabel"
        healthLabel.Size = UDim2.new(1, 0, 0.2, 0)
        healthLabel.Position = UDim2.new(0, 0, 0.2, 0)
        healthLabel.BackgroundTransparency = 1
        healthLabel.TextScaled = true
        healthLabel.Parent = billboard

        -- Tambahkan label untuk jarak
        local distanceLabel = Instance.new("TextLabel")
        distanceLabel.Name = "DistanceLabel"
        distanceLabel.Size = UDim2.new(1, 0, 0.2, 0)
        distanceLabel.Position = UDim2.new(0, 0, 0.4, 0)
        distanceLabel.BackgroundTransparency = 1
        distanceLabel.TextScaled = true
        distanceLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
        distanceLabel.Parent = billboard

        -- Tambahkan label untuk inventory
        local inventoryLabel = Instance.new("TextLabel")
        inventoryLabel.Name = "InventoryLabel"
        inventoryLabel.Size = UDim2.new(1, 0, 0.2, 0)
        inventoryLabel.Position = UDim2.new(0, 0, 0.6, 0)
        inventoryLabel.BackgroundTransparency = 1
        inventoryLabel.TextScaled = true
        inventoryLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        inventoryLabel.Parent = billboard

        billboard.Parent = humanoidRootPart
        espElements[player] = billboard
    end

    -- Perbarui konten ESP
    local billboard = espElements[player]
    if displayName and espActive then
        billboard.NameLabel.Text = player.Name
        billboard.NameLabel.Visible = true
    else
        billboard.NameLabel.Visible = false
    end

    if displayHealth and espActive then
        billboard.HealthLabel.Text = "Health: " .. math.floor(humanoid.Health)
        billboard.HealthLabel.TextColor3 = getHealthColor(humanoid.Health)
        billboard.HealthLabel.Visible = true
    else
        billboard.HealthLabel.Visible = false
    end

    if displayDistance and espActive then
        local localPlayer = game.Players.LocalPlayer
        local distance = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and 
                         (localPlayer.Character.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude or 0
        billboard.DistanceLabel.Text = "Distance: " .. math.floor(distance)
        billboard.DistanceLabel.Visible = true
    else
        billboard.DistanceLabel.Visible = false
    end

    if displayInventory and espActive then
        billboard.InventoryLabel.Text = "Inventory: " .. getInventoryValue(player)
        billboard.InventoryLabel.Visible = true
    else
        billboard.InventoryLabel.Visible = false
    end
end

-- Fungsi untuk menghapus semua ESP
local function removeAllESP()
    for player, billboard in pairs(espElements) do
        if billboard then
            billboard:Destroy()
        end
    end
    espElements = {} -- Reset tabel ESP
end

-- Toggle ESP
Tab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "EnableESP",
    Callback = function(Value)
        espActive = Value
        if not espActive then
            removeAllESP()
        else
            for _, player in pairs(game.Players:GetPlayers()) do
                createOrUpdateESP(player)
            end
        end
    end,
})

-- Toggle nama
Tab:CreateToggle({
    Name = "Display Name",
    CurrentValue = false,
    Flag = "DisplayName",
    Callback = function(Value)
        displayName = Value
        if espActive then
            for _, player in pairs(game.Players:GetPlayers()) do
                createOrUpdateESP(player)
            end
        end
    end,
})

-- Toggle health
Tab:CreateToggle({
    Name = "Display Health",
    CurrentValue = false,
    Flag = "DisplayHealth",
    Callback = function(Value)
        displayHealth = Value
        if espActive then
            for _, player in pairs(game.Players:GetPlayers()) do
                createOrUpdateESP(player)
            end
        end
    end,
})

-- Toggle jarak
Tab:CreateToggle({
    Name = "Display Distance",
    CurrentValue = false,
    Flag = "DisplayDistance",
    Callback = function(Value)
        displayDistance = Value
        if espActive then
            for _, player in pairs(game.Players:GetPlayers()) do
                createOrUpdateESP(player)
            end
        end
    end,
})

-- Toggle untuk menampilkan inventory
Tab:CreateToggle({
    Name = "Display Inventory",
    CurrentValue = false,
    Flag = "DisplayInventory",
    Callback = function(Value)
        displayInventory = Value
        if espActive then
            for _, player in pairs(game.Players:GetPlayers()) do
                createOrUpdateESP(player)
            end
        end
    end,
})

-- Update loop untuk memperbarui ESP secara terus-menerus
game:GetService("RunService").RenderStepped:Connect(function()
    if espActive then
        for _, player in pairs(game.Players:GetPlayers()) do
            createOrUpdateESP(player)
        end
    end
end)
local ESPEnabled = {Tiny = false, Mini = false, Big = false} -- Status toggle ESP
local ESPConnections = {} -- Menyimpan koneksi untuk pembaruan
local player = game.Players.LocalPlayer

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local espMiniGEFEnabled = false
local espTinyGEFEnabled = false
local activeESP = {
    MiniGEF = {},
    TinyGEF = {}
}

-- Utility Function: Menghitung jarak
local function getDistance(position)
    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        return (humanoidRootPart.Position - position).Magnitude
    end
    return math.huge -- Jika tidak ada karakter, kembalikan jarak maksimum
end

-- Utility Function: Membuat ESP
local function createESP(object, text, color, category)
    if not object or not category then return end

    -- Cek apakah BillboardGui sudah ada
    local billboard = object:FindFirstChild("ESP_Billboard")
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee = object
        billboard.AlwaysOnTop = true

        local textLabel = Instance.new("TextLabel", billboard)
        textLabel.Name = "ESP_Label"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextColor3 = color
        textLabel.TextScaled = true

        billboard.Parent = object
    end

    -- Perbarui teks dan warna
    local label = billboard:FindFirstChild("ESP_Label")
    if label then
        label.Text = text
        label.TextColor3 = color
    end

    -- Simpan ke daftar ESP aktif
    table.insert(activeESP[category], billboard)
end

-- Fungsi untuk menghapus ESP berdasarkan kategori
local function clearESPByCategory(category)
    if not activeESP[category] then return end
    for _, billboard in ipairs(activeESP[category]) do
        if billboard and billboard.Parent then
            billboard:Destroy()
        end
    end
    activeESP[category] = {}
end

-- Fungsi untuk memperbarui ESP untuk model tertentu
local function updateModelESP(modelName, category, isEnabled)
    if not isEnabled then
        clearESPByCategory(category)
        return
    end

    local gefs = workspace:FindFirstChild("GEFs")
    if not gefs then
        warn("workspace.GEFs not found")
        return
    end

    for _, model in ipairs(gefs:GetChildren()) do
        if model:IsA("Model") and model.Name == modelName then
            local head = model:FindFirstChild("Head")
            local health = model:FindFirstChild("Health")

            if head and health and head:IsA("MeshPart") and health:IsA("NumberValue") then
                local healthValue = health.Value
                local distance = getDistance(head.Position)

                -- Tentukan warna berdasarkan nilai kesehatan
                local color = Color3.new(0, 1, 0) -- Hijau
                if healthValue < 10 then
                    color = Color3.new(1, 0, 0) -- Merah
                elseif healthValue < 60 then
                    color = Color3.new(1, 0.5, 0) -- Oranye
                end

                -- Buat atau perbarui ESP
                createESP(head, modelName .. "\nHealth: " .. healthValue .. "\nDistance: " .. math.floor(distance), color, category)
            end
        end
    end
end

-- Toggle untuk ESP Mini GEF
Tab:CreateToggle({
    Name = "ESP Mini GEF",
    CurrentValue = false,
    Flag = "MiniGEFESP",
    Callback = function(value)
        espMiniGEFEnabled = value
        if value then
            print("ESP Mini GEF enabled")
        else
            print("ESP Mini GEF disabled")
        end
    end,
})

-- Toggle untuk ESP Tiny GEF
Tab:CreateToggle({
    Name = "ESP Tiny GEF",
    CurrentValue = false,
    Flag = "TinyGEFESP",
    Callback = function(value)
        espTinyGEFEnabled = value
        if value then
            print("ESP Tiny GEF enabled")
        else
            print("ESP Tiny GEF disabled")
        end
    end,
})

-- Loop untuk memperbarui ESP
RunService.RenderStepped:Connect(function()
    if espMiniGEFEnabled then
        updateModelESP("Mini GEF", "MiniGEF", true)
    else
        updateModelESP("Mini GEF", "MiniGEF", false)
    end

    if espTinyGEFEnabled then
        updateModelESP("Tiny GEF", "TinyGEF", true)
    else
        updateModelESP("Tiny GEF", "TinyGEF", false)
    end
end)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Variabel untuk menyimpan status ESP dan koneksi
local ESPEnabled = {
    GEF = false
}
local ESPConnections = {}

-- Utility Function: Menghitung jarak
local function getDistance(position)
    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        return (humanoidRootPart.Position - position).Magnitude
    end
    return math.huge -- Jika tidak ada karakter, kembalikan jarak maksimum
end

-- Utility Function: Membuat atau memperbarui ESP
local function updateESP(object, title, health, distance)
    if not object then return end

    -- Cek apakah BillboardGui sudah ada
    local billboard = object:FindFirstChild("ESP_Billboard")
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "ESP_Billboard"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.Adornee = object
        billboard.AlwaysOnTop = true

        local textLabel = Instance.new("TextLabel", billboard)
        textLabel.Name = "ESP_Label"
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextScaled = true
        textLabel.TextColor3 = Color3.new(0, 1, 0) -- Default hijau

        billboard.Parent = object
    end

    -- Perbarui teks dan warna berdasarkan kesehatan
    local label = billboard:FindFirstChild("ESP_Label")
    if label then
        local color = Color3.new(0, 1, 0) -- Hijau
        if health < 10 then
            color = Color3.new(1, 0, 0) -- Merah
        elseif health < 60 then
            color = Color3.new(1, 0.5, 0) -- Oranye
        end

        label.Text = title .. "\nHealth: " .. health .. "\nDistance: " .. math.floor(distance)
        label.TextColor3 = color
    end
end

-- Fungsi untuk menangani ESP GEF
local function updateGEFESP()
    local gef = workspace:FindFirstChild("GEF")
    if gef and gef:FindFirstChild("RootPart") and gef.RootPart:FindFirstChild("Hitbox") and gef:FindFirstChild("Health") then
        local hitbox = gef.RootPart.Hitbox
        local health = gef.Health.Value
        local distance = getDistance(hitbox.Position)
        updateESP(hitbox, "GEF", health, distance)
    else
        warn("GEF not found or missing components")
    end
end

-- Membuat Toggle untuk GEF ESP
Tab:CreateToggle({
    Name = "ESP GEF",
    CurrentValue = false,
    Flag = "ESP_GEF",
    Callback = function(value)
        ESPEnabled.GEF = value
        if value then
            -- Sambungkan ke Heartbeat untuk memperbarui ESP
            ESPConnections.GEF = RunService.Heartbeat:Connect(updateGEFESP)
        else
            -- Hapus koneksi jika toggle dimatikan
            if ESPConnections.GEF then
                ESPConnections.GEF:Disconnect()
                ESPConnections.GEF = nil
            end
            -- Hapus ESP dari GEF jika ada
            local gef = workspace:FindFirstChild("GEF")
            if gef and gef:FindFirstChild("RootPart") and gef.RootPart:FindFirstChild("Hitbox") then
                local esp = gef.RootPart.Hitbox:FindFirstChild("ESP_Billboard")
                if esp then esp:Destroy() end
            end
        end
    end,
})
local Tab = Window:CreateTab("Shop", "store")
local Section = Tab:CreateSection("sell",true)
local autoSellAll = false -- Status toggle untuk Auto Sell All

-- Fungsi untuk menjual semua item di Backpack
local function sellAllItems()
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        warn("Backpack not found.")
        return
    end

    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            game:GetService("ReplicatedStorage").Events.SellItem:FireServer(item)
            print("Sold item:", item.Name)
        end
    end
end

-- Toggle untuk Auto Sell All
Tab:CreateToggle({
    Name = "Auto Sell All",
    CurrentValue = false,
    Flag = "AutoSellAllToggle",
    Callback = function(value)
        autoSellAll = value
        print("Auto Sell All:", autoSellAll)

        if autoSellAll then
            -- Menjalankan loop untuk menjual semua item secara berkala
            task.spawn(function()
                while autoSellAll do
                    sellAllItems()
                    task.wait(1) -- Delay untuk menghindari spam
                end
            end)
        end
    end,
})

local selectedItems = {} -- Menyimpan item yang dipilih dari dropdown
local sellSpecificSelected = false -- Status toggle untuk menjual item yang dipilih

-- Daftar nama item tetap, termasuk GPS
local predefinedItems = {
    "Hammer", "Handgun", "Medkit", "Bullets", "Bat", "Shotgun",
    "Shells", "Lantern", "Crowbar", "Money", "Soda", "Food", "GPS"
}

-- Fungsi untuk menjual item berdasarkan nama
local function sellItemByName(itemName)
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        warn("Backpack not found.")
        return
    end

    for _, item in ipairs(backpack:GetChildren()) do
        if item.Name == itemName then
            game:GetService("ReplicatedStorage").Events.SellItem:FireServer(item)
            print("Sold item:", item.Name)
            break -- Hentikan loop setelah item ditemukan dan dijual
        end
    end
end

-- Dropdown untuk memilih item yang akan dijual
Tab:CreateDropdown({
    Name = "Select Items to Sell",
    Options = predefinedItems, -- Daftar nama item tetap
    MultiSelection = true, -- Pastikan MultiSelection aktif
    Flag = "SelectedItemsDropdown",
    Callback = function(selected)
        -- Pastikan `selected` selalu berupa tabel
        if typeof(selected) == "string" then
            selectedItems = {selected} -- Jika dropdown hanya mengembalikan satu string
        else
            selectedItems = selected -- Jika multi-seleksi, gunakan tabel langsung
        end
        print("Selected items to sell:", selectedItems)
    end,
})

-- Toggle untuk menjual item yang dipilih di dropdown
local Section Tab:CreateToggle({
    Name = "Sell Specific Items",
    CurrentValue = false,
    Flag = "SellSpecificSelectedToggle",
    Callback = function(value)
        sellSpecificSelected = value
        print("Sell Specific Selected Items:", sellSpecificSelected)

        if sellSpecificSelected then
            -- Menjual semua item yang dipilih saat toggle diaktifkan
            task.spawn(function()
                while sellSpecificSelected do
                    for _, itemName in ipairs(selectedItems) do
                        sellItemByName(itemName)
                    end
                    task.wait(1) -- Delay untuk menghindari spam
                end
            end)
        end
    end,
})
local Section = Tab:CreateSection("shop",true)
local Section = Tab:CreateSection("upgrade",true) -- The 2nd argument is to tell if its only a Title and doesnt contain element
-- Membuat Button untuk MaxStamina
Tab:CreateButton({
    Name = "Purchase Max Stamina",
    Callback = function()
        local args = {
            [1] = "MaxStamina"
        }
        game:GetService("ReplicatedStorage").Events.PurchaseEvent:FireServer(unpack(args))
        print("Purchased Max Stamina")
    end,
})

-- Membuat Button untuk StaminaRegen
Tab:CreateButton({
    Name = "Purchase Stamina Regen",
    Callback = function()
        local args = {
            [1] = "StaminaRegen"
        }
        game:GetService("ReplicatedStorage").Events.PurchaseEvent:FireServer(unpack(args))
        print("Purchased Stamina Regen")
    end,
})

-- Membuat Button untuk Storage
Tab:CreateButton({
    Name = "Purchase Storage",
    Callback = function()
        local args = {
            [1] = "Storage"
        }
        game:GetService("ReplicatedStorage").Events.PurchaseEvent:FireServer(unpack(args))
        print("Purchased Storage")
    end,
})
local Section = Tab:CreateSection("buy",true) -- The 2nd argument is to tell if its only a Title and doesnt contain element
-- Fungsi untuk mencari semua item di toko dan otomatis membelinya
local function autoBuyItem(itemName)
    -- Mencari seluruh toko di Workspace.Buildings
    for _, building in ipairs(workspace.Buildings:GetChildren()) do
        if building:IsA("Model") and building:FindFirstChild("Nodes") then
            local nodes = building:FindFirstChild("Nodes")
            local room = nodes and nodes:FindFirstChild("Room")
            local shop = room and room:FindFirstChild("Shop")
            local proximityPromptFolder = shop and shop:FindFirstChild("ProximityPrompt")
            local itemFolder = proximityPromptFolder and proximityPromptFolder:FindFirstChild("Folder")

            -- Validasi keberadaan folder item
            if itemFolder then
                local item = itemFolder:FindFirstChild(itemName)

                if item and item:IsA("ValueBase") then
                    local price = item.Value

                    -- Menjalankan FireServer untuk membeli item
                    local args = {
                        [1] = item
                    }
                    game:GetService("ReplicatedStorage").Events.BuyItem:FireServer(unpack(args))
                    print("BuyItem event fired for", itemName)
                    return
                end
            end
        end
    end

    -- Jika tidak ditemukan
    warn("Item", itemName, "not found in any Shop.")
end

-- Membuat tombol untuk membeli item secara otomatis
local items = {"Hammer", "Handgun", "Medkit", "Bullets", "Bat", "Shotgun", "Shells"}
for _, item in ipairs(items) do
    Tab:CreateButton({
        Name = "Buy ?1 " .. item,
        Callback = function()
            autoBuyItem(item)
        end,
    })
end
local Tab = Window:CreateTab("Players", "users-round")
local Section = Tab:CreateSection("Tools")
local speaker = game.Players.LocalPlayer
local currentToolSize = {}
local currentGripPos = {}
local toolNames = {"Bat", "Crowbar", "Crowbars"}
local selectedSizeBat = 10 -- Default size untuk Bat
local selectedSizeCrowbar = 10 -- Default size untuk Crowbar(s)

-- Fungsi untuk mendapatkan tool yang sedang di-hold
local function getEquippedTool()
    if speaker.Character then
        for _, v in pairs(speaker.Character:GetChildren()) do
            if v:IsA("Tool") and table.find(toolNames, v.Name) then
                return v
            end
        end
    end
    return nil
end

local function applyHitbox(tool, size)
    if not tool or not tool:FindFirstChild("Handle") then return end

    if not currentToolSize[tool] then
        currentToolSize[tool] = tool.Handle.Size
        currentGripPos[tool] = tool.GripPos
    end

    if not tool.Handle:FindFirstChild("SelectionBoxCreated") then
        local a = Instance.new("SelectionBox")
        a.Name = "SelectionBoxCreated"
        a.Parent = tool.Handle
        a.Adornee = tool.Handle
    end

    tool.Handle.Massless = true
    tool.Handle.Size = Vector3.new(size, size, size)
    tool.GripPos = Vector3.new(0, 0, 0)
    speaker.Character:FindFirstChildOfClass("Humanoid"):UnequipTools()
end

local function removeHitbox(tool)
    if not tool or not tool:FindFirstChild("Handle") then return end

    if currentToolSize[tool] then
        tool.Handle.Size = currentToolSize[tool]
        tool.GripPos = currentGripPos[tool]
        currentToolSize[tool] = nil
        currentGripPos[tool] = nil
    end

    if tool.Handle:FindFirstChild("SelectionBoxCreated") then
        tool.Handle.SelectionBoxCreated:Destroy()
    end
end

local ToggleBat = Tab:CreateToggle({
   Name = "MoreHitbox Bat",
   CurrentValue = false,
   Flag = "Toggle11",
   Callback = function(Value)
       local tool = getEquippedTool()
       if tool and tool.Name == "Bat" then
           if Value then
               applyHitbox(tool, selectedSizeBat)
           else
               removeHitbox(tool)
           end
       end
   end,
})

local ToggleCrowbar = Tab:CreateToggle({
   Name = "MoreHitbox Crowbar",
   CurrentValue = false,
   Flag = "Toggle22",
   Callback = function(Value)
       local tool = getEquippedTool()
       if tool and (tool.Name == "Crowbar" or tool.Name == "Crowbars") then
           if Value then
               applyHitbox(tool, selectedSizeCrowbar)
           else
               removeHitbox(tool)
           end
       end
   end,
})

local SliderBat = Tab:CreateSlider({
   Name = "Bat Size",
   Range = {10, 100},
   Increment = 10,
   Suffix = "Size",
   CurrentValue = 10,
   Flag = "SliderBat",
   Callback = function(Value)
       selectedSizeBat = Value
       local tool = getEquippedTool()
       if tool and tool.Name == "Bat" then
           applyHitbox(tool, selectedSizeBat)
       end
   end,
})

local SliderCrowbar = Tab:CreateSlider({
   Name = "Crowbar Size",
   Range = {10, 100},
   Increment = 10,
   Suffix = "Size",
   CurrentValue = 10,
   Flag = "SliderCrowbar",
   Callback = function(Value)
       selectedSizeCrowbar = Value
       local tool = getEquippedTool()
       if tool and (tool.Name == "Crowbar" or tool.Name == "Crowbars") then
           applyHitbox(tool, selectedSizeCrowbar)
       end
   end,
})
local gefsHitboxToggle
local followPart = nil
local welds = {} -- Tabel untuk menyimpan welds

gefsHitboxToggle = Tab:CreateToggle({
    Name = "Enable GEFs Follow Part",
    CurrentValue = false,
    Flag = "ToggleGEFsFollow",
    Callback = function(Value)
        if Value then
            -- Buat part yang akan mengikuti karakter
            followPart = Instance.new("Part")
            followPart.Name = "GEFsFollowPart"
            followPart.Size = Vector3.new(2, 2, 2)
            followPart.Transparency = 0.5
            followPart.Color = Color3.new(1, 0, 0)
            followPart.Anchored = false
            followPart.CanCollide = false
            followPart.Parent = workspace

            -- Buat BodyVelocity untuk mengikuti karakter
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            bodyVelocity.Parent = followPart

            -- Hubungkan part ke depan karakter
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

            if humanoidRootPart then
                -- Posisikan part di depan karakter
                local offset = humanoidRootPart.CFrame:VectorToWorldSpace(Vector3.new(0, 0, -5))
                followPart.CFrame = humanoidRootPart.CFrame + offset

                -- Buat weld untuk menghubungkan part ke karakter
                local weld = Instance.new("Weld")
                weld.Part0 = humanoidRootPart
                weld.Part1 = followPart
                weld.C0 = CFrame.new(0, 0, -5) -- Posisi relatif di depan karakter
                weld.Parent = followPart
            end

            -- Hubungkan semua Hitbox dari Tiny GEF dan Mini GEF ke followPart
            for _, gef in ipairs(workspace.GEFs:GetChildren()) do
                if gef.Name == "Tiny GEF" or gef.Name == "Mini GEF" then
                    local hitbox = gef:FindFirstChild("Hitbox")
                    if hitbox then
                        local weld = Instance.new("Weld")
                        weld.Part0 = followPart
                        weld.Part1 = hitbox
                        weld.C0 = CFrame.new() -- Posisi relatif
                        weld.Parent = hitbox
                        table.insert(welds, weld) -- Simpan weld ke tabel
                    end
                end
            end

            -- Buat loop untuk mengikuti karakter
            game:GetService("RunService").Heartbeat:Connect(function()
                if followPart and humanoidRootPart then
                    local offset = humanoidRootPart.CFrame:VectorToWorldSpace(Vector3.new(0, 0, -5))
                    followPart.CFrame = humanoidRootPart.CFrame + offset
                end
            end)
        else
            -- Hapus part dan welds jika toggle dinonaktifkan
            if followPart then
                followPart:Destroy()
                followPart = nil
            end

            for _, weld in ipairs(welds) do
                weld:Destroy()
            end
            welds = {} -- Kosongkan tabel welds
        end
    end,
})
local gefsToggle = Tab:CreateToggle({
    Name = "No gef mini damage",
    CurrentValue = false,
    Flag = "Toggle33",
    Callback = function(Value)
        if Value then
            -- Start detecting and destroying Hurtbox for Mini GEF
            gefsConnection = workspace.GEFs.ChildAdded:Connect(function(child)
                if child.Name == "Mini GEF" and child:FindFirstChild("Hurtbox") then
                    child.Hurtbox:Destroy()
                end
            end)

            -- Destroy existing Hurtbox
            for _, gef in ipairs(workspace.GEFs:GetChildren()) do
                if gef.Name == "Mini GEF" and gef:FindFirstChild("Hurtbox") then
                    gef.Hurtbox:Destroy()
                end
            end
        else
            -- Stop detecting new Mini GEFs
            if gefsConnection then
                gefsConnection:Disconnect()
                gefsConnection = nil
            end
        end
    end,
})

local sgefToggle = Tab:CreateToggle({
    Name = "No gef small damage",
    CurrentValue = false,
    Flag = "Toggle34",
    Callback = function(Value)
        if Value then
            -- Start detecting and destroying Hurtbox for Tiny GEF
            sgefConnection = workspace.GEFs.ChildAdded:Connect(function(child)
                if child.Name == "Tiny GEF" and child:FindFirstChild("Hurtbox") then
                    child.Hurtbox:Destroy()
                end
            end)

            -- Destroy existing Hurtbox
            for _, gef in ipairs(workspace.GEFs:GetChildren()) do
                if gef.Name == "Tiny GEF" and gef:FindFirstChild("Hurtbox") then
                    gef.Hurtbox:Destroy()
                end
            end
        else
            -- Stop detecting new Tiny GEFs
            if sgefConnection then
                sgefConnection:Disconnect()
                sgefConnection = nil
            end
        end
    end,
})
local StaminaRegenInput = Tab:CreateInput({
    Name = "Set Stamina Regen",
    PlaceholderText = "Enter Value",
    NumbersOnly = true,
    CharacterLimit = 15,
    OnEnter = true,
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local Value = tonumber(Text)
        if Value then
            game:GetService("Players").LocalPlayer.Upgrades.StaminaRegen.Value = Value
        end
    end
})

local MaxStaminaInput = Tab:CreateInput({
    Name = "Set Max Stamina",
    PlaceholderText = "Enter Value",
    NumbersOnly = true,
    CharacterLimit = 15,
    OnEnter = true,
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local Value = tonumber(Text)
        if Value then
            game:GetService("Players").LocalPlayer.Upgrades.MaxStamina.Value = Value
        end
    end
})
local gefsHitboxToggle, sgefHitboxToggle
local gefsHitboxSlider, sgefHitboxSlider

-- Tabel untuk menyimpan ukuran asli Hitbox
local originalHitboxSizes = {}

-- Fungsi untuk menyimpan ukuran asli Hitbox
local function saveOriginalHitboxSizes()
    for _, gef in ipairs(workspace.GEFs:GetChildren()) do
        if gef.Name == "Mini GEF" or gef.Name == "Tiny GEF" then
            local hitbox = gef:FindFirstChild("Hitbox")
            if hitbox then
                originalHitboxSizes[gef] = hitbox.Size
            end
        end
    end
end

-- Panggil fungsi untuk menyimpan ukuran asli saat script pertama kali dijalankan
saveOriginalHitboxSizes()

gefsHitboxToggle = Tab:CreateToggle({
    Name = "Enable hitbox Gefs",
    CurrentValue = false,
    Flag = "Toggle33",
    Callback = function(Value)
        if Value then
            -- Simpan ukuran asli Hitbox jika belum disimpan
            saveOriginalHitboxSizes()

            -- Hubungkan event untuk Mini GEF yang baru ditambahkan
            gefsConnection = workspace.GEFs.ChildAdded:Connect(function(child)
                if child.Name == "Mini GEF" then
                    local hitbox = child:FindFirstChild("Hitbox")
                    if hitbox then
                        -- Simpan ukuran asli Hitbox
                        originalHitboxSizes[child] = hitbox.Size
                        -- Ubah ukuran Hitbox
                        hitbox.Size = Vector3.new(gefsHitboxSlider, gefsHitboxSlider, gefsHitboxSlider)
                    end
                end
            end)

            -- Ubah ukuran Hitbox untuk Mini GEF yang sudah ada
            for _, gef in ipairs(workspace.GEFs:GetChildren()) do
                if gef.Name == "Mini GEF" then
                    local hitbox = gef:FindFirstChild("Hitbox")
                    if hitbox then
                        hitbox.Size = Vector3.new(gefsHitboxSlider, gefsHitboxSlider, gefsHitboxSlider)
                    end
                end
            end
        else
            -- Nonaktifkan toggle dan kembalikan ukuran Hitbox ke semula
            if gefsConnection then
                gefsConnection:Disconnect()
                gefsConnection = nil
            end

            -- Kembalikan ukuran Hitbox untuk Mini GEF
            for _, gef in ipairs(workspace.GEFs:GetChildren()) do
                if gef.Name == "Mini GEF" then
                    local hitbox = gef:FindFirstChild("Hitbox")
                    if hitbox and originalHitboxSizes[gef] then
                        hitbox.Size = originalHitboxSizes[gef]
                    end
                end
            end
        end
    end,
})

sgefHitboxToggle = Tab:CreateToggle({
    Name = "Enable hitbox sgef",
    CurrentValue = false,
    Flag = "Toggle34",
    Callback = function(Value)
        if Value then
            -- Simpan ukuran asli Hitbox jika belum disimpan
            saveOriginalHitboxSizes()

            -- Hubungkan event untuk Tiny GEF yang baru ditambahkan
            sgefConnection = workspace.GEFs.ChildAdded:Connect(function(child)
                if child.Name == "Tiny GEF" then
                    local hitbox = child:FindFirstChild("Hitbox")
                    if hitbox then
                        -- Simpan ukuran asli Hitbox
                        originalHitboxSizes[child] = hitbox.Size
                        -- Ubah ukuran Hitbox
                        hitbox.Size = Vector3.new(sgefHitboxSlider, sgefHitboxSlider, sgefHitboxSlider)
                    end
                end
            end)

            -- Ubah ukuran Hitbox untuk Tiny GEF yang sudah ada
            for _, gef in ipairs(workspace.GEFs:GetChildren()) do
                if gef.Name == "Tiny GEF" then
                    local hitbox = gef:FindFirstChild("Hitbox")
                    if hitbox then
                        hitbox.Size = Vector3.new(sgefHitboxSlider, sgefHitboxSlider, sgefHitboxSlider)
                    end
                end
            end
        else
            -- Nonaktifkan toggle dan kembalikan ukuran Hitbox ke semula
            if sgefConnection then
                sgefConnection:Disconnect()
                sgefConnection = nil
            end

            -- Kembalikan ukuran Hitbox untuk Tiny GEF
            for _, gef in ipairs(workspace.GEFs:GetChildren()) do
                if gef.Name == "Tiny GEF" then
                    local hitbox = gef:FindFirstChild("Hitbox")
                    if hitbox and originalHitboxSizes[gef] then
                        hitbox.Size = originalHitboxSizes[gef]
                    end
                end
            end
        end
    end,
})

gefsHitboxSlider = Tab:CreateSlider({
    Name = "Hitbox for gefs",
    Range = {3, 20},
    Increment = 1,
    Suffix = "Size",
    CurrentValue = 4,
    Flag = "Slider11",
    Callback = function(Value)
        gefsHitboxSlider = Value
        if gefsHitboxToggle.CurrentValue then
            for _, gef in ipairs(workspace.GEFs:GetChildren()) do
                if gef.Name == "Mini GEF" then
                    local hitbox = gef:FindFirstChild("Hitbox")
                    if hitbox then
                        hitbox.Size = Vector3.new(Value, Value, Value)
                    end
                end
            end
        end
    end,
})

sgefHitboxSlider = Tab:CreateSlider({
    Name = "Hitbox for sgef",
    Range = {3, 20},
    Increment = 1,
    Suffix = "Size",
    CurrentValue = 10,
    Flag = "Slider22",
    Callback = function(Value)
        sgefHitboxSlider = Value
        if sgefHitboxToggle.CurrentValue then
            for _, gef in ipairs(workspace.GEFs:GetChildren()) do
                if gef.Name == "Tiny GEF" then
                    local hitbox = gef:FindFirstChild("Hitbox")
                    if hitbox then
                        hitbox.Size = Vector3.new(Value, Value, Value)
                    end
                end
            end
        end
    end,
})
local Tab = Window:CreateTab("Misc", "braces")
local Section = Tab:CreateSection("server",true) -- The 2nd argument is to tell if its only a Title and doesnt contain element
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local currentPlaceId = game.PlaceId -- ID tempat saat ini
local currentJobId = game.JobId -- ID server saat ini

-- Fungsi untuk mendapatkan waktu saat ini dalam format yang sesuai
local function getCurrentDateTime()
    local date = os.date("*t") -- Ambil waktu saat ini
    return string.format("%04d-%02d-%02d_%02d-%02d-%02d", date.year, date.month, date.day, date.hour, date.min, date.sec)
end

-- Fungsi untuk membuat file log
local function createLogFile(errorMessage)
    -- Dapatkan nama file berdasarkan waktu saat ini
    local fileName = getCurrentDateTime() .. ".lua"
    local folderPath = "ArrayField/logserver/"
    local fullPath = folderPath .. fileName

    -- Pastikan folder ada (membuat folder jika belum ada)
    if not isfolder("ArrayField") then
        makefolder("ArrayField")
    end
    if not isfolder(folderPath) then
        makefolder(folderPath)
    end

    -- Isi file dengan log teleport dan error (jika ada)
    local fileContent = string.format(
        "-- Log teleport\nlocal placeId = %d\nlocal jobId = \"%s\"\n\n",
        currentPlaceId,
        currentJobId
    )
    if errorMessage then
        fileContent = fileContent .. string.format("-- Error:\n%s\n", errorMessage)
    end

    -- Simpan file
    writefile(fullPath, fileContent)
    print("Log file created at:", fullPath)
end

-- Buat tombol
Tab:CreateButton({
    Name = "Rejoin Server",
    Interact = "Click log saved",
    Callback = function()
        -- Debug: Cetak klik tombon

        -- Cek variabel penting
        if not currentPlaceId or not currentJobId or not player then
            local errorMessage = "Teleport failed: Missing required data."
            warn(errorMessage)
            createLogFile(errorMessage)
            return
        end

        -- Panggil teleport dengan pcall
        local success, err = pcall(function()
            TeleportService:TeleportToPlaceInstance(currentPlaceId, currentJobId, player)
        end)

        -- Tangani jika teleport gagal atau berhasil
        if not success then
            local errorMessage = "Teleport failed: " .. tostring(err)
            warn(errorMessage)
            createLogFile(errorMessage)
        else
            print("Teleport")
            createLogFile() -- Buat log tanpa error
        end
    end,
})

Tab:CreateButton({
    Name = "Infinite Yield",
    Interact = "Click run another script",
    Callback = function()
        -- Eksekusi script Infinite Yield
        local success, err = pcall(function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
        end)

        -- Tangani jika terjadi error
        if not success then
            warn("Failed to execute Infinite Yield:", err)
        end
    end,
})
local UserSettings = UserSettings()
local UserGameSettings = UserSettings:GetService("UserGameSettings")
local shiftLockLoop = nil -- Menyimpan koneksi loop
local shiftLockEnabled = false -- Status toggle Shift Lock

-- Fungsi untuk mengatur Shift Lock
local function setShiftLock(value)
    if value then
        UserGameSettings.RotationType = Enum.RotationType.CameraRelative
        print("Shift Lock Enabled")
    else
        UserGameSettings.RotationType = Enum.RotationType.MovementRelative
        print("Shift Lock Disabled")
    end
end

-- Fungsi loop Shift Lock
local function shiftLockHandler()
    while shiftLockEnabled do
        setShiftLock(true)
        task.wait(0.1) -- Interval loop
    end
end

-- Membuat toggle untuk Shift Lock
Tab:CreateToggle({
    Name = "Enable Shift Lock",
    CurrentValue = false,
    Flag = "ShiftLockToggle",
    Callback = function(Value)
        shiftLockEnabled = Value

        if shiftLockEnabled then
            if not shiftLockLoop then
                shiftLockLoop = task.spawn(shiftLockHandler)
            end
        else
            if shiftLockLoop then
                shiftLockLoop = nil
            end
            setShiftLock(false)
        end
    end,
})
Tab:CreateButton({
    Name = "Clear Trees",
    Interact = "Click",
    Callback = function()
        -- Periksa apakah path workspace.TreesNo ada
        local treesNo = workspace:FindFirstChild("TreesNo")
        if treesNo then
            -- Hapus semua children dari TreesNo
            for _, child in ipairs(treesNo:GetChildren()) do
                child:Destroy()
            end
            print("Trees clear.")
        else
            warn("workspace.TreesNo does not exist.")
        end
    end,
})

local Tab = Window:CreateTab("Autobuilding", "hammer")
local Button = Tab:CreateButton({
    Name = "house_one",
    Interact = 'Click',
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")

        if tool and tool.Name == "Hammer" then
            local success = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/wipff2/gef/refs/heads/main/auto"))()
            end)

            if not success then
                warn("Failed to load script.")
            end
        else
            ArrayField:Notify({
                Title = "Get Error",
                Content = "Did you know you need to use the Hammer tool for this?",
                Duration = 10,
                Image = 4483362458,
                Actions = {
                    Ignore = {
                        Name = "Okay!",
                        Callback = function()
                            print("tool")
                        end
                    },
                },
            })
        end
    end,
})
local Button = Tab:CreateButton({
   Name = "House 2",
   Callback = function()
   -- auto build house2
print("coming soon house2")
   end,
})

ArrayField:LoadConfiguration() --di bagian bawah semua kode
