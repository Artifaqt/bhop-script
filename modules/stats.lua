-- Stats Module
-- Handles session statistics tracking
-- All speeds are horizontal (2D) speeds only

local Stats = {}

-- Session Statistics
local sessionStats = {
    totalJumps = 0,
    perfectJumps = 0,
    topSpeed = 0,  -- Max horizontal speed reached
    totalDistance = 0,  -- Total horizontal distance traveled
    sessionTime = 0,
    avgSpeed = 0,  -- Average horizontal speed
    speedSamples = {},  -- Rolling window of speed samples
}

-- Module API
function Stats.init()
    -- Nothing to initialize
end

function Stats.recordJump(isPerfect)
    sessionStats.totalJumps = sessionStats.totalJumps + 1
    if isPerfect then
        sessionStats.perfectJumps = sessionStats.perfectJumps + 1
    end
end

function Stats.updateStats(speed2D, dt)
    -- Update session time
    sessionStats.sessionTime = sessionStats.sessionTime + dt

    -- Update speed samples for average (rolling window of 100 samples)
    table.insert(sessionStats.speedSamples, speed2D)
    if #sessionStats.speedSamples > 100 then
        table.remove(sessionStats.speedSamples, 1)
    end

    -- Calculate average horizontal speed
    local avgSpeed = 0
    for _, s in ipairs(sessionStats.speedSamples) do
        avgSpeed = avgSpeed + s
    end
    sessionStats.avgSpeed = #sessionStats.speedSamples > 0
        and (avgSpeed / #sessionStats.speedSamples)
        or 0

    -- Update total horizontal distance traveled
    sessionStats.totalDistance = sessionStats.totalDistance + (speed2D * dt)

    -- Update top horizontal speed
    if speed2D > sessionStats.topSpeed then
        sessionStats.topSpeed = speed2D
    end
end

function Stats.getStats()
    return sessionStats
end

function Stats.reset()
    sessionStats.totalJumps = 0
    sessionStats.perfectJumps = 0
    sessionStats.topSpeed = 0
    sessionStats.totalDistance = 0
    sessionStats.sessionTime = 0
    sessionStats.avgSpeed = 0
    sessionStats.speedSamples = {}
end

function Stats.exportConfig()
    return {}  -- Stats don't need to be exported in config
end

function Stats.importConfig(data)
    -- Stats don't need to be imported
end

return Stats
