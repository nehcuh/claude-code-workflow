# Project Context

## Session Handoff

<!-- handoff:start -->
### 2026-03-24 记忆自动加载功能 — ✅ 已合并

- **功能**: Claude Code 和 OpenCode 自动加载项目记忆文件
- **实现**:
  - MemoryAutoload 模块：检测记忆文件、交互式配置
  - `vibe memory autoload` 命令（enable/disable/status）
  - Claude Code: preCommand hook 自动读取 memory/*.md
  - OpenCode: 生成 .vibe/opencode/memory-context.md 并注入 instructions
- **代码审查**: 修复 File.expand_path('~') 测试隔离问题（P011）
- **提交**: 678d9e6，5 文件，+841/-2 行，16 测试 50 断言全绿
- **状态**: 已推送到 origin/main，功能可用
- **下一步**: 验证功能在实际项目中的效果

### 2026-03-24 Skill 软链接命名规范 — 已修改

- **修改**: 统一 skill 软链接命名格式为 `{repo}-{skill}`（如 `gstack-autoplan`、`superpowers-brainstorming`）
- **文件**: 9 个文件修改（superpowers_installer.rb, gstack_installer.rb, external_tools.rb, integrations/*.yaml 等）
- **变更**:
  - 软链接路径: `~/.config/{platform}/skills/{repo}-{skill}`
  - gstack: 为每个子技能单独创建软链接（gstack-autoplan, gstack-browse 等）
  - superpowers: 命名改为 superpowers-{skill} 格式
- **架构**: 统一存储 `~/.config/skills/` → 平台软链接 `~/.config/{platform}/skills/`
- **教训**: 软链接命名规范避免冲突、多平台技能复用架构
- **下一步**: 测试验证安装流程，确保 init 时正确创建软链接

### 2026-03-24 gstack 安装器 Bugfix — ✅ 已修复

- **问题**: 用户重新 init 时 gstack 安装到 `~/.config/opencode/skills/gstack` 而非统一路径 `~/.config/skills/gstack`
- **修复**: lib/vibe/gstack_installer.rb
  - 强制使用 unified 路径作为物理存储
  - 自动创建平台软链接（Claude Code、OpenCode）
  - 添加 Bun 环境预检查，未安装时给出友好指引
- **测试**: 15 runs, 29 assertions, 0 failures
- **教训**: P009（安装器路径问题）、P010（AI 会话结束指令识别）
<!-- handoff:end -->

## Project Overview

VibeSOP - AI 原生开发工作流编排系统
