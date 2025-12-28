<<<<<<< HEAD
-- Physics Module
-- Handles all bhop physics calculations and state

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Physics = {}

-- State
local player, character, humanoid, rootPart
local bhopEnabled = false
local autoHop = false
local isJumping = false
local isTyping = false
local currentVelocity = Vector3.new(0, 0, 0)
local maxSpeedReached = 0
local bodyVelocity

-- Configuration
local config = {
    GROUND_FRICTION = 6,
    GROUND_ACCELERATE = 10,
    AIR_ACCELERATE = 16,
    GROUND_SPEED = 16,
    AIR_CAP = 10,
    JUMP_POWER = 50,
    STOP_SPEED = 1,
}

-- Keybinds
local keybindConfig = {
    toggleKey = Enum.KeyCode.B,
    jumpKey = Enum.KeyCode.Space,
}

-- Store originals
local originalWalkSpeed
local originalJumpPower

-- Preset Library
local presetLibrary = {
    ["CS 1.6 Classic"] = {
        GROUND_FRICTION = 6,
        GROUND_ACCELERATE = 10,
        AIR_ACCELERATE = 16,
        GROUND_SPEED = 16,
        AIR_CAP = 10,
        JUMP_POWER = 50,
        STOP_SPEED = 1,
    },
    ["CS:GO Style"] = {
        GROUND_FRICTION = 5,
        GROUND_ACCELERATE = 12,
        AIR_ACCELERATE = 1200,
        GROUND_SPEED = 18,
        AIR_CAP = 0.4,
        JUMP_POWER = 55,
        STOP_SPEED = 1.5,
    },
    ["TF2 Scout"] = {
        GROUND_FRICTION = 4,
        GROUND_ACCELERATE = 15,
        AIR_ACCELERATE = 10,
        GROUND_SPEED = 26,
        AIR_CAP = 12,
        JUMP_POWER = 58,
        STOP_SPEED = 2,
    },
    ["Quake"] = {
        GROUND_FRICTION = 8,
        GROUND_ACCELERATE = 10,
        AIR_ACCELERATE = 70,
        GROUND_SPEED = 20,
        AIR_CAP = 30,
        JUMP_POWER = 60,
        STOP_SPEED = 1,
    },
    ["Easy Mode"] = {
        GROUND_FRICTION = 3,
        GROUND_ACCELERATE = 20,
        AIR_ACCELERATE = 30,
        GROUND_SPEED = 20,
        AIR_CAP = 20,
        JUMP_POWER = 60,
        STOP_SPEED = 0.5,
    },
}

-- Physics Functions
local function isGrounded()
    local rayOrigin = rootPart.Position
    local rayDirection = Vector3.new(0, -4, 0)
    local raycastParams = RaycastParams.new()

    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    return raycastResult ~= nil
end

local function getWishDir()
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

local function airAccelerate(wishdir, wishspeed, accel, dt)
    local currentspeed = currentVelocity:Dot(wishdir)
    local addspeed = wishspeed - currentspeed

    if addspeed <= 0 then
        return
    end

    local accelspeed = math.min(accel * wishspeed * dt, addspeed)
    currentVelocity = currentVelocity + wishdir * accelspeed
end

local function groundAccelerate(wishdir, wishspeed, accel, dt)
    local currentspeed = currentVelocity:Dot(wishdir)
    local addspeed = wishspeed - currentspeed

    if addspeed <= 0 then
        return
    end

    local accelspeed = math.min(accel * dt * wishspeed, addspeed)
    currentVelocity = currentVelocity + wishdir * accelspeed
end

local function applyFriction(dt)
    local speed = currentVelocity.Magnitude

    if speed < 0.1 then
        currentVelocity = Vector3.new(0, 0, 0)
        return
    end

    local control = speed < config.STOP_SPEED and config.STOP_SPEED or speed
    local drop = control * config.GROUND_FRICTION * dt
    local newSpeed = math.max(speed - drop, 0)

    if speed > 0 then
        currentVelocity = currentVelocity * (newSpeed / speed)
    end
end

local function updatePhysics(dt)
    if not bhopEnabled or not character or not rootPart then
        return
    end

    local wishDir = getWishDir()
    local onGround = isGrounded()

    if onGround then
        applyFriction(dt)
        groundAccelerate(wishDir, config.GROUND_SPEED, config.GROUND_ACCELERATE, dt)

        -- Auto-hop or manual jump
        local shouldJump = false
        if autoHop and not isTyping then
            shouldJump = not isJumping
        elseif UserInputService:IsKeyDown(keybindConfig.jumpKey) and not isJumping and not isTyping then
            shouldJump = true
        end

        if shouldJump then
            rootPart.Velocity = Vector3.new(currentVelocity.X, config.JUMP_POWER, currentVelocity.Z)
            isJumping = true
        end
    else
        local wishspeed = config.AIR_CAP
        airAccelerate(wishDir, wishspeed, config.AIR_ACCELERATE, dt)
        isJumping = false
    end

    local newVelocity = Vector3.new(currentVelocity.X, 0, currentVelocity.Z)
    bodyVelocity.Velocity = newVelocity

    local speed = currentVelocity.Magnitude
    if speed > maxSpeedReached then
        maxSpeedReached = speed
    end
end

-- Module API
function Physics.init(plr, char, hum, root)
    player = plr
    character = char
    humanoid = hum
    rootPart = root

    originalWalkSpeed = humanoid.WalkSpeed
    originalJumpPower = humanoid.JumpPower

    -- Create BodyVelocity
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "BhopVelocity"
    bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
    bodyVelocity.P = 10000
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart

    -- Track text box focus
    UserInputService.TextBoxFocused:Connect(function()
        isTyping = true
    end)

    UserInputService.TextBoxFocusReleased:Connect(function()
        isTyping = false
    end)

    -- Physics Loop
    RunService.RenderStepped:Connect(function(dt)
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
        currentVelocity = Vector3.new(0, 0, 0)
        maxSpeedReached = 0
        bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
    else
        humanoid.WalkSpeed = originalWalkSpeed
        humanoid.JumpPower = originalJumpPower
        rootPart.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
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

function Physics.getVelocity()
    return currentVelocity
end

function Physics.isGrounded()
    return isGrounded()
end

function Physics.getWishDir()
    return getWishDir()
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

function Physics.getPresets()
    return presetLibrary
end

function Physics.loadPreset(presetName)
    if presetLibrary[presetName] then
        for key, value in pairs(presetLibrary[presetName]) do
            config[key] = value
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
        keybindConfig.toggleKey = Enum.KeyCode[data.keybinds.toggleKey] or Enum.KeyCode.B
        keybindConfig.jumpKey = Enum.KeyCode[data.keybinds.jumpKey] or Enum.KeyCode.Space
    end
end

return Physics
=======
-- physics.lua placeholder
return {}
>>>>>>> 0025280d5488b7ed7179d1d1d6b72baa4496fdc3
