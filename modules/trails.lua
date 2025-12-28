-- Trails Module
-- Enhanced trail system with decal support

local Trails = {}

-- State
local player, rootPart, Physics
local enabled = false
local trailParts = {}
local lastTrailTime = 0

-- Trail Configuration
local trailConfig = {
    -- General settings
    maxParts = 20,
    updateInterval = 0.05,
    fadeTime = 1.0,
    minSpeed = 5,

    -- Visual settings
    useDecals = true,
    decalTexture = "rbxassetid://6073894888",  -- Default decal
    color = Color3.fromRGB(100, 200, 255),
    transparency = 0.5,
    size = Vector3.new(2, 2, 0.1),

    -- Rotation settings
    randomRotation = true,
    rotationRange = 360,  -- degrees
    spinSpeed = 0,  -- degrees per second (0 = no spin)
}

local function createTrailPart()
    local part = Instance.new("Part")
    part.Size = trailConfig.size
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = trailConfig.useDecals and 1 or trailConfig.transparency
    part.Parent = workspace

    if trailConfig.useDecals then
        -- Create decal on part
        local decal = Instance.new("Decal")
        decal.Texture = trailConfig.decalTexture
        decal.Color3 = trailConfig.color
        decal.Transparency = trailConfig.transparency
        decal.Face = Enum.NormalId.Front
        decal.Parent = part

        -- Add decal to back face too
        local decalBack = Instance.new("Decal")
        decalBack.Texture = trailConfig.decalTexture
        decalBack.Color3 = trailConfig.color
        decalBack.Transparency = trailConfig.transparency
        decalBack.Face = Enum.NormalId.Back
        decalBack.Parent = part

        -- Random rotation if enabled
        if trailConfig.randomRotation then
            local randomAngle = math.random() * trailConfig.rotationRange
            part.CFrame = part.CFrame * CFrame.Angles(0, 0, math.rad(randomAngle))
        end

        return part, {decal, decalBack}
    else
        -- Use colored neon material
        part.Material = Enum.Material.Neon
        part.Color = trailConfig.color
        part.Transparency = trailConfig.transparency

        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Sphere
        mesh.Parent = part

        return part, nil
    end
end

-- Module API
function Trails.init(plr, root, physics)
    player = plr
    rootPart = root
    Physics = physics
end

function Trails.update(speed, dt)
    if not enabled or speed < trailConfig.minSpeed then
        return
    end

    local currentTime = tick()
    if currentTime - lastTrailTime < trailConfig.updateInterval then
        return
    end

    lastTrailTime = currentTime

    local trailPart, decals = createTrailPart()
    trailPart.CFrame = rootPart.CFrame
    table.insert(trailParts, {part = trailPart, decals = decals, time = currentTime})

    -- Remove old trail parts
    if #trailParts > trailConfig.maxParts then
        local oldTrail = table.remove(trailParts, 1)
        oldTrail.part:Destroy()
    end

    -- Fade effect
    task.spawn(function()
        local fadeSteps = trailConfig.fadeTime / 0.05
        local transparencyIncrement = (1 - trailConfig.transparency) / fadeSteps

        for i = 1, fadeSteps do
            task.wait(0.05)

            if trailPart and trailPart.Parent then
                if decals then
                    for _, decal in ipairs(decals) do
                        decal.Transparency = math.min(1, decal.Transparency + transparencyIncrement)
                    end
                else
                    trailPart.Transparency = math.min(1, trailPart.Transparency + transparencyIncrement)
                end

                -- Spin if enabled
                if trailConfig.spinSpeed > 0 then
                    trailPart.CFrame = trailPart.CFrame * CFrame.Angles(0, 0, math.rad(trailConfig.spinSpeed * 0.05))
                end
            end
        end

        if trailPart then
            trailPart:Destroy()
        end
    end)
end

function Trails.setEnabled(value)
    enabled = value
    if not enabled then
        -- Clear all trail parts
        for _, trail in ipairs(trailParts) do
            if trail.part then
                trail.part:Destroy()
            end
        end
        trailParts = {}
    end
end

function Trails.isEnabled()
    return enabled
end

function Trails.getConfig()
    return trailConfig
end

function Trails.setConfig(key, value)
    if trailConfig[key] ~= nil then
        trailConfig[key] = value
    end
end

function Trails.setDecalTexture(textureId)
    trailConfig.decalTexture = textureId
end

function Trails.setColor(color)
    trailConfig.color = color
end

function Trails.setTransparency(transparency)
    trailConfig.transparency = transparency
end

function Trails.setSize(size)
    trailConfig.size = size
end

function Trails.setRandomRotation(value)
    trailConfig.randomRotation = value
end

function Trails.setRotationRange(range)
    trailConfig.rotationRange = range
end

function Trails.setSpinSpeed(speed)
    trailConfig.spinSpeed = speed
end

function Trails.setUseDecals(value)
    trailConfig.useDecals = value
end

function Trails.exportConfig()
    return {
        trails = trailConfig,
        enabled = enabled,
    }
end

function Trails.importConfig(data)
    if data.trails then
        for key, value in pairs(data.trails) do
            if trailConfig[key] ~= nil then
                if key == "color" and type(value) == "table" then
                    trailConfig[key] = Color3.fromRGB(value.R * 255, value.G * 255, value.B * 255)
                elseif key == "size" and type(value) == "table" then
                    trailConfig[key] = Vector3.new(value.X, value.Y, value.Z)
                else
                    trailConfig[key] = value
                end
            end
        end
    end

    if data.enabled ~= nil then
        enabled = data.enabled
    end
end

return Trails
