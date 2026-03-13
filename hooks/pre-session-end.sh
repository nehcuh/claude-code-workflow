#!/bin/bash
# Pre-Session-End Hook
# Prompts user to save session progress before exiting Claude Code

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}  Session End Detected${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Not in a git repository. Skipping session save.${NC}"
    exit 0
fi

# Check if memory/ directory exists
if [ ! -d "memory" ]; then
    echo -e "${YELLOW}No memory/ directory found. Creating...${NC}"
    mkdir -p memory
fi

# Check if there are uncommitted changes
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${YELLOW}⚠️  You have uncommitted changes.${NC}"
    echo ""
fi

# Prompt user
echo -e "${GREEN}Would you like to save your session progress?${NC}"
echo ""
echo "This will:"
echo "  • Update memory/session.md with current progress"
echo "  • Record any lessons learned in memory/project-knowledge.md"
echo "  • Update PROJECT_CONTEXT.md (if exists)"
echo ""
echo -e "${YELLOW}Options:${NC}"
echo "  [y] Yes, save session progress (recommended)"
echo "  [n] No, exit without saving"
echo "  [c] Cancel exit, continue working"
echo ""
read -p "Your choice [y/n/c]: " -n 1 -r
echo ""

case $REPLY in
    [Yy])
        echo ""
        echo -e "${GREEN}✓ Triggering session-end...${NC}"
        echo ""
        # Return special exit code to trigger session-end
        exit 42
        ;;
    [Nn])
        echo ""
        echo -e "${YELLOW}⚠️  Exiting without saving. Progress may be lost.${NC}"
        echo ""
        exit 0
        ;;
    [Cc])
        echo ""
        echo -e "${GREEN}✓ Cancelled exit. Continue working.${NC}"
        echo ""
        exit 1
        ;;
    *)
        echo ""
        echo -e "${RED}Invalid choice. Cancelling exit.${NC}"
        echo ""
        exit 1
        ;;
esac
