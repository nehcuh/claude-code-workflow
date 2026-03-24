# Project Context

## Session Handoff

<!-- handoff:start -->
### 2026-03-24 gstack 安装器 Bugfix — ✅ 已修复

- **问题**: 用户重新 init 时 gstack 安装到 `~/.config/opencode/skills/gstack` 而非统一路径 `~/.config/skills/gstack`
- **修复**: lib/vibe/gstack_installer.rb
  - 强制使用 unified 路径作为物理存储
  - 自动创建平台软链接（Claude Code、OpenCode）
  - 添加 Bun 环境预检查，未安装时给出友好指引
- **测试**: 15 runs, 29 assertions, 0 failures
- **教训**: P009（安装器路径问题）、P010（AI 会话结束指令识别）
- **下一步**: 用户验证修复效果，测试重新 init 流程

### 2026-03-24 Modern CLI Tools Detection — ✅ 已合并到 main

- **完成**: 4 阶段完整实现 + 评审修复，已合并到 main 分支
  - Phase 1: modern-cli.yaml + external_tools.rb + 16 个单元测试
  - Phase 2: render_tools_doc + platforms.yaml 更新 + Entrypoint 引用
  - Phase 3: vibe init 集成 + vibe doctor 刷新 + vibe tools 子命令
  - Phase 4: README/CHANGELOG/docs 更新 + E2E 测试框架
  - 修复: 运行时错误（ask_yes_no 参数）+ 未使用变量警告 + E2E 测试路径
- **代码量**: 1,058 行新增，20 个文件改动
- **测试**: 26 个新测试，72 assertions，全绿通过
- **Commits**: f9cca44, 7c95bea, 5e2b05d, 7e69fed, a32d807（修复）
- **评审评分**: 9.4/10 ⭐⭐⭐⭐⭐
- **下一步**: 继续 Q2 路线图其他 Phase（Token 优化 / RIPER/Parry）
<!-- handoff:end -->


### 2026-03-18
- **完成**: Windows 原生支持（cmd.exe 批处理）、项目改名 VibeSOP、Instinct 学习系统（Phase 1）、Quick Start 重写、文档全面同步
- **关键决策**: Instinct 存储用 YAML（Git 友好）、Windows 用文件复制替代 symlink、置信度算法 60/30/10 权重
- **测试状态**: 324 tests, 1001 assertions, 0 failures
- **教训**: 功能开发必须同步更新 7 处文档（已记录到 MEMORY.md）
- **下一步**: 从 docs/roadmap-2026-q2.md 选择 Phase 2（Token 优化）或 Phase 6（RIPER/Parry）开始
- **生态研究**: 已分析 everything-claude-code，结论保存在 memory/ecosystem-research.md
