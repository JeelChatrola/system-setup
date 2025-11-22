# System Setup Bootstrapper

A lightweight, reliable bootstrapper for Debian/Ubuntu systems.
It installs the "core" environment (i3, Docker, Nix) so you can pull your dotfiles and get to work.

## 🚀 Quick Start (Fresh Install)

**1. Clone the repo:**

**2. Run the installer:**
```bash
./install.sh
```

**3. Choose an option:**
*   **Option 10 (Install Everything):** Sets up Nix, Docker, Alacritty, i3, Rofi, and Appearance.
*   **Option 6 (i3 Window Manager):** Installs i3 + Polybar + Wallpaper + Rofi.

---

## 🛠 What's Included?

### Core System
*   **Nix Package Manager:** (Determinate Systems) For your CLI tools & dev env.
*   **Docker:** Official Docker Engine + Compose.
*   **NVIDIA Toolkit:** GPU support for Docker containers.

### Desktop Environment (The "Clean" Setup)
*   **Window Manager:** i3 (Tiling WM)
*   **Terminal:** Alacritty (GPU accelerated)
*   **Launcher:** Rofi (Modern App Launcher)
*   **Bar:** Polybar (Beautiful status bar)
*   **Wallpaper:** Nitrogen (Wallpaper manager)
*   **Appearance:** Gruvbox Dark Theme + Nerd Fonts (JetBrainsMono)

---

## ⌨️ Cheat Sheet (i3)

Once installed, here is how you survive:

| Action | Shortcut |
| :--- | :--- |
| **Open Terminal** | `Win + Enter` |
| **Open Apps** | `Win + d` (Type app name) |
| **Close Window** | `Win + Shift + q` |
| **Help Popup** | `Win + Shift + ?` |
| **Restart i3** | `Win + Shift + r` (Use after config changes) |
| **Exit/Logout** | `Win + Shift + e` |

---

## 📂 Configuration

Don't edit files in `/etc` or `~/.config` directly if you want to save them.
Edit them in **`configs/`** and re-run the installer (or copy them manually).

*   **i3:** `configs/i3-config`
*   **Polybar:** `configs/polybar-config.ini`
*   **Launcher:** `configs/polybar-launch.sh`

---

## 🔄 Workflow for New Machines

1.  **Install OS:** Ubuntu Server or Desktop (Minimal).
2.  **Run this repo:** `./install.sh` -> Install Everything.
3.  **Reboot/Login:** Select `i3` session at login (if graphical) or just log in.
4.  **Next Steps:**
    *   Clone your **Nix Home Manager** repo to install your CLI tools (`git`, `zsh`, `neovim`, etc).
    *   Install GUI apps manually or via Flatpak (Chrome, Zen, Cursor).

## ❌ What is NOT included?
*   **Browsers:** Install Chrome/Zen manually (they update too often).
*   **Editors:** Install VSCode/Cursor manually.
*   **User Dotfiles:** Manage your `.zshrc`, `.gitconfig` via Home Manager.
