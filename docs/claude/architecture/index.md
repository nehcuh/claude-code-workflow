# Project Architecture

## Directory Structure

```
├── core/                    # Portable SSOT
│   ├── policies/           # Behavior and routing policies
│   ├── skills/             # Skill registry
│   └── security/           # Security policy
│
├── .vibe/                  # Runtime configs
│   └── claude-code/        # Target-specific overlays
│
├── docs/                   # Documentation
│   └── claude/             # Claude Code progressive disclosure
│
└── bin/                    # CLI tools
```

## Design Principles

1. **Portable Core** — SSOT in `core/`, no target-specific logic
2. **Provider-Neutral** — Workflow spec works across Claude Code, OpenCode, etc.
3. **Overlay Pattern** — Target adaptations via overlay files, not mutation
4. **Mechanical Enforcement** — Rules enforced by tools, not conventions

## Dependency Flow

```
User Request
    ↓
Capability Tier Routing (claude.opus/sonnet/haiku)
    ↓
Scenario Matching → Skill Selection
    ↓
Execution with Safety Constraints
    ↓
Verification Before Completion
```

## Key Files

| File | Purpose |
|------|---------|
| `core/policies/behaviors.yaml` | Behavior policy SSOT |
| `core/policies/task-routing.yaml` | Task complexity routing |
| `core/skills/registry.yaml` | Portable skill definitions |
| `.vibe/claude-code/skill-routing.yaml` | Claude Code specific mappings |
