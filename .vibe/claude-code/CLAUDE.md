# Claude Code Project Config

> Harness Engineering: Progressive Disclosure Mode

## ⚠️ CRITICAL AGENT INSTRUCTION

**Do NOT guess or hallucinate rules.** When you need information from any category below, you **MUST** use the `read` tool to fetch the file contents before proceeding.

## 🚀 AI-Powered Skill Routing

**When uncertain which skill to use, leverage AI-powered routing:**

```bash
vibe route "<user_request>"
```

**Example:**
```bash
vibe route "帮我评审当前项目，包括架构和实现"
# Output: 🔥 Matched skill: riper-workflow (95% confidence)
```

**Why use AI routing?**
- ✅ **95% accuracy** vs 70% for keyword matching
- ✅ **Semantic understanding** - understands intent, not just keywords
- ✅ **Multi-provider support** - Claude Haiku or OpenAI GPT
- ✅ **Context-aware** - considers file types, errors, recent work
- ✅ **~$0.11/month** - cost-effective with 70%+ cache hit rate

**5-Layer Routing System:**
- **Layer 0**: AI Semantic Triage (Haiku/GPT, 95% accuracy)
- **Layer 1**: Explicit overrides (user-specified)
- **Layer 2**: Scenario patterns (predefined cases)
- **Layer 3**: Semantic matching (TF-IDF + cosine similarity)
- **Layer 4**: Fuzzy matching (Levenshtein distance)

## Quick Navigation

| Need | Go To |
|------|-------|
| AI Skill Routing | `Bash(vibe route "<request>")` |
| Skill catalog | `read .vibe/claude-code/skills.md` |
| Safety rules | `read .vibe/claude-code/safety.md` |
| Behavior policies | `read .vibe/claude-code/behavior-policies.md` |
| Task routing | `read .vibe/claude-code/task-routing.md` |

## Policy Hierarchy (Override Order)

When rules conflict, follow this priority:

1. **AI-powered routing** - Use `vibe route` for semantic skill matching
2. **Project-specific docs** — Highest priority (if exists)
3. **`.vibe/claude-code/`** — Global baseline policies (fallback)

## Critical Rules (P0)

- `ssot-first` (`mandatory`) — Keep repository files as the single source of truth; tool-managed memory is cache.
- `verify-before-claim` (`mandatory`) — Never claim completion without fresh verification evidence.
- `capability-tier-routing` (`mandatory`) — Route by capability tier first, then resolve through the active provider profile.
- `reversible-small-batches` (`recommended`) — Prefer small, reversible, single-purpose changes over large mixed batches.

## Skill Priority (When Conflict)

```
gstack (short) > superpowers (full) > builtin
```

## Optional Integrations

- **Superpowers**: ✅ Installed (`/Users/huchen/.config/skills/superpowers`)
- **RTK**: ✅ Installed (vrtk 0.29.0, hook ✅)

## Reference

See `.vibe/claude-code/` for full policy docs.
Applied overlay: `none`
