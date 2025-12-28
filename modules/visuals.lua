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
local debugHUDFrame, debugSpeedLabel, debugVelXLabel, debugVelZLabel, debugGroundLabel
local debugWishSpeedLabel, debugCurrentSpeedLabel, debugAddSpeedLabel, debugAccelSpeedLabel
local debugSurfaceAngleLabel, debugDtLabel, debugCoyoteLabel, debugJumpBufferLabel

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
    debugHUDFrame.Size = UDim2.new(0, 280, 0, 305)
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

    debugSpeedLabel = createDebugLabel("Speed 2D: 0.0", 0)
    debugVelXLabel = createDebugLabel("Vel X: 0.0", 22)
    debugVelZLabel = createDebugLabel("Vel Z: 0.0", 44)
    debugGroundLabel = createDebugLabel("Ground: false", 66)
    debugSurfaceAngleLabel = createDebugLabel("Surface °: 0.0", 88)
    debugWishSpeedLabel = createDebugLabel("Wish Speed: 0.0", 110)
    debugCurrentSpeedLabel = createDebugLabel("Current Speed: 0.0", 132)
    debugAddSpeedLabel = createDebugLabel("Add Speed: 0.0", 154)
    debugAccelSpeedLabel = createDebugLabel("Accel Speed: 0.0", 176)
    debugDtLabel = createDebugLabel("dt: 0.000", 198)
    debugCoyoteLabel = createDebugLabel("Coyote: false", 220)
    debugJumpBufferLabel = createDebugLabel("Jump Buffer: false", 242)
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
            local config = Physics.getConfig()

            -- Calculate arrow rotation
            local angle = math.atan2(wishDir.X, wishDir.Z)
            directionArrow.Rotation = math.deg(-angle)

            -- CS/Quake-style strafe efficiency calculation
            local speed2D = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
            local efficiency = 0
            local actualAngleDeg = 0
            local optimalAngleDeg = 0

            if speed2D > 0.1 then
                -- Calculate actual angle between velocity and wish direction
                local velocityDir = Vector3.new(velocity.X, 0, velocity.Z).Unit
                local wishDirFlat = Vector3.new(wishDir.X, 0, wishDir.Z).Unit
                local dot = math.clamp(velocityDir:Dot(wishDirFlat), -1, 1)
                actualAngleDeg = math.deg(math.acos(dot))

                -- Calculate optimal strafe angle
                if speed2D > config.AIR_CAP then
                    -- At speeds above AIR_CAP, there's an optimal angle
                    local ratio = math.clamp(config.AIR_CAP / speed2D, 0, 1)
                    optimalAngleDeg = math.deg(math.acos(ratio))
                else
                    -- Below AIR_CAP, optimal is to strafe directly forward
                    optimalAngleDeg = 0
                end

                -- Calculate efficiency based on angular deviation
                local angleDiff = math.abs(actualAngleDeg - optimalAngleDeg)

                -- Speed-based tolerance (tighter at low speeds, looser at high speeds)
                local speedFactor = math.clamp(speed2D / 50, 0.3, 1)
                local maxTolerance = 15 + (25 * speedFactor)  -- 15° at low speed, up to 40° at high speed

                efficiency = math.clamp(1 - (angleDiff / maxTolerance), 0, 1)

                -- Update label with angle info
                if visualConfig.showDebugHUD then
                    strafeQualityLabel.Text = string.format("Efficiency: %.0f%% (%.0f° / %.0f°)",
                        efficiency * 100, actualAngleDeg, optimalAngleDeg)
                else
                    strafeQualityLabel.Text = string.format("Efficiency: %.0f%%", efficiency * 100)
                end
            else
                strafeQualityLabel.Text = "Efficiency: 0%"
            end

            -- More intuitive color feedback
            if efficiency > 0.85 then
                -- Perfect (green)
                directionArrow.ImageColor3 = Color3.fromRGB(100, 255, 100)
            elseif efficiency > 0.65 then
                -- Good (yellow-green)
                directionArrow.ImageColor3 = Color3.fromRGB(200, 255, 100)
            elseif efficiency > 0.45 then
                -- Okay (yellow)
                directionArrow.ImageColor3 = Color3.fromRGB(255, 255, 100)
            elseif efficiency > 0.25 then
                -- Poor (orange)
                directionArrow.ImageColor3 = Color3.fromRGB(255, 180, 100)
            else
                -- Bad (red)
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
        local vel2D = Physics.getVelocity2D()
        local debugData = Physics.getDebugData()

        debugSpeedLabel.Text = string.format("Speed 2D: %.1f", speed)
        debugVelXLabel.Text = string.format("Vel X: %.1f", vel2D.X)
        debugVelZLabel.Text = string.format("Vel Z: %.1f", vel2D.Y)
        debugGroundLabel.Text = string.format("Ground: %s", tostring(onGround))
        debugSurfaceAngleLabel.Text = string.format("Surface °: %.1f", debugData.surfaceAngle)
        debugWishSpeedLabel.Text = string.format("Wish Speed: %.1f", debugData.wishSpeed)
        debugCurrentSpeedLabel.Text = string.format("Current Speed: %.1f", debugData.currentSpeed)
        debugAddSpeedLabel.Text = string.format("Add Speed: %.1f", debugData.addSpeed)
        debugAccelSpeedLabel.Text = string.format("Accel Speed: %.1f", debugData.accelSpeed)
        debugDtLabel.Text = string.format("dt: %.3f", debugData.dt)
        debugCoyoteLabel.Text = string.format("Coyote: %s", tostring(debugData.coyoteActive))
        debugJumpBufferLabel.Text = string.format("Jump Buffer: %s", tostring(debugData.jumpBuffered))
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
