-- Initialize the UI
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- Create a ScreenGui if it doesn't exist
local screenGui = PlayerGui:FindFirstChild("DiscordLinkGui")
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "KtfRhdg"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
end

-- Create the TextLabel
local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 100, 0, 20)
label.Position = UDim2.new(0.5, -50, 0.8, -30)  -- Positioned above the button
label.BackgroundTransparency = 1  -- Set background transparency to 1
label.Text = "ViRetro HUB"
label.TextColor3 = Color3.new(1, 1, 1)  -- Optional: set text color to white
label.Parent = screenGui

-- Create the TextButton
local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 100, 0, 20)  -- Smaller size: width 100, height 20
button.Position = UDim2.new(0.5, -50, 0.8, -10)  -- 20% up from the bottom
button.BackgroundTransparency = 1  -- Set background transparency to 1
button.Text = "Copy Dc Link!!"
button.Parent = screenGui

-- Copy to clipboard function
local function copyToClipboard()
    setclipboard("https://discord.gg/Y7XvfFrD")
    button.Text = "Copied"
    wait(2)
    button.Text = "Click Me!!!"
end

-- Connect the button click to the function
button.MouseButton1Click:Connect(copyToClipboard)

wait(18)
screenGui:Destroy()