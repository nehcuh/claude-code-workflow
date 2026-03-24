# Project Context

## Session Handoff

<!-- handoff:start -->
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
