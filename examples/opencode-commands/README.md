# OpenCode Custom Commands

This directory contains example custom commands for OpenCode users.

## Installation

Copy these files to your OpenCode commands directory:

```bash
# For global commands
cp examples/opencode-commands/*.md ~/.config/opencode/commands/

# For project-specific commands
cp examples/opencode-commands/*.md .opencode/commands/
```

## Available Commands

### `/save-exit` - Save Session Before Exit

Executes the session-end workflow and prepares for safe exit.

**Usage:**
```
/save-exit
```

**What it does:**
1. Reviews current session work
2. Executes session-end skill
3. Updates memory files
4. Commits changes (if applicable)
5. Provides confirmation

**When to use:**
- Before closing OpenCode
- At the end of a work session
- When switching to a different project

## Creating Your Own Commands

OpenCode commands are markdown files with frontmatter:

```markdown
---
description: Your command description
agent: optional-agent-name
model: optional-model-override
---

Your command template here.

You can use:
- $ARGUMENTS - All arguments
- $1, $2, etc. - Individual arguments
- !command! - Shell command output
- @filename - File reference
```

See [OpenCode Commands Documentation](https://opencode.ai/docs/zh-cn/commands) for more details.

## Related Documentation

- [Session Management for OpenCode](../../docs/session-management-opencode.md)
- [Session End Skill](../../skills/session-end/SKILL.md)
- [Memory Management](../../rules/memory-flush.md)
