-- Bhop Hub by Artifaqt
-- CS 1.6 Style Bunny Hop Physics for Roblox
-- Modular Version - Main Loader

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Cleanup from previous execution
local function cleanup()
    local playerGui = player:WaitForChild("PlayerGui")

    -- Remove old GUIs
    local oldGui = playerGui:FindFirstChild("BhopVisualsGUI")
    if oldGui then oldGui:Destroy() end

    local oldCustomGui = playerGui:FindFirstChild("BhopHubUI")
    if oldCustomGui then oldCustomGui:Destroy() end

    local oldBodyVel = rootPart:FindFirstChild("BhopVelocity")
    if oldBodyVel then oldBodyVel:Destroy() end

    humanoid.WalkSpeed = 16
    humanoid.JumpPower = 50
    humanoid.AutoRotate = true
    rootPart.Velocity = Vector3.new(0, 0, 0)
    rootPart.RotVelocity = Vector3.new(0, 0, 0)
end

cleanup()
wait(0.1)

-- GitHub Repository Base URL (UPDATE THIS WITH YOUR REPO)
local GITHUB_BASE = "https://raw.githubusercontent.com/Artifaqt/bhop-script/refs/heads/main/modules/"

-- Load Modules
print("[BHOP HUB] Loading modules...")

local Physics = loadstring(game:HttpGet(GITHUB_BASE .. "physics.lua"))()
local Visuals = loadstring(game:HttpGet(GITHUB_BASE .. "visuals.lua"))()
local Trails = loadstring(game:HttpGet(GITHUB_BASE .. "trails.lua"))()
local Sounds = loadstring(game:HttpGet(GITHUB_BASE .. "sounds.lua"))()
local Stats = loadstring(game:HttpGet(GITHUB_BASE .. "stats.lua"))()
local UI = loadstring(game:HttpGet(GITHUB_BASE .. "ui_custom.lua"))()

print("[BHOP HUB] All modules loaded!")

-- Initialize modules
Physics.init(player, character, humanoid, rootPart)
Visuals.init(player, Physics)
Trails.init(player, rootPart, Physics)
Sounds.init(rootPart, Physics, Stats)
Stats.init()

-- Create Custom UI
UI.createWindow(Physics, Visuals, Trails, Sounds, Stats)

-- Input Handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Physics.getToggleKey() then
        Physics.toggleBhop()
        UI.syncToggle(Physics.isEnabled())
    end
end)

print("[BHOP HUB] Loaded successfully! Press 'B' to toggle bhop mode.")