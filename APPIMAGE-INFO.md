# 📦 About AppImage

## What is AppImage?

**AppImage** is a format for distributing portable software on Linux. Think of it like a `.exe` on Windows or `.dmg` on macOS - it's a single file that contains everything the app needs to run.

## Why Use AppImage?

✅ **Portable** - One file, works everywhere  
✅ **No installation needed** - Just download and run  
✅ **Sandboxed** - Doesn't affect your system  
✅ **Always latest** - Developers often provide AppImages for latest versions

## When to Use AppImage

Good for:
- 🎨 **Apps not in apt repos** (e.g., Obsidian, MuseScore, Kdenlive)
- 🚀 **Latest versions** of software (newer than apt provides)
- 💼 **Portable apps** you want to run from USB or move between machines
- 🧪 **Testing software** without installing system-wide

## Do You Need It?

**If you're not sure, skip it for now!**

You can always install it later with:
```bash
./debian/setup-appimage.sh
```

## What Our Script Does

The `setup-appimage.sh` script:
1. Installs FUSE (required to run AppImages)
2. Installs AppImageLauncher (manages AppImages nicely)
3. Provides `appimage-manager` CLI tool for easy management

## Common AppImage Apps

Popular apps available as AppImage:
- **Obsidian** - Note-taking
- **Cursor** - We use this! (already installed via our script)
- **Kdenlive** - Video editing
- **MuseScore** - Music notation
- **Krita** - Digital painting
- **Balena Etcher** - USB/SD card writer

## Example Usage

```bash
# After running setup-appimage.sh

# Install an AppImage
appimage-manager install https://example.com/app.AppImage myapp

# List installed AppImages
appimage-manager list

# Run it
myapp

# Remove it
appimage-manager remove myapp
```

## Alternative: Use Nix Instead

**For most software, we recommend using Nix instead:**

```bash
# Install via Nix (cleaner, reproducible)
nix-env -iA nixpkgs.obsidian

# Or via home-manager (better for dotfiles)
# Add to home.nix: home.packages = [ pkgs.obsidian ];
```

## Summary

- **AppImage** = Portable apps in a single file
- **Good for**: Apps not in repos, testing, portable usage
- **Skip if**: You're happy with apt + Nix (recommended)
- **Install later**: `./debian/setup-appimage.sh`

---

**Bottom line**: AppImage is useful but not essential. Most apps are better managed through Nix or apt.

