# Project Context

## Session Handoff

<!-- handoff:start -->
### 2025-03-22 Test Coverage Improvement
- **完成**: 单元测试覆盖率从 52.65% 提升到 68.26%（line coverage），分支覆盖率从 37.4% 提升到 56.57%
- **新增测试**: 7 个新测试文件，157+ 测试用例，277+ 断言
  - test_errors.rb - 错误类层次结构测试
  - test_utils.rb - 核心工具（deep_merge, deep_copy, 验证）
  - test_hook_installer.rb - Hook 安装逻辑
  - test_user_interaction.rb - 用户交互工具
  - test_path_safety.rb - 路径安全和重叠检测
  - test_external_tools.rb - 外部工具检测
  - test_version.rb - 版本常量验证
- **测试状态**: 649 runs, 1455 assertions, 0 failures, 0 errors, 2 skips
- **技术要点**:
  - 修复 SimpleCov 配置问题（删除不存在的 branch_coverage_report 调用）
  - 处理 macOS 路径规范化（/tmp → /private/tmp 符号链接）
  - 测试私有方法：使用 respond_to?(method, true) 或 instance_methods(true)
- **已提交**: 所有新测试文件已创建，测试全部通过
- **下一步**: 继续提升分支覆盖率至 55%+，或添加 CLI 命令模块测试

### 2026-03-22 晚上
- **修复**: `vibe init` 时只检查 superpowers，遗漏 gstack
- **改动**:
  - `core/integrations/recommended.yaml` - 添加 gstack 到推荐列表
  - `lib/vibe/integration_setup.rb` - 添加 gstack 状态消息处理
  - `lib/vibe/integration_recommendations.rb` - 添加 gstack 标签
  - `lib/vibe/integration_manager.rb` - 始终显示集成状态摘要
- **测试**: 37 tests passed
- **状态**: 已修改但未提交

### 2026-03-22 上午
- 4项评审改进完成：SessionAnalyzer 格式版本检测、InstinctManager 权重可配置、Grader token 预算、vibe onboard 命令
- improve/review-suggestions 已合并，README/CHANGELOG 已同步
<!-- handoff:end -->

### 2026-03-18
- **完成**: Windows 原生支持（cmd.exe 批处理）、项目改名 VibeSOP、Instinct 学习系统（Phase 1）、Quick Start 重写、文档全面同步
- **关键决策**: Instinct 存储用 YAML（Git 友好）、Windows 用文件复制替代 symlink、置信度算法 60/30/10 权重
- **测试状态**: 324 tests, 1001 assertions, 0 failures
- **教训**: 功能开发必须同步更新 7 处文档（已记录到 MEMORY.md）
- **下一步**: 从 docs/roadmap-2026-q2.md 选择 Phase 2（Token 优化）或 Phase 6（RIPER/Parry）开始
- **生态研究**: 已分析 everything-claude-code，结论保存在 memory/ecosystem-research.md

