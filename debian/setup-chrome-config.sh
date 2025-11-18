#!/bin/bash
# Apply Chrome/Chromium configuration from config file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/configs"
CHROME_CONFIG="$CONFIG_DIR/chrome-preferences.json"

echo "🌐 Setting up Chrome configuration..."

# Check if Chrome is installed
if ! command -v google-chrome &> /dev/null; then
    echo "⚠️  Chrome not found. Install it first:"
    echo "   ./debian/install-chrome.sh"
    exit 1
fi

# Chrome profile directory
CHROME_DIR="$HOME/.config/google-chrome"
CHROME_PROFILE="$CHROME_DIR/Default"

# Create profile directory if it doesn't exist
mkdir -p "$CHROME_PROFILE"

# Copy config to user directory for reference
USER_CHROME_CONFIG="$HOME/.config/chrome-preferences.json"
if [ -f "$CHROME_CONFIG" ]; then
    cp "$CHROME_CONFIG" "$USER_CHROME_CONFIG"
    echo "✅ Copied Chrome config to: $USER_CHROME_CONFIG"
else
    echo "❌ Config file not found: $CHROME_CONFIG"
    exit 1
fi

# Important Note about Chrome Preferences
cat << 'EOF'

📝 Chrome Configuration Notes:
═══════════════════════════════

Chrome's Preferences file is managed by Chrome itself and uses integrity checks.
We CANNOT directly edit the Preferences file while Chrome is running.

Instead, we've provided a reference configuration at:
  ~/.config/chrome-preferences.json

To apply settings:

  METHOD 1: Chrome Policies (Recommended for system-wide)
  ────────────────────────────────────────────────────────
  1. Create: /etc/opt/chrome/policies/managed/custom.json
  2. Add your policies there
  3. Restart Chrome

  METHOD 2: Manual Configuration (One-time setup)
  ────────────────────────────────────────────────
  1. Close Chrome completely
  2. Use chrome://settings/ to configure manually
  3. Or run Chrome with specific flags

  METHOD 3: Command-line Flags (Session-specific)
  ────────────────────────────────────────────────
  Create ~/.config/chrome-flags.conf with:
    --disable-background-networking
    --disable-sync
    --enable-features=WebUIDarkMode
  
  Then launch with: google-chrome $(cat ~/.config/chrome-flags.conf)

Recommended: Use chrome://settings/ for initial setup, then manage
extensions and settings through your Google account sync.

For window managers: Chrome works great! Use --new-window flag
to control window behavior.

EOF

# Create a launcher script with flags
CHROME_LAUNCHER="$HOME/.local/bin/chrome-custom"
mkdir -p "$HOME/.local/bin"

cat > "$CHROME_LAUNCHER" << 'EOF'
#!/bin/bash
# Chrome launcher with custom flags

FLAGS=(
    --enable-features=WebUIDarkMode
    --force-dark-mode
    # Add more flags as needed
)

google-chrome "${FLAGS[@]}" "$@"
EOF

chmod +x "$CHROME_LAUNCHER"

echo ""
echo "✅ Chrome configuration setup complete!"
echo ""
echo "📍 Files created:"
echo "   Config reference: $USER_CHROME_CONFIG"
echo "   Custom launcher: $CHROME_LAUNCHER"
echo ""
echo "💡 Next steps:"
echo "   1. Configure Chrome manually via chrome://settings/"
echo "   2. Or use: chrome-custom (launcher with dark mode)"
echo "   3. Edit flags in: $CHROME_LAUNCHER"
echo ""

