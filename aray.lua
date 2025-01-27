-- getgenv().SecureMode = true

local ArrayField = loadstring(game:HttpGet('https://raw.githubusercontent.com/UI-Interface/ArrayField/main/Source.lua'))()

local Window = ArrayField:CreateWindow({
   Name = "ArrayField",
   LoadingTitle = "ArrayField Interface",
   LoadingSubtitle = "by anon",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "ArrayField"
   },
   Discord = {
      Enabled = true,
      Invite = "gg/A24f827B", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the discord every time they load it up
   },
   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided",
      FileName = "Key", -- It is recommended to use something unique as other scripts using ArrayField may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like ArrayField to get the key from
      Actions = {
            [1] = {
                Text = 'Click here to copy the key link <--',
                OnPress = function()
                    print('Pressed')
                end,
                }
            },
      Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
   }
})

Window:Prompt({
    Title = 'Interface',
    SubTitle = 'approve',
    Content = 'running this script means you have agreed to the rules on my discord',
    Actions = {
        Accept = {
            Name = 'Accept',
            Callback = function()
                print('Pressed')
            end,
        }
    }
})

local Tab = Window:CreateTab("top", 4483362458) -- Title, Image
-- Daftar nama tools
local items = {"Bat", "Crowbar", "Food", "Hammer", "Handgun", "Lantern", "Money", "Soda", "Shotgun", "Shells", "Bullets", "Medkit", "GPS"}

-- Variabel untuk menyimpan posisi awal dan status ProximityPrompt
local returnToOriginal = false -- Status toggle untuk kembali ke posisi awal
local autoTriggerPrompt = false -- Status toggle untuk auto-trigger ProximityPrompt
local originalPosition = nil -- Posisi awal pemain

-- Membuat Toggle untuk kembali ke posisi awal
Tab:CreateToggle({
    Name = "Return to Original Position",
    CurrentValue = false,
    Flag = "ReturnToggle",
    Callback = function(Value)
        returnToOriginal = Value
        print("Return to Original Position:", returnToOriginal)
    end,
})

-- Membuat Toggle untuk auto-trigger ProximityPrompt
Tab:CreateToggle({
    Name = "Auto Trigger ProximityPrompt",
    CurrentValue = false,
    Flag = "AutoTriggerPromptToggle",
    Callback = function(Value)
        autoTriggerPrompt = Value
    end,
})
local autoDropHeldItem = false

-- Membuat Toggle untuk auto-drop item yang dipegang
Tab:CreateToggle({
    Name = "Auto Drop Hold Item",
    CurrentValue = false,
    Flag = "AutoDropHeldItemToggle",
    Callback = function(Value)
        autoDropHeldItem = Value
    end,
})

-- Fungsi untuk drop item yang sedang dipegang
local function dropHeldItem()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()

    -- Cek tool di tangan pemain
    local heldTool = character:FindFirstChildOfClass("Tool")
    if not heldTool then
        print("No found.")
        return
    end

    -- Memanggil event DropItem
    local dropItemEvent = game:GetService("ReplicatedStorage").Events:FindFirstChild("DropItem")
    if dropItemEvent then
        wait(0.3)
        dropItemEvent:FireServer(heldTool)
    end
end
local Section = Tab:CreateSection("tools",true)
-- Membuat tombol untuk setiap item
local excludeDistance = 20 -- Jarak awal untuk pengecualian (bisa diubah lewat slider)

-- Membuat slider untuk mengatur jarak pengecualian
local Slider = Tab:CreateSlider({
    Name = "Exclude Distance",
    Range = {0, 20}, -- Rentang slider (0-20 stud)
    Increment = 1, -- Nilai kenaikan setiap geser
    Suffix = " Studs",
    CurrentValue = excludeDistance, -- Nilai awal
    Flag = "ExcludeDistanceSlider",
    Callback = function(Value)
        excludeDistance = Value
        print("Exclude Distance set to:", excludeDistance)
    end,
})

-- Membuat tombol untuk setiap item dengan pengecualian jarak
for _, item in ipairs(items) do
    Tab:CreateButton({
        Name = item .. " Teleport",
        Callback = function()
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            
            -- Validasi keberadaan HumanoidRootPart
            if not humanoidRootPart then
                warn("HumanoidRootPart not found.")
                return
            end
            
            -- Menyimpan posisi awal jika toggle aktif
            if returnToOriginal then
                originalPosition = humanoidRootPart.CFrame
            end
            
            -- Validasi folder Pickups
            local pickupsFolder = workspace:FindFirstChild("Pickups")
            if not pickupsFolder then
                warn("workspace.Pickups not found.")
                return
            end
            
            -- Validasi keberadaan item di folder Pickups
            local toolPart = pickupsFolder:FindFirstChild(item)
            if not toolPart or not toolPart:IsA("MeshPart") then
                warn(item .. " not found.")
                return
            end

            -- Mengukur jarak antara karakter dan item
            local distance = (humanoidRootPart.Position - toolPart.Position).Magnitude
            if distance <= excludeDistance then
                return
            end
            
            -- Teleportasi ke MeshPart
            humanoidRootPart.CFrame = toolPart.CFrame
            print("Teleport to", item)
            
            -- Tunggu 0.2 detik agar karakter sampai ke MeshPart
            task.wait(0.4)

            -- Memicu ProximityPrompt jika ada
            local proximityPrompt = toolPart:FindFirstChildOfClass("ProximityPrompt")
            if proximityPrompt then
                -- Bypass jarak dan penghalang
                proximityPrompt.RequiresLineOfSight = false
                proximityPrompt.MaxActivationDistance = math.huge -- Jarak tak terbatas

                fireproximityprompt(proximityPrompt, 0) -- Gunakan angka 0 untuk input keyboard
                task.wait(0.1) -- Tunggu singkat untuk pemrosesan
                fireproximityprompt(proximityPrompt, 1) -- Hentikan trigger dengan angka 1
            end
            
            -- Kembali ke posisi awal jika toggle aktif
            if returnToOriginal and originalPosition then
                wait(0.6) -- Delay sebelum kembali (opsional)
                humanoidRootPart.CFrame = originalPosition
                
                -- Drop item yang dipegang jika auto-drop aktif
                if autoDropHeldItem then
                    dropHeldItem()
                end
            end
        end,
    })
end
local autoTeleportToMoney = false
local autoReturnSavePos = false -- Status toggle untuk auto return save posisi
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

-- Membuat Toggle untuk Auto Return Save Position
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
        warn("HumanoidRootPart not found.")
        return
    end

    -- Validasi folder Pickups
    local pickupsFolder = workspace:FindFirstChild("Pickups")
    if not pickupsFolder then
        warn("workspace.Pickups not found.")
        return
    end

    -- Validasi keberadaan Money
    local moneyPart = pickupsFolder:FindFirstChild("Money")
    if not moneyPart or not moneyPart:IsA("MeshPart") then
        warn("Money MeshPart not found in workspace.Pickups.")
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
    if autoReturnSavePos and savedPosition then
        humanoidRootPart.CFrame = savedPosition
    else
        humanoidRootPart.CFrame = originalPosition
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
        end
    end,
})
local Section = Tab:CreateSection("player", true)
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
            activateSpeedBoost(selectedSpeedMultiplier)
        else
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
        task.wait(1) -- Tunggu karakter selesai dimuat
        attachLightToHead()
        adjustLightBrightness()
    end
end)
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
            warn("No valid players to teleport to.")
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
            warn("Failed teleport. Target player valid position.")
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
    Big = false
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

-- Fungsi untuk menangani ESP Big GEF
local function updateBigGEFESP()
    local bigGEF = workspace:FindFirstChild("GEF")
    if bigGEF and bigGEF:FindFirstChild("Head") and bigGEF:FindFirstChild("Health") then
        local head = bigGEF.Head
        local health = bigGEF.Health.Value
        local distance = getDistance(head.Position)
        updateESP(head, "Big GEF", health, distance)
    else
        warn("Big GEF not found or missing components")
    end
end

-- Membuat Toggle untuk Big GEF ESP
Tab:CreateToggle({
    Name = "ESP Big GEF",
    CurrentValue = false,
    Flag = "ESP_Big_GEF",
    Callback = function(value)
        ESPEnabled.Big = value
        if value then
            -- Sambungkan ke Heartbeat untuk memperbarui ESP
            ESPConnections.Big = RunService.Heartbeat:Connect(updateBigGEFESP)
        else
            -- Hapus koneksi jika toggle dimatikan
            if ESPConnections.Big then
                ESPConnections.Big:Disconnect()
                ESPConnections.Big = nil
            end
            -- Hapus ESP dari Big GEF jika ada
            local bigGEF = workspace:FindFirstChild("GEF")
            if bigGEF and bigGEF:FindFirstChild("Head") then
                local esp = bigGEF.Head:FindFirstChild("ESP_Billboard")
                if esp then esp:Destroy() end
            end
        end
    end,
})
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
    Name = "Sell Specific Selected Items",
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
local Section = Tab:CreateSection("buy",true)
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
local Section = Tab:CreateSection("shop",true) -- The 2nd argument is to tell if its only a Title and doesnt contain element
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
                    print("BuyItem for", itemName)
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
local Tab = Window:CreateTab("msc", 4483362458) -- Title, Image
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
    print("file created:", fullPath)
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
    else
        UserGameSettings.RotationType = Enum.RotationType.MovementRelative
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
        end
    end,
})


ArrayField:LoadConfiguration() --di bagian bawah semua kode
