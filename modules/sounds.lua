<<<<<<< HEAD
-- Sounds Module
-- Handles all sound effects

local Sounds = {}

local ContentProvider = game:GetService("ContentProvider")
=======
local Sounds = { }
>>>>>>> 0025280d5488b7ed7179d1d1d6b72baa4496fdc3

local function normalizeAssetId(input)
    if not input then return nil end
    local str = tostring(input)
    if str:match("^rbxassetid://%d+$") then
        return str
    end
    local id = str:match("(%d+)")
    if id then
        return "rbxassetid://" .. id
    end
    return nil
end

<<<<<<< HEAD
local warned = {}
local function warnOnce(key, msg)
    if warned[key] then return end
    warned[key] = true
    warn(msg)
end

local function safePreload(inst, key)
    pcall(function()
        ContentProvider:PreloadAsync({inst})
    end)
end

local function safePlay(inst, key)
    local ok, err = pcall(function()
        inst:Play()
    end)
    if not ok then
        warnOnce(key, "[Sounds] Failed to play sound (likely private/restricted or wrong type): " .. tostring(err))
        return false
    end
    return true
end


-- State
local rootPart, Physics, Stats
local enabled = false
local wasGrounded = true

-- Sound Configuration
local soundConfig = {
    jumpSoundId = "rbxassetid://117034355804907",  -- Default jump sound
    landSoundId = "rbxassetid://117034355804907",  -- Default land sound
    jumpVolume = 0.5,
    landVolume = 0.3,
    jumpPitch = 1.0,
    landPitch = 0.8,
}

-- Sound instances
local jumpSound
local landSound

-- Module API
function Sounds.init(root, physics, stats)
    rootPart = root
    Physics = physics
    Stats = stats

    -- Create Sound instances
    jumpSound = Instance.new("Sound")
    jumpSound.Name = "BhopJumpSound"
    jumpSound.SoundId = soundConfig.jumpSoundId
    safePreload(jumpSound, "jump_preload")
    jumpSound.Volume = soundConfig.jumpVolume
    jumpSound.Pitch = soundConfig.jumpPitch
    jumpSound.Parent = rootPart

    landSound = Instance.new("Sound")
    landSound.Name = "BhopLandSound"
    landSound.SoundId = soundConfig.landSoundId
    safePreload(landSound, "land_preload")
    landSound.Volume = soundConfig.landVolume
    landSound.Pitch = soundConfig.landPitch
    landSound.Parent = rootPart
end

function Sounds.update(speed, onGround)
    if not enabled then
        wasGrounded = onGround
        return
    end

    -- Track jump/land events
    if not wasGrounded and onGround then
        -- Just landed
        safePlay(landSound, "land_play")
elseif wasGrounded and not onGround then
        -- Just jumped
        safePlay(jumpSound, "jump_play")
    end

    wasGrounded = onGround
end

function Sounds.setEnabled(value)
    enabled = value
end

function Sounds.isEnabled()
    return enabled
end

function Sounds.setJumpSound(soundId, volume, pitch)
    local asset = normalizeAssetId(soundId) or soundConfig.jumpSoundId
    soundConfig.jumpSoundId = asset
    soundConfig.jumpVolume = volume or soundConfig.jumpVolume
    soundConfig.jumpPitch = pitch or soundConfig.jumpPitch

    jumpSound.SoundId = soundConfig.jumpSoundId
    safePreload(jumpSound, "jump_preload")
    jumpSound.Volume = soundConfig.jumpVolume
    jumpSound.Pitch = soundConfig.jumpPitch
end

function Sounds.setLandSound(soundId, volume, pitch)
    local asset = normalizeAssetId(soundId) or soundConfig.landSoundId
    soundConfig.landSoundId = asset
    soundConfig.landVolume = volume or soundConfig.landVolume
    soundConfig.landPitch = pitch or soundConfig.landPitch

    landSound.SoundId = soundConfig.landSoundId
    safePreload(landSound, "land_preload")
    landSound.Volume = soundConfig.landVolume
    landSound.Pitch = soundConfig.landPitch
end

function Sounds.getConfig()
    return soundConfig
end

function Sounds.exportConfig()
    return {
        sounds = soundConfig,
        enabled = enabled,
    }
end

function Sounds.importConfig(data)
    if data.sounds then
        for key, value in pairs(data.sounds) do
            if soundConfig[key] ~= nil then
                soundConfig[key] = value
            end
        end

        -- Apply sound config
        jumpSound.SoundId = soundConfig.jumpSoundId
    safePreload(jumpSound, "jump_preload")
        jumpSound.Volume = soundConfig.jumpVolume
        jumpSound.Pitch = soundConfig.jumpPitch

        landSound.SoundId = soundConfig.landSoundId
    safePreload(landSound, "land_preload")
        landSound.Volume = soundConfig.landVolume
        landSound.Pitch = soundConfig.landPitch
    end

    if data.enabled ~= nil then
        enabled = data.enabled
    end
end


function Sounds.previewJump(optionalInput)
    if optionalInput then
        local asset = normalizeAssetId(optionalInput)
        if asset then
            jumpSound.SoundId = asset
            safePreload(jumpSound, "jump_preview_preload")
        end
    end
    return safePlay(jumpSound, "jump_preview_play")
end

function Sounds.previewLand(optionalInput)
    if optionalInput then
        local asset = normalizeAssetId(optionalInput)
        if asset then
            landSound.SoundId = asset
            safePreload(landSound, "land_preview_preload")
        end
    end
    return safePlay(landSound, "land_preview_play")
end

=======

local jumpSound = Instance.new("Sound")
local landSound = Instance.new("Sound")

jumpSound.SoundId = "rbxassetid://117034355804907"
landSound.SoundId = "rbxassetid://117034355804907"

function Sounds.setJumpSound(input, volume, pitch)
    local asset = normalizeAssetId(input)
    if asset then jumpSound.SoundId = asset end
    if volume then jumpSound.Volume = volume end
    if pitch then jumpSound.PlaybackSpeed = pitch end
end

function Sounds.setLandSound(input, volume, pitch)
    local asset = normalizeAssetId(input)
    if asset then landSound.SoundId = asset end
    if volume then landSound.Volume = volume end
    if pitch then landSound.PlaybackSpeed = pitch end
end

function Sounds.init() end
>>>>>>> 0025280d5488b7ed7179d1d1d6b72baa4496fdc3
return Sounds
