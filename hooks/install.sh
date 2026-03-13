#!/bin/bash
# Install pre-session-end hook globally

set -e

HOOK_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/pre-session-end.sh"
HOOK_DEST="$HOME/.claude/hooks/pre-session-end.sh"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo "Installing pre-session-end hook..."
echo ""

# Create hooks directory if it doesn't exist
mkdir -p "$HOME/.claude/hooks"

# Copy hook script
echo "→ Copying hook to $HOOK_DEST"
cp "$HOOK_SOURCE" "$HOOK_DEST"
chmod +x "$HOOK_DEST"

# Check if settings.json exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "→ Creating $SETTINGS_FILE"
    echo '{}' > "$SETTINGS_FILE"
fi

# Check if hook is already configured
if grep -q "PreSessionEnd" "$SETTINGS_FILE"; then
    echo ""
    echo "⚠️  PreSessionEnd hook already configured in settings.json"
    echo "   Please manually verify the configuration."
else
    echo "→ Configuring hook in settings.json"

    # Use jq if available, otherwise manual edit
    if command -v jq &> /dev/null; then
        # Backup settings
        cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup"

        # Add hook configuration
        jq '.hooks.PreSessionEnd = [{"type": "command", "command": "~/.claude/hooks/pre-session-end.sh"}]' \
            "$SETTINGS_FILE.backup" > "$SETTINGS_FILE"

        echo "   ✓ Hook configured successfully"
        echo "   (Backup saved to $SETTINGS_FILE.backup)"
    else
        echo ""
        echo "⚠️  jq not found. Please manually add to $SETTINGS_FILE:"
        echo ""
        echo '  "hooks": {'
        echo '    "PreSessionEnd": ['
        echo '      {'
        echo '        "type": "command",'
        echo '        "command": "~/.claude/hooks/pre-session-end.sh"'
        echo '      }'
        echo '    ]'
        echo '  }'
        echo ""
    fi
fi

echo ""
echo "✓ Installation complete!"
echo ""
echo "The hook will now prompt you to save progress before exiting Claude Code."
echo ""
echo "To test: Run 'claude' and then type '/exit'"
