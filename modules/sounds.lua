local Sounds = { }

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
return Sounds
