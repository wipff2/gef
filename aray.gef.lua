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
        toclipboard(text)"
    elseif syn and syn.write_clipboard then
        syn.write_clipboard(text)
    else
        warn("Clipboard function not supported")
    end
end

-- Button untuk menyalin kode
local Button = Tab:CreateButton({
    Name = "Copy Script,
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
Input:Set("loadstring(game:HttpGet('https://raw.githubusercontent.com/nAlwspa/rayfield/refs/heads/main/fef.lua'))()")
local Section = Tab:CreateSection("Items", true)

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
    end

    -- Optimasi: Kurangi jumlah beam untuk performa lebih baik
    local numBeams = 16 -- Dikurangi dari 30 untuk performa lebih baik
    local angleIncrement = (2 * math.pi) / numBeams

    for i = 1, numBeams do
        local beamPart = Instance.new("Part")
        beamPart.Size = Vector3.new(0.3, 0.3, 0.3) -- Sedikit lebih besar untuk kompensasi jumlah yang lebih sedikit
        beamPart.Transparency = 0.7 -- Lebih transparan
        beamPart.Material = Enum.Material.Neon -- Material yang lebih ringan
        beamPart.Color = Color3.new(1, 0, 0)
        beamPart.Anchored = true
        beamPart.CanCollide = false
        beamPart.CastShadow = false -- Nonaktifkan shadow untuk performa
        beamPart.Parent = workspace

        table.insert(previewBeams, beamPart)
    end
end

local function destroyPreviewCircle()
    for _, beam in ipairs(previewBeams) do
        beam:Destroy()
    end
    previewBeams = {}
end

-- Optimasi: Cache variabel untuk menghindari perhitungan berulang
local lastPosition = nil
local updateCounter = 0
local UPDATE_FREQUENCY = 1 -- Update setiap 3 frame (bukan setiap frame)

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

    local currentPosition = humanoidRootPart.Position
    
    -- Optimasi: Skip update jika posisi tidak berubah signifikan
    if lastPosition and (currentPosition - lastPosition).Magnitude < 0.1 then
        return
    end
    
    lastPosition = currentPosition

    local numBeams = #previewBeams
    local angleIncrement = (2 * math.pi) / numBeams

    for i, beam in ipairs(previewBeams) do
        local angle = i * angleIncrement
        local x = math.cos(angle) * excludeDistance
        local z = math.sin(angle) * excludeDistance
        local beamPosition = currentPosition + Vector3.new(x, 0, z)

        beam.Position = beamPosition -- Gunakan Position saja, bukan CFrame untuk yang sederhana
    end
end

local function startUpdatingBeams()
    local heartbeat = game:GetService("RunService").Heartbeat
    
    heartbeat:Connect(function()
        if not isPreviewActive then
            return
        end
        
        -- Optimasi: Update tidak setiap frame, tapi setiap beberapa frame
        updateCounter = (updateCounter + 1) % UPDATE_FREQUENCY
        if updateCounter == 0 then
            updateBeams()
        end
    end)
end

-- Alternatif yang lebih efisien: Gunakan Part tunggal dengan Mesh
local function createOptimizedPreviewCircle()
    if previewCircle then
        return
    end

    -- Buat part tunggal dengan SpecialMesh untuk lingkaran
    local circlePart = Instance.new("Part")
    circlePart.Name = "PreviewCircle"
    circlePart.Size = Vector3.new(excludeDistance * 2, 0.1, excludeDistance * 2)
    circlePart.Transparency = 0.8
    circlePart.Color = Color3.new(1, 0, 0)
    circlePart.Material = Enum.Material.Neon
    circlePart.Anchored = true
    circlePart.CanCollide = false
    circlePart.CastShadow = false
    
    local mesh = Instance.new("CylinderMesh")
    mesh.Parent = circlePart
    
    circlePart.Parent = workspace
    previewCircle = circlePart
end

local function updateOptimizedCircle()
    if not previewCircle then
        return
    end
    
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local humanoidRootPart = character.HumanoidRootPart
    previewCircle.Position = humanoidRootPart.Position + Vector3.new(0, -2.5, 0) -- Posisikan di bawah karakter
end
Tab:CreateToggle(
    {
        Name = "Show Distance Exclude",
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

Tab:CreateSlider(
    {
        Name = "Exclude Number",
        Range = {0, 20},
        Increment = 1,
        Suffix = " Studs",
        CurrentValue = excludeDistance,
        Flag = "ExcludeDistanceSlider",
        Callback = function(Value)
            excludeDistance = Value
            if isPreviewActive then
                updateBeams()
            end
        end
    }
)
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

table.insert(items, 1, "None")

local function teleportToItem(item)
    if item == "None" then
        return
    end

    table.insert(teleportQueue, function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

        if not humanoidRootPart then
            warn("HumanoidRootPart not found.")
            table.remove(teleportQueue, 1)
            return
        end

        -- Optimasi: Nonaktifkan fisika sementara selama teleport
        local bodyVelocity = humanoidRootPart:FindFirstChild("BodyVelocity")
        local bodyGyro = humanoidRootPart:FindFirstChild("BodyGyro")
        
        -- Buat anchor sementara untuk stabilisasi
        local tempAnchor = Instance.new("BodyVelocity")
        tempAnchor.Velocity = Vector3.new(0, 0, 0)
        tempAnchor.MaxForce = Vector3.new(0, 0, 0) -- Awalnya nonaktif
        tempAnchor.Parent = humanoidRootPart

        local nearestItem = findNearestItemOutsideExcludeDistance(item)
        if not nearestItem then
            warn("No " .. item .. " found.")
            tempAnchor:Destroy()
            table.remove(teleportQueue, 1)
            return
        end

        if returnToOriginal and not isTeleporting then
            originalPosition = humanoidRootPart.CFrame
            isTeleporting = true
        end

        -- Stabilisasi sebelum teleport
        humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        
        -- Teleport dengan offset yang aman
        local teleportCFrame = nearestItem.CFrame + Vector3.new(0, 3, 0) -- Offset vertikal
        humanoidRootPart.CFrame = teleportCFrame
        
        -- Aktifkan stabilisasi setelah teleport
        tempAnchor.MaxForce = Vector3.new(4000, 4000, 4000) -- Force moderat
        tempAnchor.Velocity = Vector3.new(0, 0, 0)

        task.wait(0.1) -- Tunggu sebentar untuk stabil

        if autoTriggerPrompt then
            local promptsTriggered = 0
            for _, descendant in ipairs(workspace:GetDescendants()) do
                if descendant:IsA("ProximityPrompt") then
                    local promptDistance = (humanoidRootPart.Position - descendant.Parent.Position).Magnitude
                    if promptDistance <= descendant.MaxActivationDistance then
                        fireproximityprompt(descendant, 0)
                        task.wait(0.15) -- Tunggu lebih singkat
                        fireproximityprompt(descendant, 1)
                        promptsTriggered = promptsTriggered + 1
                        
                        if promptsTriggered >= 2 then break end
                    end
                end
            end
        end

        if returnToOriginal and originalPosition then
            task.wait(0.3) -- Tunggu lebih singkat
            
            -- Stabilisasi sebelum kembali
            humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            
            -- Kembali dengan offset aman
            local returnCFrame = originalPosition + Vector3.new(0, 3, 0)
            humanoidRootPart.CFrame = returnCFrame
            
            -- Stabilisasi setelah kembali
            tempAnchor.Velocity = Vector3.new(0, 0, 0)
            
            print("Back")
            task.wait(0.2)
        end

        -- Bersihkan stabilisasi setelah delay
        task.wait(0.1)
        tempAnchor:Destroy()

        if autoDropHeldItem then
            dropHeldItem()
        end

        isTeleporting = false
        table.remove(teleportQueue, 1)

        -- Jalankan tugas berikutnya jika ada
        if #teleportQueue > 0 then
            task.wait(0.3) -- Tunggu sebentar sebelum teleport berikutnya
            teleportQueue[1]()
        end
    end)

    if #teleportQueue == 1 then
        teleportQueue[1]()
    end
end

-- Fungsi alternatif yang lebih stabil menggunakan TweenService
local function smoothTeleportToItem(item)
    if item == "None" then
        return
    end

    table.insert(teleportQueue, function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

        if not humanoidRootPart then
            table.remove(teleportQueue, 1)
            return
        end

        local nearestItem = findNearestItemOutsideExcludeDistance(item)
        if not nearestItem then
            table.remove(teleportQueue, 1)
            return
        end

        -- Nonaktifkan gravitasi sementara untuk karakter
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true -- Mencegah interupsi fisika
        end

        -- Reset velocity
        humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

        if returnToOriginal and not isTeleporting then
            originalPosition = humanoidRootPart.CFrame
            isTeleporting = true
        end

        local targetCFrame = nearestItem.CFrame + Vector3.new(0, 2.5, 0)
        humanoidRootPart.CFrame = targetCFrame
        
        task.wait(0.1)

        if autoTriggerPrompt then
            local region = Region3.new(
                humanoidRootPart.Position - Vector3.new(10, 10, 10),
                humanoidRootPart.Position + Vector3.new(10, 10, 10)
            )
            local parts = workspace:FindPartsInRegion3(region, nil, 50)
            
            for _, part in ipairs(parts) do
                local prompt = part:FindFirstChildOfClass("ProximityPrompt")
                if prompt then
                    fireproximityprompt(prompt, 0)
                    task.wait(0.1)
                    fireproximityprompt(prompt, 1)
                    break
                end
            end
        end

        if returnToOriginal and originalPosition then
            task.wait(0.2)
            
            -- Reset velocity lagi sebelum kembali
            humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            
            local returnCFrame = originalPosition + Vector3.new(0, 2.5, 0)
            humanoidRootPart.CFrame = returnCFrame
            
            task.wait(0.1)
        end

        -- Kembalikan kontrol ke player
        if humanoid then
            humanoid.PlatformStand = false
        end

        if autoDropHeldItem then
            task.wait(0.1)
            dropHeldItem()
        end

        isTeleporting = false
        table.remove(teleportQueue, 1)

        if #teleportQueue > 0 then
            task.wait(0.4) -- Delay lebih panjang antar teleport
            teleportQueue[1]()
        end
    end)

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
local autoSellAll = false 
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

local selectedItems = {} 
local sellSpecificSelected = false

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
local Section = Tab:CreateSection("upgrade", true)
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
   PlaceholderText = "input here",
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

    local MinStamina, MaxStaminaValue = 1, 4
    local MinEnergy, MaxEnergy = 70, 100
    local CurrentMaxEnergy = math.clamp(MinEnergy + ((MaxStamina - MinStamina) / (MaxStaminaValue - MinStamina)) * (MaxEnergy - MinEnergy), MinEnergy, MaxEnergy)

    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local HealthFull = Humanoid and Humanoid.Health >= 100
    local EnergyFull = Energy and Energy.Value >= CurrentMaxEnergy

    if HealthFull and EnergyFull then return end

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

RunService.Heartbeat:Connect(check)
RunService.Heartbeat:Connect(HealPlayer)
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
            lightInstance.Brightness = 1.6 -- Cahaya kecil saat siang
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
------
local Section = Tab:CreateSection("Tools")
local toolNames = {"Bat", "Crowbar", "Crowbars"}

local function getEquippedTool()
    local character = game.Players.LocalPlayer.Character
    if character then
        for _, tool in pairs(character:GetChildren()) do
            if tool:IsA("Tool") and table.find(toolNames, tool.Name) then
                return tool
            end
        end
    end
end

local function setHitboxSize(tool, size)
    if tool and tool:FindFirstChild("Handle") then
        tool.Handle.Size = Vector3.new(size, size, size)
        tool.GripPos = Vector3.new(0, 0, 2)
    end
end

local function resetHitboxSize(tool)
    if tool and tool:FindFirstChild("Handle") then
        tool.Handle.Size = Vector3.new(4, 4, 4) -- Ukuran default
        tool.GripPos = Vector3.new(0, 0, 0)
    end
end

local ToggleBat = Tab:CreateToggle({
    Name = "Hitbox Bat",
    CurrentValue = false,
    Flag = "ToggleBat",
    Callback = function(Value)
        local tool = getEquippedTool()
        if tool and tool.Name == "Bat" then
            if Value then
                setHitboxSize(tool, 30)
            else
                resetHitboxSize(tool)
            end
        end
    end
})

local ToggleCrowbar = Tab:CreateToggle({
    Name = "Hitbox Crowbar",
    CurrentValue = false,
    Flag = "ToggleCrowbar",
    Callback = function(Value)
        local tool = getEquippedTool()
        if tool and (tool.Name == "Crowbar" or tool.Name == "Crowbars") then
            if Value then
                setHitboxSize(tool, 30)
            else
                resetHitboxSize(tool)
            end
        end
    end
})
--------
local gefsHitboxToggle, sgefHitboxToggle

local function updateHitboxSize(name, size)
    for _, gef in ipairs(workspace.GEFs:GetChildren()) do
        if gef.Name == name then
            local hitbox = gef:FindFirstChild("Hitbox")
            if hitbox then
                hitbox.Size = Vector3.new(size, size, size)
            end
        end
    end
end

gefsHitboxToggle = Tab:CreateToggle({
    Name = "hitbox Gefs",
    CurrentValue = false,
    Flag = "Toggle33",
    Callback = function(Value)
        updateHitboxSize("Mini GEF", Value and 30 or 4)
    end
})

sgefHitboxToggle = Tab:CreateToggle({
    Name = "hitbox sgef",
    CurrentValue = false,
    Flag = "Toggle34",
    Callback = function(Value)
        updateHitboxSize("Tiny GEF", Value and 30 or 4)
    end
})
--------
local toggleActive = false
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

local function deleteParticles()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") then
            obj:Destroy()
        end
    end
end

local connection
function startDetectingParticles()
    deleteParticles()

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

local isRunning = false
local heartbeatConnection
local function checking()
    if not isRunning then return end
    
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
local Section = Tab:CreateSection("Esp")
local Section = Tab:CreateSection("esp player")
local espActive = true
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

-- ESP Configuration
local ESPEnabled = {
    MiniGEF = false,
    TinyGEF = false,
    GEF = false
}
local ESPs = {}

-- Utility: Menghitung jarak dari pemain
local function getDistance(position)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    return hrp and (hrp.Position - position).Magnitude or math.huge
end

-- Membuat ESP
local function createESP(rootPart, text, category, color)
    if not rootPart or ESPs[rootPart] then return end

    local BillboardGui = Instance.new("BillboardGui")
    BillboardGui.Parent = game.CoreGui
    BillboardGui.Adornee = rootPart
    BillboardGui.Size = UDim2.new(0, 200, 0, 50)
    BillboardGui.StudsOffset = Vector3.new(0, 3, 0)
    BillboardGui.AlwaysOnTop = true

    local TextLabel = Instance.new("TextLabel", BillboardGui)
    TextLabel.Size = UDim2.new(1, 0, 1, 0)
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextScaled = true
    TextLabel.TextColor3 = color
    TextLabel.Font = Enum.Font.SourceSansBold
    TextLabel.Text = text

    ESPs[rootPart] = BillboardGui
end

-- Menghapus ESP jika GEF dihapus
local function removeESP(rootPart)
    if ESPs[rootPart] then
        ESPs[rootPart]:Destroy()
        ESPs[rootPart] = nil
    end
end

-- Update ESP untuk semua GEF
local function updateESP()
    local existingGEFs = {}

    -- Cek GEF utama di workspace
    for _, gef in ipairs(workspace:GetChildren()) do
        if gef:IsA("Model") and gef:FindFirstChild("RootPart") and ESPEnabled.GEF then
            local rootPart = gef.RootPart
            local distance = getDistance(rootPart.Position)
            createESP(rootPart, "GEF\nDistance: " .. math.floor(distance), "GEF", Color3.new(1, 0, 0))
            existingGEFs[rootPart] = true
        end
    end

    -- Cek Mini GEF & Tiny GEF di workspace.GEFs
    local gefsFolder = workspace:FindFirstChild("GEFs")
    if gefsFolder then
        for _, model in ipairs(gefsFolder:GetChildren()) do
            if model:IsA("Model") and model:FindFirstChild("Head") then
                local category = ESPEnabled.MiniGEF and model.Name == "Mini GEF" and "MiniGEF" or
                                 ESPEnabled.TinyGEF and model.Name == "Tiny GEF" and "TinyGEF" or nil

                if category then
                    local rootPart = model.Head
                    local distance = getDistance(rootPart.Position)
                    createESP(rootPart, model.Name .. "\nDistance: " .. math.floor(distance), category, Color3.new(0, 1, 0))
                    existingGEFs[rootPart] = true
                end
            end
        end
    end

    -- Hapus ESP jika GEF sudah tidak ada
    for rootPart, _ in pairs(ESPs) do
        if not existingGEFs[rootPart] or not rootPart:IsDescendantOf(workspace) then
            removeESP(rootPart)
        end
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

-- Toggle ESP GEF
Tab:CreateToggle({
    Name = "ESP GEF",
    CurrentValue = false,
    Flag = "GEFESP",
    Callback = function(value)
        ESPEnabled.GEF = value
    end
})

-- Loop untuk update ESP
RunService.RenderStepped:Connect(updateESP)
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
                        esp.Size = UDim2.new(0, 90, 0, 50)
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
        esp.Size = UDim2.new(0, 90, 0, 50)
        esp.Adornee = target
        esp.StudsOffset = Vector3.new(0, 5, 0) -- Posisi di atas target
        esp.AlwaysOnTop = true
        esp.Parent = target

        -- Buat TextLabel
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 0.6
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
local Section = Tab:CreateSection("server", true)
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local currentPlaceId = game.PlaceId
local currentJobId = game.JobId

local function getCurrentDateTime()
    local date = os.date("*t")
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
    task.wait(2)
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
                local errorMessage = "Teleport failed: Missing data."
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
                task.wait(2)
                print("Teleport")
                createLogFile() -- Buat log tanpa error
            end
        end
    }
)
Tab:CreateButton(
    {
        Name = "Infinite Yield",
        Interact = "Click run script",
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
-- Button Fix Lag (Aman untuk trees)
Tab:CreateButton(
    {
        Name = "Fix Lag",
        Interact = "Click",
        Callback = function()
            -- Optimasi part yang tidak penting tanpa menghancurkan trees
            local optimized = 0
            
            -- Hapus part kecil/dekorasi yang tidak penting
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Part") then
                    -- Hapus part yang sangat kecil (dekorasi)
                    if obj.Size.Magnitude < 2 and obj.Transparency > 0.8 then
                        obj:Destroy()
                        optimized = optimized + 1
                    -- Nonaktifkan collision untuk part dekorasi
                    elseif obj.Name:lower():find("decoration") or obj.Name:lower():find("effect") then
                        obj.CanCollide = false
                        obj.CastShadow = false
                        optimized = optimized + 1
                    end
                -- Hapus partikel effect yang berat
                elseif obj:IsA("ParticleEmitter") then
                    if obj.Name:lower():find("smoke") or obj.Name:lower():find("spark") then
                        obj:Destroy()
                        optimized = optimized + 1
                    end
                -- Optimasi lighting
                elseif obj:IsA("PointLight") or obj:IsA("SpotLight") then
                    if obj.Range > 50 then
                        obj.Enabled = false
                        optimized = optimized + 1
                    end
                end
            end
            
            -- Clear debris (part yang jatuh)
            game:GetService("Debris"):ClearAllChildren()
            
            -- Optimasi graphics settings
            local lighting = game:GetService("Lighting")
            lighting.GlobalShadows = false
            lighting.FogEnd = 1000
            
        end
    }
)

-- Button No Render (Reduce Graphics)
Tab:CreateButton(
    {
        Name = "No Render⚠️",
        Interact = "Click", 
        Callback = function()
            local players = game:GetService("Players")
            local lighting = game:GetService("Lighting")
            local runService = game:GetService("RunService")
            
            -- Extreme graphics reduction
            lighting.GlobalShadows = false
            lighting.FogEnd = 100
            lighting.Brightness = 2
            lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            
            -- Remove all lighting effects
            for _, effect in ipairs(lighting:GetChildren()) do
                if effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or 
                   effect:IsA("ColorCorrectionEffect") or effect:IsA("BloomEffect") then
                    effect.Enabled = false
                end
            end
            
            -- Optimize terrain
            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                terrain.Decoration = false
                terrain.WaterReflection = false
                terrain.WaterTransparency = 0.5
            end
            
            -- Hide distant objects
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Part") then
                    if (obj.Position - players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > 200 then
                        obj.Transparency = 1
                        obj.CanCollide = false
                    end
                end
            end
            
            print("No Render activated - Extreme performance mode")
        end
    }
)

-- Button Destroy Terraria (Hanya untuk game Terraria-like)
Tab:CreateButton(
    {
        Name = "Destroy Terraria⚠️",
        Interact = "Click",
        Callback = function()
            local destroyed = 0
            
            -- Hancurkan block/terrain yang umum di game Terraria
            local terrariaBlocks = {
                 "stone", "dirt", "sand", "clay", "mud", 
                 "tree", "ore", "copper", "iron", "silver", "gold",
                 "brick", "marble", "granite", "ice", "snow"
            }
            
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Part") then
                    local nameLower = obj.Name:lower()
                    
                    -- Cek apakah ini block terraria
                    for _, blockName in ipairs(terrariaBlocks) do
                        if nameLower:find(blockName) then
                            -- Hancurkan block yang jauh dari player
                            local player = game.Players.LocalPlayer
                            if player and player.Character then
                                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                                if hrp and (obj.Position - hrp.Position).Magnitude > 50 then
                                    obj:Destroy()
                                    destroyed = destroyed + 1
                                    break
                                end
                            end
                        end
                    end
                    
                    -- Hancurkan part yang sangat kecil (dekorasi)
                    if obj.Size.Magnitude < 1 and obj.Transparency == 0 then
                        obj:Destroy()
                        destroyed = destroyed + 1
                    end
                end
                
                -- Hancurkan model terraria yang umum
                if obj:IsA("Model") then
                    local nameLower = obj.Name:lower()
                    if nameLower:find("tree") or nameLower:find("rock") or nameLower:find("boulder") then
                        local player = game.Players.LocalPlayer
                        if player and player.Character then
                            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                            if hrp and (obj:GetExtentsSize() - hrp.Position).Magnitude > 100 then
                                obj:Destroy()
                                destroyed = destroyed + 1
                            end
                        end
                    end
                end
            end
            
            print("Destroyed " .. destroyed .. " Terraria objects")
        end
    }
)
local Section = Tab:CreateSection("stats")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
isStatsActive = false

local Paragraph = Tab:CreateParagraph({Title = "Stats Info", Content = "waiting data.."})

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

    local GEFStatus = "❌"
    if gefRoot and gefRoot:FindFirstChild("RootPart") and gefRoot.RootPart:FindFirstChild("ShatterHitbox") then
        GEFStatus = "✅"
    end

    local dayValue = serverSettings:FindFirstChild("Day")
    local timeStatus = (dayValue and dayValue.Value) and "Time is: Day" or "Time is: Night"

    Paragraph:Set({
        Title = "Stats Info",
        Content = "GEF: " .. GEFStatus ..
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
    Name = "activ monitor",
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
    "Large House One",
    "houseidk",
    "MiniHouse",
    "MarketCity",
    "Market2"
}

local housePositions = {
    ["Tower"] = Vector3.new(-449, 61, 219),
    ["Housefloor"] = Vector3.new(-297, 9, 362),
    ["houseidk"] = Vector3.new(554, 7, 486),
    ["MiniHouse"] = Vector3.new(-30, 10, -139),
    ["MarketCity"] = Vector3.new(-64, 8, 377),
    ["Market2"] = Vector3.new(21, 8, 308)
}

-- Fungsi untuk memuat skrip berdasarkan pilihan dropdown
local function loadHouseScript(houseName)
    local urls = {
        ["House One"] = "https://raw.githubusercontent.com/wipff2/gef/refs/heads/main/houseone",
        ["Large House One"] = "https://raw.githubusercontent.com/wipff2/gef/refs/heads/main/largehouse",
        ["MarketCity"] = "https://raw.githubusercontent.com/wipff2/Plank/refs/heads/main/market",
        ["Market2"] = "https://raw.githubusercontent.com/wipff2/Plank/refs/heads/main/market2%20city",
        ["MiniHouse"] = "https://raw.githubusercontent.com/wipff2/Plank/refs/heads/main/mini%20house",
        ["houseidk"] = "https://raw.githubusercontent.com/wipff2/Plank/refs/heads/main/house%20garage",
        ["Housefloor"] = "https://raw.githubusercontent.com/wipff2/Plank/refs/heads/main/house2garage",
        ["Tower"] = "https://raw.githubusercontent.com/wipff2/Plank/refs/heads/main/Tower"
    }
    
    if urls[houseName] then
        local success, err = pcall(function()
            loadstring(game:HttpGet(urls[houseName]))()
        end)
        
        Rayfield:Notify({
            Title = success and "Success" or "Error",
            Content = success and (houseName .. " success!") or ("Failed to load " .. houseName .. ": " .. tostring(err)),
            Duration = 6.5,
            Image = 4483362458,
        })
    end
end

local selectedHouse = "None" -- Variabel global untuk menyimpan pilihan terakhir

Tab:CreateDropdown({
    Name = "Select House",
    Options = houseOptions,
    CurrentOption = {"None"},
    MultipleOptions = false,
    Flag = "HouseDropdown",
    Callback = function(Options)
        selectedHouse = Options[1] -- Simpan pilihan terakhir
        print("Dropdown selected:", selectedHouse) -- Debugging
        if selectedHouse ~= "None" then
            loadHouseScript(selectedHouse)
        end
    end
})

Tab:CreateButton({
    Name = "Teleport to House",
    Callback = function()
        print("Using selectedHouse:", selectedHouse) -- Debugging
        if housePositions[selectedHouse] then
            local character = game.Players.LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = CFrame.new(housePositions[selectedHouse])
                Rayfield:Notify({
                    Title = "Teleported!",
                    Content = "You have been teleported to " .. selectedHouse .. "!",
                    Duration = 6.5,
                    Image = 4483362458,
                })
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Teleport failed. Character not found!",
                    Duration = 6.5,
                    Image = 4483362458,
                })
            end
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "No valid house selected for teleportation!",
                Duration = 6.5,
                Image = 4483362458,
            })
        end
    end
})
local Paragraph = Tab:CreateParagraph({Title = "how to stop build?", Content = "unequip tool, die/rejoin"})