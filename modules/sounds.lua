-- Sounds Module
-- Handles all sound effects

local Sounds = {}

-- State
local rootPart, Physics, Stats
local enabled = false
local wasGrounded = true

-- Sound Configuration
local soundConfig = {
    jumpSoundId = "rbxassetid://3398620867",  -- Default jump sound
    landSoundId = "rbxassetid://3398620867",  -- Default land sound
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
    jumpSound.Volume = soundConfig.jumpVolume
    jumpSound.Pitch = soundConfig.jumpPitch
    jumpSound.Parent = rootPart

    landSound = Instance.new("Sound")
    landSound.Name = "BhopLandSound"
    landSound.SoundId = soundConfig.landSoundId
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
        landSound:Play()

        -- Record jump stats
        local isPerfect = speed > (Physics.getConfig().GROUND_SPEED * 0.9)
        Stats.recordJump(isPerfect)
    elseif wasGrounded and not onGround then
        -- Just jumped
        jumpSound:Play()
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
    soundConfig.jumpSoundId = soundId or soundConfig.jumpSoundId
    soundConfig.jumpVolume = volume or soundConfig.jumpVolume
    soundConfig.jumpPitch = pitch or soundConfig.jumpPitch

    jumpSound.SoundId = soundConfig.jumpSoundId
    jumpSound.Volume = soundConfig.jumpVolume
    jumpSound.Pitch = soundConfig.jumpPitch
end

function Sounds.setLandSound(soundId, volume, pitch)
    soundConfig.landSoundId = soundId or soundConfig.landSoundId
    soundConfig.landVolume = volume or soundConfig.landVolume
    soundConfig.landPitch = pitch or soundConfig.landPitch

    landSound.SoundId = soundConfig.landSoundId
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
        jumpSound.Volume = soundConfig.jumpVolume
        jumpSound.Pitch = soundConfig.jumpPitch

        landSound.SoundId = soundConfig.landSoundId
        landSound.Volume = soundConfig.landVolume
        landSound.Pitch = soundConfig.landPitch
    end

    if data.enabled ~= nil then
        enabled = data.enabled
    end
end

return Sounds
