# Changelog

## Latest Updates

### ✨ New Features

#### 🎨 Separated Configuration Files
- **configs/gnome-settings.conf** - All GNOME/gsettings in one editable file
- **configs/keybindings.conf** - Custom keybindings configuration
- Scripts now copy these to `~/.config/` for easy customization
- Version control friendly! Track your config changes in git

#### 🌐 Added Zen Browser
- Beautiful, privacy-focused browser based on Firefox
- Modern UI with vertical tabs, split view
- Alternative to Chrome for privacy-conscious users
- Install with: `./install.sh zen`

#### 🛠️ New Helper Commands
- `apply-appearance` - Apply GNOME settings from config file
- Parses `~/.config/gnome-settings.conf` and applies all settings
- Easier to customize and version control

### 🔄 Changes

#### Simplified AppImage
- AppImage support moved to optional (removed from essentials)
- Created `APPIMAGE-INFO.md` to explain what it is
- Most users should use Nix instead for better package management
- Still available: `./debian/setup-appimage.sh`

#### Better Organization
```
configs/                        # NEW: Configuration files
  ├── gnome-settings.conf      # GNOME appearance settings
  └── keybindings.conf         # Custom keybindings

debian/
  ├── install-zen.sh           # NEW: Zen browser
  ├── setup-appearance.sh      # UPDATED: Uses config files
  └── setup-keybindings.sh     # UPDATED: Uses config files
```

### 📝 Philosophy

**System package manager (apt)**:
- ✅ Docker, NVIDIA (kernel integration)
- ✅ Desktop integration (launcher, keybindings)
- ✅ Browsers, terminals

**Nix (user packages)**:
- ✅ Development tools
- ✅ CLI utilities
- ✅ Dotfiles via home-manager

**Why?** Best of both worlds - stable system with reproducible user environment!

### 🎯 Updated Menu

New interactive menu structure:
```
📦 Core System (1-3)
   - Nix, Docker, NVIDIA

🌐 Browsers & Editors (4-6)
   - Chrome, Zen, Cursor

💻 Terminal & Tools (7)
   - Alacritty

⚙️  Customization (8-10)
   - Launcher, Keybindings, Appearance

🚀 Quick Install (11-12)
   - Essentials (1-7)
   - Everything (1-10)
```

### 📦 What's in "Essentials" Now
1. Nix Package Manager
2. Docker + Docker Compose
3. Google Chrome
4. Zen Browser
5. Cursor AI Editor
6. Alacritty Terminal

### 💡 Tips

1. **Edit configs before applying**:
   ```bash
   nano ~/.config/gnome-settings.conf
   apply-appearance
   ```

2. **Version control your configs**:
   ```bash
   cd ~/system-setup
   git add configs/
   git commit -m "My custom settings"
   ```

3. **Customize keybindings**:
   ```bash
   nano ~/.config/keybindings.conf
   ./debian/setup-keybindings.sh
   ```

### 🚀 Recommended Setup Flow

```bash
# 1. Clone repo
git clone <your-repo> ~/system-setup
cd ~/system-setup

# 2. Customize configs (optional)
nano configs/gnome-settings.conf
nano configs/keybindings.conf

# 3. Install everything
./install.sh all

# 4. Log out/in

# 5. Apply your customized appearance
apply-appearance

# 6. Set up Nix dotfiles
# See POST-INSTALL-NIX.md
```

---

**Made with ❤️ for clean, reproducible system setups**

