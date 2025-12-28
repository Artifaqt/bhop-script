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
local originalPhysicalProperties = {}  -- Store for all body parts

-- Configuration (CS 1.6 defaults)
local config = {
    -- Ground movement
    GROUND_FRICTION = 4,  -- Standard friction
    GROUND_ACCELERATE = 10,  -- Source-like value (will be multiplied by wishSpeed * dt)
    GROUND_SPEED = 30,  -- Target ground speed in Roblox units
    STOP_SPEED = 1,

    -- Air movement
    AIR_ACCELERATE = 15,  -- Source-like value for air control
    AIR_CAP = 1.0,  -- Air wishspeed cap (1.0 = no limit, same as ground)
    AIR_WISH_SPEED_CAP = 30,  -- Air wishspeed cap used for acceleration (Source-like)

    -- Jump
    JUMP_POWER = 50,

    -- Grounding
    GROUND_DISTANCE = 0.8,  -- How far to raycast for ground (increased for Roblox)
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
        GROUND_ACCELERATE = 10,  -- Source-like value
        AIR_ACCELERATE = 15,  -- Source-like value
        GROUND_SPEED = 30,
        AIR_CAP = 1.0,  -- No air limit
        JUMP_POWER = 50,
        STOP_SPEED = 1,
        SLOPE_LIMIT = 45,
        GROUND_DISTANCE = 0.8,  -- Increased for Roblox
        SNAP_DOWN_DISTANCE = 0.15,
        COYOTE_TIME = 0.1,
        JUMP_BUFFER_TIME = 0.1,
    },
    ["CS:GO Style"] = {
        GROUND_FRICTION = 5.2,
        GROUND_ACCELERATE = 12,  -- Slightly higher than 1.6
        AIR_ACCELERATE = 18,  -- Slightly higher air control
        GROUND_SPEED = 30,
        AIR_CAP = 0.8,  -- Some air restriction
        JUMP_POWER = 55,
        STOP_SPEED = 1,
        SLOPE_LIMIT = 45,
        GROUND_DISTANCE = 0.8,  -- Increased for Roblox
        SNAP_DOWN_DISTANCE = 0.15,
        COYOTE_TIME = 0.1,
        JUMP_BUFFER_TIME = 0.1,
    },
    ["TF2 Scout"] = {
        GROUND_FRICTION = 4,
        GROUND_ACCELERATE = 12,  -- Faster acceleration
        AIR_ACCELERATE = 18,
        GROUND_SPEED = 40,  -- Scout is faster
        AIR_CAP = 1.0,  -- No air limit
        JUMP_POWER = 58,
        STOP_SPEED = 1,
        SLOPE_LIMIT = 50,
        GROUND_DISTANCE = 0.8,  -- Increased for Roblox
        SNAP_DOWN_DISTANCE = 0.15,
        COYOTE_TIME = 0.1,
        JUMP_BUFFER_TIME = 0.1,
    },
    ["Quake"] = {
        GROUND_FRICTION = 6,
        GROUND_ACCELERATE = 10,
        AIR_ACCELERATE = 10,  -- Classic Quake value
        GROUND_SPEED = 35,
        AIR_CAP = 1.5,  -- Allow higher speeds
        JUMP_POWER = 60,
        STOP_SPEED = 1,
        SLOPE_LIMIT = 50,
        GROUND_DISTANCE = 0.8,  -- Increased for Roblox
        SNAP_DOWN_DISTANCE = 0.15,
        COYOTE_TIME = 0.1,
        JUMP_BUFFER_TIME = 0.1,
    },
    ["Easy Mode"] = {
        GROUND_FRICTION = 2,  -- Low friction
        GROUND_ACCELERATE = 20,  -- Higher for easy mode
        AIR_ACCELERATE = 30,  -- Very high for easy mode
        GROUND_SPEED = 35,
        AIR_CAP = 1.5,  -- Allow higher speeds
        JUMP_POWER = 60,
        STOP_SPEED = 0.5,
        SLOPE_LIMIT = 60,
        GROUND_DISTANCE = 0.8,  -- Increased for Roblox
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
    -- Build wish velocity from cached input and camera yaw (horizontal only).
    -- Returns BOTH wishDir and wishSpeed (Source-style pipeline).
    if isTyping then
        return Vector3.zero, 0
    end

    local fmove = cachedInputs.forward  -- -1..1
    local smove = cachedInputs.right    -- -1..1

    if math.abs(fmove) < 1e-3 and math.abs(smove) < 1e-3 then
        return Vector3.zero, 0
    end

    local forward, right = getYawVectors()

    -- Raw wish velocity (not normalized yet)
    local wishVel = forward * fmove + right * smove
    local wishMag = wishVel.Magnitude
    if wishMag < 1e-3 then
        return Vector3.zero, 0
    end

    local wishDir = wishVel / wishMag

    -- Wishspeed: scale by input magnitude (diagonal normalized via wishMag<=sqrt(2))
    -- This feels closer to Source and fixes 'no gain' cases where wishspeed is effectively too low.
    local inputScale = math.clamp(wishMag, 0, 1) -- keyboard typically 1, diagonal slightly >1 before clamp
    local baseWishSpeed = config.GROUND_SPEED * inputScale

    local wishSpeed
    if isGrounded then
        wishSpeed = baseWishSpeed
    else
        -- Air wishspeed cap (Source-like): cap the wishspeed used for acceleration,
        -- but DO NOT cap the actual velocity magnitude.
        local airCap = config.AIR_WISH_SPEED_CAP or config.GROUND_SPEED
        wishSpeed = math.min(baseWishSpeed, airCap)
    end

    return wishDir, wishSpeed
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
    -- accel * wishSpeed * dt gives proper acceleration that scales with speed
    local accelSpeed = accel * wishSpeed * dt
    if accelSpeed > addSpeed then
        accelSpeed = addSpeed
    end

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
        -- Apply jump using AssemblyLinearVelocity (vertical only)
        rootPart.AssemblyLinearVelocity = Vector3.new(vel2.X, config.JUMP_POWER, vel2.Y)

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

    -- 3. Get current velocity from AssemblyLinearVelocity (not fought by Humanoid)
    local robloxVel = rootPart.AssemblyLinearVelocity
    local velX = math.abs(robloxVel.X) < 0.05 and 0 or robloxVel.X
    local velZ = math.abs(robloxVel.Z) < 0.05 and 0 or robloxVel.Z
    vel2 = Vector2.new(velX, velZ)

    -- 4. Build wish direction + wish speed (Source-style)
    local wishDir, wishSpeed = getWishVelocity()
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
        rootPart.AssemblyLinearVelocity = Vector3.new(vel2.X, config.JUMP_POWER, vel2.Y)
        isGrounded = false
        lastGroundTime = 0
        didJump = true
    else
        -- Manual jump with coyote time and jump buffer
        didJump = handleJump()
    end

    -- 8. Apply velocity using AssemblyLinearVelocity (not fought by Humanoid)
    if not didJump then
        local currentY = rootPart.AssemblyLinearVelocity.Y
        rootPart.AssemblyLinearVelocity = Vector3.new(vel2.X, currentY, vel2.Y)
    end

    -- 9. Snap to ground if needed (disabled - can kill horizontal speed)
    -- if isGrounded and not didJump then
    --     snapToGround()
    -- end

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

    -- Store original physical properties for ALL body parts
    originalPhysicalProperties = {}
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            originalPhysicalProperties[part] = part.CustomPhysicalProperties
        end
    end

    -- Apply zero friction to ALL body parts (not just rootPart!)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CustomPhysicalProperties = PhysicalProperties.new(
                0.7,   -- Density
                0,     -- Friction (ZERO - we handle this ourselves)
                0,     -- Elasticity
                1,     -- FrictionWeight
                1      -- ElasticityWeight
            )
        end
    end

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
        humanoid.AutoRotate = false
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        vel2 = Vector2.new(0, 0)
        maxSpeedReached = 0

        -- Apply custom physics properties to ALL body parts
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CustomPhysicalProperties = PhysicalProperties.new(
                    0.7,   -- Density
                    0,     -- Friction (ZERO - we handle this ourselves)
                    0,     -- Elasticity
                    1,     -- FrictionWeight
                    1      -- ElasticityWeight
                )
            end
        end
    else
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpPower = originalJumpPower
        humanoid.AutoRotate = true
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

        -- Restore original physical properties for ALL body parts
        for part, props in pairs(originalPhysicalProperties) do
            if part:IsA("BasePart") then
                part.CustomPhysicalProperties = propss
            end
        end
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
