# Project Context

## Session Handoff

<!-- handoff:start -->
### 2026-03-18 17:52
- **完成**: 2026 Q2 Roadmap 全部 6 个 Phase（Token优化、验证循环、并行化、工具链检测、社区最佳实践）
- **分支**: feat/token-optimization (20 commits, 38 files, 6318+ insertions)
- **测试**: 253 tests, 583 assertions, 100% pass
- **关键模块**: TokenOptimizer, ModelSelector, BackgroundTaskManager, CheckpointManager, Grader, WorktreeManager, CascadeExecutor, ToolchainDetector, SecurityScanner, TddEnforcer, ContextOptimizer
- **CLI**: 新增 8 组命令（token, checkpoint, grade, tasks, worktree, cascade, toolchain, scan）
- **Skills**: riper-workflow (5-phase), using-git-worktrees
- **技术坑**: Ruby 2.6 兼容性（filter_map/tally 禁用）、TddEnforcer resolver 必须返回 nil、check 方法顺序
- **下一步**: 用户验证后合并到 main，更新 README Phase 5-6 章节
<!-- handoff:end -->

### 2026-03-18
- **完成**: Windows 原生支持（cmd.exe 批处理）、项目改名 VibeSOP、Instinct 学习系统（Phase 1）、Quick Start 重写、文档全面同步
- **关键决策**: Instinct 存储用 YAML（Git 友好）、Windows 用文件复制替代 symlink、置信度算法 60/30/10 权重
- **测试状态**: 324 tests, 1001 assertions, 0 failures
- **教训**: 功能开发必须同步更新 7 处文档（已记录到 MEMORY.md）
- **下一步**: 从 docs/roadmap-2026-q2.md 选择 Phase 2（Token 优化）或 Phase 6（RIPER/Parry）开始
- **生态研究**: 已分析 everything-claude-code，结论保存在 memory/ecosystem-research.md

