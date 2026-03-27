#!/bin/bash
# Install Git Hooks for Harness Engineering
# Binds verify-harness.sh to pre-commit to enforce constraints locally

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"

echo "🔧 Installing Harness Engineering Git hooks..."

# Ensure .git/hooks directory exists
if [ ! -d "$HOOKS_DIR" ]; then
    echo "❌ .git/hooks directory not found. Are you in a git repository?"
    exit 1
fi

# Create pre-commit hook
cat > "$PRE_COMMIT_HOOK" << 'EOF'
#!/bin/bash
# Pre-commit hook for Harness Engineering
# Automatically runs verification before allowing commits

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

echo "🔍 Running Harness pre-commit checks..."

# Run harness verification
if [ -f "$PROJECT_ROOT/scripts/verify-harness.sh" ]; then
    "$PROJECT_ROOT/scripts/verify-harness.sh"
else
    echo "❌ verify-harness.sh not found. Skipping harness checks."
    exit 0
fi

echo "✅ Pre-commit checks passed. Proceeding with commit."
EOF

# Make hook executable
chmod +x "$PRE_COMMIT_HOOK"

echo "✅ Pre-commit hook installed successfully."
echo ""
echo "Hook will now:"
echo "  • Check CLAUDE.md line count (< 150 lines)"
echo "  • Verify docs/claude/ structure exists"
echo "  • Check for dead internal links"
echo "  • Block commit if any check fails"
echo ""
echo "To bypass (not recommended): git commit --no-verify"
