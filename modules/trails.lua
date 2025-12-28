local Trails = { }

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


local trailConfig = {
    decalTexture = "rbxassetid://8508980536",
}

function Trails.setDecalTexture(input)
    local asset = normalizeAssetId(input)
    if asset then
        trailConfig.decalTexture = asset
    end
end

function Trails.init() end
return Trails
