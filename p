local Tab = Window:CreateTab("Autobuilding", "hammer")

local houseOptions = {
    "None", -- Tambahkan opsi None agar tidak langsung memuat skrip
    "House One",
    "Large House One",
    "MarketCity", -- Tambahkan opsi Market City
    "MiniHouse",
    "houseidk",
    "Housefloor",
    "Tower"
}

-- Fungsi untuk memuat skrip berdasarkan pilihan dropdown
local function loadHouseScript(houseName)
    if houseName == "House One" then
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
    elseif houseName == "MarketCity" then
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/wipff2/Plank/refs/heads/main/market"))()
        end)
        if success then
            Rayfield:Notify({
                Title = "Success",
                Content = "Market City loaded successfully!",
                Duration = 6.5,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to load Market City: " .. tostring(err),
                Duration = 6.5,
                Image = 4483362458,
            })
        end
    elseif houseName == "MiniHouse" then
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/wipff2/Plank/refs/heads/main/mini%20house"))()
        end)
        if success then
            Rayfield:Notify({
                Title = "Success",
                Content = "Market City loaded successfully!",
                Duration = 6.5,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to load Market City: " .. tostring(err),
                Duration = 6.5,
                Image = 4483362458,
            })
        end
    elseif houseName == "houseidk" then
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/wipff2/Plank/refs/heads/main/house%20garage"))()
        end)
        if success then
            Rayfield:Notify({
                Title = "Success",
                Content = "Market City loaded successfully!",
                Duration = 6.5,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to load Market City: " .. tostring(err),
                Duration = 6.5,
                Image = 4483362458,
            })
        end
    elseif houseName == "Housefloor" then
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/wipff2/Plank/refs/heads/main/house%20garage"))()
        end)
        if success then
            Rayfield:Notify({
                Title = "Success",
                Content = "Market City loaded successfully!",
                Duration = 6.5,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to load Market City: " .. tostring(err),
                Duration = 6.5,
                Image = 4483362458,
            })
        end
    elseif houseName == "tower" then
        local success, err = pcall(function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/wipff2/Plank/refs/heads/main/Tower"))()
        end)
        if success then
            Rayfield:Notify({
                Title = "Success",
                Content = "Market City loaded successfully!",
                Duration = 6.5,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Failed to load Market City: " .. tostring(err),
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