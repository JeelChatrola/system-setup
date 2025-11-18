#!/bin/bash
# Apply Zen Browser configuration from config file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/configs"
ZEN_USER_JS="$CONFIG_DIR/zen-user.js"

echo "🌐 Setting up Zen Browser configuration..."

# Check if Zen is installed
if ! command -v zen-browser &> /dev/null && [ ! -f "$HOME/.local/bin/zen-browser" ]; then
    echo "⚠️  Zen Browser not found. Install it first:"
    echo "   ./debian/install-zen.sh"
    exit 1
fi

# Find Zen profile directory
ZEN_PROFILES_DIR="$HOME/.zen-browser"

# Copy config to user directory for easy editing
USER_ZEN_CONFIG="$HOME/.config/zen-user.js"
if [ -f "$ZEN_USER_JS" ]; then
    cp "$ZEN_USER_JS" "$USER_ZEN_CONFIG"
    echo "✅ Copied Zen config to: $USER_ZEN_CONFIG"
else
    echo "❌ Config file not found: $ZEN_USER_JS"
    exit 1
fi

# Check if profile directory exists
if [ ! -d "$ZEN_PROFILES_DIR" ]; then
    echo ""
    echo "📝 Zen profile directory not found yet."
    echo "   Start Zen Browser once to create profile:"
    echo "   zen-browser"
    echo ""
    echo "   Then run this script again to apply config."
    exit 0
fi

# Find the default profile
PROFILE_DIR=$(find "$ZEN_PROFILES_DIR" -maxdepth 1 -name "*.default*" -type d | head -n 1)

if [ -z "$PROFILE_DIR" ]; then
    echo ""
    echo "📝 No Zen profile found yet."
    echo "   Start Zen Browser once to create profile:"
    echo "   zen-browser"
    echo ""
    echo "   Then run this script again to apply config."
    exit 0
fi

echo "📍 Found Zen profile: $PROFILE_DIR"

# Copy user.js to profile
cp "$USER_ZEN_CONFIG" "$PROFILE_DIR/user.js"
echo "✅ Applied configuration to: $PROFILE_DIR/user.js"

# Create userChrome.css for UI customization (optional)
CHROME_DIR="$PROFILE_DIR/chrome"
mkdir -p "$CHROME_DIR"

if [ ! -f "$CHROME_DIR/userChrome.css" ]; then
    cat > "$CHROME_DIR/userChrome.css" << 'EOF'
/* Zen Browser Custom CSS */
/* Customize the browser UI appearance */

/* Example: Hide tab bar if using vertical tabs */
/*
#TabsToolbar {
  visibility: collapse !important;
}
*/

/* Example: Compact toolbar */
/*
#nav-bar {
  padding-top: 0px !important;
  padding-bottom: 0px !important;
}
*/

/* Add your customizations below */

EOF
    echo "✅ Created userChrome.css template: $CHROME_DIR/userChrome.css"
fi

# Enable userChrome.css in prefs.js
PREFS_JS="$PROFILE_DIR/prefs.js"
if [ -f "$PREFS_JS" ]; then
    if ! grep -q "toolkit.legacyUserProfileCustomizations.stylesheets" "$PREFS_JS"; then
        echo 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >> "$PREFS_JS"
        echo "✅ Enabled userChrome.css support"
    fi
fi

echo ""
echo "✅ Zen Browser configuration complete!"
echo ""
echo "📍 Configuration files:"
echo "   user.js: $PROFILE_DIR/user.js"
echo "   userChrome.css: $CHROME_DIR/userChrome.css"
echo "   Edit template: $USER_ZEN_CONFIG"
echo ""
echo "💡 To customize:"
echo "   1. Edit: nano $USER_ZEN_CONFIG"
echo "   2. Reapply: ./debian/setup-zen-config.sh"
echo "   3. Restart Zen Browser"
echo ""
echo "💡 For UI customization:"
echo "   Edit: $CHROME_DIR/userChrome.css"
echo ""
echo "🔧 Window Manager Tips:"
echo "   - Zen works great with tiling WMs"
echo "   - Compact mode enabled for better space usage"
echo "   - Disable window decorations in user.js if needed"
echo ""

