# Project Context

## Session Handoff

<!-- handoff:start -->
### 2026-03-23 Modern CLI Tools Detection — PRD + 设计评审

- **完成**: PRD（826行）、实现计划（1000行）、评审请求文档全部产出
- **核心设计**: 静态文档注入（跨平台）、独立 TOOLS.md、init 检测 + doctor 刷新、用户 opt-in
- **GLM-5 评审结论**: 通过，3 必须修复（跨平台检测用 Ruby 原生 PATH、重新启用路径、明确项目级范围为 v1.0 不支持）
- **不采纳**: 并行检测（过早优化）、文件缓存（过度设计）
- **文件**: docs/prd-modern-cli-tools.md, docs/implementation-plan-modern-cli-tools.md
- **下一步**:
  1. 更新 PRD 和实现计划（修复 3 个必须项）
  2. 创建 `feature/modern-cli-tools` 分支
  3. 执行 Phase 1（创建 modern-cli.yaml + 扩展 external_tools.rb）

### 2026-03-23 代码质量改进
- **完成**: 深度审查 + 质量改进全部推送 main（commit 0cc0313）
- **主要改动**: `find_repo_root` 去重、新增 2 个测试文件（+50 tests）
- **测试状态**: 1311 runs, 0 failures；行覆盖率 76.1%；RuboCop 零警告
<!-- handoff:end -->


### 2026-03-18
- **完成**: Windows 原生支持（cmd.exe 批处理）、项目改名 VibeSOP、Instinct 学习系统（Phase 1）、Quick Start 重写、文档全面同步
- **关键决策**: Instinct 存储用 YAML（Git 友好）、Windows 用文件复制替代 symlink、置信度算法 60/30/10 权重
- **测试状态**: 324 tests, 1001 assertions, 0 failures
- **教训**: 功能开发必须同步更新 7 处文档（已记录到 MEMORY.md）
- **下一步**: 从 docs/roadmap-2026-q2.md 选择 Phase 2（Token 优化）或 Phase 6（RIPER/Parry）开始
- **生态研究**: 已分析 everything-claude-code，结论保存在 memory/ecosystem-research.md

