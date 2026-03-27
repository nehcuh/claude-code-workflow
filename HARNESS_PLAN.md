# Harness Engineering 优化规划

基于 OpenAI Harness Engineering 理念，针对本项目进行的系统性优化。

---

## 背景

Harness Engineering 的三大核心维度：
1. **Context Engineering** - 渐进式上下文披露
2. **Architectural Constraints** - 机械执行约束
3. **Entropy Management** - 熵管理/垃圾回收

---

## 阶段一：Context Engineering 重构

### 目标
将单体式 `CLAUDE.md` 拆分为渐进式披露的文档结构。

### 任务列表

- [ ] 1.1 创建 `docs/claude/` 目录结构
  ```
  docs/claude/
  ├── index.md          # 精简导航 (~100 行)
  ├── routing.md        # 能力路由规则
  ├── safety.md         # 安全策略
  └── skills/           # 技能使用指南
  ```

- [ ] 1.2 重写 `index.md` 为导航地图格式
  - 保留最高频使用的信息
  - 深层链接到详细文档

- [ ] 1.3 迁移现有 CLAUDE.md 内容
  - 架构相关内容 → `docs/claude/architecture/`
  - 路由相关内容 → `docs/claude/routing.md`
  - 安全相关内容 → `docs/claude/safety.md`

- [ ] 1.4 更新 `.claude/CLAUDE.md` 软链接或精简入口

---

## 阶段二：Architectural Constraints（机械验证）

### 目标
建立可自动验证的约束机制。

### 任务列表

- [ ] 2.1 创建 `scripts/verify-harness.sh`
  - 检查文档交叉链接有效性
  - 验证 `CLAUDE.md` 行数限制 (<150 行)

- [ ] 2.2 创建 `.github/workflows/harness-check.yml`
  - PR 时自动运行验证
  - 文档过期检测

- [ ] 2.3 添加 `golden-principles.yaml`
  ```yaml
  principles:
    - id: prefer-shared-skills
      description: 优先使用共享技能而非内联逻辑
    - id: mechanical-enforcement-first
      description: 优先使用机械约束而非人工审查
    - id: progressive-disclosure
      description: 上下文渐进式披露，避免信息过载
  ```

---

## 阶段三：Entropy Management

### 目标
建立持续的模式发现和债务管理机制。

### 任务列表

- [ ] 3.1 创建 `docs/technical-debt/` 目录
  - 记录已知问题
  - 追踪重复出现的模式

- [ ] 3.2 创建 `scripts/entropy-scan.sh`
  - 扫描重复代码/模式
  - 检测文档与代码不同步

- [ ] 3.3 设计熵监控机制
  - 定期扫描（考虑 cron job）
  - 生成债务报告

---

## 阶段四：验证与迭代

- [ ] 4.1 在实际使用中验证新结构
- [ ] 4.2 收集反馈并调整
- [ ] 4.3 更新 `PROJECT_CONTEXT.md`

---

## 当前进度

| 阶段 | 状态 | 备注 |
|-----|------|------|
| 阶段一 | ✅ 已完成 | CLAUDE.md 精简至 39 行，显式 Agent 指令，Policy Hierarchy 明确 |
| 阶段二 | ✅ 已完成 | verify-harness.sh（含死链检测）、install-hooks.sh、CI 工作流 |
| 阶段三 | ✅ 已完成 | entropy-scan.sh（含 TTL 检查）、technical-debt/GC 机制 |
| 阶段四 | ✅ 已完成 | 实际使用验证通过，已更新 PROJECT_CONTEXT.md |

---

## 相关资源

- [OpenAI Harness Engineering](https://openai.com/index/harness-engineering/)
- [InfoQ 深度解析](https://www.infoq.com/news/2026/02/openai-harness-engineering-codex/)
