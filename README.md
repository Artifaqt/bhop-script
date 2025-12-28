# Bhop Hub - Modular Bunny Hop Script for Roblox

CS 1.6 Style Bunny Hop Physics with full visual customization and advanced trail system.

## Features

- **Authentic CS 1.6 Physics** - Ground friction, air acceleration, strafe mechanics
- **Multiple Presets** - CS 1.6, CS:GO, TF2 Scout, Quake, Easy Mode
- **Visual Systems**:
  - Velocity meter with color-coded speed display
  - Strafe helper showing optimal movement direction
  - Session statistics tracker
  - Debug HUD with real-time physics info
- **Advanced Trail System**:
  - Decal-based or neon sphere trails
  - Customizable colors, transparency, and size
  - Random rotation and spin effects
  - Fully configurable via UI
- **Customizable Sounds** - Change jump/land sound effects
- **Auto-Hop Mode** - Automatic jumping when grounded
- **Config System** - Export/import configurations via clipboard
- **Modular Architecture** - Easy to maintain and extend

## Setup Instructions

### 1. Upload to GitHub

1. Create a new GitHub repository (e.g., `roblox-bhop-hub`)
2. Upload the following file structure:

```
your-repo/
├── bhop_hub.lua          (Main loader)
└── modules/
    ├── physics.lua       (Physics engine)
    ├── visuals.lua       (HUD elements)
    ├── trails.lua        (Trail system)
    ├── sounds.lua        (Sound effects)
    ├── stats.lua         (Statistics)
    └── ui.lua            (UI management)
```

3. Make sure all files are in the `main` branch

### 2. Update the Main File

Edit `bhop_hub.lua` and update line 42:

```lua
local GITHUB_BASE = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/modules/"
```

Replace `YOUR_USERNAME` with your GitHub username and `YOUR_REPO` with your repository name.

Example:
```lua
local GITHUB_BASE = "https://raw.githubusercontent.com/Artifaqt/roblox-bhop-hub/main/modules/"
```

### 3. Usage in Roblox

Load the script using:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/bhop_hub.lua"))()
```

## Module Overview

### Physics Module (`physics.lua`)
- Handles all movement calculations
- Manages bhop state and configuration
- Implements CS 1.6 physics algorithms
- Provides preset system

### Visuals Module (`visuals.lua`)
- Creates and updates HUD elements
- Velocity meter with color gradients
- Strafe helper with efficiency display
- Session stats and debug info

### Trails Module (`trails.lua`)
- **NEW**: Decal-based trail system
- Customizable textures, colors, and transparency
- Random rotation and spin effects
- Efficient part management

### Sounds Module (`sounds.lua`)
- **FIXED**: Proper sound loading with valid IDs
- Customizable jump and land sounds
- Volume and pitch controls
- Integrated with stats tracking

### Stats Module (`stats.lua`)
- Tracks session statistics
- Jump counting and perfect jump detection
- Speed averaging and distance tracking
- Top speed recording

### UI Module (`ui.lua`)
- Creates Starlight interface
- Manages all tabs and controls
- Handles config import/export
- Syncs UI with keyboard toggles

## Controls

- **B** - Toggle bhop mode on/off
- **SPACE** - Jump (or use Auto-Hop)
- **WASD** - Movement (strafe in air for speed gain)

## Configuration

### Export Config
1. Open the **Presets** tab
2. Click **Export Config**
3. Share the clipboard content with friends

### Import Config
1. Copy a config string
2. Go to **Presets** tab
3. Paste into **Import Config** field

### Trails Customization
1. Open the **Trails** tab
2. Enable **Use Decals** for texture-based trails
3. Enter a decal texture ID (e.g., `rbxassetid://6073894888`)
4. Customize:
   - **Random Rotation** - Randomize initial orientation
   - **Rotation Range** - Max random rotation (0-360°)
   - **Spin Speed** - Continuous rotation (degrees/sec)
   - **Transparency** - Trail opacity
   - **Max Parts** - Trail length

### Custom Sounds
1. Open the **Sounds** tab
2. Enter sound asset IDs:
   - Jump Sound ID
   - Land Sound ID
3. Adjust volume and pitch for each sound

## Presets

### CS 1.6 Classic
Authentic Counter-Strike 1.6 bhop physics
- Moderate air acceleration
- Balanced ground friction
- Classic feel

### CS:GO Style
Modern Counter-Strike mechanics
- Very high air acceleration
- Tight air cap
- More responsive

### TF2 Scout
Team Fortress 2 Scout movement
- High ground speed
- Low friction
- Fast acceleration

### Quake
Arena shooter mechanics
- High air cap
- Strong air control
- Maximum speed potential

### Easy Mode
Beginner-friendly settings
- Low friction
- High acceleration
- Forgiving air control

## Troubleshooting

### Modules fail to load
- Check your GitHub repository is public
- Verify the GITHUB_BASE URL is correct
- Ensure all module files are in the `modules/` folder

### Sounds don't play
- Use valid Roblox asset IDs
- Format: `rbxassetid://NUMBERS`
- Check sound IDs in the Sounds tab

### Trails not appearing
- Enable trails in the Trails tab
- Increase **Max Parts** if trails are too short
- Check **Min Speed** threshold (default: 5)

### UI toggle doesn't sync with B key
- This is intentional - pressing B toggles bhop
- UI will update after Starlight processes the change

## Credits

**Created by Artifaqt**

- Physics: CS 1.6 Source Engine implementation
- UI: Starlight Interface Suite
- Icons: Nebula Icon Library

## License

Free to use and modify. Credit appreciated!

## Version History

### v2.0.0 (Modular Rewrite)
- Split into modular architecture
- Added decal-based trail system
- Fixed sound loading issues
- Added auto-hop mode
- Improved config system
- Added trail customization tab
- Added sounds customization tab

### v1.0.0
- Initial monolithic release
- Basic bhop physics
- Simple visual systems
