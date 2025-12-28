local GITHUB_BASE = "https://raw.githubusercontent.com/Artifaqt/bhop-script/refs/heads/main/modules/"

local Physics  = loadstring(game:HttpGet(GITHUB_BASE .. "physics.lua"))()
local Visuals  = loadstring(game:HttpGet(GITHUB_BASE .. "visuals.lua"))()
local Trails   = loadstring(game:HttpGet(GITHUB_BASE .. "trails.lua"))()
local Sounds   = loadstring(game:HttpGet(GITHUB_BASE .. "sounds.lua"))()
local Stats    = loadstring(game:HttpGet(GITHUB_BASE .. "stats.lua"))()
local UI       = loadstring(game:HttpGet(GITHUB_BASE .. "ui.lua"))()

Physics.init(player, character, humanoid, rootPart)
Visuals.init(player, Physics)
Trails.init(player, rootPart, Physics)
Sounds.init(rootPart, Physics, Stats)
Stats.init()
UI.createWindow(Starlight, NebulaIcons, Physics, Visuals, Trails, Sounds, Stats)
