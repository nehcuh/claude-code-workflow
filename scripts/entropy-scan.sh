#!/bin/bash
# Entropy Scan - Detect patterns of chaos and documentation drift
# Part of Harness Engineering entropy management

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

WARNINGS=0
DAYS_THRESHOLD=90

echo "🧹 Running Entropy Scan..."
echo ""

# Check 1: Documentation drift - files modified recently but docs not updated
echo "📚 Checking documentation freshness..."
# Find markdown files modified in last 7 days
RECENT_MD=$(find "$PROJECT_ROOT" -name "*.md" -mtime -7 -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | head -20)
if [ -n "$RECENT_MD" ]; then
    echo "   Recently modified docs (last 7 days):"
    echo "$RECENT_MD" | while read -r file; do
        echo "     - $(basename "$file")"
    done
fi

# Check 2: Technical debt TTL - find stale entries
echo ""
echo "⏰ Checking technical debt TTL (threshold: ${DAYS_THRESHOLD} days)..."
DEBT_FILE="$PROJECT_ROOT/docs/technical-debt/index.md"
if [ -f "$DEBT_FILE" ]; then
    # Extract dates in format [YYYY-MM-DD] from active issues
    CURRENT_DATE=$(date +%s)
    while IFS= read -r line; do
        if [[ "$line" =~ \[([0-9]{4}-[0-9]{2}-[0-9]{2})\] ]]; then
            DATE_STR="${BASH_REMATCH[1]}"
            ENTRY_DATE=$(date -j -f "%Y-%m-%d" "$DATE_STR" +%s 2>/dev/null || date -d "$DATE_STR" +%s 2>/dev/null)
            if [ -n "$ENTRY_DATE" ]; then
                DAYS_OLD=$(( (CURRENT_DATE - ENTRY_DATE) / 86400 ))
                if [ $DAYS_OLD -gt $DAYS_THRESHOLD ]; then
                    echo "   ⚠️  Stale entry ($DAYS_OLD days old): $line"
                    WARNINGS=$((WARNINGS + 1))
                fi
            fi
        fi
    done < "$DEBT_FILE"
fi

# Check 3: Check for duplicate patterns (basic - file naming conventions)
echo ""
echo "🔍 Checking for pattern inconsistencies..."
# Check if both .yaml and .yml exist
YAML_COUNT=$(find "$PROJECT_ROOT" -maxdepth 1 -name "*.yaml" | wc -l)
YML_COUNT=$(find "$PROJECT_ROOT" -maxdepth 1 -name "*.yml" | wc -l)
if [ "$YAML_COUNT" -gt 0 ] && [ "$YML_COUNT" -gt 0 ]; then
    echo "   ⚠️  Mixed .yaml and .yml extensions detected"
    WARNINGS=$((WARNINGS + 1))
fi

# Check 4: Golden principles sync
echo ""
echo "🎯 Checking golden principles alignment..."
if [ -f "$PROJECT_ROOT/golden-principles.yaml" ] && [ -f "$PROJECT_ROOT/docs/claude/safety.md" ]; then
    # Check if principles are mentioned in safety.md
    if ! grep -q "Golden Principles" "$PROJECT_ROOT/docs/claude/safety.md"; then
        echo "   ⚠️  golden-principles.yaml exists but not referenced in safety.md"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

echo ""
if [ $WARNINGS -eq 0 ]; then
    echo "✅ Entropy scan complete. No warnings."
    exit 0
else
    echo "⚠️  Entropy scan complete. $WARNINGS warning(s) found."
    exit 0  # Warnings don't fail the build
fi
