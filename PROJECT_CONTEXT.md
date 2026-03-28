# Project Context

## Session Handoff

<!-- handoff:start -->
### 2026-03-28 VibeSOP 全面评审 + 修复 — ✅ 10 commits

- **评审发现**: 测试无法运行(21%覆盖率)、3 个 500+ 行大类、43 个碎片文档、硬编码常量分散
- **修复清单**:
  1. 清理 git 状态（删除 11 个废弃模块，提交新模块和修改）
  2. 修复测试套件（6 个 failure/error → 全绿）
  3. 拆分 3 个大类为 18 个子模块（SkillRouter/DocRendering/ExternalTools）
  4. 删除 17 个过程性文档（-7026 行）
  5. 提取硬编码常量到 `lib/vibe/defaults.rb`（6+ 模块引用）
  6. 补全遗漏常量迁移（superpowers_installer, skill_router 子模块）
  7. 新增 6 个测试文件（+249 tests, 72% coverage）
- **关键决策**: 后台 agent 改坏测试文件时，用 `git checkout HEAD -- <file>` 恢复
- **陷阱记录**: P013（agent API 不匹配）、P014（并行文件覆盖）、P015（git checkout 恢复）
- **最终状态**: 1424 tests green, 71.96% line, 54.55% branch, clean git

### 2026-03-27 preCommand hook 格式 Bug 修复 — ✅ 已修复

- **问题**: Claude Code 启动时报错 `Invalid key in record`
- **根因**: memory_autoload.rb:217 将字符串推入 preCommand 数组，需对象格式
- **状态**: 已修复并提交

<!-- handoff:end -->

## Project Overview

VibeSOP - AI 原生开发工作流编排系统
