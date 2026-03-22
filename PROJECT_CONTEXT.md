# Project Context

## Session Handoff

<!-- handoff:start -->
### 2026-03-22
- **分支**: improve/review-suggestions（基于跨模型评审建议）
- **完成**: 改进 2 — SessionAnalyzer 格式版本检测（SUPPORTED_FORMATS, detect_format, parse_sessions_v1/v2）
- **待做**: 改进 3（InstinctManager 权重可配置）→ 改进 4（Grader token 预算）→ 改进 1（vibe onboard 命令）→ 测试 → 文档同步
- **下一步**: `lib/vibe/instinct_manager.rb` 加 DEFAULT_WEIGHTS + `config: { weights: {} }` 参数
<!-- handoff:end -->

### 2026-03-18
- **完成**: Windows 原生支持（cmd.exe 批处理）、项目改名 VibeSOP、Instinct 学习系统（Phase 1）、Quick Start 重写、文档全面同步
- **关键决策**: Instinct 存储用 YAML（Git 友好）、Windows 用文件复制替代 symlink、置信度算法 60/30/10 权重
- **测试状态**: 324 tests, 1001 assertions, 0 failures
- **教训**: 功能开发必须同步更新 7 处文档（已记录到 MEMORY.md）
- **下一步**: 从 docs/roadmap-2026-q2.md 选择 Phase 2（Token 优化）或 Phase 6（RIPER/Parry）开始
- **生态研究**: 已分析 everything-claude-code，结论保存在 memory/ecosystem-research.md

