# 🌐 Browser Configuration Guide

## Overview

Both Chrome and Zen Browser can be configured via files for consistent, reproducible setups!

## 📦 Configuration Files

### Zen Browser (Firefox-based)
```
configs/zen-user.js           # Main config file
~/.config/zen-user.js         # Copied here after setup
~/.zen-browser/<profile>/user.js        # Applied config
~/.zen-browser/<profile>/chrome/userChrome.css  # UI customization
```

### Chrome
```
configs/chrome-preferences.json    # Reference config
~/.config/chrome-preferences.json  # Copied here
~/.local/bin/chrome-custom         # Launcher with flags
```

## 🚀 Quick Setup

### Zen Browser

```bash
# 1. Install Zen
./install.sh zen

# 2. Start Zen once (creates profile)
zen-browser

# 3. Apply configuration
./debian/setup-zen-config.sh

# 4. Restart Zen
```

### Chrome

```bash
# 1. Install Chrome
./install.sh chrome

# 2. Apply config (creates launcher and reference)
./debian/setup-chrome-config.sh

# 3. Use custom launcher or configure manually
chrome-custom  # Or use chrome://settings/
```

## 🎨 What's Configured

### Zen Browser (`zen-user.js`)

**Privacy & Security:**
- ✅ Telemetry disabled
- ✅ Enhanced tracking protection (strict)
- ✅ HTTPS-only mode
- ✅ Pocket disabled

**Performance:**
- ✅ Hardware acceleration enabled
- ✅ VA-API video decoding
- ✅ Memory optimization

**UI & Behavior:**
- ✅ Compact mode (great for tiling WMs!)
- ✅ Smooth scrolling
- ✅ Vertical tabs enabled
- ✅ Split view support
- ✅ No fullscreen warnings

**Window Manager Friendly:**
- ✅ Reduced animations
- ✅ Compact UI density
- ✅ System decorations option
- ✅ Middle-click paste (Linux)

### Chrome (`chrome-custom` launcher)

- ✅ Dark mode forced
- ✅ WebUI dark theme
- ✅ Custom flags support

**Note:** Chrome's main preferences must be set via `chrome://settings/` due to integrity checks.

## 🪟 Window Manager Compatibility

### ✅ Both browsers work GREAT with window managers!

#### Tested with:
- **i3 / Sway** - Excellent
- **bspwm** - Excellent  
- **Awesome** - Excellent
- **dwm / st** - Works well
- **Xmonad** - Works well
- **Hyprland** - Excellent

### Why they work well:

1. **Standard Protocols** - Both follow X11/Wayland standards
2. **No Special Requirements** - Work like any other window
3. **Configurable** - Can disable animations, decorations
4. **Keyboard-friendly** - Extensive keyboard shortcuts

### Window Manager Specific Tips

#### For Tiling WMs (i3, bspwm, etc.):

**Zen Browser:**
```javascript
// In zen-user.js

// Disable window animations
user_pref("toolkit.cosmeticAnimations.enabled", false);

// Use system decorations (better for WM control)
user_pref("browser.tabs.drawInTitlebar", false);

// Compact mode
user_pref("browser.uidensity", 1);
```

**Chrome:**
```bash
# In chrome-custom launcher
google-chrome \
  --new-window \
  --disable-features=TabHoverCardImages \
  --disable-smooth-scrolling
```

#### i3/Sway Config Example:

```
# ~/.config/i3/config or ~/.config/sway/config

# Float dialog windows
for_window [window_role="pop-up"] floating enable
for_window [window_role="task_dialog"] floating enable

# Browsers in specific workspaces
assign [class="Google-chrome"] $ws2
assign [class="Zen-browser"] $ws2

# Keybindings
bindsym $mod+b exec zen-browser
bindsym $mod+Shift+b exec google-chrome
```

#### bspwm Config Example:

```bash
# ~/.config/bspwm/bspwmrc

# Browser rules
bspc rule -a Google-chrome desktop='^2'
bspc rule -a Zen-browser desktop='^2'

# Float dialogs
bspc rule -a '*:*:*' state=floating role=pop-up
```

## 🎯 Customization

### Zen Browser

Edit your config:
```bash
nano ~/.config/zen-user.js
```

Common customizations:
```javascript
// Disable smooth scrolling
user_pref("general.smoothScroll", false);

// Change UI density (0=normal, 1=compact, 2=touch)
user_pref("browser.uidensity", 0);

// Disable WebRTC (for privacy)
user_pref("media.peerconnection.enabled", false);

// Auto-play videos
user_pref("media.autoplay.default", 5); // 0=allow, 5=block

// Disable animations completely
user_pref("ui.prefersReducedMotion", 1);
```

Reapply:
```bash
./debian/setup-zen-config.sh
# Restart Zen Browser
```

### Chrome

Edit launcher flags:
```bash
nano ~/.local/bin/chrome-custom
```

Useful flags:
```bash
FLAGS=(
    --new-window                    # Force new window
    --force-dark-mode              # Dark mode everything
    --disable-features=Translate   # Disable translate popup
    --disable-background-networking # Less network activity
    --disk-cache-size=52428800     # Limit cache to 50MB
)
```

## 🔧 Advanced: UI Customization

### Zen Browser CSS Customization

Edit userChrome.css:
```bash
nano ~/.zen-browser/<profile>/chrome/userChrome.css
```

Examples:
```css
/* Hide tab bar (if using tree-style tabs) */
#TabsToolbar {
  visibility: collapse !important;
}

/* Compact navigation bar */
#nav-bar {
  padding: 2px !important;
}

/* Minimal URL bar */
#urlbar {
  font-size: 12px !important;
}

/* Hide bookmarks toolbar */
#PersonalToolbar {
  visibility: collapse !important;
}
```

## 📝 Best Practices

### For Version Control (Dotfiles)

```bash
# In your dotfiles repo
dotfiles/
├── browsers/
│   ├── zen-user.js
│   ├── chrome-flags.conf
│   └── userChrome.css
└── install.sh

# Symlink to system-setup configs
ln -s ~/dotfiles/browsers/zen-user.js ~/system-setup/configs/zen-user.js
```

### For Multiple Machines

1. Keep configs in your system-setup repo
2. Customize per-machine with environment variables:

```javascript
// In zen-user.js
// Use different settings based on hostname
// (This requires manual editing per machine)
```

Or use different config branches:
```bash
git checkout desktop-config  # For desktop
git checkout laptop-config   # For laptop
```

## 🐛 Troubleshooting

### Zen config not applying?

```bash
# Check profile location
ls ~/.zen-browser/

# Start Zen once to create profile
zen-browser

# Reapply config
./debian/setup-zen-config.sh

# Verify user.js exists
ls ~/.zen-browser/*.default*/user.js
```

### Chrome not respecting settings?

Chrome uses integrity checks. Use one of:
1. Manual configuration via `chrome://settings/`
2. Chrome policies (system-wide)
3. Command-line flags (per-session)

### Window manager issues?

```bash
# Check window class
xprop | grep WM_CLASS

# For i3/sway, check window roles
swaymsg -t get_tree | grep -A 10 "Zen"
```

## 📚 Resources

- [Zen Browser Docs](https://docs.zen-browser.app/)
- [Firefox user.js Reference](https://kb.mozillazine.org/User.js_file)
- [Chrome Command Line Switches](https://peter.sh/experiments/chromium-command-line-switches/)
- [userChrome.css Guide](https://www.userchrome.org/)

## 🎯 Summary

**Zen Browser:**
- ✅ Full configuration via user.js
- ✅ UI customization via userChrome.css
- ✅ Excellent window manager support
- ✅ Privacy-focused defaults

**Chrome:**
- ⚠️  Limited file-based config (uses chrome://settings/)
- ✅ Command-line flags work great
- ✅ Excellent window manager support
- ✅ Google sync for cross-machine settings

**Both browsers work perfectly with tiling window managers!** 🚀

