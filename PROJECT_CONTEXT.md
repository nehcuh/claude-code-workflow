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
### 2026-03-27 Harness Engineering 实施 — ✅ 已完成

- **背景**: 基于 OpenAI Harness Engineering 理念优化项目提示词管理架构
- **核心改进**:
  1. **渐进式上下文披露**: CLAUDE.md 从 83 行精简至 52 行，深层文档拆分至 `docs/claude/`
  2. **机械约束**: `scripts/verify-harness.sh` 强制检查行数、死链、目录结构
  3. **约束前置**: `scripts/install-hooks.sh` 绑定 pre-commit hook，本地阻断违规提交
  4. **熵管理**: `scripts/entropy-scan.sh` 实现 TTL 技术债务监控（90 天过期告警）
- **关键文件**:
  - `CLAUDE.md` — 精简导航 + 显式 Agent 指令（`read` 命令格式）
  - `docs/claude/skills/routing.md` — 技能选择指南
  - `docs/claude/safety.md` — 安全策略 + Golden Principles
  - `golden-principles.yaml` — 可机械执行的规则定义
  - `.github/workflows/harness-check.yml` — CI 自动验证
- **验证结果**: 所有检查通过，pre-commit hook 工作正常
- **状态**: ✅ 已合并到 main
- **下一步**: 持续监控 entropy-scan.sh 输出，清理技术债务

<!-- handoff:end -->

## Project Overview

VibeSOP - AI 原生开发工作流编排系统
