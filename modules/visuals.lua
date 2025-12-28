-- Visuals Module
-- Handles velocity meter, strafe helper, session stats display, and debug HUD

local Visuals = {}

-- State
local player, Physics
local visualGui

-- Configuration
local visualConfig = {
    showDebugHUD = false,
    showVelocityMeter = false,
    showStrafeHelper = false,
    showSessionStats = false,
}

-- GUI Elements
local velocityMeterFrame, velocityValue, velocityBarFill
local strafeHelperFrame, directionArrow, strafeQualityLabel
local sessionStatsFrame, jumpCountLabel, perfectJumpLabel, topSpeedLabel, avgSpeedLabel, distanceLabel, sessionTimeLabel
local debugHUDFrame, debugSpeedLabel, debugVelXLabel, debugVelZLabel, debugGroundLabel, debugFrictionLabel, debugAirAccelLabel, debugMaxSpeedLabel

local function createVelocityMeter()
    velocityMeterFrame = Instance.new("Frame")
    velocityMeterFrame.Name = "VelocityMeter"
    velocityMeterFrame.Size = UDim2.new(0, 250, 0, 150)
    velocityMeterFrame.Position = UDim2.new(1, -270, 1, -170)
    velocityMeterFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    velocityMeterFrame.BackgroundTransparency = 0.2
    velocityMeterFrame.BorderSizePixel = 0
    velocityMeterFrame.Visible = false
    velocityMeterFrame.Parent = visualGui

    local velocityCorner = Instance.new("UICorner")
    velocityCorner.CornerRadius = UDim.new(0, 8)
    velocityCorner.Parent = velocityMeterFrame

    local velocityTitle = Instance.new("TextLabel")
    velocityTitle.Size = UDim2.new(1, 0, 0, 25)
    velocityTitle.Position = UDim2.new(0, 0, 0, 5)
    velocityTitle.BackgroundTransparency = 1
    velocityTitle.Text = "VELOCITY"
    velocityTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
    velocityTitle.TextSize = 14
    velocityTitle.Font = Enum.Font.GothamBold
    velocityTitle.Parent = velocityMeterFrame

    velocityValue = Instance.new("TextLabel")
    velocityValue.Size = UDim2.new(1, 0, 0, 60)
    velocityValue.Position = UDim2.new(0, 0, 0, 30)
    velocityValue.BackgroundTransparency = 1
    velocityValue.Text = "0"
    velocityValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    velocityValue.TextSize = 48
    velocityValue.Font = Enum.Font.GothamBold
    velocityValue.Parent = velocityMeterFrame

    local velocityBar = Instance.new("Frame")
    velocityBar.Size = UDim2.new(0.9, 0, 0, 8)
    velocityBar.Position = UDim2.new(0.05, 0, 0, 100)
    velocityBar.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    velocityBar.BorderSizePixel = 0
    velocityBar.Parent = velocityMeterFrame

    local velocityBarCorner = Instance.new("UICorner")
    velocityBarCorner.CornerRadius = UDim.new(0, 4)
    velocityBarCorner.Parent = velocityBar

    velocityBarFill = Instance.new("Frame")
    velocityBarFill.Size = UDim2.new(0, 0, 1, 0)
    velocityBarFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    velocityBarFill.BorderSizePixel = 0
    velocityBarFill.Parent = velocityBar

    local velocityBarFillCorner = Instance.new("UICorner")
    velocityBarFillCorner.CornerRadius = UDim.new(0, 4)
    velocityBarFillCorner.Parent = velocityBarFill

    local velocitySubtext = Instance.new("TextLabel")
    velocitySubtext.Size = UDim2.new(1, 0, 0, 20)
    velocitySubtext.Position = UDim2.new(0, 0, 0, 115)
    velocitySubtext.BackgroundTransparency = 1
    velocitySubtext.Text = "studs/s"
    velocitySubtext.TextColor3 = Color3.fromRGB(150, 150, 160)
    velocitySubtext.TextSize = 12
    velocitySubtext.Font = Enum.Font.Gotham
    velocitySubtext.Parent = velocityMeterFrame
end

local function createStrafeHelper()
    strafeHelperFrame = Instance.new("Frame")
    strafeHelperFrame.Name = "StrafeHelper"
    strafeHelperFrame.Size = UDim2.new(0, 200, 0, 200)
    strafeHelperFrame.Position = UDim2.new(0.5, -100, 0.5, -100)
    strafeHelperFrame.BackgroundTransparency = 1
    strafeHelperFrame.Visible = false
    strafeHelperFrame.Parent = visualGui

    local centerCircle = Instance.new("Frame")
    centerCircle.Size = UDim2.new(0, 20, 0, 20)
    centerCircle.Position = UDim2.new(0.5, -10, 0.5, -10)
    centerCircle.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    centerCircle.BackgroundTransparency = 0.3
    centerCircle.BorderSizePixel = 0
    centerCircle.Parent = strafeHelperFrame

    local centerCorner = Instance.new("UICorner")
    centerCorner.CornerRadius = UDim.new(1, 0)
    centerCorner.Parent = centerCircle

    directionArrow = Instance.new("ImageLabel")
    directionArrow.Size = UDim2.new(0, 60, 0, 60)
    directionArrow.Position = UDim2.new(0.5, -30, 0, 20)
    directionArrow.BackgroundTransparency = 1
    directionArrow.Image = "rbxassetid://7733717447"
    directionArrow.ImageColor3 = Color3.fromRGB(100, 255, 100)
    directionArrow.Rotation = 0
    directionArrow.Parent = strafeHelperFrame

    strafeQualityLabel = Instance.new("TextLabel")
    strafeQualityLabel.Size = UDim2.new(1, 0, 0, 30)
    strafeQualityLabel.Position = UDim2.new(0, 0, 1, -30)
    strafeQualityLabel.BackgroundTransparency = 1
    strafeQualityLabel.Text = "Efficiency: 0%"
    strafeQualityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    strafeQualityLabel.TextSize = 16
    strafeQualityLabel.Font = Enum.Font.GothamBold
    strafeQualityLabel.Parent = strafeHelperFrame
end

local function createSessionStats()
    sessionStatsFrame = Instance.new("Frame")
    sessionStatsFrame.Name = "SessionStats"
    sessionStatsFrame.Size = UDim2.new(0, 220, 0, 200)
    sessionStatsFrame.Position = UDim2.new(0, 20, 1, -220)
    sessionStatsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    sessionStatsFrame.BackgroundTransparency = 0.2
    sessionStatsFrame.BorderSizePixel = 0
    sessionStatsFrame.Visible = false
    sessionStatsFrame.Parent = visualGui

    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 8)
    statsCorner.Parent = sessionStatsFrame

    local statsTitle = Instance.new("TextLabel")
    statsTitle.Size = UDim2.new(1, 0, 0, 30)
    statsTitle.BackgroundTransparency = 1
    statsTitle.Text = "📊 SESSION STATS"
    statsTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
    statsTitle.TextSize = 14
    statsTitle.Font = Enum.Font.GothamBold
    statsTitle.Parent = sessionStatsFrame

    local statsContainer = Instance.new("Frame")
    statsContainer.Size = UDim2.new(1, -20, 1, -40)
    statsContainer.Position = UDim2.new(0, 10, 0, 35)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = sessionStatsFrame

    local function createStatLabel(text, yPos)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 0, 0, yPos)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(200, 200, 210)
        label.TextSize = 12
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = statsContainer
        return label
    end

    jumpCountLabel = createStatLabel("Jumps: 0", 0)
    perfectJumpLabel = createStatLabel("Perfect: 0 (0%)", 22)
    topSpeedLabel = createStatLabel("Top Speed: 0.0", 44)
    avgSpeedLabel = createStatLabel("Avg Speed: 0.0", 66)
    distanceLabel = createStatLabel("Distance: 0 studs", 88)
    sessionTimeLabel = createStatLabel("Time: 0:00", 110)
end

local function createDebugHUD()
    debugHUDFrame = Instance.new("Frame")
    debugHUDFrame.Name = "DebugHUD"
    debugHUDFrame.Size = UDim2.new(0, 280, 0, 200)
    debugHUDFrame.Position = UDim2.new(0, 20, 0, 20)
    debugHUDFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    debugHUDFrame.BackgroundTransparency = 0.2
    debugHUDFrame.BorderSizePixel = 0
    debugHUDFrame.Visible = false
    debugHUDFrame.Parent = visualGui

    local debugCorner = Instance.new("UICorner")
    debugCorner.CornerRadius = UDim.new(0, 8)
    debugCorner.Parent = debugHUDFrame

    local debugTitle = Instance.new("TextLabel")
    debugTitle.Size = UDim2.new(1, 0, 0, 30)
    debugTitle.BackgroundTransparency = 1
    debugTitle.Text = "🔧 DEBUG INFO"
    debugTitle.TextColor3 = Color3.fromRGB(255, 150, 50)
    debugTitle.TextSize = 14
    debugTitle.Font = Enum.Font.GothamBold
    debugTitle.Parent = debugHUDFrame

    local debugContainer = Instance.new("Frame")
    debugContainer.Size = UDim2.new(1, -20, 1, -40)
    debugContainer.Position = UDim2.new(0, 10, 0, 35)
    debugContainer.BackgroundTransparency = 1
    debugContainer.Parent = debugHUDFrame

    local function createDebugLabel(text, yPos)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 0, 0, yPos)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(200, 200, 210)
        label.TextSize = 11
        label.Font = Enum.Font.RobotoMono
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = debugContainer
        return label
    end

    debugSpeedLabel = createDebugLabel("Speed: 0.0", 0)
    debugVelXLabel = createDebugLabel("Vel X: 0.0", 22)
    debugVelZLabel = createDebugLabel("Vel Z: 0.0", 44)
    debugGroundLabel = createDebugLabel("Ground: false", 66)
    debugFrictionLabel = createDebugLabel("Friction: 6", 88)
    debugAirAccelLabel = createDebugLabel("Air Accel: 16", 110)
    debugMaxSpeedLabel = createDebugLabel("Max Speed: 0.0", 132)
end

-- Module API
function Visuals.init(plr, physics)
    player = plr
    Physics = physics

    -- Create Visual GUI Container
    visualGui = Instance.new("ScreenGui")
    visualGui.Name = "BhopVisualsGUI"
    visualGui.ResetOnSpawn = false
    visualGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    visualGui.Parent = player:WaitForChild("PlayerGui")

    -- Create all visual elements
    createVelocityMeter()
    createStrafeHelper()
    createSessionStats()
    createDebugHUD()
end

function Visuals.update(speed, onGround, sessionStats)
    -- Update Velocity Meter
    if visualConfig.showVelocityMeter then
        velocityMeterFrame.Visible = true
        velocityValue.Text = string.format("%.0f", speed)

        local speedPercent = math.clamp(speed / 100, 0, 1)
        velocityValue.TextColor3 = Color3.fromRGB(
            255 * (1 - speedPercent) + 100 * speedPercent,
            255 * (1 - speedPercent) + 200 * speedPercent,
            255
        )

        local barPercent = math.clamp(speed / 150, 0, 1)
        velocityBarFill.Size = UDim2.new(barPercent, 0, 1, 0)
        velocityBarFill.BackgroundColor3 = velocityValue.TextColor3
    else
        velocityMeterFrame.Visible = false
    end

    -- Update Strafe Helper
    if visualConfig.showStrafeHelper then
        strafeHelperFrame.Visible = true

        local wishDir = Physics.getWishDir()
        if wishDir.Magnitude > 0 then
            local velocity = Physics.getVelocity()
            local angle = math.atan2(wishDir.X, wishDir.Z)
            directionArrow.Rotation = math.deg(-angle)

            local dot = velocity.Unit:Dot(wishDir)
            local efficiency = math.clamp((dot + 1) / 2, 0, 1)
            strafeQualityLabel.Text = string.format("Efficiency: %.0f%%", efficiency * 100)

            if efficiency > 0.9 then
                directionArrow.ImageColor3 = Color3.fromRGB(100, 255, 100)
            elseif efficiency > 0.7 then
                directionArrow.ImageColor3 = Color3.fromRGB(255, 255, 100)
            else
                directionArrow.ImageColor3 = Color3.fromRGB(255, 100, 100)
            end
        end
    else
        strafeHelperFrame.Visible = false
    end

    -- Update Session Stats
    if visualConfig.showSessionStats and sessionStats then
        sessionStatsFrame.Visible = true

        jumpCountLabel.Text = string.format("Jumps: %d", sessionStats.totalJumps)

        local perfectPercent = sessionStats.totalJumps > 0
            and (sessionStats.perfectJumps / sessionStats.totalJumps * 100)
            or 0
        perfectJumpLabel.Text = string.format("Perfect: %d (%.1f%%)",
            sessionStats.perfectJumps, perfectPercent)

        topSpeedLabel.Text = string.format("Top Speed: %.1f", sessionStats.topSpeed)
        avgSpeedLabel.Text = string.format("Avg Speed: %.1f", sessionStats.avgSpeed)
        distanceLabel.Text = string.format("Distance: %.0f studs", sessionStats.totalDistance)

        local minutes = math.floor(sessionStats.sessionTime / 60)
        local seconds = math.floor(sessionStats.sessionTime % 60)
        sessionTimeLabel.Text = string.format("Time: %d:%02d", minutes, seconds)
    else
        sessionStatsFrame.Visible = false
    end

    -- Update Debug HUD
    if visualConfig.showDebugHUD then
        debugHUDFrame.Visible = true

        local velocity = Physics.getVelocity()
        local config = Physics.getConfig()

        debugSpeedLabel.Text = string.format("Speed: %.1f", speed)
        debugVelXLabel.Text = string.format("Vel X: %.1f", velocity.X)
        debugVelZLabel.Text = string.format("Vel Z: %.1f", velocity.Z)
        debugGroundLabel.Text = string.format("Ground: %s", tostring(onGround))
        debugFrictionLabel.Text = string.format("Friction: %d", config.GROUND_FRICTION)
        debugAirAccelLabel.Text = string.format("Air Accel: %d", config.AIR_ACCELERATE)
        debugMaxSpeedLabel.Text = string.format("Max Speed: %.1f", sessionStats and sessionStats.topSpeed or 0)
    else
        debugHUDFrame.Visible = false
    end
end

function Visuals.setVelocityMeterEnabled(value)
    visualConfig.showVelocityMeter = value
end

function Visuals.setStrafeHelperEnabled(value)
    visualConfig.showStrafeHelper = value
end

function Visuals.setSessionStatsEnabled(value)
    visualConfig.showSessionStats = value
end

function Visuals.setDebugHUDEnabled(value)
    visualConfig.showDebugHUD = value
end

function Visuals.getConfig()
    return visualConfig
end

function Visuals.exportConfig()
    return {
        visuals = visualConfig,
    }
end

function Visuals.importConfig(data)
    if data.visuals then
        for key, value in pairs(data.visuals) do
            if visualConfig[key] ~= nil then
                visualConfig[key] = value
            end
        end
    end
end

return Visuals
