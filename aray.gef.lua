-- getgenv().SecureMode = true

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window =
    Rayfield:CreateWindow(
    {
        Name = "H Deepmarian hb keyless",
        Icon = Home,
        LoadingTitle = "Rayfield Interface",
        LoadingSubtitle = "by -me",
        Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes
        DisableRayfieldPrompts = false,
        DisableBuildWarnings = false,
        ConfigurationSaving = {
            Enabled = false,
            FolderName = nil,
            FileName = "Big Hub"
        },
        Discord = {
            Enabled = false,
            Invite = "noinvitelink",
            RememberJoins = false
        },
        KeySystem = false,
        KeySettings = {
            Title = "Untitled",
            Subtitle = "Key System",
            Note = "No method of obtaining the key is provided",
            FileName = "nicefilees", 
            SaveKey = false,
            GrabKeyFromSite = false,
            Key = {"Hello"}
        }
    }
)
local Tab = Window:CreateTab("Tops", "anchor")
local Label =
    Tab:CreateLabel(
    "My script my Rules ,you love me or hate me i don't care",
    4483362458,
    Color3.fromRGB(255, 255, 255),
    false
)
local HttpService = game:GetService("HttpService")
local scriptURL = "https://raw.githubusercontent.com/nAlwspa/rayfield/refs/heads/main/fef.lua"
local scriptCode = "loadstring(game:HttpGet('" .. scriptURL .. "'))()"

-- Fungsi untuk menyalin ke clipboard (berfungsi di executor tertentu)
local function CopyToClipboard(text)
    if setclipboard then
        setclipboard(text)
    elseif toclipboard then
        toclipboard(text)
    elseif syn and syn.write_clipboard then
        syn.write_clipboard(text)
    else
        warn("Clipboard function not supported")
    end
end

-- Button untuk menyalin kode
local Button = Tab:CreateButton({
    Name = "Copy Loadstring",
    Callback = function()
        CopyToClipboard(scriptCode)
    end,
})

-- Input untuk mengupdate loadstring
local Input = Tab:CreateInput({
    Name = "Script",
    CurrentValue = scriptURL,
    PlaceholderText = "Enter new URL",
    RemoveTextAfterFocusLost = false,
    Flag = "Input1",
    Callback = function(Text)
        scriptCode = string.format(codeTemplate, Text)
    end,
})

-- Contoh cara mengubah teks input dari kode
Input:Set("loadstring(game:HttpGet('https://raw.githubusercontent.com/nAlwspa/rayfield/refs/heads/main/fef.lua'))()") -- Akan memperbarui input dan loadstring
-- Membuat Section untuk metode teleport
local Section = Tab:CreateSection("TP Method", true)

-- Daftar nama tools
local items = {
    "Bat",
    "Crowbar",
    "Food",
    "Hammer",
    "Handgun",
    "Lantern",
    "Money",
    "Soda",
    "Shotgun",
    "Shells",
    "Bullets",
    "Medkit",
    "GPS"
}

-- Variabel global
local returnToOriginal = false
local autoTriggerPrompt = false
local autoDropHeldItem = false
local originalPosition = nil
local excludeDistance = 20
local isPreviewActive = false
local isTeleporting = false
local previewBeams = {} 
local isPreviewActive = false
local teleportQueue = {} -- Antrian teleportasi

-- Toggle untuk kembali ke posisi awal
Tab:CreateToggle({
    Name = "Auto Return to Position",
    CurrentValue = false,
    Flag = "ReturnToggle",
    Callback = function(Value)
        returnToOriginal = Value
    end
})

-- Toggle untuk auto-trigger ProximityPrompt
Tab:CreateToggle({
    Name = "Auto pick items",
    CurrentValue = false,
    Flag = "AutoTriggerPromptToggle",
    Callback = function(Value)
        autoTriggerPrompt = Value
    end
})

-- Toggle untuk auto-drop item yang dipegang
Tab:CreateToggle({
    Name = "Auto Drop Items",
    CurrentValue = false,
    Flag = "AutoDropHeldItemToggle",
    Callback = function(Value)
        autoDropHeldItem = Value
    end
})
local function dropHeldItem()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local heldTool = character:FindFirstChildOfClass("Tool")

    if not heldTool then
        print("Not found.")
        return
    end

    task.wait(0.5) -- Delay sebelum drop item
    local dropItemEvent = game:GetService("ReplicatedStorage").Events:FindFirstChild("DropItem")
    
    if dropItemEvent then
        dropItemEvent:FireServer(heldTool)
        print("Drop:", heldTool.Name)
    else
        warn("not found")
    end
end

local function createPreviewCircle()
    if #previewBeams > 0 then
        return
    end -- Jika sudah ada, jangan buat lagi

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
    if not character then
        return
    end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        return
    end

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
    game:GetService("RunService").Heartbeat:Connect(
        function()
            if isPreviewActive then
                updateBeams() -- Perbarui posisi beam setiap frame
            end
        end
    )
end
local Section = Tab:CreateSection("Distance")
-- Toggle untuk mengaktifkan/menonaktifkan preview jarak
Tab:CreateToggle(
    {
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
        end
    }
)

-- Slider untuk mengatur jarak excludeDistance
Tab:CreateSlider(
    {
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
        end
    }
)
local Section = Tab:CreateSection("Item")
local function findNearestItemOutsideExcludeDistance(itemName)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

    if not humanoidRootPart then
        warn("HumanoidRootPart nf")
        return nil
    end

    local pickupsFolder = workspace:FindFirstChild("Pickups")
    if not pickupsFolder then
        warn("not found.")
        return nil
    end

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

-- Menambahkan opsi "None" untuk mencegah teleportasi langsung
table.insert(items, 1, "None")

-- Fungsi teleportasi dengan antrian
local function teleportToItem(item)
    if item == "None" then
        return -- Jika "None" dipilih, jangan lakukan apa pun
    end

    table.insert(teleportQueue, function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

        if not humanoidRootPart then
            warn("HumanoidRootPart not found.")
            table.remove(teleportQueue, 1) -- Hapus tugas yang gagal
            return
        end

        local nearestItem = findNearestItemOutsideExcludeDistance(item)
        if not nearestItem then
            warn("No " .. item .. " found.")
            table.remove(teleportQueue, 1) -- Hapus tugas yang gagal
            return
        end

        if returnToOriginal and not isTeleporting then
            originalPosition = humanoidRootPart.CFrame
            isTeleporting = true
            print("Position saved.")
        end

        humanoidRootPart.CFrame = nearestItem.CFrame
        print("Teleport")

        task.wait(0.2)

        if autoTriggerPrompt then
            local promptsTriggered = 0
            for _, descendant in ipairs(workspace:GetDescendants()) do
                if descendant:IsA("ProximityPrompt") then
                    local promptDistance = (humanoidRootPart.Position - descendant.Parent.Position).Magnitude
                    if promptDistance <= descendant.MaxActivationDistance then
                        fireproximityprompt(descendant, 0)
                        task.wait(0.2)
                        fireproximityprompt(descendant, 1)
                        promptsTriggered = promptsTriggered + 1
                    end
                end
            end
        end

        if returnToOriginal and originalPosition then
            task.wait(0.5)
            humanoidRootPart.CFrame = originalPosition
            print("Back")

            task.wait(0.3)
        end

        if autoDropHeldItem then
            dropHeldItem()
        end

        isTeleporting = false -- Reset status teleportasi
        table.remove(teleportQueue, 1) -- Hapus tugas yang telah selesai

        -- Jalankan tugas berikutnya jika ada dalam antrian
        if #teleportQueue > 0 then
            teleportQueue[1]()
        end
    end)

    -- Jika tidak ada teleportasi yang sedang berjalan, mulai proses pertama dalam antrian
    if #teleportQueue == 1 then
        teleportQueue[1]()
    end
end

-- Dropdown untuk memilih item dan teleport
Tab:CreateDropdown({
    Name = "Select Item to Teleport",
    Options = items,
    CurrentOption = {"None"}, -- Default None
    MultipleOptions = false,
    Flag = "ItemTeleportDropdown",
    Callback = function(Options)
        if Options[1] then
            teleportToItem(Options[1]) -- Jalankan teleportasi sesuai pilihan
        end
    end
})
local Section = Tab:CreateSection("Money")
local autoTeleportToMoney = false
local autoReturn = false -- Status toggle untuk auto return ke posisi sebelum teleport
local autoReturnSavePos = false -- Status toggle untuk auto return ke posisi yang disimpan
local savedPosition = nil -- Posisi yang disimpan
local Label = Tab:CreateLabel("Saved Position: None") -- Label untuk menampilkan posisi

-- Membuat Toggle untuk auto-teleport ke Money
Tab:CreateToggle(
    {
        Name = "Auto Get Money",
        CurrentValue = false,
        Flag = "AutoTeleportMoney",
        Callback = function(Value)
            autoTeleportToMoney = Value

            if autoTeleportToMoney then
                task.spawn(
                    function()
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
                    end
                )
            end
        end
    }
)

-- Membuat Toggle untuk Auto Return (kembali ke posisi sebelum teleport)
Tab:CreateToggle(
    {
        Name = "Auto Return",
        CurrentValue = false,
        Flag = "AutoReturn",
        Callback = function(Value)
            autoReturn = Value
        end
    }
)

-- Membuat Toggle untuk Auto Return to Saved Position
Tab:CreateToggle(
    {
        Name = "Auto Return to Saved Position",
        CurrentValue = false,
        Flag = "AutoReturnSavePos",
        Callback = function(Value)
            autoReturnSavePos = Value
        end
    }
)

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
Tab:CreateButton(
    {
        Name = "Save Current Position",
        Callback = function()
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

            if humanoidRootPart then
                savedPosition = humanoidRootPart.CFrame
                local positionText =
                    string.format(
                    "X: %.2f, Y: %.2f, Z: %.2f",
                    savedPosition.Position.X,
                    savedPosition.Position.Y,
                    savedPosition.Position.Z
                )
                Label:Set("Saved Position: " .. positionText)
                print("Save:", savedPosition)
            else
                warn("Error.")
            end
        end
    }
)

local Tab = Window:CreateTab("Shop", "store")
local Section = Tab:CreateSection("sell", true)
local autoSellAll = false -- Status toggle untuk Auto Sell All

-- Fungsi untuk menjual semua item di Backpack
local function sellAllItems()
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        return
    end

    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            game:GetService("ReplicatedStorage").Events.SellItem:FireServer(item)
            print("Sell item:", item.Name)
        end
    end
end

-- Toggle untuk Auto Sell All
Tab:CreateToggle(
    {
        Name = "Auto Sell All",
        CurrentValue = false,
        Flag = "AutoSellAllToggle",
        Callback = function(value)
            autoSellAll = value

            if autoSellAll then
                -- Menjalankan loop untuk menjual semua item secara berkala
                task.spawn(
                    function()
                        while autoSellAll do
                            sellAllItems()
                            task.wait(1) -- Delay untuk menghindari spam
                        end
                    end
                )
            end
        end
    }
)

local selectedItems = {} -- Menyimpan item yang dipilih dari dropdown
local sellSpecificSelected = false -- Status toggle untuk menjual item yang dipilih

-- Daftar nama item tetap, termasuk GPS
local predefinedItems = {
    "Hammer",
    "Handgun",
    "Medkit",
    "Bullets",
    "Bat",
    "Shotgun",
    "Shells",
    "Lantern",
    "Crowbar",
    "Money",
    "Soda",
    "Food",
    "GPS"
}

-- Fungsi untuk menjual item berdasarkan nama
local function sellItemByName(itemName)
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then
        return
    end

    for _, item in ipairs(backpack:GetChildren()) do
        if item.Name == itemName then
            game:GetService("ReplicatedStorage").Events.SellItem:FireServer(item)
            print("Sell item:", item.Name)
            break -- Hentikan loop setelah item ditemukan dan dijual
        end
    end
end

-- Dropdown untuk memilih item yang akan dijual
Tab:CreateDropdown(
    {
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
            print("Select:", selectedItems)
        end
    }
)

-- Toggle untuk menjual item yang dipilih di dropdown
local Section
Tab:CreateToggle(
    {
        Name = "Sell Specific Items",
        CurrentValue = false,
        Flag = "SellSpecificSelectedToggle",
        Callback = function(value)
            sellSpecificSelected = value
            print("Succes Sell:", sellSpecificSelected)

            if sellSpecificSelected then
                -- Menjual semua item yang dipilih saat toggle diaktifkan
                task.spawn(
                    function()
                        while sellSpecificSelected do
                            for _, itemName in ipairs(selectedItems) do
                                sellItemByName(itemName)
                            end
                            task.wait(1) -- Delay untuk menghindari spam
                        end
                    end
                )
            end
        end
    }
)
local Section = Tab:CreateSection("upgrade", true) -- The 2nd argument is to tell if its only a Title and doesnt contain element
-- Membuat Button untuk MaxStamina
Tab:CreateButton(
    {
        Name = "Purchase Max Stamina",
        Callback = function()
            local args = {
                [1] = "MaxStamina"
            }
            game:GetService("ReplicatedStorage").Events.PurchaseEvent:FireServer(unpack(args))
            print("Buying MaxStamina")
        end
    }
)

-- Membuat Button untuk StaminaRegen
Tab:CreateButton(
    {
        Name = "Purchase Stamina Regen",
        Callback = function()
            local args = {
                [1] = "StaminaRegen"
            }
            game:GetService("ReplicatedStorage").Events.PurchaseEvent:FireServer(unpack(args))
            print("Buying StaminaRegen")
        end
    }
)

-- Membuat Button untuk Storage
Tab:CreateButton(
    {
        Name = "Purchase Storage",
        Callback = function()
            local args = {
                [1] = "Storage"
            }
            game:GetService("ReplicatedStorage").Events.PurchaseEvent:FireServer(unpack(args))
            print("Buying Storage")
        end
    }
)
local Section = Tab:CreateSection("shop")
local itemDropdown -- Variabel untuk menyimpan dropdown
local connection -- Variabel untuk menyimpan koneksi event pemantauan
local itemMap = {} -- Peta item untuk pencocokan nama

local function autoBuyItem(item)
    game:GetService("ReplicatedStorage").Events.BuyItem:FireServer(item)
    print("Buy ", item.Name)
end

local function updateDropdown()
    local itemOptions = {"None"} -- Tambahkan opsi default "None"
    itemMap = {}

    for _, building in ipairs(workspace.Buildings:GetChildren()) do
        if building:IsA("Model") and building:FindFirstChild("Nodes") then
            local nodes = building:FindFirstChild("Nodes")
            local room = nodes and nodes:FindFirstChild("Room")
            local shop = room and room:FindFirstChild("Shop")
            local proximityPromptFolder = shop and shop:FindFirstChild("ProximityPrompt")
            local itemFolder = proximityPromptFolder and proximityPromptFolder:FindFirstChild("Folder")

            if itemFolder then
                for _, item in ipairs(itemFolder:GetChildren()) do
                    if item:IsA("ValueBase") then
                        local itemName = string.format("[%s]:[%s]", item.Name, tostring(item.Value))
                        table.insert(itemOptions, itemName)
                        itemMap[itemName] = item
                    end
                end
            end
        end
    end
    
    -- Update dropdown dengan daftar item baru
    if itemDropdown then
        itemDropdown:Set(itemOptions)
    else
        -- Jika dropdown belum ada, buat yang baru
        itemDropdown = Tab:CreateDropdown({
            Name = "Shop Items",
            Options = itemOptions,
            CurrentOption = {"None"},
            MultipleOptions = false,
            Flag = "ItemDropdown",
            Callback = function(selected)
                if selected[1] ~= "None" then
                    local selectedItem = itemMap[selected[1]]
                    if selectedItem then
                        autoBuyItem(selectedItem)
                    end
                end
            end,
        })
    end
end

local function startScanning()
    updateDropdown()
    connection = workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("ValueBase") then
            updateDropdown()
        end
    end)
    workspace.DescendantRemoving:Connect(function(obj)
        if obj:IsA("ValueBase") then
            updateDropdown()
        end
    end)
end

local function stopScanning()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

Tab:CreateToggle({
    Name = "On/off Shop",
    Default = false,
    Callback = function(state)
        if state then
            startScanning()
        else
            stopScanning()
        end
    end,
})
local Tab = Window:CreateTab("Players", "users-round")
local Button = Tab:CreateButton({
    Name = "kill our self character",
    Callback = function()
       local player = game.Players.LocalPlayer
       if player and player.Character and player.Character:FindFirstChild("Humanoid") then
          player.Character.Humanoid.Health = 0
       end
    end,
 })
 local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local noclipConnection

local function Noclip()
    noclipConnection = RunService.Stepped:Connect(function()
        if character then
            for _, child in pairs(character:GetDescendants()) do
                if child:IsA("BasePart") and child.CanCollide == true then
                    child.CanCollide = false
                end
            end
        end
    end)
end

local function Unnoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
    end
    if character then
        local lowerTorso = character:FindFirstChild("LowerTorso")
        local upperTorso = character:FindFirstChild("UpperTorso")
        local humanoid = character:FindFirstChildOfClass("Humanoid")

        if lowerTorso then lowerTorso.CanCollide = true end
        if upperTorso then upperTorso.CanCollide = true end
        if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end
    end
end

local Toggle = Tab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Flag = "NoclipToggle",
   Callback = function(Value)
      if Value then
         Noclip()
      else
         Unnoclip()
      end
   end,
})
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")

local speed = 16 -- Default speed
local speedLoopEnabled = false
local speedLoopConnection

local function SetSpeed(value)
    if humanoid then
        humanoid.WalkSpeed = value
    end
end

local function SpeedOn()
    if not speedLoopEnabled then
        speedLoopEnabled = true
        SetSpeed(speed)
        speedLoopConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if humanoid.WalkSpeed ~= speed then
                humanoid.WalkSpeed = speed
            end
        end)
    end
end

local function SpeedOff()
    if speedLoopEnabled then
        speedLoopEnabled = false
        if speedLoopConnection then
            speedLoopConnection:Disconnect()
            speedLoopConnection = nil
        end
        humanoid.WalkSpeed = 16 -- Kembali ke kecepatan default
    end
end

local ToggleSpeed = Tab:CreateToggle({
   Name = "Speed Toggle",
   CurrentValue = false,
   Flag = "SpeedToggle",
   Callback = function(Value)
      if Value then
         SpeedOn()
      else
         SpeedOff()
      end
   end,
})

local SpeedInput = Tab:CreateInput({
   Name = "Set Speed",
   CurrentValue = tostring(speed),
   PlaceholderText = "Masukkan Kecepatan",
   RemoveTextAfterFocusLost = false,
   Flag = "SpeedInput",
   Callback = function(Text)
      local newSpeed = tonumber(Text)
      if newSpeed and newSpeed > 0 then
         speed = newSpeed
         if speedLoopEnabled then
            SetSpeed(speed)
         end
      end
   end,
})

local Section = Tab:CreateSection("Players")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

Tab:CreateButton(
    {
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
                
            else
                warn("Failed Error.")
            end
        end
    }
)
local InfJumpEnabled = false

-- Toggle untuk Infinite Jump
Tab:CreateToggle(
    {
        Name = "InfJump",
        CurrentValue = false,
        Flag = "InfJumpToggle",
        Callback = function(Value)
            InfJumpEnabled = Value
            if InfJumpEnabled then
                local UserInputService = game:GetService("UserInputService")
                UserInputService.JumpRequest:Connect(
                    function()
                        if InfJumpEnabled then
                            local player = game.Players.LocalPlayer
                            local character = player.Character or player.CharacterAdded:Wait()
                            local humanoid = character:FindFirstChildOfClass("Humanoid")
                            if humanoid then
                                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                            end
                        end
                    end
                )
            end
        end
    }
)

local gefsConnection, sgefConnection
local gefToggle =
    Tab:CreateToggle(
    {
        Name = "Godmode",
        CurrentValue = false,
        Flag = "Toggle_GEF",
        Callback = function(Value)
            if Value then
                -- Start detecting and destroying Hurtbox for Mini GEF & Tiny GEF
                gefsConnection =
                    workspace.GEFs.ChildAdded:Connect(
                    function(child)
                        if (child.Name == "Mini GEF" or child.Name == "Tiny GEF") and child:FindFirstChild("Hurtbox") then
                            child.Hurtbox:Destroy()
                        end
                    end
                )

                -- Destroy existing Hurtbox for Mini GEF & Tiny GEF
                for _, gef in ipairs(workspace.GEFs:GetChildren()) do
                    if (gef.Name == "Mini GEF" or gef.Name == "Tiny GEF") and gef:FindFirstChild("Hurtbox") then
                        gef.Hurtbox:Destroy()
                    end
                end
            else
                -- Stop detecting new Mini GEFs & Tiny GEFs
                if gefsConnection then
                    gefsConnection:Disconnect()
                    gefsConnection = nil
                end
            end
        end
    }
)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Backpack = LocalPlayer:WaitForChild("Backpack")

-- Toggle untuk Fast Eat Food
local ToggleState = false
local Toggle = Tab:CreateToggle({
   Name = "Fast Eat Food",
   CurrentValue = false,
   Flag = "AutoEatToggle",
   Callback = function(Value)
      ToggleState = Value
   end,
})

-- Toggle untuk Fast Heal Medkit
local HealingEnabled = false
local ToggleHeal = Tab:CreateToggle({
   Name = "Fast Heal Medkit",
   CurrentValue = false,
   Flag = "HealingToggle",
   Callback = function(Value)
      HealingEnabled = Value
   end,
})

local function check()
    if not ToggleState then return end -- Hanya berjalan jika toggle aktif

    local Player = game:GetService("Players").LocalPlayer
    local Character = Player.Character
    local Backpack = Player.Backpack
    local MaxStamina = Player.Upgrades:FindFirstChild("MaxStamina") and Player.Upgrades.MaxStamina.Value or 1
    local Energy = workspace:FindFirstChild(Player.Name) and workspace[Player.Name]:FindFirstChild("Energy")

    -- Hitung MaxEnergy berdasarkan MaxStamina (1 = 70, 4 = 100)
    local MinStamina, MaxStaminaValue = 1, 4
    local MinEnergy, MaxEnergy = 70, 100
    local CurrentMaxEnergy = math.clamp(MinEnergy + ((MaxStamina - MinStamina) / (MaxStaminaValue - MinStamina)) * (MaxEnergy - MinEnergy), MinEnergy, MaxEnergy)

    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local HealthFull = Humanoid and Humanoid.Health >= 100
    local EnergyFull = Energy and Energy.Value >= CurrentMaxEnergy

    -- Hanya makan jika setidaknya salah satu nilai belum penuh
    if HealthFull and EnergyFull then return end

    -- Cari Food di workspace.LocalPlayer.Food
    local Tool = workspace:FindFirstChild(Player.Name) and workspace[Player.Name]:FindFirstChild("Food")

    if Tool then
        local Progress = Tool:FindFirstChild("Progress")
        local EatEvent = Tool:FindFirstChild("Eat")

        if Progress and EatEvent and Progress:IsA("NumberValue") then
            Progress.Value = 1 -- Set progress ke penuh
            EatEvent:FireServer() -- Kirim event makan ke server
        end
    end
end

-- Fungsi untuk penyembuhan otomatis
local function HealPlayer()
    if not HealingEnabled then return end -- Tidak melakukan apa-apa jika toggle OFF

    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    if Humanoid and Humanoid.Health >= 100 then return end -- Tidak heal jika darah penuh

    local Tool = Character:FindFirstChild("Medkit")
    if Tool then
        local Progress = Tool:FindFirstChild("Progress")
        if Progress and Progress:IsA("NumberValue") then
            Progress.Value = 1
        end

        local HealEvent = Tool:FindFirstChild("Heal")
        if HealEvent and HealEvent:IsA("RemoteEvent") then
            HealEvent:FireServer()
        end

        
    end
end

-- Loop untuk menjalankan fungsi setiap frame
RunService.Heartbeat:Connect(check)
RunService.Heartbeat:Connect(HealPlayer)
-- Loop untuk mengecek setiap frame
RunService.Heartbeat:Connect(check)
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
        local isDay =
            ReplicatedStorage:FindFirstChild("ServerSettings") and
            ReplicatedStorage.ServerSettings:FindFirstChild("Day") and
            ReplicatedStorage.ServerSettings.Day.Value

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
        warn("Character not found..")
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
Tab:CreateToggle(
    {
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
        end
    }
)

-- Menangani perubahan waktu (Day/Night)
if ReplicatedStorage:FindFirstChild("ServerSettings") and ReplicatedStorage.ServerSettings:FindFirstChild("Day") then
    ReplicatedStorage.ServerSettings.Day:GetPropertyChangedSignal("Value"):Connect(
        function()
            if lightEnabled then
                adjustLightBrightness()
            end
        end
    )
end

-- Menangani respawn pemain (agar cahaya tetap ada setelah respawn)
LocalPlayer.CharacterAdded:Connect(
    function()
        if lightEnabled then
            task.wait(0.6) -- Tunggu karakter selesai dimuat
            attachLightToHead()
            adjustLightBrightness()
        end
    end
)
local Toggle =
    Tab:CreateToggle(
    {
        Name = "fullbright",
        CurrentValue = false,
        Flag = "Togg99", -- Identifier unik
        Callback = function(Value)
            local lighting = game:GetService("Lighting")
            -- Variable untuk menyimpan koneksi event
            local fullBrightConnection

            if Value then
                -- Aktifkan full bright
                fullBrightConnection =
                    lighting:GetPropertyChangedSignal("ClockTime"):Connect(
                    function()
                        -- Pastikan ClockTime tetap pada nilai terang
                        lighting.Brightness = 3
                        lighting.ClockTime = 14
                        lighting.FogEnd = 1e10
                        lighting.GlobalShadows = false
                    end
                )

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
        end
    }
)
local autoSpawn = false -- Status toggle auto-spawn

-- Membuat Toggle untuk Auto-Spawn
Tab:CreateToggle(
    {
        Name = "Auto-Spawn",
        CurrentValue = false,
        Flag = "AutoSpawnToggle",
        Callback = function(Value)
            autoSpawn = Value

            if autoSpawn then
                task.spawn(
                    function()
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
                    end
                )
            end
        end
    }
)
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
    if not tool or not tool:FindFirstChild("Handle") then
        return
    end

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
    tool.GripPos = Vector3.new(0, 0, 2)
    speaker.Character:FindFirstChildOfClass("Humanoid"):UnequipTools()
end

local function removeHitbox(tool)
    if not tool or not tool:FindFirstChild("Handle") then
        return
    end

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

local ToggleBat =
    Tab:CreateToggle(
    {
        Name = "Hitbox Bat",
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
        end
    }
)

local ToggleCrowbar =
    Tab:CreateToggle(
    {
        Name = "Hitbox Crowbar",
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
        end
    }
)

local SliderBat =
    Tab:CreateSlider(
    {
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
        end
    }
)

local SliderCrowbar =
    Tab:CreateSlider(
    {
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
        end
    }
)
local toggleActive = false -- Status toggle

-- Toggle UI dari library yang Anda gunakan
local Toggle =
    Tab:CreateToggle(
    {
        Name = "One Hit",
        CurrentValue = false,
        Flag = "Toggle_Particleemit",
        Callback = function(Value)
            toggleActive = Value -- Ubah status toggle
            if toggleActive then
                startDetectingParticles()
            else
                stopDetectingParticles()
            end
        end
    }
)

-- Fungsi untuk mendeteksi dan menghapus ParticleEmitter
local function deleteParticles()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            obj:Destroy()
        end
    end
end

local connection  -- Menyimpan koneksi event

-- Fungsi untuk mulai deteksi otomatis
function startDetectingParticles()
    deleteParticles() -- Hapus partikel yang sudah ada

    connection =
        workspace.DescendantAdded:Connect(
        function(obj)
            if toggleActive and obj:IsA("ParticleEmitter") then
                obj:Destroy()
            end
        end
    )
end

-- Fungsi untuk menghentikan deteksi otomatis
function stopDetectingParticles()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end
local StaminaRegenInput =
    Tab:CreateInput(
    {
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
    }
)

local MaxStaminaInput =
    Tab:CreateInput(
    {
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
    }
)
local RunService = game:GetService("RunService")
local GEFs = workspace:FindFirstChild("GEFs")

if not GEFs then
    warn("Found Nothing!")
end

-- Variabel untuk toggle status
local isRunning = false
local heartbeatConnection -- Variabel untuk menyimpan koneksi Heartbeat

-- Fungsi untuk mengecek dan menghapus GoTo
local function checking()
    if not isRunning then return end -- Jika toggle tidak aktif, hentikan proses
    
    for _, gef in ipairs(GEFs:GetChildren()) do
        if gef:IsA("Model") and (gef.Name:find("Mini GEF") or gef.Name:find("Tiny GEF")) then
            local goTo = gef:FindFirstChild("GoTo")
            if goTo then
                goTo:Destroy()
            end
        end
    end
end

-- Fungsi untuk mengontrol toggle
local Toggle = Tab:CreateToggle({
   Name = "Auto Ghost",
   CurrentValue = false,
   Flag = "AutoRemove",
   Callback = function(Value)
       isRunning = Value -- Mengubah status toggle
       
       if isRunning then
           -- Mulai deteksi dengan Heartbeat jika belum berjalan
           if not heartbeatConnection then
               heartbeatConnection = RunService.Heartbeat:Connect(checking)
               
           end
       else
           -- Hentikan deteksi dengan memutus koneksi
           if heartbeatConnection then
               heartbeatConnection:Disconnect()
               heartbeatConnection = nil
               
           end
       end
   end,
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

gefsHitboxToggle =
    Tab:CreateToggle(
    {
        Name = "hitbox Gefs",
        CurrentValue = false,
        Flag = "Toggle33",
        Callback = function(Value)
            if Value then
                -- Simpan ukuran asli Hitbox jika belum disimpan
                saveOriginalHitboxSizes()

                -- Hubungkan event untuk Mini GEF yang baru ditambahkan
                gefsConnection =
                    workspace.GEFs.ChildAdded:Connect(
                    function(child)
                        if child.Name == "Mini GEF" then
                            local hitbox = child:FindFirstChild("Hitbox")
                            if hitbox then
                                -- Simpan ukuran asli Hitbox
                                originalHitboxSizes[child] = hitbox.Size
                                -- Ubah ukuran Hitbox
                                hitbox.Size = Vector3.new(gefsHitboxSlider, gefsHitboxSlider, gefsHitboxSlider)
                            end
                        end
                    end
                )

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
        end
    }
)

sgefHitboxToggle =
    Tab:CreateToggle(
    {
        Name = "hitbox sgef",
        CurrentValue = false,
        Flag = "Toggle34",
        Callback = function(Value)
            if Value then
                -- Simpan ukuran asli Hitbox jika belum disimpan
                saveOriginalHitboxSizes()

                -- Hubungkan event untuk Tiny GEF yang baru ditambahkan
                sgefConnection =
                    workspace.GEFs.ChildAdded:Connect(
                    function(child)
                        if child.Name == "Tiny GEF" then
                            local hitbox = child:FindFirstChild("Hitbox")
                            if hitbox then
                                -- Simpan ukuran asli Hitbox
                                originalHitboxSizes[child] = hitbox.Size
                                -- Ubah ukuran Hitbox
                                hitbox.Size = Vector3.new(sgefHitboxSlider, sgefHitboxSlider, sgefHitboxSlider)
                            end
                        end
                    end
                )

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
        end
    }
)

gefsHitboxSlider =
    Tab:CreateSlider(
    {
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
        end
    }
)

sgefHitboxSlider =
    Tab:CreateSlider(
    {
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
        end
    }
)
local Section = Tab:CreateSection("Esp")
local Section = Tab:CreateSection("esp player")
local espActive = false
local displayName = false
local displayHealth = false
local displayDistance = false
local displayInventory = false

local espElements = {}

local function getHealthColor(health)
    if health <= 10 then
        return Color3.fromRGB(255, 0, 0) -- Merah
    elseif health <= 60 then
        return Color3.fromRGB(255, 165, 0) -- Orange
    else
        return Color3.fromRGB(0, 255, 0) -- Hijau
    end
end

local function getInventoryValue(player)
    local stats = workspace:FindFirstChild(player.Name) and workspace[player.Name]:FindFirstChild("Stats")
    local inventory = stats and stats:FindFirstChild("Inventory")
    return inventory and inventory.Value or "N/A"
end

local function removeESP(player)
    if espElements[player] then
        espElements[player]:Destroy()
        espElements[player] = nil
    end
end

local function createOrUpdateESP(player)
    if player == game.Players.LocalPlayer then return end

    local character = player.Character
    if not character then return end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoidRootPart or not humanoid then return end

    -- Hapus ESP lama sebelum membuat yang baru
    removeESP(player)

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = humanoidRootPart
    billboard.Size = UDim2.new(0, 200, 0, 70)
    billboard.AlwaysOnTop = true
    billboard.Name = "PlayerESP"

    local function createLabel(name, position, color)
        local label = Instance.new("TextLabel")
        label.Name = name
        label.Size = UDim2.new(1, 0, 0.2, 0)
        label.Position = UDim2.new(0, 0, position, 0)
        label.BackgroundTransparency = 1
        label.TextScaled = true
        label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        label.Parent = billboard
        return label
    end

    createLabel("NameLabel", 0)
    createLabel("HealthLabel", 0.2)
    createLabel("DistanceLabel", 0.4, Color3.fromRGB(0, 255, 255))
    createLabel("InventoryLabel", 0.6, Color3.fromRGB(255, 255, 0))

    billboard.Parent = humanoidRootPart
    espElements[player] = billboard

    local function updateESP()
        if not espElements[player] then return end
        local nameLabel = billboard:FindFirstChild("NameLabel")
        local healthLabel = billboard:FindFirstChild("HealthLabel")
        local distanceLabel = billboard:FindFirstChild("DistanceLabel")
        local inventoryLabel = billboard:FindFirstChild("InventoryLabel")

        if nameLabel then
            nameLabel.Text = player.Name
            nameLabel.Visible = displayName and espActive
        end

        if healthLabel then
            healthLabel.Text = "Health: " .. math.floor(humanoid.Health)
            healthLabel.TextColor3 = getHealthColor(humanoid.Health)
            healthLabel.Visible = displayHealth and espActive
        end

        if distanceLabel then
            local localPlayer = game.Players.LocalPlayer
            local distance = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and
                (localPlayer.Character.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude or 0
            distanceLabel.Text = "Distance: " .. math.floor(distance)
            distanceLabel.Visible = displayDistance and espActive
        end

        if inventoryLabel then
            inventoryLabel.Text = "Inventory: " .. getInventoryValue(player)
            inventoryLabel.Visible = displayInventory and espActive
        end
    end

    -- Update ESP setiap detik
    task.spawn(function()
        while espActive and character.Parent do
            updateESP()
            task.wait(1)
        end
    end)

    -- Hapus ESP jika pemain mati
    humanoid.Died:Connect(function()
        removeESP(player)
    end)
end

local function removeAllESP()
    for _, billboard in pairs(espElements) do
        if billboard then billboard:Destroy() end
    end
    espElements = {}
end

-- Tambah listener saat pemain respawn
game.Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if espActive then
            task.wait(1) -- Tunggu character ter-load
            createOrUpdateESP(player)
        end
    end)
end)

-- ESP Toggles
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
    end
})

Tab:CreateToggle({
    Name = "Display Name",
    CurrentValue = false,
    Flag = "DisplayName",
    Callback = function(Value)
        displayName = Value
    end
})

Tab:CreateToggle({
    Name = "Display Health",
    CurrentValue = false,
    Flag = "DisplayHealth",
    Callback = function(Value)
        displayHealth = Value
    end
})

Tab:CreateToggle({
    Name = "Display Distance",
    CurrentValue = false,
    Flag = "DisplayDistance",
    Callback = function(Value)
        displayDistance = Value
    end
})

Tab:CreateToggle({
    Name = "Display Inventory",
    CurrentValue = false,
    Flag = "DisplayInventory",
    Callback = function(Value)
        displayInventory = Value
    end
})
-- Pastikan update ESP jika toggle diubah
task.spawn(function()
    while true do
        if espActive then
            for _, player in pairs(game.Players:GetPlayers()) do
                if espElements[player] then
                    createOrUpdateESP(player)
                end
            end
        end
        task.wait(1)
    end
end)
local ESP_Toggle = false
local ESP_Connection

local function ApplyESP(pickup)
    if pickup:IsA("BasePart") or pickup:IsA("MeshPart") then
        -- Highlight
        if not pickup:FindFirstChild("ESP_Highlight") then
            local highlight = Instance.new("Highlight")
            highlight.Parent = pickup
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.Name = "ESP_Highlight"
        end

        -- BillboardGui (Text)
        if not pickup:FindFirstChild("ESP_Billboard") then
            local billboard = Instance.new("BillboardGui")
            billboard.Parent = pickup
            billboard.Size = UDim2.new(4, 0, 1, 0)
            billboard.StudsOffset = Vector3.new(0, 2, 0)
            billboard.AlwaysOnTop = true
            billboard.Name = "ESP_Billboard"

            local textLabel = Instance.new("TextLabel")
            textLabel.Parent = billboard
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = pickup.Name
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            textLabel.TextScaled = true
            textLabel.Font = Enum.Font.SourceSansBold
        end
    end
end

local function RemoveESP(pickup)
    if pickup:FindFirstChild("ESP_Highlight") then
        pickup.ESP_Highlight:Destroy()
    end
    if pickup:FindFirstChild("ESP_Billboard") then
        pickup.ESP_Billboard:Destroy()
    end
end

local function ToggleESP(Value)
    ESP_Toggle = Value
    if ESP_Toggle then
        -- Pasang ESP ke semua item yang ada
        for _, pickup in ipairs(workspace.Pickups:GetChildren()) do
            ApplyESP(pickup)
        end

        -- Loop untuk mendeteksi item baru
        ESP_Connection = workspace.Pickups.ChildAdded:Connect(function(pickup)
            task.wait(0.1) -- Tunggu sedikit agar item ter-load
            ApplyESP(pickup)
        end)
    else
        -- Hapus semua ESP
        for _, pickup in ipairs(workspace.Pickups:GetChildren()) do
            RemoveESP(pickup)
        end

        -- Matikan listener
        if ESP_Connection then
            ESP_Connection:Disconnect()
            ESP_Connection = nil
        end
    end
end

local Toggle = Tab:CreateToggle({
    Name = "ESP All Item",
    CurrentValue = false,
    Flag = "ToggleESP",
    Callback = function(Value)
        ToggleESP(Value)
    end
})
local Section = Tab:CreateSection("Gef esp")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Variabel ESP
local ESPEnabled = {
    MiniGEF = false,
    TinyGEF = false,
    BigGEF = false
}
local activeESP = {
    MiniGEF = {},
    TinyGEF = {},
    BigGEF = {}
}

-- Utility: Menghitung jarak
local function getDistance(position)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    return hrp and (hrp.Position - position).Magnitude or math.huge
end

-- Utility: Buat ESP
local function createESP(object, text, color, category)
    if not object or not category then return end

    -- Hapus ESP lama di kategori ini
    if activeESP[category] then
        for _, esp in ipairs(activeESP[category]) do
            if esp and esp.Parent then
                esp:Destroy()
            end
        end
    end
    activeESP[category] = {}

    -- Buat BillboardGui baru
    local billboard = Instance.new("BillboardGui")
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
    textLabel.TextColor3 = color
    textLabel.Text = text

    billboard.Parent = object
    table.insert(activeESP[category], billboard)
end

-- Hapus ESP kategori tertentu
local function clearESPByCategory(category)
    for _, esp in ipairs(activeESP[category]) do
        if esp and esp.Parent then
            esp:Destroy()
        end
    end
    activeESP[category] = {}
end

-- Update ESP berdasarkan model
local function updateModelESP(modelName, category, partName, isEnabled)
    if not isEnabled then
        clearESPByCategory(category)
        return
    end

    local model
    if modelName == "Big GEF" then
        model = workspace:FindFirstChild("GEF") -- 🔧 Perbaikan di sini
    else
        local gefs = workspace:FindFirstChild("GEFs")
        if gefs then
            for _, m in ipairs(gefs:GetChildren()) do
                if m:IsA("Model") and m.Name == modelName then
                    model = m
                    break
                end
            end
        end
    end

    if not model then return end

    local part = model:FindFirstChild(partName)
    local health = model:FindFirstChild("Health")

    if part and health and health:IsA("NumberValue") then
        local distance = getDistance(part.Position)
        local healthValue = health.Value

        -- Warna berdasarkan health
        local color = Color3.new(0, 1, 0) -- Hijau
        if healthValue < 10 then
            color = Color3.new(1, 0, 0) -- Merah
        elseif healthValue < 60 then
            color = Color3.new(1, 0.5, 0) -- Oranye
        end

        createESP(part, modelName .. "\nHealth: " .. healthValue .. "\nDistance: " .. math.floor(distance), color, category)
    end
end

-- Toggle ESP Mini GEF
Tab:CreateToggle({
    Name = "ESP Mini GEF",
    CurrentValue = false,
    Flag = "MiniGEFESP",
    Callback = function(value)
        ESPEnabled.MiniGEF = value
    end
})

-- Toggle ESP Tiny GEF
Tab:CreateToggle({
    Name = "ESP Tiny GEF",
    CurrentValue = false,
    Flag = "TinyGEFESP",
    Callback = function(value)
        ESPEnabled.TinyGEF = value
    end
})

-- Toggle ESP Big GEF
Tab:CreateToggle({
    Name = "ESP Big GEF",
    CurrentValue = false,
    Flag = "BigGEFESP",
    Callback = function(value)
        ESPEnabled.BigGEF = value
    end
})

-- Loop Update ESP
RunService.RenderStepped:Connect(function()
    updateModelESP("Mini GEF", "MiniGEF", "Head", ESPEnabled.MiniGEF)
    updateModelESP("Tiny GEF", "TinyGEF", "Head", ESPEnabled.TinyGEF)
    updateModelESP("Big GEF", "BigGEF", "RootPart", ESPEnabled.BigGEF) -- 🔧 Sekarang fix
end)
local Section = Tab:CreateSection("Building")
local espList = {} -- Simpan semua ESP yang dibuat

local Toggle = Tab:CreateToggle({
    Name = "ESP Shop",
    CurrentValue = false,
    Flag = "ToggleESP",
    Callback = function(Value)
        if Value then
            -- Aktifkan ESP untuk semua Shop
            local buildings = workspace:FindFirstChild("Buildings")

            if buildings then
                for _, house in ipairs(buildings:GetChildren()) do
                    local shop = house:FindFirstChild("Shop")
                    if shop then
                        -- Buat BillboardGui (ESP Text)
                        local esp = Instance.new("BillboardGui")
                        esp.Size = UDim2.new(0, 100, 0, 50)
                        esp.Adornee = shop
                        esp.StudsOffset = Vector3.new(0, 5, 0) -- Geser ke atas Shop
                        esp.AlwaysOnTop = true
                        esp.Parent = shop

                        -- Buat TextLabel
                        local label = Instance.new("TextLabel")
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundTransparency = 1
                        label.Text = "Shop"
                        label.TextColor3 = Color3.fromRGB(255, 255, 0)
                        label.TextScaled = true
                        label.Font = Enum.Font.SourceSansBold
                        label.Parent = esp

                        -- Simpan ESP ke dalam daftar
                        table.insert(espList, esp)
                    end
                end
            end
        else
            -- Hapus semua ESP jika toggle dimatikan
            for _, esp in ipairs(espList) do
                if esp then
                    esp:Destroy()
                end
            end
            espList = {} -- Kosongkan daftar ESP
        end
    end,
})
local ESPs = {} -- Menyimpan semua ESP yang dibuat

local function createESP(target)
    if target and not ESPs[target] then
        -- Buat BillboardGui (ESP Text)
        local esp = Instance.new("BillboardGui")
        esp.Size = UDim2.new(0, 100, 0, 50)
        esp.Adornee = target
        esp.StudsOffset = Vector3.new(0, 5, 0) -- Posisi di atas target
        esp.AlwaysOnTop = true
        esp.Parent = target

        -- Buat TextLabel
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "Tower"
        label.TextColor3 = Color3.fromRGB(255, 0, 0) -- Warna merah
        label.TextScaled = true
        label.Font = Enum.Font.SourceSansBold
        label.Parent = esp

        -- Simpan ESP agar bisa dihapus nanti
        ESPs[target] = esp
    end
end

local function removeAllESP()
    for _, esp in pairs(ESPs) do
        if esp then
            esp:Destroy()
        end
    end
    ESPs = {} -- Kosongkan daftar ESP
end

local Toggle = Tab:CreateToggle({
    Name = "Toggle ESP Tower",
    CurrentValue = false,
    Flag = "ToggleESPTower",
    Callback = function(Value)
        if Value then
            -- Aktifkan ESP untuk semua Tower
            local buildings = workspace:FindFirstChild("Buildings")
            if buildings then
                for _, obj in ipairs(buildings:GetChildren()) do
                    if obj.Name:find("Tower") then -- Cek jika nama mengandung "Tower"
                        createESP(obj)
                    end
                end
            end
        else
            -- Hapus semua ESP jika toggle dimatikan
            removeAllESP()
        end
    end,
})
local Tab = Window:CreateTab("Misc", "braces")
local Button = Tab:CreateButton({
    Name = "destroy gui",
    Callback = function()
       Rayfield:Destroy()
    end,
 }) 
local Section = Tab:CreateSection("server", true) -- The 2nd argument is to tell if its only a Title and doesnt contain element
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local currentPlaceId = game.PlaceId -- ID tempat saat ini
local currentJobId = game.JobId -- ID server saat ini

-- Fungsi untuk mendapatkan waktu saat ini dalam format yang sesuai
local function getCurrentDateTime()
    local date = os.date("*t") -- Ambil waktu saat ini
    return string.format(
        "%04d-%02d-%02d_%02d-%02d-%02d",
        date.year,
        date.month,
        date.day,
        date.hour,
        date.min,
        date.sec
    )
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
    local fileContent =
        string.format('-- Log teleport\nlocal placeId = %d\nlocal jobId = "%s"\n\n', currentPlaceId, currentJobId)
    if errorMessage then
        fileContent = fileContent .. string.format("-- Error:\n%s\n", errorMessage)
    end

    -- Simpan file
    writefile(fullPath, fileContent)
    print("Log file at:", fullPath)
end

-- Buat tombol
Tab:CreateButton(
    {
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
            local success, err =
                pcall(
                function()
                    TeleportService:TeleportToPlaceInstance(currentPlaceId, currentJobId, player)
                end
            )

            -- Tangani jika teleport gagal atau berhasil
            if not success then
                local errorMessage = "Teleport failed: " .. tostring(err)
                warn(errorMessage)
                createLogFile(errorMessage)
            else
                print("Teleport")
                createLogFile() -- Buat log tanpa error
            end
        end
    }
)
Tab:CreateButton(
    {
        Name = "Infinite Yield",
        Interact = "Click run another script",
        Callback = function()
            -- Eksekusi script Infinite Yield
            local success, err =
                pcall(
                function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
                end
            )

            -- Tangani jika terjadi error
            if not success then
                warn("Failed to execute Infinite Yield")
            end
        end
    }
)
Tab:CreateButton(
    {
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
                
            end
        end
    }
) 
local Section = Tab:CreateSection("stats")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

isStatsActive = false

local Paragraph = Tab:CreateParagraph({Title = "Stats Info", Content = "waiting data/toggle on..."})

local function updateParagraph()
    if not isStatsActive then return end 

    local upgrades = LocalPlayer:FindFirstChild("Upgrades")
    local stats = LocalPlayer:FindFirstChild("Stats")
    local character = LocalPlayer.Character
    local workspaceStats = workspace:FindFirstChild(LocalPlayer.Name) -- Ganti dengan nama LocalPlayer
    local serverSettings = ReplicatedStorage:FindFirstChild("ServerSettings")
    local gefRoot = workspace:FindFirstChild("GEF")

    if not (upgrades and stats and workspaceStats and serverSettings) then
        print("Missing data:", upgrades and "Upgrades" or "nil", stats and "Stats" or "nil", workspaceStats and "WorkspaceStats" or "nil", serverSettings and "ServerSettings" or "nil")
        Paragraph:Set({Title = "Stats Info", Content = "waiting"})
        return
    end

    local function getValue(instance, path)
        local target = instance
        for _, part in ipairs(path) do
            target = target and target:FindFirstChild(part)
            if not target then return "nil" end
        end
        return target.Value
    end

    local bullets = getValue(workspaceStats, {"Ammo", "Bullets"})
    local days = getValue(workspaceStats, {"Stats", "Days"})
    local difficulty = getValue(workspaceStats, {"Vars", "Difficulty"})
    local energy = getValue(workspaceStats, {"Energy"})
    local gefsKilled = getValue(workspaceStats, {"Stats", "GefsKilled"})
    local inventory = getValue(workspaceStats, {"Stats", "Inventory"})
    local maxStamina = getValue(upgrades, {"MaxStamina"})
    local playtime = getValue(stats, {"Playtime"})
    local shells = getValue(workspaceStats, {"Ammo", "Shells"})
    local staminaRegen = getValue(upgrades, {"StaminaRegen"})
    local storage = getValue(upgrades, {"Storage"})
    local timeSurvived = getValue(workspaceStats, {"Stats", "TimeSurvived"})

    local healthStatus = "Unknown"
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            healthStatus = humanoid.Health > 0 and "Alive" or "Dead"
        end
    end

    local bigGefStatus = "❌"
    if gefRoot and gefRoot:FindFirstChild("RootPart") and gefRoot.RootPart:FindFirstChild("ShatterHitbox") then
        bigGefStatus = "✅"
    end

    local dayValue = serverSettings:FindFirstChild("Day")
    local timeStatus = (dayValue and dayValue.Value) and "Time is: Day" or "Time is: Night"

    Paragraph:Set({
        Title = "Stats Info",
        Content = "Big Gef: " .. bigGefStatus ..
            "\nBullets: " .. bullets ..
            "\nDays count: " .. days ..
            "\nDifficulty: " .. difficulty ..
            "\nEnergy: " .. energy ..
            "\nGefs Killed: " .. gefsKilled ..
            "\nHealth: " .. healthStatus ..
            "\nInventory: " .. inventory ..
            "\nMax Stamina lvl: " .. maxStamina ..
            "\nPlaytime: " .. playtime ..
            "\nShells: " .. shells ..
            "\nStamina Regen lvl: " .. staminaRegen ..
            "\nStorage lvl: " .. storage ..
            "\nTime Survived: " .. timeSurvived ..
            "\n" .. timeStatus
    })
end

local renderConnection

local Toggle = Tab:CreateToggle({
    Name = "activate Stats",
    CurrentValue = false,
    Flag = "ToggleStats",
    Callback = function(state)
        isStatsActive = state
        
        if isStatsActive then
            if not renderConnection then
                renderConnection = RunService.RenderStepped:Connect(updateParagraph)
            end
        else
            if renderConnection then
                renderConnection:Disconnect()
                renderConnection = nil
            end
            Paragraph:Set({Title = "Stats Info", Content = "waiting data/toggle on..."})
        end
    end
})
local Tab = Window:CreateTab("Autobuilding", "hammer")
local houseOptions = {
    "None", -- Tambahkan opsi None agar tidak langsung memuat skrip
    "House One",
    "Large House One"
}

-- Fungsi untuk memuat skrip berdasarkan pilihan dropdown
local function loadHouseScript(houseName)
    if houseName == "House One" then
        print("Loading House One...")
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/wipff2/gef/refs/heads/main/houseone"))()
        end)
        if success then
            Rayfield:Notify({
                Title = "Success",
                Content = "House One loaded successfully!",
                Duration = 6.5,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to load House One: " .. tostring(err),
                Duration = 6.5,
                Image = 4483362458,
            })
        end
    elseif houseName == "Large House One" then
        print("Loading Large House One...")
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/wipff2/gef/refs/heads/main/largehouse"))()
        end)
        if success then
            Rayfield:Notify({
                Title = "Success",
                Content = "Large House One loaded successfully!",
                Duration = 6.5,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to load Large House One: " .. tostring(err),
                Duration = 6.5,
                Image = 4483362458,
            })
        end
    end
end

-- Dropdown untuk memilih dan menjalankan skrip rumah
Tab:CreateDropdown({
    Name = "Select House",
    Options = houseOptions,
    CurrentOption = {"None"}, -- Default None
    MultipleOptions = false,
    Flag = "HouseDropdown",
    Callback = function(Options)
        if Options[1] and Options[1] ~= "None" then
            loadHouseScript(Options[1]) -- Jalankan skrip sesuai pilihan dropdown
        end
    end
})
