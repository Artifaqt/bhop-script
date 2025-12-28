# GitHub Upload Guide

Quick reference for uploading your Bhop Hub to GitHub.

## File Structure to Upload

```
your-repository/
├── bhop_hub.lua
├── README.md
└── modules/
    ├── physics.lua
    ├── visuals.lua
    ├── trails.lua
    ├── sounds.lua
    ├── stats.lua
    └── ui.lua
```

## Step-by-Step Upload Process

### Option 1: Upload via GitHub Web Interface

1. **Create New Repository**
   - Go to https://github.com/new
   - Name it (e.g., `roblox-bhop-hub`)
   - Make it **Public**
   - Click "Create repository"

2. **Upload Files**
   - Click "uploading an existing file"
   - Drag and drop `bhop_hub.lua` and `README.md`
   - Click "Commit changes"

3. **Create modules folder**
   - Click "Add file" → "Create new file"
   - Type `modules/physics.lua` in the name field
   - Paste the contents of `physics.lua`
   - Click "Commit changes"
   - Repeat for all other module files

### Option 2: Upload via Git Command Line

```bash
# Navigate to your bhop script folder
cd "c:\Users\Artifaqt\Downloads\bhop script"

# Initialize git
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit - Modular bhop hub"

# Add remote (replace with your repo URL)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### Option 3: GitHub Desktop

1. Open GitHub Desktop
2. File → Add Local Repository
3. Choose `c:\Users\Artifaqt\Downloads\bhop script`
4. Publish repository
5. Make sure it's **Public**

## After Upload

### Update the Loader

Edit `bhop_hub.lua` on GitHub (or locally and push):

**Line 42:**
```lua
local GITHUB_BASE = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/modules/"
```

**Example (if your username is "Artifaqt" and repo is "bhop-hub"):**
```lua
local GITHUB_BASE = "https://raw.githubusercontent.com/Artifaqt/bhop-hub/main/modules/"
```

### Get Your Loadstring

Your final loadstring will be:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/bhop_hub.lua"))()
```

**Example:**
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Artifaqt/bhop-hub/main/bhop_hub.lua"))()
```

## Verify It Works

1. Copy your loadstring
2. Open Roblox Studio or use an executor
3. Paste and run the loadstring
4. You should see: `[BHOP HUB] Loading modules...` followed by `[BHOP HUB] Loaded successfully!`

## Troubleshooting

### "HTTP 404" Error
- Repository is not public
- File paths are incorrect
- Branch is not `main` (change `/main/` in URLs if using `master`)

### "Module failed to load"
- Check spelling of file names (case-sensitive!)
- Verify all 6 module files are uploaded
- Make sure files are in `modules/` folder

### "Unable to cast value to function"
- One of the module files has syntax errors
- Check file contents were copied correctly

## Making Changes

After making changes to any module:

1. Edit the file on GitHub or push changes via git
2. Users need to re-run the loadstring to get updates
3. No need to update the main `bhop_hub.lua` unless you change module names

## Benefits of This Setup

✅ Easy updates - just edit files on GitHub
✅ Version control - track all changes
✅ Shareable - one loadstring for everything
✅ Maintainable - each module is independent
✅ Professional - proper code organization

## Example Repository

Here's what your repository structure looks like on GitHub:

```
📁 your-repo
├── 📄 bhop_hub.lua
├── 📄 README.md
├── 📄 GITHUB_UPLOAD.md (optional)
└── 📁 modules
    ├── 📄 physics.lua
    ├── 📄 visuals.lua
    ├── 📄 trails.lua
    ├── 📄 sounds.lua
    ├── 📄 stats.lua
    └── 📄 ui.lua
```

## Quick Checklist

- [ ] Repository created and is **Public**
- [ ] All 7 files uploaded (1 main + 6 modules)
- [ ] `modules/` folder created
- [ ] Updated GITHUB_BASE in `bhop_hub.lua`
- [ ] Tested loadstring in Roblox
- [ ] Script loads successfully

## Need Help?

If you encounter issues:
1. Check repository is public
2. Verify file names match exactly
3. Ensure branch is `main` not `master`
4. Test the raw URLs directly in browser

---

**Ready to share!** Once uploaded, share your loadstring with others!
