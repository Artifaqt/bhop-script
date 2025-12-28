# Bhop Hub v2.1 - Improvements Summary

## Overview
This document summarizes the improvements made to the Bhop Hub modular system.

---

## 1. CS/Quake-Style Strafe Efficiency Calculation

### Location
[modules/visuals.lua:289-348](modules/visuals.lua#L289-L348)

### What Changed
Replaced the simple dot product calculation with authentic CS/Quake physics:

**Old Method:**
- Simple dot product between velocity and input direction
- Fixed thresholds (90% = green, 70% = yellow, etc.)
- No consideration for speed or physics config

**New Method:**
- Calculates optimal strafe angle: `θ_opt = acos(AIR_CAP / speed)` when `speed > AIR_CAP`
- Compares actual input angle vs optimal angle
- Speed-based tolerance system:
  - Tighter tolerance at low speeds (15°)
  - Looser tolerance at high speeds (up to 40°)
  - Scales smoothly between 0-50 studs/s

**Debug Mode:**
- When Debug HUD is enabled, shows `actual° / optimal°` in efficiency label
- Example: `Efficiency: 87% (23° / 25°)`

### Color Feedback Thresholds
- **>85%** - Perfect (bright green)
- **>65%** - Good (yellow-green)
- **>45%** - Okay (yellow)
- **>25%** - Poor (orange)
- **≤25%** - Bad (red)

### Benefits
- More accurate feedback for experienced players
- Teaches proper strafe angles for different speeds
- Stable indicator at high speeds (no flickering)
- Educational - shows exactly how far off optimal you are

---

## 2. Trail Preset Persistence

### Location
[modules/trails.lua:332-363](modules/trails.lua#L332-L363)

### What Changed
Trail presets now persist in config exports:

**Export:**
```lua
function Trails.exportConfig()
    return {
        trails = trailConfig,
        enabled = enabled,
        presets = trailPresets,  -- NEW: Include saved presets
    }
end
```

**Import:**
```lua
function Trails.importConfig(data)
    -- ... existing config import ...

    -- NEW: Import saved presets
    if data.presets and type(data.presets) == "table" then
        trailPresets = data.presets
    end
end
```

### Benefits
- Presets survive script reloads
- Share custom trail presets with friends via config export
- Build a personal library of trail styles
- No need to recreate presets every session

---

## 3. Live Preview on Asset ID Paste

### Location
- [modules/ui.lua:646-651](modules/ui.lua#L646-L651) - Jump sound
- [modules/ui.lua:697-701](modules/ui.lua#L697-L701) - Land sound
- [modules/ui.lua:469-473](modules/ui.lua#L469-L473) - Decal texture

### What Changed
All asset ID inputs now auto-preview when you paste an ID:

**Jump/Land Sounds:**
```lua
Callback = function(text)
    Sounds.setJumpSound(text)
    -- Auto-preview on paste
    if text and text ~= "" then
        task.delay(0.1, function()
            Sounds.previewJump()
        end)
    end
end
```

**Decal Textures:**
```lua
Callback = function(text)
    Trails.setDecalTexture(text)
    -- Auto-preview on paste
    if text and text ~= "" then
        task.delay(0.1, function()
            Trails.previewDecal()
        end)
    end
end
```

### Benefits
- Instant feedback when testing new assets
- No need to click "Test" button after pasting
- Faster workflow for finding the perfect sound/decal
- 100ms delay prevents spam if typing quickly

---

## 4. Physics UI Auto-Update on Preset Load

### Location
[modules/ui.lua:18-70](modules/ui.lua#L18-L70), [210](modules/ui.lua#L210), [265](modules/ui.lua#L265)

### What Changed
Physics sliders now update visually when loading presets or importing configs:

**Preset Load:**
```lua
Physics.loadPreset(options[1])
updatePhysicsUI()  -- NEW: Update UI to reflect new preset values
```

**Config Import:**
```lua
if importData.physics then Physics.importConfig(importData.physics) end
-- ... other imports ...
updatePhysicsUI()  -- NEW: Update UI to reflect imported values
```

**Update Function:**
- Stores references to all physics sliders
- Safe update logic with multiple fallback methods
- Works with different Starlight UI library versions

### Benefits
- Visual feedback when switching presets
- See exactly what values each preset uses
- No confusion about current physics settings
- Helps learn the differences between presets

---

## Version History

### v2.1.0 (Current)
- ✅ Implemented CS/Quake-style strafe efficiency calculation
- ✅ Added speed-based tolerance for strafe helper
- ✅ Improved color feedback (5 levels instead of 3)
- ✅ Added optional angle display in debug mode
- ✅ Trail presets now persist in config export/import
- ✅ Live sound preview on ID paste
- ✅ Live decal preview on ID paste
- ✅ Physics UI auto-updates when loading presets

### v2.0.0
- Modular architecture
- Decal-based trail system
- Fixed sound loading
- Auto-hop mode
- Improved config system

### v1.0.0
- Initial monolithic release

---

## Testing Checklist

- [ ] Load CS 1.6 preset - verify all sliders update
- [ ] Load CS:GO preset - verify high air accel values show correctly
- [ ] Enable strafe helper + debug HUD - verify angle display shows
- [ ] Strafe at low speed (10-20) - verify tight tolerance
- [ ] Strafe at high speed (60+) - verify looser tolerance, stable color
- [ ] Save trail preset - export config - reimport - verify preset still exists
- [ ] Paste sound ID - verify auto-preview plays after 100ms
- [ ] Paste decal ID - verify preview part spawns automatically
- [ ] Import friend's config - verify physics sliders update visually

---

## Technical Notes

### Strafe Efficiency Formula
```
speed2D = horizontal_velocity.magnitude
optimalAngle = acos(clamp(AIR_CAP / speed2D, 0, 1))  // when speed > AIR_CAP
actualAngle = acos(clamp(velocity_dir · wish_dir, -1, 1))
angleDiff = |actualAngle - optimalAngle|

speedFactor = clamp(speed2D / 50, 0.3, 1)
maxTolerance = 15° + (25° × speedFactor)  // 15-40° range

efficiency = clamp(1 - (angleDiff / maxTolerance), 0, 1)
```

### Why Speed-Based Tolerance?
At low speeds:
- Small angle errors have big impact on acceleration
- Tighter feedback helps learn proper technique
- 15° tolerance feels responsive

At high speeds:
- Harder to maintain perfect angles due to sensitivity
- Looser tolerance prevents flickering indicators
- 40° tolerance feels fair and stable

---

## Credits

**Physics Improvements:** CS 1.6/Quake III Arena source code reference
**UI Enhancements:** Community feedback
**Created by:** Artifaqt

---

**Enjoy the improved bhop experience!** 🚀
