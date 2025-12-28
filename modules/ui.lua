-- UI Module
-- Creates and manages the Starlight UI

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local UI = {}

-- State
local Starlight, NebulaIcons
local Physics, Visuals, Trails, Sounds, Stats
local BhopToggle, AutoHopToggle

-- Physics UI element references
local PhysicsSliders = {}

-- Function to update physics UI elements to reflect current config
local function updatePhysicsUI()
    local config = Physics.getConfig()

    -- Safe update function that tries multiple methods
    local function safeSetSlider(slider, value)
        if not slider then return false end

        -- Try direct Set method
        if type(slider) == "table" and type(slider.Set) == "function" then
            local ok = pcall(function()
                slider:Set(value)
            end)
            if ok then return true end
        end

        -- Try SetValue method
        if type(slider) == "table" and type(slider.SetValue) == "function" then
            local ok = pcall(function()
                slider:SetValue(value)
            end)
            if ok then return true end
        end

        -- Try Starlight flag system
        if Starlight and type(Starlight.SetFlag) == "function" then
            for flagName, sliderRef in pairs({
                ground_friction_slider = PhysicsSliders.friction,
                ground_accel_slider = PhysicsSliders.groundAccel,
                ground_speed_slider = PhysicsSliders.groundSpeed,
                air_accel_slider = PhysicsSliders.airAccel,
                air_cap_slider = PhysicsSliders.airCap,
                jump_power_slider = PhysicsSliders.jumpPower,
            }) do
                if sliderRef == slider then
                    pcall(function()
                        Starlight:SetFlag(flagName, value)
                    end)
                    return true
                end
            end
        end

        return false
    end

    -- Update all sliders
    safeSetSlider(PhysicsSliders.friction, config.GROUND_FRICTION)
    safeSetSlider(PhysicsSliders.groundAccel, config.GROUND_ACCELERATE)
    safeSetSlider(PhysicsSliders.groundSpeed, config.GROUND_SPEED)
    safeSetSlider(PhysicsSliders.airAccel, config.AIR_ACCELERATE)
    safeSetSlider(PhysicsSliders.airCap, config.AIR_CAP)
    safeSetSlider(PhysicsSliders.jumpPower, config.JUMP_POWER)
end

local function createWindow()
    return Starlight:CreateWindow({
        Name = "Bhop Hub",
        Subtitle = "by Artifaqt",
        Icon = NebulaIcons:GetIcon('sports_motorsports', 'Material'),
        LoadingSettings = {
            Title = "Bhop Hub",
            Subtitle = "Loading bunny hop physics...",
        },
        FileSettings = {
            ConfigFolder = "BhopHub"
        },
    })
end

local function createDashboard(window)
    local MainSection = window:CreateTabSection("Main", false)
    local DashboardTab = MainSection:CreateTab({
        Name = "Dashboard",
        Icon = NebulaIcons:GetIcon('dashboard', 'Material'),
        Columns = 1,
    }, "dashboard_tab")

    local StatusGroupbox = DashboardTab:CreateGroupbox({
        Name = "Status",
        Column = 1,
    }, "status_groupbox")

    BhopToggle = StatusGroupbox:CreateToggle({
        Name = "Enable Bhop",
        CurrentValue = false,
        Style = 2,
        Icon = NebulaIcons:GetIcon('rocket_launch', 'Material'),
        Callback = function(value)
            Physics.toggleBhop(value)
            -- Note: This callback is triggered by UI clicks, not B key presses

            Starlight:Notification({
                Title = value and "Bhop Enabled" or "Bhop Disabled",
                Icon = NebulaIcons:GetIcon(value and 'check_circle' or 'cancel', 'Material'),
                Content = value and "Press SPACE + WASD to bhop." or "Normal movement restored.",
            }, "bhop_notif")
        end,
    }, "bhop_toggle")

    AutoHopToggle = StatusGroupbox:CreateToggle({
        Name = "Auto Bhop",
        CurrentValue = false,
        Style = 2,
        Icon = NebulaIcons:GetIcon('autorenew', 'Material'),
        Tooltip = "Automatically jump when you hit the ground",
        Callback = function(value)
            Physics.setAutoHop(value)
        end,
    }, "autohop_toggle")

    local InfoGroupbox = DashboardTab:CreateGroupbox({
        Name = "Quick Info",
        Column = 1,
    }, "info_groupbox")

    InfoGroupbox:CreateLabel({
        Name = "Press 'B' to toggle bhop mode",
        Icon = NebulaIcons:GetIcon('keyboard', 'Material'),
    }, "info_label_1")

    InfoGroupbox:CreateLabel({
        Name = "Enable visuals in the Visuals tab",
        Icon = NebulaIcons:GetIcon('visibility', 'Material'),
    }, "info_label_2")
end

local function createPhysicsTab(window)
    local ConfigSection = window:CreateTabSection("Configuration")
    local PhysicsTab = ConfigSection:CreateTab({
        Name = "Physics",
        Icon = NebulaIcons:GetIcon('science', 'Material'),
        Columns = 2,
    }, "physics_tab")

    local GroundPhysicsGroupbox = PhysicsTab:CreateGroupbox({
        Name = "Ground Physics",
        Column = 1,
    }, "ground_physics_groupbox")

    local config = Physics.getConfig()

    PhysicsSliders.friction = GroundPhysicsGroupbox:CreateSlider({
        Name = "Friction",
        Icon = NebulaIcons:GetIcon('straighten', 'Material'),
        Range = {0, 20},
        Increment = 0.5,
        CurrentValue = config.GROUND_FRICTION,
        Tooltip = "Ground deceleration. Higher = stop faster.",
        Callback = function(value)
            Physics.setConfig("GROUND_FRICTION", value)
        end,
    }, "ground_friction_slider")

    PhysicsSliders.groundAccel = GroundPhysicsGroupbox:CreateSlider({
        Name = "Acceleration",
        Icon = NebulaIcons:GetIcon('speed', 'Material'),
        Range = {1, 50},
        Increment = 1,
        CurrentValue = config.GROUND_ACCELERATE,
        Tooltip = "How fast you reach ground speed.",
        Callback = function(value)
            Physics.setConfig("GROUND_ACCELERATE", value)
        end,
    }, "ground_accel_slider")

    PhysicsSliders.groundSpeed = GroundPhysicsGroupbox:CreateSlider({
        Name = "Ground Speed",
        Icon = NebulaIcons:GetIcon('directions_run', 'Material'),
        Range = {10, 50},
        Increment = 1,
        CurrentValue = config.GROUND_SPEED,
        Tooltip = "Base running speed on ground.",
        Callback = function(value)
            Physics.setConfig("GROUND_SPEED", value)
        end,
    }, "ground_speed_slider")

    local AirPhysicsGroupbox = PhysicsTab:CreateGroupbox({
        Name = "Air Physics",
        Column = 2,
    }, "air_physics_groupbox")

    PhysicsSliders.airAccel = AirPhysicsGroupbox:CreateSlider({
        Name = "Air Acceleration",
        Icon = NebulaIcons:GetIcon('air', 'Material'),
        Range = {1, 100},
        Increment = 1,
        CurrentValue = config.AIR_ACCELERATE,
        Tooltip = "Air strafe power. CS 1.6 uses ~16.",
        Callback = function(value)
            Physics.setConfig("AIR_ACCELERATE", value)
        end,
    }, "air_accel_slider")

    PhysicsSliders.airCap = AirPhysicsGroupbox:CreateSlider({
        Name = "Air Cap",
        Icon = NebulaIcons:GetIcon('height', 'Material'),
        Range = {0.1, 30},
        Increment = 0.5,
        CurrentValue = config.AIR_CAP,
        Tooltip = "Max speed added per air strafe.",
        Callback = function(value)
            Physics.setConfig("AIR_CAP", value)
        end,
    }, "air_cap_slider")

    PhysicsSliders.jumpPower = AirPhysicsGroupbox:CreateSlider({
        Name = "Jump Power",
        Icon = NebulaIcons:GetIcon('arrow_upward', 'Material'),
        Range = {20, 100},
        Increment = 5,
        CurrentValue = config.JUMP_POWER,
        Tooltip = "Jump height.",
        Callback = function(value)
            Physics.setConfig("JUMP_POWER", value)
        end,
    }, "jump_power_slider")
end

local function createPresetsTab(window)
    local ConfigSection = window:CreateTabSection("Configuration")
    local PresetsTab = ConfigSection:CreateTab({
        Name = "Presets",
        Icon = NebulaIcons:GetIcon('inventory_2', 'Material'),
        Columns = 1,
    }, "presets_tab")

    local PresetLibraryGroupbox = PresetsTab:CreateGroupbox({
        Name = "Preset Library",
        Column = 1,
    }, "preset_library_groupbox")

    local presets = Physics.getPresets()
    local presetNames = {}
    for name, _ in pairs(presets) do
        table.insert(presetNames, name)
    end
    table.sort(presetNames)

    local PresetLabel = PresetLibraryGroupbox:CreateLabel({
        Name = "Built-in Presets",
        Icon = NebulaIcons:GetIcon('library_books', 'Material'),
    }, "preset_library_label")

    PresetLabel:AddDropdown({
        Options = presetNames,
        CurrentOptions = {},
        Placeholder = "Select a preset...",
        Callback = function(options)
            if #options > 0 then
                Physics.loadPreset(options[1])
                updatePhysicsUI()  -- Update UI to reflect new preset values
                Starlight:Notification({
                    Title = "Preset Loaded",
                    Icon = NebulaIcons:GetIcon('check', 'Material'),
                    Content = "Loaded: " .. options[1],
                }, "preset_load_notif")
            end
        end,
    }, "preset_dropdown")

    local ShareGroupbox = PresetsTab:CreateGroupbox({
        Name = "Share Configs",
        Column = 1,
    }, "share_groupbox")

    ShareGroupbox:CreateButton({
        Name = "Export Config",
        Icon = NebulaIcons:GetIcon('upload', 'Material'),
        Tooltip = "Copy config to clipboard",
        Callback = function()
            local exportData = {
                physics = Physics.exportConfig(),
                visuals = Visuals.exportConfig(),
                trails = Trails.exportConfig(),
                sounds = Sounds.exportConfig(),
            }

            local encoded = HttpService:JSONEncode(exportData)
            setclipboard(encoded)

            Starlight:Notification({
                Title = "Config Exported",
                Icon = NebulaIcons:GetIcon('content_copy', 'Material'),
                Content = "Config copied to clipboard!",
            }, "export_notif")
        end,
    }, "export_button")

    ShareGroupbox:CreateInput({
        Name = "Import Config",
        Icon = NebulaIcons:GetIcon('download', 'Material'),
        PlaceholderText = "Paste config here...",
        Tooltip = "Paste config to import",
        RemoveTextAfterFocusLost = true,
        Callback = function(text)
            if text == "" then return end

            local success = pcall(function()
                local importData = HttpService:JSONDecode(text)

                if importData.physics then Physics.importConfig(importData.physics) end
                if importData.visuals then Visuals.importConfig(importData.visuals) end
                if importData.trails then Trails.importConfig(importData.trails) end
                if importData.sounds then Sounds.importConfig(importData.sounds) end

                -- Update UI to reflect imported values
                updatePhysicsUI()

                Starlight:Notification({
                    Title = "Config Imported",
                    Icon = NebulaIcons:GetIcon('download', 'Material'),
                    Content = "Successfully loaded config!",
                }, "import_success_notif")
            end)

            if not success then
                Starlight:Notification({
                    Title = "Import Failed",
                    Icon = NebulaIcons:GetIcon('error', 'Material'),
                    Content = "Invalid config data.",
                }, "import_fail_notif")
            end
        end,
    }, "import_input")
end

local function createVisualsTab(window)
    local VisualsSection = window:CreateTabSection("Visuals")
    local VisualsTab = VisualsSection:CreateTab({
        Name = "Display",
        Icon = NebulaIcons:GetIcon('visibility', 'Material'),
        Columns = 1,
    }, "visuals_tab")

    local DisplayGroupbox = VisualsTab:CreateGroupbox({
        Name = "HUD Elements",
        Column = 1,
    }, "display_groupbox")

    DisplayGroupbox:CreateToggle({
        Name = "Velocity Meter",
        CurrentValue = false,
        Style = 2,
        Icon = NebulaIcons:GetIcon('speed', 'Material'),
        Callback = function(value)
            Visuals.setVelocityMeterEnabled(value)
        end,
    }, "velocity_meter_toggle")

    DisplayGroupbox:CreateToggle({
        Name = "Strafe Helper",
        CurrentValue = false,
        Style = 2,
        Icon = NebulaIcons:GetIcon('navigation', 'Material'),
        Callback = function(value)
            Visuals.setStrafeHelperEnabled(value)
        end,
    }, "strafe_helper_toggle")

    DisplayGroupbox:CreateToggle({
        Name = "Session Stats",
        CurrentValue = false,
        Style = 2,
        Icon = NebulaIcons:GetIcon('analytics', 'Material'),
        Callback = function(value)
            Visuals.setSessionStatsEnabled(value)
        end,
    }, "stats_toggle")

    DisplayGroupbox:CreateToggle({
        Name = "Debug HUD",
        CurrentValue = false,
        Style = 2,
        Icon = NebulaIcons:GetIcon('bug_report', 'Material'),
        Callback = function(value)
            Visuals.setDebugHUDEnabled(value)
        end,
    }, "debug_hud_toggle")

    local EffectsGroupbox = VisualsTab:CreateGroupbox({
        Name = "Effects & Stats",
        Column = 1,
    }, "effects_groupbox")

    EffectsGroupbox:CreateToggle({
        Name = "Sound Effects",
        CurrentValue = false,
        Style = 2,
        Icon = NebulaIcons:GetIcon('volume_up', 'Material'),
        Callback = function(value)
            Sounds.setEnabled(value)
        end,
    }, "sounds_toggle")

    EffectsGroupbox:CreateButton({
        Name = "Reset Session Stats",
        Icon = NebulaIcons:GetIcon('restart_alt', 'Material'),
        Callback = function()
            Stats.reset()
            Starlight:Notification({
                Title = "Stats Reset",
                Icon = NebulaIcons:GetIcon('check', 'Material'),
                Content = "Session stats reset.",
            }, "stats_reset_notif")
        end,
    }, "reset_stats_button")
end

local function createTrailsTab(window)
    local VisualsSection = window:CreateTabSection("Visuals")
    local TrailsTab = VisualsSection:CreateTab({
        Name = "Trails",
        Icon = NebulaIcons:GetIcon('timeline', 'Material'),
        Columns = 2,
    }, "trails_tab")

    local TrailToggleGroupbox = TrailsTab:CreateGroupbox({
        Name = "Trail Settings",
        Column = 1,
    }, "trail_toggle_groupbox")

    TrailToggleGroupbox:CreateToggle({
        Name = "Enable Trails",
        CurrentValue = false,
        Style = 2,
        Icon = NebulaIcons:GetIcon('timeline', 'Material'),
        Callback = function(value)
            Trails.setEnabled(value)
        end,
    }, "trail_toggle")

    local trailConfig = Trails.getConfig()

    TrailToggleGroupbox:CreateToggle({
        Name = "Use Decals",
        CurrentValue = trailConfig.useDecals,
        Style = 2,
        Icon = NebulaIcons:GetIcon('image', 'Material'),
        Tooltip = "Use decal textures instead of solid spheres",
        Callback = function(value)
            Trails.setUseDecals(value)
        end,
    }, "use_decals_toggle")

    TrailToggleGroupbox:CreateInput({
        Name = "Decal Texture ID",
        PlaceholderText = "rbxassetid://...",
        CurrentValue = trailConfig.decalTexture,
        Callback = function(text)
            Trails.setDecalTexture(text)
            -- Auto-preview on paste
            if text and text ~= "" then
                task.delay(0.1, function()
                    Trails.previewDecal()
                end)
            end
        end,
    }, "decal_texture_input")


    TrailToggleGroupbox:CreateButton({
        Name = "Preview Decal",
        Icon = NebulaIcons:GetIcon('image', 'Material'),
        Tooltip = "Shows the current decal in front of your camera for a few seconds",
        Callback = function()
            Trails.previewDecal()
        end,
    }, "trail_preview_decal_btn")

    
    local PresetsGroupbox = TrailsTab:CreateGroupbox({
        Name = "Trail Presets",
        Column = 1,
    }, "trail_presets_groupbox")

    local trailPresetName = "Default"
    local trailPresetImport = ""

    PresetsGroupbox:CreateInput({
        Name = "Preset Name",
        PlaceholderText = "e.g. Frost, Neon, Glass...",
        CurrentValue = trailPresetName,
        Callback = function(text)
            trailPresetName = tostring(text or "")
        end,
    }, "trail_preset_name_input")

    PresetsGroupbox:CreateButton({
        Name = "Save Current as Preset",
        Icon = NebulaIcons:GetIcon('save', 'Material'),
        Tooltip = "Stores the current trail settings under this name (in-session)",
        Callback = function()
            local ok, err = Trails.savePreset(trailPresetName)
            if not ok then warn("[Trails] Save preset failed: " .. tostring(err)) end
        end,
    }, "trail_preset_save_btn")

    PresetsGroupbox:CreateButton({
        Name = "Load Preset",
        Icon = NebulaIcons:GetIcon('download', 'Material'),
        Tooltip = "Loads the preset into current trail settings (in-session)",
        Callback = function()
            local ok, err = Trails.loadPreset(trailPresetName)
            if not ok then warn("[Trails] Load preset failed: " .. tostring(err)) end
        end,
    }, "trail_preset_load_btn")

    PresetsGroupbox:CreateButton({
        Name = "Delete Preset",
        Icon = NebulaIcons:GetIcon('trash', 'Material'),
        Tooltip = "Deletes the preset (in-session)",
        Callback = function()
            local ok, err = Trails.deletePreset(trailPresetName)
            if not ok then warn("[Trails] Delete preset failed: " .. tostring(err)) end
        end,
    }, "trail_preset_delete_btn")

    PresetsGroupbox:CreateButton({
        Name = "Export Preset to Clipboard",
        Icon = NebulaIcons:GetIcon('upload', 'Material'),
        Tooltip = "Copies the preset JSON to your clipboard",
        Callback = function()
            local data, err = Trails.exportPreset(trailPresetName)
            if not data then
                warn("[Trails] Export preset failed: " .. tostring(err))
                return
            end
            if setclipboard then
                setclipboard(data)
            else
                warn("[Trails] setclipboard not available in this executor")
            end
        end,
    }, "trail_preset_export_btn")

    PresetsGroupbox:CreateInput({
        Name = "Import Preset JSON",
        PlaceholderText = "{...}",
        CurrentValue = trailPresetImport,
        Callback = function(text)
            trailPresetImport = tostring(text or "")
        end,
    }, "trail_preset_import_input")

    PresetsGroupbox:CreateButton({
        Name = "Import + Apply Preset",
        Icon = NebulaIcons:GetIcon('download', 'Material'),
        Tooltip = "Imports a preset JSON string and applies it immediately",
        Callback = function()
            local ok, err = Trails.importPreset(trailPresetName, trailPresetImport)
            if not ok then warn("[Trails] Import preset failed: " .. tostring(err)) end
        end,
    }, "trail_preset_import_btn")

local CustomizeGroupbox = TrailsTab:CreateGroupbox({
        Name = "Customization",
        Column = 2,
    }, "trail_customize_groupbox")

    CustomizeGroupbox:CreateToggle({
        Name = "Random Rotation",
        CurrentValue = trailConfig.randomRotation,
        Style = 2,
        Icon = NebulaIcons:GetIcon('autorenew', 'Material'),
        Callback = function(value)
            Trails.setRandomRotation(value)
        end,
    }, "random_rotation_toggle")

    CustomizeGroupbox:CreateSlider({
        Name = "Rotation Range",
        Range = {0, 360},
        Increment = 15,
        CurrentValue = trailConfig.rotationRange,
        Tooltip = "Max random rotation in degrees",
        Callback = function(value)
            Trails.setRotationRange(value)
        end,
    }, "rotation_range_slider")

    CustomizeGroupbox:CreateSlider({
        Name = "Spin Speed",
        Range = {0, 360},
        Increment = 15,
        CurrentValue = trailConfig.spinSpeed,
        Tooltip = "Rotation speed (degrees/sec)",
        Callback = function(value)
            Trails.setSpinSpeed(value)
        end,
    }, "spin_speed_slider")

    CustomizeGroupbox:CreateSlider({
        Name = "Transparency",
        Range = {0, 1},
        Increment = 0.05,
        CurrentValue = trailConfig.transparency,
        Callback = function(value)
            Trails.setTransparency(value)
        end,
    }, "trail_transparency_slider")

    CustomizeGroupbox:CreateSlider({
        Name = "Max Parts",
        Range = {5, 50},
        Increment = 5,
        CurrentValue = trailConfig.maxParts,
        Tooltip = "Maximum trail parts visible",
        Callback = function(value)
            Trails.setConfig("maxParts", value)
        end,
    }, "max_parts_slider")
end

local function createSoundsTab(window)
    local VisualsSection = window:CreateTabSection("Visuals")
    local SoundsTab = VisualsSection:CreateTab({
        Name = "Sounds",
        Icon = NebulaIcons:GetIcon('volume_up', 'Material'),
        Columns = 2,
    }, "sounds_tab")

    local soundConfig = Sounds.getConfig()

    local JumpSoundGroupbox = SoundsTab:CreateGroupbox({
        Name = "Jump Sound",
        Column = 1,
    }, "jump_sound_groupbox")

    JumpSoundGroupbox:CreateInput({
        Name = "Sound ID",
        PlaceholderText = "rbxassetid://...",
        CurrentValue = soundConfig.jumpSoundId,
        Callback = function(text)
            Sounds.setJumpSound(text)
            -- Auto-preview on paste
            if text and text ~= "" then
                task.delay(0.1, function()
                    Sounds.previewJump()
                end)
            end
        end,
    }, "jump_sound_id")

    JumpSoundGroupbox:CreateButton({
        Name = "Test Jump Sound",
        Icon = NebulaIcons:GetIcon('play_arrow', 'Material'),
        Tooltip = "Plays the current jump sound once",
        Callback = function()
            Sounds.previewJump()
        end,
    }, "test_jump_sound_btn")


    JumpSoundGroupbox:CreateSlider({
        Name = "Volume",
        Range = {0, 1},
        Increment = 0.1,
        CurrentValue = soundConfig.jumpVolume,
        Callback = function(value)
            Sounds.setJumpSound(nil, value)
        end,
    }, "jump_volume_slider")

    JumpSoundGroupbox:CreateSlider({
        Name = "Pitch",
        Range = {0.5, 2},
        Increment = 0.1,
        CurrentValue = soundConfig.jumpPitch,
        Callback = function(value)
            Sounds.setJumpSound(nil, nil, value)
        end,
    }, "jump_pitch_slider")

    local LandSoundGroupbox = SoundsTab:CreateGroupbox({
        Name = "Land Sound",
        Column = 2,
    }, "land_sound_groupbox")

    LandSoundGroupbox:CreateInput({
        Name = "Sound ID",
        PlaceholderText = "rbxassetid://...",
        CurrentValue = soundConfig.landSoundId,
        Callback = function(text)
            Sounds.setLandSound(text)
            -- Auto-preview on paste
            if text and text ~= "" then
                task.delay(0.1, function()
                    Sounds.previewLand()
                end)
            end
        end,
    }, "land_sound_id")

    LandSoundGroupbox:CreateButton({
        Name = "Test Land Sound",
        Icon = NebulaIcons:GetIcon('play_arrow', 'Material'),
        Tooltip = "Plays the current land sound once",
        Callback = function()
            Sounds.previewLand()
        end,
    }, "test_land_sound_btn")


    LandSoundGroupbox:CreateSlider({
        Name = "Volume",
        Range = {0, 1},
        Increment = 0.1,
        CurrentValue = soundConfig.landVolume,
        Callback = function(value)
            Sounds.setLandSound(nil, value)
        end,
    }, "land_volume_slider")

    LandSoundGroupbox:CreateSlider({
        Name = "Pitch",
        Range = {0.5, 2},
        Increment = 0.1,
        CurrentValue = soundConfig.landPitch,
        Callback = function(value)
            Sounds.setLandSound(nil, nil, value)
        end,
    }, "land_pitch_slider")
end

local function setupUpdateLoop()
    local wasGrounded = false

    RunService.RenderStepped:Connect(function(dt)
        local velocity = Physics.getVelocity()
        local speed = velocity.Magnitude
        local onGround = Physics.isGrounded()

        -- Keep ground state in sync even when disabled (prevents false "perfect" counts when re-enabled)
        if not Physics.isEnabled() then
            wasGrounded = onGround
            return
        end

        -- Track jump stats independently of Sounds (so disabling sounds doesn't break stats)
        if (not wasGrounded) and onGround then
            local cfg = Physics.getConfig()
            local isPerfect = speed > (cfg.GROUND_SPEED * 0.9)
            Stats.recordJump(isPerfect)
        end
        wasGrounded = onGround

        -- Update all modules
        Visuals.update(speed, onGround, Stats.getStats())
        Trails.update(speed, dt)
        Sounds.update(speed, onGround)
        Stats.updateStats(speed, dt)
    end)
end

-- Module API
function UI.createWindow(starlight, nebulaIcons, physics, visuals, trails, sounds, stats)
    Starlight = starlight
    NebulaIcons = nebulaIcons
    Physics = physics
    Visuals = visuals
    Trails = trails
    Sounds = sounds
    Stats = stats

    local window = createWindow()

    createDashboard(window)
    createPhysicsTab(window)
    createPresetsTab(window)
    createVisualsTab(window)
    createTrailsTab(window)
    createSoundsTab(window)

    -- Build config groupbox
    window:CreateTabSection("Settings"):CreateTab({
        Name = "General",
        Icon = NebulaIcons:GetIcon('settings', 'Material'),
        Columns = 1,
    }, "settings_tab"):BuildConfigGroupbox(1)

    -- Setup update loop
    setupUpdateLoop()

    -- Load autoload config
    Starlight:LoadAutoloadConfig()
end

function UI.syncToggle(enabled)
    -- Safely update the bhop toggle UI element when B key is pressed
    -- This function handles various Starlight UI library versions and never throws errors

    -- Method 1: Try direct toggle object methods
    if BhopToggle and type(BhopToggle) == "table" then
        pcall(function()
            -- Try common toggle methods in order of preference
            if type(BhopToggle.Set) == "function" then
                BhopToggle:Set(enabled)
            elseif type(BhopToggle.SetValue) == "function" then
                BhopToggle:SetValue(enabled)
            elseif type(BhopToggle.Update) == "function" then
                BhopToggle:Update(enabled)
            elseif BhopToggle.Value ~= nil then
                BhopToggle.Value = enabled
            end
        end)
    end

    -- Method 2: Try Starlight flag system (always attempt, as it's most reliable)
    if Starlight then
        pcall(function()
            -- Try SetFlag method
            if type(Starlight.SetFlag) == "function" then
                Starlight:SetFlag("bhop_toggle", enabled)
            end
        end)

        pcall(function()
            -- Try direct Flags table
            if type(Starlight.Flags) == "table" then
                Starlight.Flags["bhop_toggle"] = enabled
            end
        end)

        pcall(function()
            -- Try Options system
            if type(Starlight.Options) == "table" and type(Starlight.Options["bhop_toggle"]) == "table" then
                local opt = Starlight.Options["bhop_toggle"]
                if type(opt.Set) == "function" then
                    opt:Set(enabled)
                elseif type(opt.SetValue) == "function" then
                    opt:SetValue(enabled)
                elseif opt.Value ~= nil then
                    opt.Value = enabled
                end
            end
        end)
    end
end

return UI
