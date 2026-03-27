# Skill Selection Guide

When multiple skills can handle the same task, follow this priority order.

## Naming Convention

- **gstack skills**: Use short names like `/review`, `/office-hours`, `/qa`
- **superpowers skills**: Use full names like `/brainstorming`, `/test-driven-development`
- **builtin skills**: Use names like `systematic-debugging`, `planning-with-files`

## Flow Charts

### Debugging Flow

1. **Default**: `systematic-debugging` (P0 mandatory, builtin) — find root cause first
2. **Need scope lock**: Consider `/investigate` (gstack) — auto-freezes scope
3. **Advanced workflow**: Consider `/systematic-debugging` (superpowers) — enhanced version

### Code Review Flow

1. **Pre-landing review**: Prefer `/review` (gstack) — SQL safety, LLM boundaries, auto-fixes
2. **Comprehensive check**: Consider `/receiving-code-review` or `/requesting-code-review` (superpowers)
3. **Cross-model review**: Consider `/codex` (gstack) — second opinion via Codex CLI

### Planning Flow

1. **General complex planning**: `planning-with-files` (builtin)
2. **CEO/product angle**: `/plan-ceo-review` (gstack)
3. **Architecture angle**: `/plan-eng-review` (gstack)
4. **Design/UX angle**: `/plan-design-review` (gstack)
5. **Full auto review**: `/autoplan` (gstack) — CEO → design → eng

### Product Thinking Flow

1. **Early ideation**: Prefer `/office-hours` (gstack) — YC-style reframing
2. **Design refinement**: Consider `/brainstorming` (superpowers)

### TDD Flow

1. **Unit testing**: `/test-driven-development` (superpowers) — red-green-refactor
2. **E2E browser testing**: `/qa` (gstack) — real Chromium testing

### Refactoring Flow

1. **Systematic refactoring**: `/refactor` (superpowers) — with safety checks
2. **Post-refactor review**: `/review` (gstack)

### Architecture Flow

1. **System design**: `/writing-plans` (superpowers) — create design docs
2. **Architecture review**: `/plan-eng-review` (gstack)

## Exclusive Skills (No Conflicts)

| Skill | Purpose |
|-------|---------|
| `/qa` | Browser QA in real Chromium |
| `/ship` | Release workflow — sync, test, push, open PR |
| `/guard` | Max safety (careful + freeze) |
| `/retro` | Weekly team retrospective |
| `/design-consultation` | Build design system from scratch |
| `/design-review` | Visual design audit |
| `/subagent-driven-development` | Parallel task execution |
| `/using-git-worktrees` | Branch isolation |
| `/writing-skills` | Craft personal skills |

## Override Keywords

- Say "用 gstack" to use gstack version
- Say "用 superpowers" to use superpowers version
- Say "用 builtin" to use builtin version
