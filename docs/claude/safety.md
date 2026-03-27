# Safety Policy

## Security Severity Levels

| Level | Action |
|-------|--------|
| **P0** | Prefer hooks or permissions deny; otherwise stop with explicit block |
| **P1** | Prefer hook-mediated confirmation or manual approval |
| **P2** | Warn in output and continue with traceable reasoning |

## Critical Rules

### ssot-first (Mandatory)
Keep repository files as the single source of truth; tool-managed memory is cache.

### verify-before-claim (Mandatory)
Never claim completion without fresh verification evidence.

### root-cause-debugging (Mandatory)
Investigate root cause before attempting fixes and reassess after repeated failures.

### security-escalation (Mandatory)
Treat as security-sensitive:
- Destructive commands (rm -rf, drop tables)
- Network egress
- Secret access
- Obfuscation attempts

## Safe Defaults

- Prefer small, reversible, single-purpose changes
- Never skip hooks (--no-verify) unless explicitly requested
- Always create new commits rather than amending published ones
- Stage files by name, not with `git add -A`

## Risky Actions Requiring Confirmation

- Deleting files/branches
- Dropping database tables
- Force-pushing
- Modifying CI/CD pipelines
- Sending messages to external services

## Golden Principles

1. **prefer_shared_skills** — Use shared skills over inline logic
2. **mechanical_enforcement_first** — Prefer automated constraints over manual review
3. **progressive_disclosure** — Context revealed progressively, not dumped
4. **depth_over_breadth** — Complete one story fully before starting another
