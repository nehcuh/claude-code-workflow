# Claude Code Project Config

> Harness Engineering: Progressive Disclosure Mode

## ⚠️ CRITICAL AGENT INSTRUCTION

**Do NOT guess or hallucinate rules.** When you need information from any category below, you **MUST** use the `read` tool to fetch the file contents before proceeding.

## Quick Navigation

| Need | Go To |
|------|-------|
| Skill selection | `read docs/claude/skills/routing.md` |
| Safety rules | `read docs/claude/safety.md` |
| Architecture | `read docs/claude/architecture/index.md` |
| Behavior policies | `read .vibe/claude-code/behavior-policies.md` |

## Policy Hierarchy (Override Order)

When rules conflict, follow this priority:

1. **`docs/claude/`** — PROJECT-SPECIFIC overrides (Highest Priority)
2. **`.vibe/claude-code/`** — GLOBAL baseline policies (Fallback)

**Action**: Always check `docs/claude/` first. Only fall back to `.vibe/claude-code/` if not found.

## Critical Rules (P0)

1. **ssot-first** — Repository files are truth; tool-managed memory is cache
2. **verify-before-claim** — Fresh verification evidence before claiming completion
3. **root-cause-debugging** — Investigate root cause before fixes
4. **security-escalation** — Destructive commands require explicit confirmation

## Skill Priority (When Conflict)

```
gstack (short) > superpowers (full) > builtin
```

Examples: `/review` → `/receiving-code-review` → `verification-before-completion`

## Quick Keywords

| Say | To Use |
|-----|--------|
| "用 gstack" | gstack version |
| "用 superpowers" | superpowers version |
| "用 builtin" | builtin version |

## Reference

See `.vibe/claude-code/` for full policy docs.
