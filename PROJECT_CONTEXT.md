# Project Context

## Session Handoff

<!-- handoff:start -->
### 2026-03-25 Scene-driven skill routing — ✅ 已完成

- **功能**: gstack 和 superpowers 技能包的场景驱动路由系统
- **实现**:
  - 创建 `.vibe/skill-routing.yaml` 定义 8 个冲突场景的路由规则
  - 文档化 15+ 个独有技能（gstack 的 /qa, /ship, /guard 等）
  - 更新 `CLAUDE.md` 技能选择指南，明确命名约定：
    - gstack: `/short-names` (/review, /office-hours)
    - superpowers: `/full-names` (/brainstorming, /test-driven-development)
  - 更新 `core/skills/registry.yaml` 添加冲突解决策略
- **架构**: 统一存储 `~/.config/skills/` + 软链接多平台适配
- **提交**: 3e71224..3e71224，已推送到 origin/main
- **下一步**: 实现安装后自动触发技能适配

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
<!-- handoff:end -->

## Project Overview

VibeSOP - AI 原生开发工作流编排系统
