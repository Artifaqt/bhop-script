-- CS 1.6 Style Bhop Script for Roblox
-- Press 'B' to toggle bhop mode

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Cleanup from previous script execution
print("[BHOP] Cleaning up previous instance...")

-- Remove old debug GUI if it exists
local playerGui = player:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("BhopDebugGUI")
if oldGui then
    oldGui:Destroy()
    print("[BHOP] Removed old debug GUI")
end

-- Remove old BodyVelocity if it exists
local oldBodyVel = rootPart:FindFirstChild("BhopVelocity")
if oldBodyVel then
    oldBodyVel:Destroy()
    print("[BHOP] Removed old BodyVelocity")
end

-- Reset humanoid to default Roblox physics
humanoid.WalkSpeed = 16  -- Default Roblox walk speed
humanoid.JumpPower = 50  -- Default Roblox jump power
humanoid.AutoRotate = true
rootPart.Velocity = Vector3.new(0, 0, 0)
rootPart.RotVelocity = Vector3.new(0, 0, 0)

wait(0.1)  -- Small delay to ensure everything is reset

print("[BHOP] Cleanup complete, initializing new instance...")

-- Configuration
local TOGGLE_KEY = Enum.KeyCode.B
local JUMP_KEY = Enum.KeyCode.Space

-- Bhop State
local bhopEnabled = false
local isJumping = false
local wasInAir = false
local isTyping = false  -- Track if player is typing in any text box

-- CS 1.6 Physics Constants (now adjustable via GUI)
local config = {
    GROUND_FRICTION = 6,        -- How quickly you slow down on ground (higher = more friction)
    GROUND_ACCELERATE = 10,     -- How fast you accelerate to ground speed (higher = faster accel)
    AIR_ACCELERATE = 16,        -- Air strafe power (higher = easier to gain speed in air)
    GROUND_SPEED = 16,          -- Ground running speed (Roblox default: 16)
    AIR_CAP = 10,               -- Speed added per air strafe (higher = more speed per strafe)
    JUMP_POWER = 50,            -- Jump height
    STOP_SPEED = 1              -- Friction threshold (lower = less friction at low speeds)
}

-- Movement Variables
local moveDirection = Vector3.new(0, 0, 0)
local wishDir = Vector3.new(0, 0, 0)
local currentVelocity = Vector3.new(0, 0, 0)

-- Store original values
local originalWalkSpeed = humanoid.WalkSpeed
local originalJumpPower = humanoid.JumpPower

-- Debug Variables
local maxSpeedReached = 0
local debugEnabled = true

-- Create BodyVelocity for forcing velocity
local bodyVelocity = Instance.new("BodyVelocity")
bodyVelocity.Name = "BhopVelocity"
bodyVelocity.MaxForce = Vector3.new(0, 0, 0)  -- Start disabled
bodyVelocity.P = 10000
bodyVelocity.Velocity = Vector3.new(0, 0, 0)
bodyVelocity.Parent = rootPart

-- Track when player is typing in any text box (chat, config panel, etc.)
UserInputService.TextBoxFocused:Connect(function()
    isTyping = true
end)

UserInputService.TextBoxFocusReleased:Connect(function()
    isTyping = false
end)

-- Create Debug GUI
local function createDebugGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BhopDebugGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    -- Bottom debug bar (single line)
    local debugBar = Instance.new("Frame")
    debugBar.Name = "DebugBar"
    debugBar.Size = UDim2.new(1, 0, 0, 30)
    debugBar.Position = UDim2.new(0, 0, 1, -30)
    debugBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    debugBar.BackgroundTransparency = 0.3
    debugBar.BorderSizePixel = 0
    debugBar.Parent = screenGui

    local debugText = Instance.new("TextLabel")
    debugText.Name = "DebugText"
    debugText.Size = UDim2.new(1, -100, 1, 0)
    debugText.Position = UDim2.new(0, 5, 0, 0)
    debugText.BackgroundTransparency = 1
    debugText.TextColor3 = Color3.fromRGB(255, 255, 255)
    debugText.TextSize = 14
    debugText.Font = Enum.Font.Code
    debugText.TextXAlignment = Enum.TextXAlignment.Left
    debugText.TextYAlignment = Enum.TextYAlignment.Center
    debugText.Text = ""
    debugText.Parent = debugBar

    -- Credit text
    local creditText = Instance.new("TextLabel")
    creditText.Name = "CreditText"
    creditText.Size = UDim2.new(0, 200, 1, 0)
    creditText.Position = UDim2.new(1, -310, 0, 0)
    creditText.BackgroundTransparency = 1
    creditText.TextColor3 = Color3.fromRGB(255, 100, 150)
    creditText.TextSize = 13
    creditText.Font = Enum.Font.SourceSansBold
    creditText.TextXAlignment = Enum.TextXAlignment.Right
    creditText.TextYAlignment = Enum.TextYAlignment.Center
    creditText.Text = "Made by Artifaqt ♥️"
    creditText.Parent = debugBar

    -- Hide/Show button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Name = "ToggleButton"
    toggleBtn.Size = UDim2.new(0, 80, 0, 25)
    toggleBtn.Position = UDim2.new(1, -90, 0, 2.5)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggleBtn.BorderColor3 = Color3.fromRGB(100, 100, 100)
    toggleBtn.Text = "HIDE UI"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 12
    toggleBtn.Font = Enum.Font.SourceSansBold
    toggleBtn.Parent = debugBar

    return screenGui, debugText, toggleBtn
end

local debugGui, debugText, toggleButton = createDebugGUI()
local uiVisible = true
debugGui.Enabled = false  -- Start with debug GUI hidden

-- Config Save/Load System
local CONFIG_FOLDER = "bhop_configs"
local LAST_SETTINGS_FILE = CONFIG_FOLDER .. "/last_settings.txt"
local LAST_POSITION_FILE = CONFIG_FOLDER .. "/panel_position.txt"

-- Ensure config folder exists
pcall(function()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end)

-- Auto-save current settings
local function autoSaveSettings()
    pcall(function()
        local configData = ""
        for key, value in pairs(config) do
            configData = configData .. key .. "=" .. tostring(value) .. "\n"
        end
        writefile(LAST_SETTINGS_FILE, configData)
    end)
end

-- Save panel position
local function savePanelPosition(position)
    pcall(function()
        local posData = tostring(position.X.Offset) .. "," .. tostring(position.Y.Offset)
        writefile(LAST_POSITION_FILE, posData)
    end)
end

-- Load panel position
local function loadPanelPosition()
    local success, result = pcall(function()
        if isfile(LAST_POSITION_FILE) then
            local posData = readfile(LAST_POSITION_FILE)
            local x, y = posData:match("([^,]+),([^,]+)")
            if x and y then
                return UDim2.new(0, tonumber(x), 0, tonumber(y))
            end
        end
        -- Default: top-right (screen width - panel width - 10px margin)
        return UDim2.new(1, -360, 0, 10)
    end)

    if success and result then
        return result
    end
    return UDim2.new(1, -360, 0, 10)
end

-- Get list of all saved presets
local function getPresetList()
    local presets = {}
    pcall(function()
        if not isfolder(CONFIG_FOLDER) then
            return
        end

        local files = listfiles(CONFIG_FOLDER)
        for _, filePath in ipairs(files) do
            local fileName = filePath:match("([^/\\]+)%.txt$")
            if fileName and fileName ~= "last_settings" and fileName ~= "panel_position" then
                table.insert(presets, fileName)
            end
        end
    end)
    table.sort(presets)
    return presets
end

-- Auto-load last settings on startup
pcall(function()
    if isfile(LAST_SETTINGS_FILE) then
        local configData = readfile(LAST_SETTINGS_FILE)
        for line in configData:gmatch("[^\n]+") do
            local key, value = line:match("(.+)=(.+)")
            if key and value then
                local numValue = tonumber(value)
                if numValue and config[key] then
                    config[key] = numValue
                end
            end
        end
        print("[BHOP] Auto-loaded last settings")
    end
end)

-- Save current config
local function saveConfig(presetName)
    if presetName == "" then
        warn("[BHOP] Preset name cannot be empty!")
        return false
    end

    local success = pcall(function()
        local configData = ""
        for key, value in pairs(config) do
            configData = configData .. key .. "=" .. tostring(value) .. "\n"
        end

        local filePath = CONFIG_FOLDER .. "/" .. presetName .. ".txt"
        writefile(filePath, configData)
        print("[BHOP] Saved preset: " .. presetName)
    end)

    return success
end

-- Load config
local function loadConfig(presetName, configInputs)
    local filePath = CONFIG_FOLDER .. "/" .. presetName .. ".txt"

    local success = pcall(function()
        if not isfile(filePath) then
            warn("[BHOP] Preset not found: " .. presetName)
            return
        end

        local configData = readfile(filePath)

        for line in configData:gmatch("[^\n]+") do
            local key, value = line:match("(.+)=(.+)")
            if key and value then
                local numValue = tonumber(value)
                if numValue and config[key] then
                    config[key] = numValue
                    -- Update UI
                    if configInputs and configInputs[key] then
                        configInputs[key].Text = tostring(numValue)
                    end
                end
            end
        end

        print("[BHOP] Loaded preset: " .. presetName)
    end)

    return success
end

-- Create Config Panel
local function createConfigPanel()
    local configFrame = Instance.new("Frame")
    configFrame.Name = "ConfigPanel"
    configFrame.Size = UDim2.new(0, 350, 0, 530)
    configFrame.Position = loadPanelPosition()
    configFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
    configFrame.BackgroundTransparency = 0.05
    configFrame.BorderSizePixel = 0
    configFrame.Parent = debugGui

    -- Add rounded corners effect with UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = configFrame

    -- Title bar
    local configTitle = Instance.new("TextLabel")
    configTitle.Name = "Title"
    configTitle.Size = UDim2.new(1, 0, 0, 35)
    configTitle.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    configTitle.BorderSizePixel = 0
    configTitle.Text = "⚙ BHOP CONFIG"
    configTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
    configTitle.TextSize = 18
    configTitle.Font = Enum.Font.GothamBold
    configTitle.Parent = configFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = configTitle

    -- Make panel draggable via title bar
    local dragging = false
    local dragStart = nil
    local startPos = nil

    configTitle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = configFrame.Position
        end
    end)

    configTitle.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            configFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    configTitle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
            dragging = false
            savePanelPosition(configFrame.Position)
        end
    end)

    -- Tooltip (will be positioned dynamically)
    local tooltip = Instance.new("Frame")
    tooltip.Name = "Tooltip"
    tooltip.Size = UDim2.new(0, 250, 0, 0)
    tooltip.Position = UDim2.new(0, 0, 0, 0)
    tooltip.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    tooltip.BackgroundTransparency = 0
    tooltip.BorderSizePixel = 1
    tooltip.BorderColor3 = Color3.fromRGB(100, 200, 255)
    tooltip.Visible = false
    tooltip.ZIndex = 100
    tooltip.Parent = debugGui  -- Parent to screenGui instead of configFrame

    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = UDim.new(0, 6)
    tooltipCorner.Parent = tooltip

    local tooltipText = Instance.new("TextLabel")
    tooltipText.Name = "TooltipText"
    tooltipText.Size = UDim2.new(1, -16, 1, -12)
    tooltipText.Position = UDim2.new(0, 8, 0, 6)
    tooltipText.BackgroundTransparency = 1
    tooltipText.TextColor3 = Color3.fromRGB(220, 220, 230)
    tooltipText.TextSize = 13
    tooltipText.Font = Enum.Font.Gotham
    tooltipText.TextXAlignment = Enum.TextXAlignment.Left
    tooltipText.TextYAlignment = Enum.TextYAlignment.Top
    tooltipText.TextWrapped = true
    tooltipText.ZIndex = 100
    tooltipText.Parent = tooltip

    local configInputs = {}
    local yOffset = 45
    local spacing = 45

    local function createConfigRow(name, configKey, min, max, step, description)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -20, 0, 38)
        row.Position = UDim2.new(0, 10, 0, yOffset)
        row.BackgroundTransparency = 1
        row.Parent = configFrame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 120, 0, 18)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(180, 180, 190)
        label.TextSize = 14
        label.Font = Enum.Font.GothamMedium
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row

        -- Controls container
        local controls = Instance.new("Frame")
        controls.Size = UDim2.new(0, 200, 0, 28)
        controls.Position = UDim2.new(0, 120, 0, 5)
        controls.BackgroundTransparency = 1
        controls.Parent = row

        local minusBtn = Instance.new("TextButton")
        minusBtn.Size = UDim2.new(0, 28, 0, 28)
        minusBtn.Position = UDim2.new(0, 0, 0, 0)
        minusBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        minusBtn.BorderSizePixel = 0
        minusBtn.Text = "-"
        minusBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
        minusBtn.TextSize = 18
        minusBtn.Font = Enum.Font.GothamBold
        minusBtn.Parent = controls

        local minusCorner = Instance.new("UICorner")
        minusCorner.CornerRadius = UDim.new(0, 4)
        minusCorner.Parent = minusBtn

        local valueBox = Instance.new("TextBox")
        valueBox.Size = UDim2.new(0, 104, 0, 28)
        valueBox.Position = UDim2.new(0, 33, 0, 0)
        valueBox.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
        valueBox.BorderSizePixel = 1
        valueBox.BorderColor3 = Color3.fromRGB(60, 60, 70)
        valueBox.Text = tostring(config[configKey])
        valueBox.TextColor3 = Color3.fromRGB(100, 200, 255)
        valueBox.TextSize = 14
        valueBox.Font = Enum.Font.GothamBold
        valueBox.Parent = controls

        local valueCorner = Instance.new("UICorner")
        valueCorner.CornerRadius = UDim.new(0, 4)
        valueCorner.Parent = valueBox

        local plusBtn = Instance.new("TextButton")
        plusBtn.Size = UDim2.new(0, 28, 0, 28)
        plusBtn.Position = UDim2.new(0, 142, 0, 0)
        plusBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        plusBtn.BorderSizePixel = 0
        plusBtn.Text = "+"
        plusBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
        plusBtn.TextSize = 18
        plusBtn.Font = Enum.Font.GothamBold
        plusBtn.Parent = controls

        local plusCorner = Instance.new("UICorner")
        plusCorner.CornerRadius = UDim.new(0, 4)
        plusCorner.Parent = plusBtn

        -- Button handlers
        minusBtn.MouseButton1Click:Connect(function()
            local current = tonumber(valueBox.Text) or config[configKey]
            local newValue = math.max(min, current - step)
            config[configKey] = newValue
            valueBox.Text = tostring(newValue)
            autoSaveSettings()
        end)

        plusBtn.MouseButton1Click:Connect(function()
            local current = tonumber(valueBox.Text) or config[configKey]
            local newValue = math.min(max, current + step)
            config[configKey] = newValue
            valueBox.Text = tostring(newValue)
            autoSaveSettings()
        end)

        valueBox.FocusLost:Connect(function()
            local value = tonumber(valueBox.Text)
            if value then
                config[configKey] = math.clamp(value, min, max)
                valueBox.Text = tostring(config[configKey])
                autoSaveSettings()
            else
                valueBox.Text = tostring(config[configKey])
            end
        end)

        -- Smart tooltip positioning
        row.MouseEnter:Connect(function()
            tooltipText.Text = description

            -- Calculate tooltip height
            local textBounds = tooltipText.TextBounds
            local tooltipHeight = math.max(textBounds.Y + 20, 40)
            tooltip.Size = UDim2.new(0, 250, 0, tooltipHeight)

            -- Get screen size and panel position
            local screenSize = workspace.CurrentCamera.ViewportSize
            local panelPos = configFrame.AbsolutePosition
            local panelSize = configFrame.AbsoluteSize
            local rowPosY = panelPos.Y + yOffset

            -- Determine which side has more room
            local leftSpace = panelPos.X
            local rightSpace = screenSize.X - (panelPos.X + panelSize.X)

            local tooltipX, tooltipY

            if rightSpace > leftSpace and rightSpace > 260 then
                -- Show on right
                tooltipX = panelPos.X + panelSize.X + 10
            else
                -- Show on left
                tooltipX = panelPos.X - 260
            end

            -- Align with row
            tooltipY = rowPosY - 5

            -- Keep tooltip on screen
            if tooltipY + tooltipHeight > screenSize.Y then
                tooltipY = screenSize.Y - tooltipHeight - 10
            end
            if tooltipY < 0 then
                tooltipY = 10
            end

            tooltip.Position = UDim2.new(0, tooltipX, 0, tooltipY)
            tooltip.Visible = true
        end)

        row.MouseLeave:Connect(function()
            tooltip.Visible = false
        end)

        yOffset = yOffset + spacing
        configInputs[configKey] = valueBox
    end

    createConfigRow("Ground Friction", "GROUND_FRICTION", 0, 10000, 1,
        "Controls deceleration when on ground. Higher = stop faster.")

    createConfigRow("Ground Accel", "GROUND_ACCELERATE", 1, 10000, 5,
        "How fast you reach ground speed. Higher = instant, lower = gradual.")

    createConfigRow("Air Accel", "AIR_ACCELERATE", 10, 100000, 50,
        "Air strafe power. Higher = easier speed gain. CS 1.6 uses ~1000.")

    createConfigRow("Ground Speed", "GROUND_SPEED", 10, 10000, 5,
        "Running speed on ground. Doesn't limit bhop speed!")

    createConfigRow("Air Cap", "AIR_CAP", 0.1, 10000, 1,
        "Max speed added per air strafe. Higher = bigger boost.")

    createConfigRow("Jump Power", "JUMP_POWER", 20, 10000, 5,
        "Jump height. Higher = more airtime for strafing.")

    createConfigRow("Stop Speed", "STOP_SPEED", 0.1, 10000, 0.5,
        "Friction threshold. Lower = easier to keep momentum.")

    -- Preset System UI
    yOffset = yOffset + 10

    local presetDivider = Instance.new("Frame")
    presetDivider.Size = UDim2.new(1, -20, 0, 1)
    presetDivider.Position = UDim2.new(0, 10, 0, yOffset)
    presetDivider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    presetDivider.BorderSizePixel = 0
    presetDivider.Parent = configFrame

    yOffset = yOffset + 15

    local presetTitle = Instance.new("TextLabel")
    presetTitle.Size = UDim2.new(1, -20, 0, 20)
    presetTitle.Position = UDim2.new(0, 10, 0, yOffset)
    presetTitle.BackgroundTransparency = 1
    presetTitle.Text = "💾 PRESETS"
    presetTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
    presetTitle.TextSize = 15
    presetTitle.Font = Enum.Font.GothamBold
    presetTitle.TextXAlignment = Enum.TextXAlignment.Left
    presetTitle.Parent = configFrame

    yOffset = yOffset + 30

    -- Dropdown container
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(1, -80, 0, 32)
    dropdownFrame.Position = UDim2.new(0, 10, 0, yOffset)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    dropdownFrame.BorderSizePixel = 1
    dropdownFrame.BorderColor3 = Color3.fromRGB(60, 60, 70)
    dropdownFrame.Parent = configFrame

    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 4)
    dropdownCorner.Parent = dropdownFrame

    local dropdownLabel = Instance.new("TextLabel")
    dropdownLabel.Size = UDim2.new(1, -30, 1, 0)
    dropdownLabel.Position = UDim2.new(0, 10, 0, 0)
    dropdownLabel.BackgroundTransparency = 1
    dropdownLabel.Text = "Select preset..."
    dropdownLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
    dropdownLabel.TextSize = 13
    dropdownLabel.Font = Enum.Font.Gotham
    dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
    dropdownLabel.Parent = dropdownFrame

    local dropdownArrow = Instance.new("TextLabel")
    dropdownArrow.Size = UDim2.new(0, 20, 1, 0)
    dropdownArrow.Position = UDim2.new(1, -25, 0, 0)
    dropdownArrow.BackgroundTransparency = 1
    dropdownArrow.Text = "▼"
    dropdownArrow.TextColor3 = Color3.fromRGB(140, 140, 150)
    dropdownArrow.TextSize = 10
    dropdownArrow.Font = Enum.Font.GothamBold
    dropdownArrow.Parent = dropdownFrame

    -- Dropdown list (hidden by default)
    local dropdownList = Instance.new("ScrollingFrame")
    dropdownList.Size = UDim2.new(1, 0, 0, 0)
    dropdownList.Position = UDim2.new(0, 0, 1, 2)
    dropdownList.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    dropdownList.BorderSizePixel = 1
    dropdownList.BorderColor3 = Color3.fromRGB(100, 200, 255)
    dropdownList.ScrollBarThickness = 4
    dropdownList.Visible = false
    dropdownList.ZIndex = 10
    dropdownList.Parent = dropdownFrame

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 4)
    listCorner.Parent = dropdownList

    local selectedPreset = nil

    -- Function to refresh dropdown list
    local function refreshDropdown()
        dropdownList:ClearAllChildren()
        local listCorner = Instance.new("UICorner")
        listCorner.CornerRadius = UDim.new(0, 4)
        listCorner.Parent = dropdownList

        local presets = getPresetList()
        local itemHeight = 28
        dropdownList.CanvasSize = UDim2.new(0, 0, 0, #presets * itemHeight)

        for i, presetName in ipairs(presets) do
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, -8, 0, itemHeight - 2)
            item.Position = UDim2.new(0, 4, 0, (i - 1) * itemHeight + 2)
            item.BackgroundColor3 = Color3.fromRGB(45, 45, 53)
            item.BorderSizePixel = 0
            item.Text = presetName
            item.TextColor3 = Color3.fromRGB(200, 200, 210)
            item.TextSize = 13
            item.Font = Enum.Font.Gotham
            item.ZIndex = 10
            item.Parent = dropdownList

            local itemCorner = Instance.new("UICorner")
            itemCorner.CornerRadius = UDim.new(0, 3)
            itemCorner.Parent = item

            item.MouseEnter:Connect(function()
                item.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            end)

            item.MouseLeave:Connect(function()
                item.BackgroundColor3 = Color3.fromRGB(45, 45, 53)
            end)

            item.MouseButton1Click:Connect(function()
                selectedPreset = presetName
                dropdownLabel.Text = presetName
                dropdownLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
                dropdownList.Visible = false
                dropdownArrow.Text = "▼"
            end)
        end
    end

    -- Toggle dropdown
    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(1, 0, 1, 0)
    dropdownBtn.BackgroundTransparency = 1
    dropdownBtn.Text = ""
    dropdownBtn.Parent = dropdownFrame

    dropdownBtn.MouseButton1Click:Connect(function()
        refreshDropdown()
        dropdownList.Visible = not dropdownList.Visible
        dropdownArrow.Text = dropdownList.Visible and "▲" or "▼"

        -- Adjust list size based on items
        local presets = getPresetList()
        local maxHeight = 140
        local itemHeight = 28
        local neededHeight = #presets * itemHeight + 4
        dropdownList.Size = UDim2.new(1, 0, 0, math.min(neededHeight, maxHeight))
    end)

    -- Load button
    local loadBtn = Instance.new("TextButton")
    loadBtn.Size = UDim2.new(0, 60, 0, 32)
    loadBtn.Position = UDim2.new(1, -70, 0, yOffset)
    loadBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
    loadBtn.BorderSizePixel = 0
    loadBtn.Text = "LOAD"
    loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    loadBtn.TextSize = 13
    loadBtn.Font = Enum.Font.GothamBold
    loadBtn.Parent = configFrame

    local loadCorner = Instance.new("UICorner")
    loadCorner.CornerRadius = UDim.new(0, 4)
    loadCorner.Parent = loadBtn

    loadBtn.MouseButton1Click:Connect(function()
        if selectedPreset then
            local success = loadConfig(selectedPreset, configInputs)
            if success then
                loadBtn.BackgroundColor3 = Color3.fromRGB(70, 200, 100)
                task.wait(0.15)
                loadBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
            end
        end
    end)

    yOffset = yOffset + 42

    -- Save new preset
    local saveLabel = Instance.new("TextLabel")
    saveLabel.Size = UDim2.new(1, -20, 0, 16)
    saveLabel.Position = UDim2.new(0, 10, 0, yOffset)
    saveLabel.BackgroundTransparency = 1
    saveLabel.Text = "Save New:"
    saveLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
    saveLabel.TextSize = 12
    saveLabel.Font = Enum.Font.GothamMedium
    saveLabel.TextXAlignment = Enum.TextXAlignment.Left
    saveLabel.Parent = configFrame

    yOffset = yOffset + 20

    local presetNameBox = Instance.new("TextBox")
    presetNameBox.Size = UDim2.new(1, -80, 0, 32)
    presetNameBox.Position = UDim2.new(0, 10, 0, yOffset)
    presetNameBox.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    presetNameBox.BorderSizePixel = 1
    presetNameBox.BorderColor3 = Color3.fromRGB(60, 60, 70)
    presetNameBox.PlaceholderText = "Preset name..."
    presetNameBox.Text = ""
    presetNameBox.TextColor3 = Color3.fromRGB(200, 200, 210)
    presetNameBox.TextSize = 13
    presetNameBox.Font = Enum.Font.Gotham
    presetNameBox.Parent = configFrame

    local nameBoxCorner = Instance.new("UICorner")
    nameBoxCorner.CornerRadius = UDim.new(0, 4)
    nameBoxCorner.Parent = presetNameBox

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0, 60, 0, 32)
    saveBtn.Position = UDim2.new(1, -70, 0, yOffset)
    saveBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    saveBtn.BorderSizePixel = 0
    saveBtn.Text = "SAVE"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.TextSize = 13
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.Parent = configFrame

    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(0, 4)
    saveCorner.Parent = saveBtn

    saveBtn.MouseButton1Click:Connect(function()
        local success = saveConfig(presetNameBox.Text)
        if success then
            saveBtn.BackgroundColor3 = Color3.fromRGB(100, 220, 100)
            presetNameBox.Text = ""
            refreshDropdown()
            task.wait(0.15)
            saveBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        end
    end)

    return configFrame, configInputs
end

local configPanel, configInputs = createConfigPanel()

-- Toggle UI visibility button
toggleButton.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    configPanel.Visible = uiVisible
    toggleButton.Text = uiVisible and "HIDE UI" or "SHOW UI"

    -- Save panel position when hiding
    if not uiVisible then
        savePanelPosition(configPanel.Position)
    end
end)

-- Update Debug GUI
local function updateDebugGUI(speed, onGround)
    if not debugEnabled or not debugText then
        return
    end

    local vel = rootPart.Velocity
    local status = bhopEnabled and "ENABLED" or "DISABLED"
    local groundStatus = onGround and "GROUNDED" or "IN AIR"
    local groundColor = onGround and "🟢" or "🔴"

    if speed > maxSpeedReached then
        maxSpeedReached = speed
    end

    local keysPressed = ""
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then keysPressed = keysPressed .. "W " end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then keysPressed = keysPressed .. "A " end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then keysPressed = keysPressed .. "S " end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then keysPressed = keysPressed .. "D " end
    if UserInputService:IsKeyDown(JUMP_KEY) then keysPressed = keysPressed .. "SPACE " end
    if keysPressed == "" then keysPressed = "NONE" end

    debugText.Text = string.format(
        "%s %s | Speed: %.1f | Max: %.1f | Ground: %.1f | Vel: (%.1f, %.1f, %.1f) | Keys: %s",
        groundColor, groundStatus,
        speed,
        maxSpeedReached,
        config.GROUND_SPEED,
        vel.X, vel.Y, vel.Z,
        keysPressed
    )
end

-- Get movement input
local function getWishDir()
    -- Don't process movement input if typing in chat or any text box
    if isTyping then
        return Vector3.new(0, 0, 0)
    end

    local camera = workspace.CurrentCamera
    local moveVector = Vector3.new(0, 0, 0)

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveVector = moveVector + camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        moveVector = moveVector - camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        moveVector = moveVector - camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        moveVector = moveVector + camera.CFrame.RightVector
    end

    if moveVector.Magnitude > 0 then
        return moveVector.Unit
    end
    return Vector3.new(0, 0, 0)
end

-- Check if player is on ground
local function isGrounded()
    local rayOrigin = rootPart.Position
    local rayDirection = Vector3.new(0, -4, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    return raycastResult ~= nil
end

-- Air acceleration (CS 1.6 style strafe)
local function airAccelerate(wishdir, wishspeed, accel, dt)
    local currentspeed = currentVelocity:Dot(wishdir)
    local addspeed = wishspeed - currentspeed

    if addspeed <= 0 then
        return
    end

    local accelspeed = math.min(accel * wishspeed * dt, addspeed)
    currentVelocity = currentVelocity + wishdir * accelspeed
end

-- Ground acceleration
local function groundAccelerate(wishdir, wishspeed, accel, dt)
    local currentspeed = currentVelocity:Dot(wishdir)
    local addspeed = wishspeed - currentspeed

    if addspeed <= 0 then
        return
    end

    local accelspeed = math.min(accel * dt * wishspeed, addspeed)
    currentVelocity = currentVelocity + wishdir * accelspeed
end

-- Apply friction
local function applyFriction(dt)
    local speed = currentVelocity.Magnitude

    -- Stop completely when very slow to avoid sliding forever
    if speed < 0.1 then
        currentVelocity = Vector3.new(0, 0, 0)
        return
    end

    -- Reduce friction when moving fast (bhop preservation)
    local control = speed < config.STOP_SPEED and config.STOP_SPEED or speed
    local drop = control * config.GROUND_FRICTION * dt

    local newSpeed = math.max(speed - drop, 0)

    if speed > 0 then
        currentVelocity = currentVelocity * (newSpeed / speed)
    end
end

-- Main physics update
local function updatePhysics(dt)
    if not bhopEnabled or not character or not rootPart then
        return
    end

    -- Get wish direction
    wishDir = getWishDir()
    local onGround = isGrounded()

    if onGround then
        -- Ground movement - friction applies, accelerate to fixed ground speed
        applyFriction(dt)
        groundAccelerate(wishDir, config.GROUND_SPEED, config.GROUND_ACCELERATE, dt)

        -- Auto bhop - jump if space is held (skip friction by staying airborne)
        -- Don't jump if typing in chat or any text box
        if UserInputService:IsKeyDown(JUMP_KEY) and not isJumping and not isTyping then
            rootPart.Velocity = Vector3.new(currentVelocity.X, config.JUMP_POWER, currentVelocity.Z)
            isJumping = true
        end
    else
        -- Air movement (strafe) - NO friction, NO speed cap (unlimited speed potential)
        local wishspeed = config.AIR_CAP
        airAccelerate(wishDir, wishspeed, config.AIR_ACCELERATE, dt)

        -- Reset jump flag when in air (allows auto-bhop to work)
        isJumping = false
    end

    -- Apply velocity via BodyVelocity (only control X and Z, Y is handled by gravity)
    local newVelocity = Vector3.new(currentVelocity.X, 0, currentVelocity.Z)
    bodyVelocity.Velocity = newVelocity

    -- Update debug display
    updateDebugGUI(currentVelocity.Magnitude, onGround)
end

-- Toggle bhop mode
local function toggleBhop()
    bhopEnabled = not bhopEnabled

    if bhopEnabled then
        print("[BHOP] Enabled - Press SPACE + WASD to bunny hop")
        -- Disable Roblox default movement
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        currentVelocity = Vector3.new(0, 0, 0)
        maxSpeedReached = 0
        -- Enable BodyVelocity to force velocity (large force on X and Z, 0 on Y for gravity)
        bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
        -- Show debug GUI
        if debugGui then
            debugGui.Enabled = true
        end
    else
        print("[BHOP] Disabled")
        -- Restore original movement
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpPower = originalJumpPower
        rootPart.Velocity = Vector3.new(0, 0, 0)
        -- Disable BodyVelocity
        bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        -- Hide debug GUI
        if debugGui then
            debugGui.Enabled = false
        end
    end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == TOGGLE_KEY then
        toggleBhop()
    end
end)

-- Physics loop
RunService.RenderStepped:Connect(function(dt)
    if bhopEnabled then
        updatePhysics(dt)
    else
        -- Update debug even when disabled
        if debugEnabled and rootPart then
            local vel = rootPart.Velocity
            local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
            updateDebugGUI(speed, isGrounded())
        end
    end
end)

-- Handle character respawn
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    originalWalkSpeed = humanoid.WalkSpeed
    originalJumpPower = humanoid.JumpPower

    bhopEnabled = false
    currentVelocity = Vector3.new(0, 0, 0)
    maxSpeedReached = 0

    -- Recreate BodyVelocity
    if bodyVelocity then
        bodyVelocity:Destroy()
    end
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "BhopVelocity"
    bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
    bodyVelocity.P = 10000
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart

    -- Recreate debug GUI
    if debugGui then
        debugGui:Destroy()
    end
    debugGui, debugText, toggleButton = createDebugGUI()
    uiVisible = true
    debugGui.Enabled = false

    -- Recreate config panel and reconnect toggle button
    configPanel, configInputs = createConfigPanel()
    toggleButton.MouseButton1Click:Connect(function()
        uiVisible = not uiVisible
        configPanel.Visible = uiVisible
        toggleButton.Text = uiVisible and "HIDE UI" or "SHOW UI"

        -- Save panel position when hiding
        if not uiVisible then
            savePanelPosition(configPanel.Position)
        end
    end)
end)

print("[BHOP] Script loaded! Press 'B' to toggle bhop mode")
