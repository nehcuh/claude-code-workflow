#!/bin/bash
# Harness Engineering Verification Script
# Checks mechanical constraints and documentation freshness

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ERRORS=0

echo "🔍 Running Harness Engineering checks..."
echo ""

# Check 1: CLAUDE.md line count (< 150 lines)
CLAUDE_LINES=$(wc -l < "$PROJECT_ROOT/CLAUDE.md")
if [ "$CLAUDE_LINES" -gt 150 ]; then
    echo "❌ CLAUDE.md exceeds 150 lines (currently $CLAUDE_LINES)"
    echo "   → Move detailed content to docs/claude/"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ CLAUDE.md line count: $CLAUDE_LINES"
fi

# Check 2: docs/claude/ structure exists
if [ ! -d "$PROJECT_ROOT/docs/claude" ]; then
    echo "❌ docs/claude/ directory missing"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ docs/claude/ structure exists"
fi

# Check 3: golden-principles.yaml exists (optional but recommended)
if [ ! -f "$PROJECT_ROOT/golden-principles.yaml" ]; then
    echo "⚠️  golden-principles.yaml not found (optional)"
else
    echo "✅ golden-principles.yaml exists"
fi

# Check 4: docs/technical-debt/ exists
if [ ! -d "$PROJECT_ROOT/docs/technical-debt" ]; then
    echo "⚠️  docs/technical-debt/ not found"
else
    echo "✅ docs/technical-debt/ exists"
fi

# Check 5: Dead link detection in CLAUDE.md
echo ""
echo "🔗 Checking internal links in CLAUDE.md..."
if [ -f "$PROJECT_ROOT/CLAUDE.md" ]; then
    # Extract markdown links, skip http/https and skip code blocks
    grep -oE '\[([^]]+)\]\(([^)]+)\)' "$PROJECT_ROOT/CLAUDE.md" | grep -v 'http' | while read -r match; do
        # Extract path from [text](path)
        link=$(echo "$match" | sed -E 's/.*\]\(([^)]+)\)/\1/')
        # Skip if empty or starts with http
        if [ -z "$link" ] || [[ "$link" =~ ^https?:// ]]; then
            continue
        fi
        # Check if file/directory exists
        if [ ! -f "$PROJECT_ROOT/$link" ] && [ ! -d "$PROJECT_ROOT/$link" ]; then
            # Try with .md extension
            if [ ! -f "$PROJECT_ROOT/$link.md" ]; then
                echo "❌ Dead link: $link"
                # Note: ERRORS increment doesn't work in subshell, using file-based approach
                touch "$PROJECT_ROOT/.harness_dead_link_found"
            fi
        fi
    done
fi

if [ -f "$PROJECT_ROOT/.harness_dead_link_found" ]; then
    rm "$PROJECT_ROOT/.harness_dead_link_found"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ All internal links valid"
fi

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ All Harness checks passed"
    exit 0
else
    echo "❌ $ERRORS check(s) failed"
    exit 1
fi
