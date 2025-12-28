-- Custom UI Module
-- Clean, modern UI using native Roblox GUI elements

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UI = {}

-- State
local Physics, Visuals, Trails, Sounds, Stats
local screenGui
local mainFrame
local currentTab = "Dashboard"

-- UI References
local bhopToggle
local autoHopToggle
local physicsSliders = {}
local visualToggles = {}

-- Theme
local theme = {
    background = Color3.fromRGB(25, 25, 30),
    surface = Color3.fromRGB(35, 35, 40),
    surfaceLight = Color3.fromRGB(45, 45, 50),
    accent = Color3.fromRGB(100, 200, 255),
    accentDark = Color3.fromRGB(70, 140, 200),
    text = Color3.fromRGB(220, 220, 230),
    textDim = Color3.fromRGB(150, 150, 160),
    success = Color3.fromRGB(100, 255, 150),
    warning = Color3.fromRGB(255, 200, 100),
    error = Color3.fromRGB(255, 100, 100),
}

-- Helper Functions
local function create(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties) do
        if k == "Parent" then continue end
        instance[k] = v
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

local function createCorner(radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function createPadding(padding)
    return create("UIPadding", {
        PaddingTop = UDim.new(0, padding),
        PaddingBottom = UDim.new(0, padding),
        PaddingLeft = UDim.new(0, padding),
        PaddingRight = UDim.new(0, padding),
    })
end

local function tween(instance, properties, duration)
    local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Toggle Button
local function createToggle(name, parent, callback)
    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Parent = parent,
    })
    createCorner(6).Parent = container

    local label = create("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = theme.text,
        TextSize = 14,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    local toggleBack = create("Frame", {
        Size = UDim2.new(0, 44, 0, 24),
        Position = UDim2.new(1, -54, 0.5, -12),
        BackgroundColor3 = theme.surfaceLight,
        BorderSizePixel = 0,
        Parent = container,
    })
    createCorner(12).Parent = toggleBack

    local toggleKnob = create("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 3, 0, 3),
        BackgroundColor3 = theme.textDim,
        BorderSizePixel = 0,
        Parent = toggleBack,
    })
    createCorner(9).Parent = toggleKnob

    local state = false

    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = container,
    })

    local function updateVisual()
        if state then
            tween(toggleBack, { BackgroundColor3 = theme.accent })
            tween(toggleKnob, { Position = UDim2.new(1, -21, 0, 3), BackgroundColor3 = Color3.fromRGB(255, 255, 255) })
        else
            tween(toggleBack, { BackgroundColor3 = theme.surfaceLight })
            tween(toggleKnob, { Position = UDim2.new(0, 3, 0, 3), BackgroundColor3 = theme.textDim })
        end
    end

    button.MouseButton1Click:Connect(function()
        state = not state
        updateVisual()
        callback(state)
    end)

    return {
        Set = function(self, value)
            state = value
            updateVisual()
        end,
        GetState = function(self)
            return state
        end
    }
end

-- Slider
local function createSlider(name, min, max, default, callback, parent)
    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Parent = parent,
    })
    createCorner(6).Parent = container

    local label = create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = theme.text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    local valueLabel = create("TextLabel", {
        Size = UDim2.new(0, 60, 0, 20),
        Position = UDim2.new(1, -70, 0, 5),
        BackgroundTransparency = 1,
        Text = tostring(default),
        TextColor3 = theme.accent,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = container,
    })

    local sliderBack = create("Frame", {
        Size = UDim2.new(1, -20, 0, 4),
        Position = UDim2.new(0, 10, 1, -14),
        BackgroundColor3 = theme.surfaceLight,
        BorderSizePixel = 0,
        Parent = container,
    })
    createCorner(2).Parent = sliderBack

    local sliderFill = create("Frame", {
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = theme.accent,
        BorderSizePixel = 0,
        Parent = sliderBack,
    })
    createCorner(2).Parent = sliderFill

    local sliderKnob = create("Frame", {
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = sliderBack,
    })
    createCorner(6).Parent = sliderKnob

    local currentValue = default
    local dragging = false

    local function updateValue(input)
        local relativeX = math.clamp((input.Position.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        currentValue = min + (relativeX * (max - min))

        -- Round to 1 decimal place
        currentValue = math.floor(currentValue * 10 + 0.5) / 10

        valueLabel.Text = tostring(currentValue)
        sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
        sliderKnob.Position = UDim2.new(relativeX, -6, 0.5, -6)

        callback(currentValue)
    end

    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateValue(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateValue(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return {
        Set = function(self, value)
            currentValue = value
            valueLabel.Text = tostring(value)
            local relativeX = (value - min) / (max - min)
            sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
            sliderKnob.Position = UDim2.new(relativeX, -6, 0.5, -6)
        end,
        GetValue = function(self)
            return currentValue
        end
    }
end

-- Button
local function createButton(name, callback, parent)
    local button = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = theme.accent,
        BorderSizePixel = 0,
        Text = name,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        Parent = parent,
    })
    createCorner(6).Parent = button

    button.MouseEnter:Connect(function()
        tween(button, { BackgroundColor3 = theme.accentDark })
    end)

    button.MouseLeave:Connect(function()
        tween(button, { BackgroundColor3 = theme.accent })
    end)

    button.MouseButton1Click:Connect(callback)

    return button
end

-- Input Field
local function createInput(name, placeholder, callback, parent)
    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 65),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    local label = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = theme.text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    local inputBack = create("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 25),
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Parent = container,
    })
    createCorner(6).Parent = inputBack

    local textBox = create("TextBox", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        PlaceholderText = placeholder,
        PlaceholderColor3 = theme.textDim,
        Text = "",
        TextColor3 = theme.text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = inputBack,
    })

    textBox.FocusLost:Connect(function()
        callback(textBox.Text)
    end)

    return textBox
end

-- Dropdown
local function createDropdown(name, options, callback, parent)
    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 65),
        BackgroundTransparency = 1,
        Parent = parent,
    })

    local label = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = theme.text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    local dropdownBack = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 25),
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Text = "",
        Parent = container,
    })
    createCorner(6).Parent = dropdownBack

    local selectedLabel = create("TextLabel", {
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = options[1] or "Select...",
        TextColor3 = theme.text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = dropdownBack,
    })

    local arrow = create("TextLabel", {
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -28, 0, 0),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = theme.textDim,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        Parent = dropdownBack,
    })

    local optionsFrame = create("ScrollingFrame", {
        Size = UDim2.new(0, 0, 0, math.min(#options * 32, 160)),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        Visible = false,
        ZIndex = 100,
        Parent = nil,  -- Will be set to screenGui when first opened
    })
    createCorner(6).Parent = optionsFrame

    local listLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = optionsFrame,
    })

    for i, option in ipairs(options) do
        local optionButton = create("TextButton", {
            Size = UDim2.new(1, -4, 0, 28),
            BackgroundColor3 = theme.surfaceLight,
            BorderSizePixel = 0,
            Text = option,
            TextColor3 = theme.text,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            Parent = optionsFrame,
        })
        createCorner(4).Parent = optionButton

        optionButton.MouseButton1Click:Connect(function()
            selectedLabel.Text = option
            optionsFrame.Visible = false
            callback(option)
        end)
    end

    dropdownBack.MouseButton1Click:Connect(function()
        optionsFrame.Visible = not optionsFrame.Visible

        if optionsFrame.Visible then
            -- Parent to screenGui for top-level rendering
            optionsFrame.Parent = screenGui

            -- Position below the dropdown button using absolute screen coordinates
            local absPos = dropdownBack.AbsolutePosition
            local absSize = dropdownBack.AbsoluteSize
            optionsFrame.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 4)
            optionsFrame.Size = UDim2.new(0, absSize.X, 0, math.min(#options * 32, 160))
        end
    end)

    return container
end

-- Create Main Window
local function createWindow()
    screenGui = create("ScreenGui", {
        Name = "BhopHubUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui"),
    })

    mainFrame = create("Frame", {
        Size = UDim2.new(0, 600, 0, 450),
        Position = UDim2.new(0.5, -300, 0.5, -225),
        BackgroundColor3 = theme.background,
        BorderSizePixel = 0,
        Parent = screenGui,
    })
    createCorner(12).Parent = mainFrame

    -- Title Bar
    local titleBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = theme.surface,
        BorderSizePixel = 0,
        Parent = mainFrame,
    })
    createCorner(12).Parent = titleBar

    local titleLabel = create("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 20, 0, 0),
        BackgroundTransparency = 1,
        Text = "🐰 BHOP HUB",
        TextColor3 = theme.accent,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar,
    })

    local closeButton = create("TextButton", {
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(1, -45, 0, 5),
        BackgroundColor3 = theme.error,
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 24,
        Font = Enum.Font.GothamBold,
        Parent = titleBar,
    })
    createCorner(8).Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- Make draggable
    local dragging, dragInput, dragStart, startPos

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    RunService.RenderStepped:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Tabs Container
    local tabsContainer = create("Frame", {
        Size = UDim2.new(0, 140, 1, -60),
        Position = UDim2.new(0, 10, 0, 55),
        BackgroundTransparency = 1,
        Parent = mainFrame,
    })

    -- Content Container
    local contentContainer = create("ScrollingFrame", {
        Size = UDim2.new(1, -160, 1, -60),
        Position = UDim2.new(0, 150, 0, 55),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = theme.accent,
        Parent = mainFrame,
    })

    local contentLayout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        Parent = contentContainer,
    })

    return tabsContainer, contentContainer
end

-- Create Dashboard Tab
local function createDashboard(parent)
    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
        Visible = true,
    })

    local layout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        Parent = container,
    })

    -- Update container size when layout changes
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        container.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
    end)

    -- Bhop Toggle
    bhopToggle = createToggle("Enable Bhop", container, function(state)
        Physics.toggleBhop(state)
    end)

    -- Auto Hop Toggle
    autoHopToggle = createToggle("Auto Bhop", container, function(state)
        Physics.setAutoHop(state)
    end)

    -- Velocity Meter Toggle
    visualToggles.velocity = createToggle("Velocity Meter", container, function(state)
        Visuals.setVelocityMeterEnabled(state)
    end)

    -- Strafe Helper Toggle
    visualToggles.strafe = createToggle("Strafe Helper", container, function(state)
        Visuals.setStrafeHelperEnabled(state)
    end)

    -- Session Stats Toggle
    visualToggles.stats = createToggle("Session Stats", container, function(state)
        Visuals.setSessionStatsEnabled(state)
    end)

    -- Debug HUD Toggle
    visualToggles.debug = createToggle("Debug HUD", container, function(state)
        Visuals.setDebugHUDEnabled(state)
    end)

    return container
end

-- Create Physics Tab
local function createPhysicsTab(parent)
    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
        Visible = false,
    })

    local layout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        Parent = container,
    })

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        container.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
    end)

    local config = Physics.getConfig()

    -- Preset Dropdown
    createDropdown("Preset", {"CS 1.6 Classic", "CS:GO Style", "TF2 Scout", "Quake", "Easy Mode"}, function(preset)
        Physics.loadPreset(preset)
        -- Update all sliders
        local newConfig = Physics.getConfig()
        physicsSliders.friction:Set(newConfig.GROUND_FRICTION)
        physicsSliders.groundAccel:Set(newConfig.GROUND_ACCELERATE)
        physicsSliders.groundSpeed:Set(newConfig.GROUND_SPEED)
        physicsSliders.airAccel:Set(newConfig.AIR_ACCELERATE)
        physicsSliders.airCap:Set(newConfig.AIR_CAP)
        physicsSliders.jumpPower:Set(newConfig.JUMP_POWER)
    end, container)

    -- Physics Sliders
    physicsSliders.friction = createSlider("Ground Friction", 0, 20, config.GROUND_FRICTION, function(value)
        Physics.setConfig("GROUND_FRICTION", value)
    end, container)

    physicsSliders.groundAccel = createSlider("Ground Acceleration", 1, 50, config.GROUND_ACCELERATE, function(value)
        Physics.setConfig("GROUND_ACCELERATE", value)
    end, container)

    physicsSliders.groundSpeed = createSlider("Ground Speed", 10, 50, config.GROUND_SPEED, function(value)
        Physics.setConfig("GROUND_SPEED", value)
    end, container)

    physicsSliders.airAccel = createSlider("Air Acceleration", 1, 100, config.AIR_ACCELERATE, function(value)
        Physics.setConfig("AIR_ACCELERATE", value)
    end, container)

    physicsSliders.airCap = createSlider("Air Cap", 0.1, 30, config.AIR_CAP, function(value)
        Physics.setConfig("AIR_CAP", value)
    end, container)

    physicsSliders.jumpPower = createSlider("Jump Power", 20, 100, config.JUMP_POWER, function(value)
        Physics.setConfig("JUMP_POWER", value)
    end, container)

    return container
end

-- Create Trails Tab
local function createTrailsTab(parent)
    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
        Visible = false,
    })

    local layout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        Parent = container,
    })

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        container.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
    end)

    local trailConfig = Trails.getConfig()

    -- Enable Toggle
    createToggle("Enable Trails", container, function(state)
        Trails.setEnabled(state)
    end)

    -- Use Decals Toggle
    createToggle("Use Decals", container, function(state)
        Trails.setUseDecals(state)
    end)

    -- Decal Texture Input
    createInput("Decal Texture ID", "rbxassetid://8508980536", function(text)
        Trails.setDecalTexture(text)
        -- Auto-preview
        if text and text ~= "" then
            task.delay(0.1, function()
                Trails.previewDecal()
            end)
        end
    end, container)

    -- Preview Button
    createButton("Preview Decal", function()
        Trails.previewDecal()
    end, container)

    -- Customization Sliders
    createSlider("Max Trail Parts", 5, 50, trailConfig.maxParts, function(value)
        Trails.setConfig("maxParts", value)
    end, container)

    createSlider("Transparency", 0, 1, trailConfig.transparency, function(value)
        Trails.setTransparency(value)
    end, container)

    createSlider("Spin Speed (deg/s)", 0, 360, trailConfig.spinSpeed, function(value)
        Trails.setSpinSpeed(value)
    end, container)

    createSlider("Rotation Range (deg)", 0, 360, trailConfig.rotationRange, function(value)
        Trails.setRotationRange(value)
    end, container)

    return container
end

-- Create Sounds Tab
local function createSoundsTab(parent)
    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
        Visible = false,
    })

    local layout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        Parent = container,
    })

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        container.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
    end)

    local soundConfig = Sounds.getConfig()

    -- Enable Toggle
    createToggle("Enable Sounds", container, function(state)
        Sounds.setEnabled(state)
    end)

    -- Jump Sound Input
    createInput("Jump Sound ID", "rbxassetid://0", function(text)
        Sounds.setJumpSound(text)
        -- Auto-preview
        if text and text ~= "" then
            task.delay(0.1, function()
                Sounds.previewJump()
            end)
        end
    end, container)

    -- Test Jump Sound Button
    createButton("Test Jump Sound", function()
        Sounds.previewJump()
    end, container)

    -- Jump Volume & Pitch
    createSlider("Jump Volume", 0, 1, soundConfig.jumpVolume, function(value)
        Sounds.setJumpSound(nil, value, nil)
    end, container)

    createSlider("Jump Pitch", 0.5, 2, soundConfig.jumpPitch, function(value)
        Sounds.setJumpSound(nil, nil, value)
    end, container)

    -- Land Sound Input
    createInput("Land Sound ID", "rbxassetid://0", function(text)
        Sounds.setLandSound(text)
        -- Auto-preview
        if text and text ~= "" then
            task.delay(0.1, function()
                Sounds.previewLand()
            end)
        end
    end, container)

    -- Test Land Sound Button
    createButton("Test Land Sound", function()
        Sounds.previewLand()
    end, container)

    -- Land Volume & Pitch
    createSlider("Land Volume", 0, 1, soundConfig.landVolume, function(value)
        Sounds.setLandSound(nil, value, nil)
    end, container)

    createSlider("Land Pitch", 0.5, 2, soundConfig.landPitch, function(value)
        Sounds.setLandSound(nil, nil, value)
    end, container)

    return container
end

-- Create Config Tab
local function createConfigTab(parent)
    local container = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = parent,
        Visible = false,
    })

    local layout = create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 10),
        Parent = container,
    })

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        container.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
    end)

    -- Export Config Button
    createButton("Export Config to Clipboard", function()
        local exportData = {
            physics = Physics.exportConfig(),
            visuals = Visuals.exportConfig(),
            trails = Trails.exportConfig(),
            sounds = Sounds.exportConfig(),
        }

        local encoded = HttpService:JSONEncode(exportData)

        if setclipboard then
            setclipboard(encoded)
            print("[BHOP HUB] Config copied to clipboard!")
        else
            warn("[BHOP HUB] setclipboard not available in this executor")
        end
    end, container)

    -- Import Config Input
    local importInput = createInput("Import Config", "Paste config JSON here...", function(text)
        if text == "" then return end

        local success = pcall(function()
            local importData = HttpService:JSONDecode(text)

            if importData.physics then Physics.importConfig(importData.physics) end
            if importData.visuals then Visuals.importConfig(importData.visuals) end
            if importData.trails then Trails.importConfig(importData.trails) end
            if importData.sounds then Sounds.importConfig(importData.sounds) end

            -- Update all sliders
            local newConfig = Physics.getConfig()
            physicsSliders.friction:Set(newConfig.GROUND_FRICTION)
            physicsSliders.groundAccel:Set(newConfig.GROUND_ACCELERATE)
            physicsSliders.groundSpeed:Set(newConfig.GROUND_SPEED)
            physicsSliders.airAccel:Set(newConfig.AIR_ACCELERATE)
            physicsSliders.airCap:Set(newConfig.AIR_CAP)
            physicsSliders.jumpPower:Set(newConfig.JUMP_POWER)

            print("[BHOP HUB] Config imported successfully!")
        end)

        if not success then
            warn("[BHOP HUB] Failed to import config - invalid JSON")
        end
    end, container)

    -- Reset to Defaults Button
    createButton("Reset to CS 1.6 Defaults", function()
        Physics.loadPreset("CS 1.6 Classic")
        -- Update all sliders
        local newConfig = Physics.getConfig()
        physicsSliders.friction:Set(newConfig.GROUND_FRICTION)
        physicsSliders.groundAccel:Set(newConfig.GROUND_ACCELERATE)
        physicsSliders.groundSpeed:Set(newConfig.GROUND_SPEED)
        physicsSliders.airAccel:Set(newConfig.AIR_ACCELERATE)
        physicsSliders.airCap:Set(newConfig.AIR_CAP)
        physicsSliders.jumpPower:Set(newConfig.JUMP_POWER)
        print("[BHOP HUB] Reset to CS 1.6 defaults")
    end, container)

    -- Spacer
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = container,
    })

    -- Section header
    local keybindsHeader = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Text = "⌨️ KEYBINDS",
        TextColor3 = theme.accent,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    -- Get current keybinds
    local keybinds = Physics.getKeybinds()

    -- Toggle Bhop Keybind
    local toggleKeyInput = createInput("Toggle Bhop Key", keybinds.toggleKey.Name, function(text)
        local keyCode = Enum.KeyCode[text]
        if keyCode then
            Physics.setKeybind("toggleKey", keyCode)
            print("[BHOP HUB] Toggle key set to: " .. text)
        else
            warn("[BHOP HUB] Invalid key: " .. text)
        end
    end, container)

    -- Jump Keybind
    local jumpKeyInput = createInput("Jump Key", keybinds.jumpKey.Name, function(text)
        local keyCode = Enum.KeyCode[text]
        if keyCode then
            Physics.setKeybind("jumpKey", keyCode)
            print("[BHOP HUB] Jump key set to: " .. text)
        else
            warn("[BHOP HUB] Invalid key: " .. text)
        end
    end, container)

    -- UI Toggle Keybind
    local uiToggleKeyInput = createInput("Toggle UI Key", keybinds.uiToggleKey.Name, function(text)
        local keyCode = Enum.KeyCode[text]
        if keyCode then
            Physics.setKeybind("uiToggleKey", keyCode)
            print("[BHOP HUB] UI toggle key set to: " .. text)
        else
            warn("[BHOP HUB] Invalid key: " .. text)
        end
    end, container)

    -- Keybind help text
    local helpText = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Text = "Enter key names like: B, Space, LeftShift, RightShift, etc.\nChanges save automatically in config export/import.",
        TextColor3 = theme.textDim,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = container,
    })

    return container
end

-- Initialize UI
function UI.createWindow(physics, visuals, trails, sounds, stats)
    Physics = physics
    Visuals = visuals
    Trails = trails
    Sounds = sounds
    Stats = stats

    local tabsContainer, contentContainer = createWindow()

    -- Create tab contents
    local dashboardContent = createDashboard(contentContainer)
    local physicsContent = createPhysicsTab(contentContainer)
    local trailsContent = createTrailsTab(contentContainer)
    local soundsContent = createSoundsTab(contentContainer)
    local configContent = createConfigTab(contentContainer)

    -- Tab buttons
    local tabs = {
        {name = "Dashboard", content = dashboardContent},
        {name = "Physics", content = physicsContent},
        {name = "Trails", content = trailsContent},
        {name = "Sounds", content = soundsContent},
        {name = "Config", content = configContent},
    }

    local tabButtons = {}

    for i, tab in ipairs(tabs) do
        local tabButton = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = tab.name == currentTab and theme.accent or theme.surface,
            BorderSizePixel = 0,
            Text = tab.name,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            LayoutOrder = i,
            Parent = tabsContainer,
        })
        createCorner(6).Parent = tabButton

        tabButton.MouseButton1Click:Connect(function()
            -- Update tab visuals
            for _, btn in ipairs(tabButtons) do
                tween(btn, { BackgroundColor3 = theme.surface })
            end
            tween(tabButton, { BackgroundColor3 = theme.accent })

            -- Update content visibility
            for _, t in ipairs(tabs) do
                t.content.Visible = (t.name == tab.name)
            end

            currentTab = tab.name
        end)

        table.insert(tabButtons, tabButton)
    end

    -- Auto-layout for tabs
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = tabsContainer,
    })

    -- Setup update loop (use Heartbeat for consistency)
    local wasGrounded = false
    RunService.Heartbeat:Connect(function(dt)
        -- Use horizontal speed (2D)
        local speed2D = Physics.getSpeed2D()
        local onGround = Physics.isGrounded()

        -- Keep ground state in sync even when disabled
        if not Physics.isEnabled() then
            wasGrounded = onGround
            return
        end

        -- Track jump stats independently (so disabling sounds doesn't break stats)
        if (not wasGrounded) and onGround then
            local cfg = Physics.getConfig()
            local isPerfect = speed2D > (cfg.GROUND_SPEED * 0.9)
            Stats.recordJump(isPerfect)
        end
        wasGrounded = onGround

        -- Update all modules with horizontal speed
        Visuals.update(speed2D, onGround, Stats.getStats())
        Trails.update(speed2D, dt)
        Sounds.update(speed2D, onGround)
        Stats.updateStats(speed2D, dt)
    end)
end

-- Sync toggle from B key press
function UI.syncToggle(enabled)
    if bhopToggle then
        bhopToggle:Set(enabled)
    end
end

-- Toggle window visibility
function UI.toggleWindow()
    if screenGui then
        screenGui.Enabled = not screenGui.Enabled
    end
end

return UI
