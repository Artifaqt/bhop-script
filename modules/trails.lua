-- Trails Module
-- Enhanced trail system with decal support

local Trails = {}

local HttpService = game:GetService("HttpService")

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

local trailPresets = {}


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
    decalTexture = "rbxassetid://8508980536",  -- Default decal
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
    local asset = normalizeAssetId(textureId)
    if asset then
        trailConfig.decalTexture = asset
    end
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


function Trails.previewDecal(optionalInput)
    -- Spawns a temporary anchored part with the current (or provided) decal texture
    local texture = normalizeAssetId(optionalInput) or trailConfig.decalTexture
    if not texture then
        warn("[Trails] previewDecal: invalid texture")
        return false
    end

    local cam = workspace.CurrentCamera
    local cf = cam and cam.CFrame or CFrame.new()
    local pos = cf.Position + (cf.LookVector * 6)

    local part = Instance.new("Part")
    part.Name = "__BhopTrailDecalPreview"
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Size = Vector3.new(4, 4, 0.2)
    part.CFrame = CFrame.new(pos, cf.Position)
    part.Transparency = 1
    part.Parent = workspace

    local d1 = Instance.new("Decal")
    d1.Texture = texture
    d1.Color3 = trailConfig.color
    d1.Transparency = 0
    d1.Face = Enum.NormalId.Front
    d1.Parent = part

    local d2 = d1:Clone()
    d2.Face = Enum.NormalId.Back
    d2.Parent = part

    local Debris = game:GetService("Debris")
    Debris:AddItem(part, 3)

    return true
end

function Trails.savePreset(name)
    if type(name) ~= "string" or name:gsub("%s+", "") == "" then
        return false, "Invalid preset name"
    end
    trailPresets[name] = HttpService:JSONDecode(HttpService:JSONEncode(trailConfig)) -- deep copy
    return true
end

function Trails.loadPreset(name)
    local preset = trailPresets[name]
    if not preset then
        return false, "Preset not found"
    end
    for k, v in pairs(preset) do
        trailConfig[k] = v
    end
    return true
end

function Trails.deletePreset(name)
    if trailPresets[name] then
        trailPresets[name] = nil
        return true
    end
    return false, "Preset not found"
end

function Trails.listPresets()
    local out = {}
    for k in pairs(trailPresets) do
        table.insert(out, k)
    end
    table.sort(out)
    return out
end

function Trails.exportPreset(name)
    local preset = trailPresets[name]
    if not preset then
        return nil, "Preset not found"
    end
    return HttpService:JSONEncode({ presetName = name, trails = preset })
end

function Trails.importPreset(name, data)
    if type(data) ~= "string" then
        return false, "Invalid data"
    end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(data)
    end)
    if not ok or type(decoded) ~= "table" then
        return false, "Decode failed"
    end
    local payload = decoded.trails or decoded
    if type(payload) ~= "table" then
        return false, "Invalid payload"
    end
    local presetName = name
    if (not presetName or presetName:gsub("%s+","")=="") and type(decoded.presetName)=="string" then
        presetName = decoded.presetName
    end
    if not presetName or presetName:gsub("%s+","")=="" then
        return false, "Missing preset name"
    end
    trailPresets[presetName] = payload
    -- apply immediately
    for k, v in pairs(payload) do
        trailConfig[k] = v
    end
    return true
end

function Trails.exportConfig()
    return {
        trails = trailConfig,
        enabled = enabled,
        presets = trailPresets,  -- Include saved presets
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

    -- Import saved presets
    if data.presets and type(data.presets) == "table" then
        trailPresets = data.presets
    end
end

return Trails
