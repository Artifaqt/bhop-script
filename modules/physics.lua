-- Physics Module (Source Engine Style)
-- Handles all bhop physics calculations with CS/Source fidelity

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Physics = {}

-- State
local player, character, humanoid, rootPart
local bhopEnabled = false
local autoHop = false
local isTyping = false

-- Movement state (2D horizontal only)
local vel2 = Vector2.new(0, 0)  -- Horizontal velocity (X, Z)
local maxSpeedReached = 0

-- Grounding state
local isGrounded = false
local groundNormal = Vector3.new(0, 1, 0)
local lastGroundTime = 0
local lastJumpRequestTime = 0
local justLanded = false

-- Input cache
local cachedInputs = {
    forward = 0,
    right = 0,
    jump = false,
}

-- Store originals
local originalWalkSpeed
local originalJumpPower

-- Configuration (CS 1.6 defaults)
local config = {
    -- Ground movement
    GROUND_FRICTION = 4,
    GROUND_ACCELERATE = 5,  -- Reduced for Roblox scale
    GROUND_SPEED = 30,  -- Target ground speed in Roblox units
    STOP_SPEED = 1,

    -- Air movement
    AIR_ACCELERATE = 50,  -- Higher for responsive strafing
    AIR_CAP = 0.7,  -- Air speed cap multiplier (70% of ground speed)

    -- Jump
    JUMP_POWER = 50,

    -- Grounding
    GROUND_DISTANCE = 0.2,  -- How far to raycast for ground
    SLOPE_LIMIT = 45,  -- Max walkable slope in degrees
    SNAP_DOWN_DISTANCE = 0.15,  -- Snap-to-ground distance

    -- Feel improvements
    COYOTE_TIME = 0.1,  -- Grace period after leaving ground (seconds)
    JUMP_BUFFER_TIME = 0.1,  -- Jump buffer window (seconds)
}

-- Keybinds
local keybindConfig = {
    toggleKey = Enum.KeyCode.B,
    jumpKey = Enum.KeyCode.Space,
    uiToggleKey = Enum.KeyCode.RightShift,
}

-- Movement debug data (exposed for HUD)
local debugData = {
    wishSpeed = 0,
    currentSpeed = 0,
    addSpeed = 0,
    accelSpeed = 0,
    onGround = false,
    surfaceAngle = 0,
    dt = 0,
    speed2D = 0,
    coyoteActive = false,
    jumpBuffered = false,
}

-- Preset Library (Roblox scale)
local presetLibrary = {
    ["CS 1.6 Classic"] = {
        GROUND_FRICTION = 4,
        GROUND_ACCELERATE = 5,
        AIR_ACCELERATE = 50,
        GROUND_SPEED = 30,
        AIR_CAP = 0.7,
        JUMP_POWER = 50,
        STOP_SPEED = 1,
        SLOPE_LIMIT = 45,
        GROUND_DISTANCE = 0.2,
        SNAP_DOWN_DISTANCE = 0.15,
        COYOTE_TIME = 0.1,
        JUMP_BUFFER_TIME = 0.1,
    },
    ["CS:GO Style"] = {
        GROUND_FRICTION = 5.2,
        GROUND_ACCELERATE = 7,
        AIR_ACCELERATE = 200,  -- CS:GO has very high air accel
        GROUND_SPEED = 30,
        AIR_CAP = 0.3,  -- Very low air cap for tight control
        JUMP_POWER = 55,
        STOP_SPEED = 1,
        SLOPE_LIMIT = 45,
        GROUND_DISTANCE = 0.2,
        SNAP_DOWN_DISTANCE = 0.15,
        COYOTE_TIME = 0.1,
        JUMP_BUFFER_TIME = 0.1,
    },
    ["TF2 Scout"] = {
        GROUND_FRICTION = 4,
        GROUND_ACCELERATE = 8,
        AIR_ACCELERATE = 50,
        GROUND_SPEED = 40,  -- Scout is faster
        AIR_CAP = 0.6,
        JUMP_POWER = 58,
        STOP_SPEED = 1,
        SLOPE_LIMIT = 50,
        GROUND_DISTANCE = 0.2,
        SNAP_DOWN_DISTANCE = 0.15,
        COYOTE_TIME = 0.1,
        JUMP_BUFFER_TIME = 0.1,
    },
    ["Quake"] = {
        GROUND_FRICTION = 6,
        GROUND_ACCELERATE = 5,
        AIR_ACCELERATE = 5,  -- Quake has low air accel
        GROUND_SPEED = 35,
        AIR_CAP = 2.0,  -- But allows high speeds through strafing
        JUMP_POWER = 60,
        STOP_SPEED = 1,
        SLOPE_LIMIT = 50,
        GROUND_DISTANCE = 0.2,
        SNAP_DOWN_DISTANCE = 0.15,
        COYOTE_TIME = 0.1,
        JUMP_BUFFER_TIME = 0.1,
    },
    ["Easy Mode"] = {
        GROUND_FRICTION = 2,
        GROUND_ACCELERATE = 10,
        AIR_ACCELERATE = 100,
        GROUND_SPEED = 35,
        AIR_CAP = 1.2,
        JUMP_POWER = 60,
        STOP_SPEED = 0.5,
        SLOPE_LIMIT = 60,
        GROUND_DISTANCE = 0.2,
        SNAP_DOWN_DISTANCE = 0.15,
        COYOTE_TIME = 0.15,  -- More forgiving
        JUMP_BUFFER_TIME = 0.15,  -- More forgiving
    },
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

-- Clamp delta time to prevent huge spikes on lag
local function clampDt(dt)
    return math.clamp(dt, 1/240, 1/30)
end

-- Get yaw-only forward/right vectors (ignore pitch)
local function getYawVectors()
    local camera = workspace.CurrentCamera
    local lookVector = camera.CFrame.LookVector
    local rightVector = camera.CFrame.RightVector

    -- Flatten to horizontal plane (ignore Y component) and normalize
    local forward = Vector2.new(lookVector.X, lookVector.Z)
    local right = Vector2.new(rightVector.X, rightVector.Z)

    if forward:Dot(forward) > 0.01 then
        forward = forward.Unit
    else
        forward = Vector2.new(0, 0)
    end

    if right:Dot(right) > 0.01 then
        right = right.Unit
    else
        right = Vector2.new(0, 0)
    end

    return forward, right
end

-- Sample inputs once per tick
local function sampleInputs()
    if isTyping then
        cachedInputs.forward = 0
        cachedInputs.right = 0
        cachedInputs.jump = false
        return
    end

    -- WASD inputs
    local fmove = 0
    local smove = 0

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then fmove = fmove + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then fmove = fmove - 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then smove = smove + 1 end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then smove = smove - 1 end

    -- Jump input
    local jump = UserInputService:IsKeyDown(keybindConfig.jumpKey)

    cachedInputs.forward = fmove
    cachedInputs.right = smove
    cachedInputs.jump = jump
end

-- Build wish velocity from inputs (normalized diagonal)
local function getWishVelocity()
    local forward, right = getYawVectors()

    -- Build wish velocity
    local wishVel = forward * cachedInputs.forward + right * cachedInputs.right

    -- Normalize diagonal input (so W+A isn't faster than W alone)
    if wishVel:Dot(wishVel) > 0.01 then
        wishVel = wishVel.Unit
    else
        wishVel = Vector2.new(0, 0)
    end

    return wishVel
end

-- Robust ground detection with slope checking
local function updateGroundState()
    if not rootPart then return end

    local rayOrigin = rootPart.Position + Vector3.new(0, 0.1, 0)
    local rayDirection = Vector3.new(0, -(config.GROUND_DISTANCE + 0.1), 0)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    -- Use AddToFilter method instead of iterating all descendants (performance fix)
    raycastParams.CollisionGroup = "Default"

    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if raycastResult then
        groundNormal = raycastResult.Normal

        -- Check slope limit (only walkable if normal.Y >= cos(slopeLimit))
        local slopeAngle = math.deg(math.acos(groundNormal.Y))
        debugData.surfaceAngle = slopeAngle

        if slopeAngle <= config.SLOPE_LIMIT then
            local wasGrounded = isGrounded
            isGrounded = true
            justLanded = not wasGrounded
            lastGroundTime = tick()
            return
        end
    end

    isGrounded = false
    justLanded = false
    groundNormal = Vector3.new(0, 1, 0)
end

-- Snap down to ground (sticky ground)
local function snapToGround()
    if not isGrounded or not rootPart then return end

    local rayOrigin = rootPart.Position
    local rayDirection = Vector3.new(0, -config.SNAP_DOWN_DISTANCE, 0)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

    if raycastResult then
        local snapDist = raycastResult.Distance - 0.05
        if snapDist > 0 then
            rootPart.CFrame = rootPart.CFrame - Vector3.new(0, snapDist, 0)
        end
    end
end

--------------------------------------------------------------------------------
-- MOVEMENT FUNCTIONS (Source-style)
--------------------------------------------------------------------------------

-- Apply friction (ground only, Source-style)
local function applyFriction(dt)
    local speed = vel2.Magnitude

    if speed < 0.1 then
        vel2 = Vector2.new(0, 0)
        return
    end

    -- Source-style friction: drop = max(speed, STOP_SPEED) * FRICTION * dt
    local control = math.max(speed, config.STOP_SPEED)
    local drop = control * config.GROUND_FRICTION * dt

    -- Calculate new speed
    local newSpeed = math.max(speed - drop, 0)

    -- Scale velocity
    if speed > 0 then
        vel2 = vel2 * (newSpeed / speed)
    end
end

-- Source-style acceleration (air or ground)
local function accelerate(wishDir, wishSpeed, accel, dt)
    -- Current speed in wish direction
    local currentSpeed = vel2:Dot(wishDir)

    -- How much speed to add
    local addSpeed = wishSpeed - currentSpeed

    if addSpeed <= 0 then
        debugData.addSpeed = 0
        debugData.accelSpeed = 0
        return
    end

    -- Acceleration amount (Source Engine formula)
    -- accel is studs/second², dt is seconds
    local accelSpeed = accel * dt * wishSpeed
    accelSpeed = math.min(accelSpeed, addSpeed)

    -- Apply acceleration
    vel2 = vel2 + wishDir * accelSpeed

    -- Debug data
    debugData.currentSpeed = currentSpeed
    debugData.addSpeed = addSpeed
    debugData.accelSpeed = accelSpeed
end

-- Handle jump with coyote time and jump buffering
local function handleJump()
    local currentTime = tick()

    -- Track jump buffer
    if cachedInputs.jump then
        lastJumpRequestTime = currentTime
    end

    -- Check if we can jump
    local canJump = false
    local coyoteActive = false
    local jumpBuffered = false

    -- Coyote time: can jump for a short time after leaving ground
    if isGrounded then
        canJump = true
    elseif (currentTime - lastGroundTime) <= config.COYOTE_TIME then
        canJump = true
        coyoteActive = true
    end

    -- Jump buffer: if jump was pressed recently and we just landed
    if justLanded and (currentTime - lastJumpRequestTime) <= config.JUMP_BUFFER_TIME then
        jumpBuffered = true
    end

    -- Execute jump
    if canJump and (cachedInputs.jump or jumpBuffered) then
        -- Apply jump (vertical only)
        rootPart.Velocity = Vector3.new(vel2.X, config.JUMP_POWER, vel2.Y)

        -- Prevent re-triggering
        isGrounded = false
        lastGroundTime = 0

        return true
    end

    debugData.coyoteActive = coyoteActive
    debugData.jumpBuffered = jumpBuffered

    return false
end

--------------------------------------------------------------------------------
-- MAIN PHYSICS UPDATE
--------------------------------------------------------------------------------

local function updatePhysics(dt)
    if not bhopEnabled or not character or not rootPart then
        return
    end

    -- Clamp dt
    dt = clampDt(dt)
    debugData.dt = dt

    -- 1. Sample inputs once
    sampleInputs()

    -- 2. Update grounded state
    updateGroundState()
    debugData.onGround = isGrounded

    -- 3. Get current velocity from Roblox and clamp near-zero to prevent flickering
    local robloxVel = rootPart.Velocity
    local velX = math.abs(robloxVel.X) < 0.5 and 0 or robloxVel.X
    local velZ = math.abs(robloxVel.Z) < 0.5 and 0 or robloxVel.Z
    vel2 = Vector2.new(velX, velZ)

    -- 4. Build wish direction/speed
    local wishVel = getWishVelocity()
    local wishDir = wishVel
    local wishSpeed = 0

    if isGrounded then
        -- Ground: wish speed is config value
        wishSpeed = config.GROUND_SPEED
    else
        -- Air: wish speed is air cap (multiplier of ground speed)
        wishSpeed = config.GROUND_SPEED * config.AIR_CAP
    end

    debugData.wishSpeed = wishSpeed

    -- 5. Apply friction (ground only)
    if isGrounded then
        applyFriction(dt)
    end

    -- 6. Apply acceleration
    if wishDir:Dot(wishDir) > 0.01 then
        if isGrounded then
            accelerate(wishDir, wishSpeed, config.GROUND_ACCELERATE, dt)
        else
            accelerate(wishDir, wishSpeed, config.AIR_ACCELERATE, dt)
        end
    end

    -- 7. Handle jump (auto-hop or manual)
    local didJump = false
    if autoHop and isGrounded then
        -- Auto-hop: always jump when grounded
        rootPart.Velocity = Vector3.new(vel2.X, config.JUMP_POWER, vel2.Y)
        isGrounded = false
        lastGroundTime = 0
        didJump = true
    else
        -- Manual jump with coyote time and jump buffer
        didJump = handleJump()
    end

    -- 8. Apply velocity (set directly, preserve vertical component)
    if not didJump then
        local currentY = rootPart.Velocity.Y
        rootPart.Velocity = Vector3.new(vel2.X, currentY, vel2.Y)
    end

    -- 9. Snap to ground if needed
    if isGrounded and not didJump then
        snapToGround()
    end

    -- 10. Track max speed
    local speed2D = vel2.Magnitude
    debugData.speed2D = speed2D
    if speed2D > maxSpeedReached then
        maxSpeedReached = speed2D
    end
end

--------------------------------------------------------------------------------
-- MODULE API
--------------------------------------------------------------------------------

function Physics.init(plr, char, hum, root)
    player = plr
    character = char
    humanoid = hum
    rootPart = root

    originalWalkSpeed = humanoid.WalkSpeed
    originalJumpPower = humanoid.JumpPower

    -- Disable Roblox material-based friction (this is critical!)
    -- Set CustomPhysicalProperties to override material friction
    rootPart.CustomPhysicalProperties = PhysicalProperties.new(
        0.7,   -- Density
        0,     -- Friction (ZERO - we handle this ourselves)
        0,     -- Elasticity
        1,     -- FrictionWeight
        1      -- ElasticityWeight
    )

    -- Track text box focus
    UserInputService.TextBoxFocused:Connect(function()
        isTyping = true
    end)

    UserInputService.TextBoxFocusReleased:Connect(function()
        isTyping = false
    end)

    -- Physics Loop (use Heartbeat for consistency)
    RunService.Heartbeat:Connect(function(dt)
        if bhopEnabled then
            updatePhysics(dt)
        end
    end)
end

function Physics.toggleBhop(value)
    if value ~= nil then
        bhopEnabled = value
    else
        bhopEnabled = not bhopEnabled
    end

    if bhopEnabled then
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0
        vel2 = Vector2.new(0, 0)
        maxSpeedReached = 0
    else
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpPower = originalJumpPower
        rootPart.Velocity = Vector3.new(0, 0, 0)
    end

    return bhopEnabled
end

function Physics.setAutoHop(value)
    autoHop = value
end

function Physics.getAutoHop()
    return autoHop
end

function Physics.isEnabled()
    return bhopEnabled
end

-- Get horizontal velocity as Vector3 (for compatibility)
function Physics.getVelocity()
    return Vector3.new(vel2.X, 0, vel2.Y)
end

-- Get true 2D velocity
function Physics.getVelocity2D()
    return vel2
end

-- Get horizontal speed
function Physics.getSpeed2D()
    local speed = vel2.Magnitude
    -- Clamp near-zero speeds to prevent displaying 0.1 when stationary
    return speed < 0.1 and 0 or speed
end

function Physics.isGrounded()
    return isGrounded
end

function Physics.getWishDir()
    local wishVel = getWishVelocity()
    return Vector3.new(wishVel.X, 0, wishVel.Y)
end

function Physics.getConfig()
    return config
end

function Physics.setConfig(key, value)
    if config[key] ~= nil then
        config[key] = value
    end
end

function Physics.getToggleKey()
    return keybindConfig.toggleKey
end

function Physics.getUIToggleKey()
    return keybindConfig.uiToggleKey
end

function Physics.getKeybinds()
    return keybindConfig
end

function Physics.setKeybind(key, keyCode)
    if keybindConfig[key] ~= nil then
        keybindConfig[key] = keyCode
        return true
    end
    return false
end

function Physics.getDebugData()
    return debugData
end

function Physics.getPresets()
    return presetLibrary
end

function Physics.loadPreset(presetName)
    if presetLibrary[presetName] then
        for key, value in pairs(presetLibrary[presetName]) do
            if config[key] ~= nil then
                config[key] = value
            end
        end
        return true
    end
    return false
end

function Physics.exportConfig()
    return {
        physics = config,
        autoHop = autoHop,
        keybinds = {
            toggleKey = keybindConfig.toggleKey.Name,
            jumpKey = keybindConfig.jumpKey.Name,
            uiToggleKey = keybindConfig.uiToggleKey.Name,
        },
    }
end

function Physics.importConfig(data)
    if data.physics then
        for key, value in pairs(data.physics) do
            if config[key] then
                config[key] = value
            end
        end
    end

    if data.autoHop ~= nil then
        autoHop = data.autoHop
    end

    if data.keybinds then
        if data.keybinds.toggleKey then
            keybindConfig.toggleKey = Enum.KeyCode[data.keybinds.toggleKey] or Enum.KeyCode.B
        end
        if data.keybinds.jumpKey then
            keybindConfig.jumpKey = Enum.KeyCode[data.keybinds.jumpKey] or Enum.KeyCode.Space
        end
        if data.keybinds.uiToggleKey then
            keybindConfig.uiToggleKey = Enum.KeyCode[data.keybinds.uiToggleKey] or Enum.KeyCode.RightShift
        end
    end
end

return Physics
