# Review Request: Modern CLI Tools Detection Feature

**Date**: 2026-03-23
**Reviewer**: ChatGPT
**Documents**:
- [PRD: Modern CLI Tools Detection](./prd-modern-cli-tools.md)
- [Implementation Plan](./implementation-plan-modern-cli-tools.md)

---

## Executive Summary

We propose adding **modern CLI tools detection and recommendation** to VibeSOP, enabling AI agents to automatically discover and prefer modern CLI tools (bat, fd, rg, etc.) when available in the user's environment.

### Key Points

**Problem**: AI agents currently use traditional Unix tools (cat, find, grep) even when users have better modern alternatives installed.

**Solution**: Detect installed modern tools during `vibe init`, generate `TOOLS.md` documentation, and let AI agents consume this information to prefer modern tools.

**Approach**: Static documentation injection (cross-platform compatible) with periodic refresh via `vibe doctor`.

**Scope**: 8 modern CLI tools (bat, fd, rg, eza, dust, duf, procs, btop)

**Timeline**: 2 weeks (10 working days)

**Risk**: Low - follows existing integration patterns, no breaking changes

---

## Design Decisions Made

### 1. AI Consumption Mechanism: Static Documentation ✅

**Decision**: Use static `TOOLS.md` file injected into platform entrypoints.

**Rationale**:
- Cross-platform compatible (Claude Code, OpenCode, future platforms)
- All platforms support document injection
- No dependency on platform-specific hooks or MCP

**Alternatives Rejected**:
- PreToolUse Hook: Only works on Claude Code
- MCP Server: Not all platforms support, requires extra process

### 2. File Location: Independent TOOLS.md ✅

**Decision**: Create standalone `TOOLS.md` file referenced from entrypoints.

**Rationale**:
- Clear separation of concerns
- Easy to maintain and update
- Users can view tool list independently

**Alternatives Rejected**:
- Embed in existing docs: Mixes concerns, harder to maintain

### 3. Refresh Frequency ✅

**Decision**:
- Auto-detect during `vibe init`
- Auto-refresh during `vibe doctor`
- Auto-refresh during `vibe apply`
- No background polling

**Rationale**:
- Balance between freshness and performance
- User has explicit control via `vibe doctor`
- No performance impact on normal operations

### 4. User Consent ✅

**Decision**: Ask user during `vibe init` if they want tool detection enabled.

**Rationale**:
- Respects user choice
- Avoids surprise behavior
- Clear opt-in/opt-out

### 5. Fallback Strategy ✅

**Decision**: Document fallback strategy in TOOLS.md, let AI handle naturally.

**Rationale**:
- AI naturally falls back when commands fail
- No special implementation needed
- Clear guidance in documentation

---

## Architecture Overview

```
core/integrations/modern-cli.yaml (config)
           ↓
lib/vibe/external_tools.rb (detection)
           ↓
lib/vibe/doc_rendering.rb (TOOLS.md generation)
           ↓
config/platforms.yaml (add 'tools' to doc_types)
           ↓
~/.claude/TOOLS.md + ~/.config/opencode/TOOLS.md
           ↓
AI Agent reads and uses
```

**Integration Points**:
- Follows same pattern as RTK/Superpowers/gstack
- Uses existing `cmd_exist?` for detection
- Uses existing `config_driven_renderers` for output
- Uses existing overlay system for customization

---

## Key Technical Decisions

### 1. Ruby 2.6 Compatibility ✅

**Constraint**: Must work with macOS system Ruby 2.6

**Implementation**:
- No `filter_map` → use `map{}.compact`
- No Ruby 2.7+ features
- Strict testing on Ruby 2.6

### 2. Alternative Binary Names ✅

**Problem**: Some tools have different names on different platforms (fd vs fdfind)

**Solution**: Support `alternatives` array in config:
```yaml
detection:
  binary: fd
  alternatives: [fdfind]
```

### 3. Performance ✅

**Target**: Detection completes within 2 seconds

**Implementation**:
- Cache detection results
- Parallel checks if needed
- No blocking operations

### 4. Cross-Platform Detection ✅

**Implementation**:
- Use `RbConfig::CONFIG['host_os']` for OS detection
- Use `where` on Windows, `which` on Unix
- Handle platform-specific paths

---

## Implementation Phases

### Phase 1: Configuration and Detection (Days 1-3)
- Create `modern-cli.yaml`
- Extend `external_tools.rb` with detection logic
- Unit tests

**Deliverable**: Working detection logic

### Phase 2: Documentation Generation (Days 4-5)
- Add `render_tools_doc` method
- Update `platforms.yaml` and `target_renderers.rb`
- Update entrypoint generation
- Unit tests

**Deliverable**: TOOLS.md generation

### Phase 3: User Interaction (Days 6-7)
- Integrate into `vibe init` flow
- Integrate into `vibe doctor` flow
- User consent logic
- Unit tests

**Deliverable**: Complete user flow

### Phase 4: Testing and Documentation (Days 8-10)
- E2E tests
- Update README and CHANGELOG
- Create user guide
- Cross-platform testing

**Deliverable**: Production-ready feature

---

## Testing Strategy

**Unit Tests**:
- Detection logic (external_tools.rb)
- Doc generation (doc_rendering.rb)
- User interaction (platform_installer.rb)
- Target: >75% coverage

**Integration Tests**:
- Full build pipeline
- Cross-platform rendering

**E2E Tests**:
- `vibe init` with tool detection
- `vibe doctor` refresh
- User opt-out scenario

**Manual Testing**:
- macOS, Linux, Windows
- Ruby 2.6 compatibility
- AI consumption verification

---

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Detection is slow | High | Low | Cache results, optimize |
| Binary name conflicts | Medium | Medium | Support alternatives |
| AI ignores recommendations | High | Medium | Clear docs, examples |
| Cross-platform failures | High | Low | Extensive testing |
| Ruby 2.6 issues | High | Low | Strict testing |

**Overall Risk**: Low

---

## Success Criteria

**Must Have (P0)**:
- ✅ Tool detection works on macOS and Linux
- ✅ TOOLS.md generated correctly
- ✅ User can opt in/out during init
- ✅ `vibe doctor` refreshes tools
- ✅ All unit tests pass
- ✅ Code coverage >75%
- ✅ Ruby 2.6 compatible

**Should Have (P1)**:
- E2E tests pass
- Documentation complete
- Works on Windows

**Nice to Have (P2)**:
- Tool installation suggestions
- Version checking

---

## Questions for Reviewer (ChatGPT)

Please review the PRD and implementation plan and provide feedback on:

1. **Architecture**: Is the static documentation approach sound? Any better alternatives?

2. **Design Decisions**: Are the 5 key decisions (consumption mechanism, file location, refresh frequency, user consent, fallback strategy) reasonable?

3. **Implementation Plan**: Is the 4-phase plan clear and complete? Any missing tasks?

4. **Risk Assessment**: Are there risks we haven't considered?

5. **Testing Strategy**: Is the testing approach sufficient?

6. **Ruby 2.6 Compatibility**: Any compatibility issues we might have missed?

7. **Cross-Platform**: Will this work reliably across Claude Code, OpenCode, and future platforms?

8. **User Experience**: Is the user interaction flow intuitive?

9. **Performance**: Will detection complete within 2 seconds?

10. **Maintainability**: Is the code structure maintainable and extensible?

---

## Specific Areas of Concern

1. **Detection Performance**: We're checking 8 tools sequentially. Should we parallelize?

2. **Cache Strategy**: Should we cache detection results? For how long?

3. **Refresh Trigger**: Is auto-refresh in `vibe doctor` too aggressive? Should it be opt-in?

4. **Alternative Binary Names**: Is the `alternatives` array approach sufficient?

5. **Error Handling**: What should happen if detection fails? Silent fail or warn user?

6. **Tool Categories**: Are the 3 categories (File Operations, Text Search, System Monitoring) sufficient?

7. **TOOLS.md Format**: Is the markdown format clear for both humans and AI?

8. **Entrypoint Integration**: Should TOOLS.md be prominently featured or just listed in reference docs?

---

## Next Steps After Review

1. Address feedback from ChatGPT
2. Revise PRD and implementation plan if needed
3. Create feature branch `feature/modern-cli-tools`
4. Execute Phase 1 (Configuration and Detection)
5. Review after each phase
6. Merge to main after all tests pass

---

## Appendix: Example Output

### Example TOOLS.md (Abbreviated)

```markdown
# Available CLI Tools

Your environment has the following modern tools:

## File Operations

- ✅ `bat` (replaces `cat`)
  - Syntax highlighting, line numbers. Use --paging=never for non-interactive output
  - Use for: Reading code files, Viewing logs
  - Path: `/opt/homebrew/bin/bat`

- ✅ `fd` (replaces `find`)
  - Faster, simpler syntax. Respects .gitignore by default
  - Use for: Finding files by name/pattern, Recursive file search
  - Path: `/opt/homebrew/bin/fd`

## Recommendation

Prefer modern tools when available for better output and performance.

## Fallback Strategy

If a modern tool fails with "command not found":
1. Fall back to the traditional tool
2. Inform the user the tool list may be outdated
3. Suggest running `vibe doctor` to refresh

---

Generated by: vibe doctor
Last updated: 2026-03-23 14:30:00
```

### Example User Interaction

```bash
$ vibe init --platform claude-code

🚀 Claude Code Global Configuration Setup
==================================================

🔍 Detecting modern CLI tools...
   Checking bat... ✅ found at /opt/homebrew/bin/bat
   Checking fd... ✅ found at /opt/homebrew/bin/fd
   Checking rg... ✅ found at /opt/homebrew/bin/rg
   Checking eza... ✅ found at /opt/homebrew/bin/eza
   Checking dust... ❌ not found
   Checking btop... ❌ not found

📊 Found 4 of 6 modern CLI tools

📝 Generate tool recommendations for AI?
   This will create ~/.claude/TOOLS.md and help AI use modern tools automatically.
   [Y/n] Y

✅ Generated ~/.claude/TOOLS.md
✅ Added reference to ~/.claude/CLAUDE.md
```

---

**Ready for Review**: Please provide comprehensive feedback on both documents.
