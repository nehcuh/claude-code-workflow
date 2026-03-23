# PRD: Modern CLI Tools Detection and Recommendation

**Version**: 1.0
**Date**: 2026-03-23
**Author**: VibeSOP Team
**Status**: Draft for Review

---

## 1. Background and Objectives

### 1.1 Background

VibeSOP generates AI workflow configurations for multiple platforms (Claude Code, OpenCode, etc.). Currently, AI agents use traditional Unix tools (cat, find, grep) by default, even when users have modern alternatives installed (bat, fd, rg).

Modern CLI tools provide:
- Better output formatting (syntax highlighting, colors)
- Improved performance (faster search, parallel processing)
- Better UX (intuitive flags, sensible defaults)

However, AI agents are unaware of these tools' availability in the user's environment.

### 1.2 Objectives

**Primary Goal**: Enable AI agents to automatically detect and prefer modern CLI tools when available.

**Success Criteria**:
1. AI agents can discover available modern tools in user's environment
2. AI agents prefer modern tools over traditional ones when available
3. AI agents gracefully fall back to traditional tools when modern ones are unavailable
4. Solution works across all supported platforms (Claude Code, OpenCode, future platforms)

### 1.3 Non-Goals

- Installing modern CLI tools for users (users install via brew/apt themselves)
- Managing tool versions or updates
- Providing tool-specific configuration or customization

---

## 2. User Scenarios

### 2.1 Primary User Persona

**Developer using VibeSOP with modern CLI tools installed**

- Has installed modern tools (bat, fd, rg, etc.) via Homebrew/apt
- Uses Claude Code or OpenCode for AI-assisted development
- Wants AI to leverage these tools automatically
- Expects seamless fallback when tools are unavailable

### 2.2 User Journey

**Initial Setup (vibe init)**

```bash
$ vibe init --platform claude-code

🚀 Claude Code Global Configuration Setup
==================================================

🔍 Detecting modern CLI tools...
✅ Found: bat, fd, rg, eza
❌ Not found: dust, btop, procs

📝 Generate tool recommendations for AI? [Y/n]
> Y

✅ Generated ~/.claude/TOOLS.md
✅ Added reference to CLAUDE.md
✅ Configuration deployed successfully
```

**AI Consumption**

When AI starts:
1. Reads `~/.claude/CLAUDE.md`
2. Sees reference to `TOOLS.md`
3. Loads tool availability information
4. Prefers modern tools when executing commands

**Tool State Changes**

User installs a new tool:
```bash
$ brew install dust
$ vibe doctor

🔍 Checking environment...
✅ Refreshing tool detection...
✅ Updated ~/.claude/TOOLS.md (added: dust)
```

### 2.3 Edge Cases

**Case 1: Tool becomes unavailable**
- User uninstalls `bat`
- AI tries to use `bat` → command not found
- AI falls back to `cat` and informs user
- User runs `vibe doctor` to refresh

**Case 2: Cross-platform differences**
- User has `fd` on macOS, `fdfind` on Ubuntu
- Detection handles both binary names
- Generated docs reflect actual binary name

**Case 3: User opts out**
- User chooses "n" during `vibe init`
- No TOOLS.md generated
- AI uses traditional tools by default

---

## 3. Functional Requirements

### 3.1 Tool Detection

**FR-1: Binary Detection**
- MUST detect if a modern CLI tool binary exists in PATH
- MUST use cross-platform detection (Windows: `where`, Unix: `which`)
- MUST handle alternative binary names (e.g., `fd` vs `fdfind`)
- MUST cache detection results for performance

**FR-2: Tool Configuration**
- MUST load tool definitions from `core/integrations/modern-cli.yaml`
- MUST support user overrides via overlay mechanism
- MUST define tool mappings (traditional → modern)
- MUST include usage notes and recommendations

**FR-3: Detection Triggers**
- MUST detect during `vibe init`
- MUST refresh during `vibe doctor`
- MUST refresh during `vibe apply`
- SHOULD NOT detect on every command (performance)

### 3.2 Documentation Generation

**FR-4: TOOLS.md Generation**
- MUST generate `TOOLS.md` in platform-specific location
- MUST list available tools with ✅/❌ status
- MUST include usage recommendations
- MUST include fallback strategy guidance
- MUST include generation timestamp

**FR-5: Entrypoint Integration**
- MUST add reference to TOOLS.md in CLAUDE.md / AGENTS.md
- MUST be visible to AI on startup
- MUST work for both global and project-level configs

**FR-6: Cross-Platform Support**
- MUST generate docs for Claude Code (`~/.claude/TOOLS.md`)
- MUST generate docs for OpenCode (`~/.config/opencode/TOOLS.md`)
- MUST use platform-agnostic rendering logic

### 3.3 User Interaction

**FR-7: User Consent**
- MUST ask user during `vibe init` if they want tool detection
- MUST allow user to skip tool detection
- MUST respect user's choice in subsequent operations

**FR-8: Refresh Mechanism**
- MUST provide `vibe doctor` to refresh tool list
- MUST show diff when tools change (added/removed)
- MUST update TOOLS.md atomically

### 3.4 AI Consumption

**FR-9: Tool Preference**
- AI SHOULD prefer modern tools when available
- AI MUST fall back to traditional tools when modern tools fail
- AI SHOULD inform user when falling back
- AI SHOULD suggest running `vibe doctor` if tool list seems stale

**FR-10: Documentation Format**
- MUST use clear, concise markdown
- MUST include examples for each tool
- MUST explain when to use each tool
- MUST be readable by both humans and AI

---

## 4. Technical Design

### 4.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     VibeSOP Core                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐      ┌──────────────────┐           │
│  │ core/            │      │ lib/vibe/        │           │
│  │ integrations/    │─────▶│ external_tools.rb│           │
│  │ modern-cli.yaml  │      │ (detection)      │           │
│  └──────────────────┘      └──────────────────┘           │
│                                     │                       │
│                                     ▼                       │
│                            ┌──────────────────┐            │
│                            │ doc_rendering.rb │            │
│                            │ (TOOLS.md gen)   │            │
│                            └──────────────────┘            │
│                                     │                       │
│                                     ▼                       │
│  ┌──────────────────────────────────────────────┐         │
│  │ config_driven_renderers.rb                   │         │
│  │ (platform-specific output)                   │         │
│  └──────────────────────────────────────────────┘         │
│                    │                    │                  │
└────────────────────┼────────────────────┼──────────────────┘
                     ▼                    ▼
         ┌──────────────────┐  ┌──────────────────┐
         │ ~/.claude/       │  │ ~/.config/       │
         │ TOOLS.md         │  │ opencode/        │
         │ CLAUDE.md        │  │ TOOLS.md         │
         └──────────────────┘  │ AGENTS.md        │
                               └──────────────────┘
                     │                    │
                     └────────┬───────────┘
                              ▼
                     ┌──────────────────┐
                     │ AI Agent         │
                     │ (reads & uses)   │
                     └──────────────────┘
```

### 4.2 Data Model

**modern-cli.yaml Structure**

```yaml
schema_version: 1
name: modern-cli-tools
type: tool_detection
description: Modern CLI tools detection and recommendation

tools:
  - traditional: cat
    modern: bat
    detection:
      binary: bat
      alternatives: []
    usage_notes: "Syntax highlighting, line numbers. Use --paging=never for non-interactive output"
    use_cases: ["Reading code files", "Viewing logs"]

  - traditional: find
    modern: fd
    detection:
      binary: fd
      alternatives: [fdfind]  # Debian/Ubuntu package name conflict
    usage_notes: "Faster, simpler syntax. Respects .gitignore by default"
    use_cases: ["Finding files by name/pattern", "Recursive file search"]

  - traditional: grep
    modern: rg
    detection:
      binary: rg
      alternatives: [ripgrep]
    usage_notes: "Respects .gitignore, faster. Use --no-ignore to search all files"
    use_cases: ["Searching code content", "Pattern matching in files"]

  - traditional: ls
    modern: eza
    detection:
      binary: eza
      alternatives: [lsd, exa]
    usage_notes: "Icons, git status, tree view. Use --icons for visual output"
    use_cases: ["Listing directory contents", "Viewing file metadata"]

  - traditional: du
    modern: dust
    detection:
      binary: dust
      alternatives: []
    usage_notes: "Visual disk usage. Use -d N to limit depth"
    use_cases: ["Checking directory sizes", "Finding large files"]

  - traditional: df
    modern: duf
    detection:
      binary: duf
      alternatives: []
    usage_notes: "Better disk usage visualization"
    use_cases: ["Checking disk space", "Monitoring storage"]

  - traditional: ps
    modern: procs
    detection:
      binary: procs
      alternatives: []
    usage_notes: "Better process listing with colors and tree view"
    use_cases: ["Listing processes", "Finding running programs"]

  - traditional: top
    modern: btop
    detection:
      binary: btop
      alternatives: [bottom, glances, htop]
    usage_notes: "Interactive system monitor with better UI"
    use_cases: ["System monitoring", "Resource usage tracking"]

integration:
  auto_enable: ask_user
  priority: P2

  targets:
    claude-code:
      method: documentation
      doc_file: TOOLS.md

    opencode:
      method: documentation
      doc_file: TOOLS.md
```

**Detection Result Structure**

```ruby
{
  traditional: "cat",
  modern: "bat",
  available: true,
  path: "/opt/homebrew/bin/bat",
  alternatives_checked: [],
  usage_notes: "Syntax highlighting...",
  use_cases: ["Reading code files", "Viewing logs"]
}
```

### 4.3 Key Components

**Component 1: external_tools.rb Extensions**

```ruby
module Vibe
  module ExternalTools
    # Detect modern CLI tools
    def detect_modern_cli_tools
      config = load_integration_config('modern-cli')
      return [] unless config

      tools = config['tools'] || []
      tools.map { |tool| detect_single_tool(tool) }.compact
    end

    # Detect a single tool with alternatives
    def detect_single_tool(tool_def)
      binary = tool_def.dig('detection', 'binary')
      alternatives = tool_def.dig('detection', 'alternatives') || []

      # Check primary binary
      if cmd_exist?(binary)
        return build_tool_result(tool_def, binary, true)
      end

      # Check alternatives
      alternatives.each do |alt|
        if cmd_exist?(alt)
          return build_tool_result(tool_def, alt, true)
        end
      end

      # Not found
      build_tool_result(tool_def, binary, false)
    end

    # Verify modern CLI tools integration
    def verify_modern_cli_tools(target_platform)
      detected = detect_modern_cli_tools
      available_count = detected.count { |t| t[:available] }

      {
        installed: available_count > 0,
        ready: available_count > 0,
        available_tools: detected.select { |t| t[:available] },
        unavailable_tools: detected.reject { |t| t[:available] },
        total_count: detected.size,
        available_count: available_count
      }
    end
  end
end
```

**Component 2: doc_rendering.rb Extensions**

```ruby
module Vibe
  module DocRendering
    def render_tools_doc(manifest)
      detected_tools = detect_modern_cli_tools
      available = detected_tools.select { |t| t[:available] }
      unavailable = detected_tools.reject { |t| t[:available] }

      lines = []
      lines << "# Available CLI Tools"
      lines << ""
      lines << "Your environment has the following modern tools:"
      lines << ""

      # Group by category
      categories = {
        "File Operations" => ["cat", "find", "ls"],
        "Text Search" => ["grep"],
        "System Monitoring" => ["du", "df", "ps", "top"]
      }

      categories.each do |category, traditionals|
        tools_in_category = detected_tools.select do |t|
          traditionals.include?(t[:traditional])
        end
        next if tools_in_category.empty?

        lines << "## #{category}"
        lines << ""

        tools_in_category.each do |tool|
          status = tool[:available] ? "✅" : "❌"
          lines << "- #{status} `#{tool[:modern]}` (replaces `#{tool[:traditional]}`)"

          if tool[:available]
            lines << "  - #{tool[:usage_notes]}"
            lines << "  - Use for: #{tool[:use_cases].join(', ')}"
            lines << "  - Path: `#{tool[:path]}`" if tool[:path]
          else
            lines << "  - Not installed"
          end
          lines << ""
        end
      end

      lines << "## Recommendation"
      lines << ""
      lines << "Prefer modern tools when available for better output and performance."
      lines << ""
      lines << "## Fallback Strategy"
      lines << ""
      lines << "If a modern tool fails with \"command not found\":"
      lines << "1. Fall back to the traditional tool"
      lines << "2. Inform the user the tool list may be outdated"
      lines << "3. Suggest running `vibe doctor` to refresh"
      lines << ""
      lines << "---"
      lines << ""
      lines << "Generated by: vibe doctor"
      lines << "Last updated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"

      lines.join("\n")
    end
  end
end
```

**Component 3: platforms.yaml Modification**

```yaml
platforms:
  claude-code:
    # ... existing config ...
    doc_types:
      global: [behavior, safety, task_routing, test_standards, tools]  # Add tools
      project: [behavior, safety, tools]  # Add tools

  opencode:
    # ... existing config ...
    doc_types:
      global: [behavior, safety, task_routing, test_standards, tools]  # Add tools
      project: [behavior, safety, tools]  # Add tools
```

**Component 4: target_renderers.rb Modification**

```ruby
def write_target_docs(output_dir, manifest, doc_types)
  doc_types.each do |type|
    # ... existing code ...
    content = case type
              when :behavior then render_behavior_doc(manifest)
              # ... other cases ...
              when :tools then render_tools_doc(manifest)  # Add this
              else
                raise Vibe::Error, "Unknown doc type: #{type}"
              end

    File.write(File.join(output_dir, filename), content)
  end
end
```

**Component 5: Entrypoint Integration**

Modify `render_generic_project_md` to include tools reference:

```ruby
def render_generic_project_md(platform_id, manifest)
  # ... existing code ...

  <<~MD
    # Project #{target_label} Configuration

    # ... existing content ...

    ## Reference docs

    Supporting notes are under `.vibe/#{platform_id}/`:
    - `behavior-policies.md` — portable behavior baseline
    - `safety.md` — safety policy
    - `routing.md` — capability tier routing
    - `task-routing.md` — task complexity routing
    - `tools.md` — available modern CLI tools  # Add this
  MD
end
```

### 4.4 Integration Points

**With existing integrations:**
- Follows same pattern as RTK/Superpowers/gstack
- Uses `core/integrations/` for configuration
- Uses `external_tools.rb` for detection
- Uses `doc_rendering.rb` for documentation

**With build system:**
- Triggered during `vibe init`
- Refreshed during `vibe doctor`
- Refreshed during `vibe apply`
- Uses `config_driven_renderers.rb` for output

**With overlay system:**
- Users can override tool list via `--overlay`
- Overlay can add/remove tools
- Overlay can modify usage notes

---

## 5. Non-Functional Requirements

### 5.1 Performance

**NFR-1: Detection Speed**
- Tool detection MUST complete within 2 seconds
- MUST cache detection results
- MUST NOT block other operations

**NFR-2: Build Impact**
- Adding tool detection MUST NOT increase `vibe init` time by more than 3 seconds
- MUST NOT impact `vibe build` performance

### 5.2 Compatibility

**NFR-3: Ruby Version**
- MUST work with Ruby 2.6+ (macOS system Ruby)
- MUST NOT use Ruby 2.7+ features (filter_map, etc.)
- MUST use `map{}.compact` instead of `filter_map`

**NFR-4: Platform Support**
- MUST work on macOS, Linux, Windows
- MUST handle platform-specific binary names
- MUST use cross-platform detection (where/which)

**NFR-5: Cross-Platform AI**
- MUST work with Claude Code
- MUST work with OpenCode
- MUST be extensible to future platforms

### 5.3 Maintainability

**NFR-6: Configuration-Driven**
- Tool list MUST be in YAML, not hardcoded
- MUST follow existing integration patterns
- MUST be easy to add new tools

**NFR-7: Testing**
- MUST have unit tests for detection logic
- MUST have unit tests for doc rendering
- MUST have E2E test for full flow
- MUST maintain >75% code coverage

### 5.4 User Experience

**NFR-8: User Control**
- Users MUST be able to opt out
- Users MUST be able to refresh manually
- Users MUST see clear status messages

**NFR-9: Error Handling**
- MUST gracefully handle missing config files
- MUST gracefully handle detection failures
- MUST NOT crash on unexpected tool output

---

## 6. Acceptance Criteria

### 6.1 Core Functionality

**AC-1: Detection Works**
- [ ] `vibe init` detects installed modern CLI tools
- [ ] Detection handles alternative binary names (fd/fdfind)
- [ ] Detection works on macOS, Linux, Windows
- [ ] Detection completes within 2 seconds

**AC-2: Documentation Generated**
- [ ] TOOLS.md is generated in correct location
- [ ] TOOLS.md lists all detected tools with status
- [ ] TOOLS.md includes usage recommendations
- [ ] TOOLS.md is referenced in CLAUDE.md/AGENTS.md

**AC-3: User Interaction**
- [ ] User is asked during `vibe init` if they want tool detection
- [ ] User can choose Y/n
- [ ] Choice is respected (no TOOLS.md if user says no)

**AC-4: Refresh Works**
- [ ] `vibe doctor` refreshes tool list
- [ ] `vibe apply` refreshes tool list
- [ ] Refresh shows diff (added/removed tools)

### 6.2 Cross-Platform

**AC-5: Claude Code Support**
- [ ] TOOLS.md generated in `~/.claude/`
- [ ] Referenced in `~/.claude/CLAUDE.md`
- [ ] AI reads and uses tool information

**AC-6: OpenCode Support**
- [ ] TOOLS.md generated in `~/.config/opencode/`
- [ ] Referenced in `~/.config/opencode/AGENTS.md`
- [ ] AI reads and uses tool information

### 6.3 Quality

**AC-7: Testing**
- [ ] Unit tests for `detect_modern_cli_tools`
- [ ] Unit tests for `render_tools_doc`
- [ ] E2E test for full init flow
- [ ] Code coverage >75%

**AC-8: Ruby 2.6 Compatibility**
- [ ] No `filter_map` usage
- [ ] No Ruby 2.7+ features
- [ ] Works on macOS system Ruby

### 6.4 Documentation

**AC-9: User Documentation**
- [ ] README updated with tool detection feature
- [ ] CHANGELOG updated
- [ ] Usage examples provided

**AC-10: Developer Documentation**
- [ ] Code comments for new methods
- [ ] Integration guide for adding new tools

---

## 7. Out of Scope (Future Enhancements)

The following are explicitly out of scope for v1.0:

1. **Tool Installation** - VibeSOP will not install tools for users
2. **Version Management** - No checking of tool versions or compatibility
3. **Tool Configuration** - No managing tool-specific config files
4. **Performance Benchmarking** - No comparing tool performance
5. **Hook-Based Dynamic Detection** - Only static documentation in v1.0
6. **MCP Server** - No MCP-based tool detection
7. **Tool Recommendations** - No suggesting which tools to install
8. **Platform-Specific Optimizations** - No platform-specific tool preferences

These may be considered for future versions based on user feedback.

---

## 8. Success Metrics

**Adoption Metrics:**
- % of users who enable tool detection during `vibe init`
- % of users who have at least 1 modern tool installed

**Usage Metrics:**
- Number of times AI uses modern tools vs traditional tools
- Number of times `vibe doctor` is run to refresh tools

**Quality Metrics:**
- Number of bug reports related to tool detection
- User satisfaction with tool recommendations

---

## 9. Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Tool detection is slow | High | Low | Cache results, optimize detection logic |
| Binary name conflicts (fd/fdfind) | Medium | Medium | Support alternative names in config |
| AI ignores tool recommendations | High | Medium | Clear documentation, examples in TOOLS.md |
| Cross-platform detection fails | High | Low | Extensive testing on all platforms |
| User confusion about refresh | Medium | Medium | Clear messaging, automatic refresh in doctor |
| Ruby 2.6 compatibility issues | High | Low | Strict testing on Ruby 2.6 |

---

## 10. Timeline and Phases

**Phase 1: Core Detection (Week 1)**
- Create `modern-cli.yaml`
- Implement detection logic
- Unit tests

**Phase 2: Documentation Generation (Week 1)**
- Implement `render_tools_doc`
- Integrate with platforms.yaml
- Update entrypoint generation

**Phase 3: User Interaction (Week 2)**
- Add to `vibe init` flow
- Add to `vibe doctor` flow
- User consent logic

**Phase 4: Testing and Polish (Week 2)**
- E2E tests
- Cross-platform testing
- Documentation updates

**Total Estimated Time: 2 weeks**

---

## 11. Appendix

### 11.1 Example TOOLS.md Output

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

- ✅ `eza` (replaces `ls`)
  - Icons, git status, tree view. Use --icons for visual output
  - Use for: Listing directory contents, Viewing file metadata
  - Path: `/opt/homebrew/bin/eza`

## Text Search

- ✅ `rg` (replaces `grep`)
  - Respects .gitignore, faster. Use --no-ignore to search all files
  - Use for: Searching code content, Pattern matching in files
  - Path: `/opt/homebrew/bin/rg`

## System Monitoring

- ❌ `dust` (replaces `du`)
  - Not installed

- ❌ `btop` (replaces `top`)
  - Not installed

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

### 11.2 Example User Interaction

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

... (rest of init flow)
```

### 11.3 Related Documents

- [VibeSOP Architecture](../README.md)
- [Integration Guide](../core/integrations/README.md)
- [RTK Integration](../core/integrations/rtk.yaml)
- [Superpowers Integration](../core/integrations/superpowers.yaml)

---

**Document Status**: Draft for Review
**Next Steps**: Review by ChatGPT, then proceed to implementation plan

