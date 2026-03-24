# Skill 配置系统 - 产品需求文档 (PRD) v2

## 1. 概述

### 1.1 背景
当前 OpenCode 已支持使用 Claude Code skills（通过 `~/.claude/skills/` 和 `~/.config/skills/` 目录下的 `SKILL.md` 文件），但管理方式原始：

- **手动管理软链接**：用户需手动在 `~/.config/opencode/skills/` 创建软链接
- **无声明式配置**：无法通过配置文件声明项目需要的 skills
- **跨项目复用困难**：不同项目需要重复配置
- **更新检测缺失**：无法感知 skill 版本变化

### 1.2 目标
构建一个**声明式、跨平台兼容、智能化**的 skill 配置系统，实现：

1. **统一配置管理**：通过 YAML/TOML 配置文件声明 skills
2. **自动链接管理**：根据配置自动创建/更新软链接
3. **Claude Code 兼容**：完全兼容现有的 `SKILL.md` 格式
4. **多源支持**：支持本地路径、Git 仓库、Registry 等多种来源
5. **智能分析**：LLM 辅助分析 skill 能力和安全性
6. **跨项目复用**：支持全局配置 + 项目级覆盖

### 1.3 术语定义

| 术语 | 定义 |
|------|------|
| **Skill Source** | Skill 的来源：本地目录、Git 仓库、Registry |
| **Skill Reference** | 对 skill 的引用：名称 + 版本/分支 + 源 |
| **Skill Link** | OpenCode 中的软链接（`~/.config/opencode/skills/{name} → {source}`）|
| **Global Config** | 用户级配置（`~/.config/opencode/config.yaml`）|
| **Project Config** | 项目级配置（`.opencode/config.yaml`）|

---

## 2. 功能需求

### 2.1 核心功能

#### F1: 声明式配置管理 (P0)

- 支持 `~/.config/opencode/config.yaml`（全局）和 `.opencode/config.yaml`（项目级）
- 配置格式支持 YAML（首选）和 TOML
- 配置合并策略：全局 → 项目级 → 运行时参数
- 配置变更自动检测（hash 比对）

**配置示例：**

```yaml
# .opencode/config.yaml
version: "1.0"

# Skill 源定义
skill_sources:
  # gstack skills（统一目录）
  gstack:
    type: local
    path: ~/.config/skills/gstack
  
  # Superpowers skills
  superpowers:
    type: local
    path: ~/.config/skills/superpowers
  
  # 团队内部 Registry
  team:
    type: registry
    url: https://skills.company.com
    auth:
      type: bearer
      token: env.TEAM_SKILLS_TOKEN
  
  # GitHub 组织 skills
  github:
    type: git
    url_template: https://github.com/my-org/{skill_name}-skill
    default_branch: main

# Skill 清单
skills:
  # 方式1：引用 gstack skill
  qa:
    source: gstack/qa    # 指向 ~/.config/skills/gstack/qa
    auto_update: true           # 检测源目录变化
  
  # 方式2：引用 superpowers skill
  brainstorming:
    source: superpowers/brainstorming
  
  # 方式3：从 Registry 安装
  custom-deploy:
    source: team/custom-deploy
    version: "1.2.0"
  
  # 方式4：从 Git 安装
  internal-tool:
    source: github/internal-tool
    ref: develop  # 分支或 tag
  
  # 方式5：直接指定路径
  my-debug:
    path: ./dev-skills/my-debug
    hot_reload: true

# 配置同步行为
sync:
  auto_link: true        # 启动时自动同步软链接
  check_updates: daily   # 更新检查频率
  on_conflict: ask       # 冲突处理：ask|skip|override
```

#### F2: 自动链接管理 (P0)

- 根据配置自动创建 `~/.config/opencode/skills/{name} → {source}` 软链接
- 支持多种链接类型：
  - **目录链接**：指向 skill 目录（最常见）
  - **文件链接**：直接指向 `SKILL.md`
- 配置变更时自动更新/删除链接
- 检测并报告链接断裂（源文件被删除）

**链接结构示例：**

```
~/.config/opencode/skills/
├── qa → ~/.config/skills/gstack/qa              # gstack skill
├── brainstorming → ~/.config/skills/superpowers/skills/brainstorming
├── custom-deploy → ~/.opencode/cache/skills/custom-deploy-1.2.0  # 下载的 skill
└── my-debug → /Users/project/dev-skills/my-debug  # 项目本地 skill
```

#### F3: 多源 Skill 获取 (P1)

**支持来源类型：**

1. **Local**（本地已存在的 skills）
   ```yaml
   source: gstack/qa
   # 解析为：~/.config/skills/gstack/qa
   ```

2. **Registry**（远程 Registry）
   ```yaml
   source: registry/team/custom-deploy
   # 下载到：~/.opencode/cache/skills/custom-deploy-{version}/
   ```

3. **Git**（Git 仓库）
   ```yaml
   source: git:https://github.com/user/skill-repo
   # 克隆到：~/.opencode/cache/skills/{hash}/
   ```

4. **Path**（相对/绝对路径）
   ```yaml
   path: ./local-skills/my-skill
   # 直接链接，不复制
   ```

#### F4: 智能分析与配置生成 (P1)

添加 skill 时，自动分析并生成配置：

1. **读取 SKILL.md**：解析 frontmatter 和指令内容
2. **LLM 分析**：
   - 识别 skill 的主要能力
   - 提取触发关键词和场景
   - 评估优先级（高频/中频/低频）
   - 检测与现有 skills 的重叠
3. **安全配置**：
   - 分析 `allowed-tools` 评估安全风险
   - 检测文件系统、网络、命令执行等敏感操作
   - 生成风险报告和建议
4. **Suggest 生成**：基于分析结果自动生成 suggest 规则

**分析示例：**

```yaml
# 自动生成的配置片段
skills:
  investigate:
    source: claude/gstack/investigate
    
    # LLM 分析结果
    ai_analysis:
      priority: high           # 高频使用
      category: debug          # 调试类
      triggers:
        - keywords: ["debug", "fix", "error", "broken", "not working"]
          confidence: 0.9
        - keywords: ["why", "how come", "what happened"]
          confidence: 0.7
      
      security:
        risk_level: low
        concerns:
          - "读取项目文件（正常）"
          - "执行 bash 命令（正常调试用途）"
      
      suggests:
        - when: "stderr contains 'Error'"
          message: "检测到错误，需要调查吗？"
          action: "/investigate"
```

#### F5: 安全审查 (P1)

- **静态分析**：扫描 `SKILL.md` 中的 `allowed-tools` 和指令内容
- **风险维度**：
  - 文件系统访问范围
  - 网络请求能力
  - 命令执行权限
  - 环境变量访问
- **分级管理**：
  - **Trusted**：来自已知源（claude/, superpowers/），无需审查
  - **Standard**：自动分析 + 低风险自动通过
  - **Sandboxed**：高风险 skill 默认沙箱运行（如可能）
  - **Blocked**：包含禁止能力的 skill 拒绝加载

#### F6: 跨项目 Skill 复用 (P1)

- **全局配置**：`~/.config/opencode/config.yaml` 定义常用 skills
- **项目继承**：新项目自动继承全局 skills
- **项目覆盖**：项目级配置可禁用或替换全局 skills
- **模板系统**：支持 skill 集合模板（如 `web-dev`, `mobile-dev`）

```yaml
# 全局配置
templates:
  web-dev:
    skills:
      - qa
      - browse
      - ship
      - review
      
# 项目配置
import_template: web-dev  # 一键导入常用 skills
skills:
  qa:
    enabled: false  # 禁用全局的 qa
```

#### F7: 版本与更新管理 (P2)

- **版本锁定**：支持 `version: "1.2.0"` 锁定特定版本
- **更新检测**：
  - 本地 skills：检测源目录修改时间
  - Git skills：检测远程分支新 commit
  - Registry skills：检测 registry 新版本
- **更新策略**：`auto_update: patch|minor|major|none`

---

## 3. 配置格式详细规范

### 3.1 完整配置示例

```yaml
# ~/.config/opencode/config.yaml (全局配置)
version: "1.0"

# Skill 源注册表
skill_sources:
  # gstack skills
  gstack:
    type: local
    path: ~/.config/skills/gstack
    trusted: true  # 跳过安全审查
  
  # Superpowers skills
  superpowers:
    type: local
    path: ~/.config/skills/superpowers/skills
    trusted: true
  
  # 本地开发 skills
  local:
    type: local
    path: ~/.config/skills/local
    trusted: false  # 需要安全审查
  
  # 公司 Registry
  company:
    type: registry
    url: https://skills.company.com/v1
    auth:
      type: bearer
      token: env.COMPANY_SKILLS_TOKEN
    trusted: false  # 需要安全审查
  
  # GitHub skills
  gh-skills:
    type: git
    url_template: https://github.com/{org}/{skill_name}-skill
    default_ref: main

# 全局 Skill 清单（所有项目默认继承）
skills:
  # 核心 workflow skills
  qa:
    source: gstack/qa
    auto_update: true
  
  browse:
    source: gstack/browse
  
  ship:
    source: gstack/ship
  
  # 安全审查相关
  cso:
    source: gstack/cso
  
  review:
    source: gstack/review
  
  # Superpowers skills
  brainstorming:
    source: superpowers/brainstorming
  
  systematic-debugging:
    source: superpowers/systematic-debugging

# 同步配置
sync:
  auto_link: true
  check_updates: daily
  on_conflict: ask

# 安全策略
security:
  default_level: standard  # strict|standard|permissive
  trusted_sources: [claude, superpowers]
  forbidden_tools:
    - CredentialAccess  # 全局禁止的能力
```

```yaml
# .opencode/config.yaml (项目级配置)
version: "1.0"

# 项目特定 skill 源
skill_sources:
  project-local:
    type: local
    path: ./.opencode/skills

# 项目级 skills（覆盖或新增）
skills:
  # 禁用全局的 qa（如果不需要）
  qa:
    enabled: false
  
  # 添加项目特定的 skills
  custom-linter:
    source: project-local/custom-linter
    hot_reload: true  # 开发模式
  
  # 从公司 Registry 添加
  deploy-pipeline:
    source: company/deploy-pipeline
    version: "2.0.0"
  
  # 直接内联定义（小型 skill）
  quick-test:
    inline:
      name: quick-test
      description: "Quick smoke test for this project"
      allowed_tools: [Bash, Read]
      instructions: |
        Run `npm test` and report results...

# 项目覆盖全局配置
sync:
  auto_link: true
  
security:
  # 项目可以更严格或更宽松
  allow_tools:
    - CredentialAccess  # 这个项目允许访问凭据
```

### 3.2 Skill Reference 格式

```yaml
# 完整格式
skill_name:
  source: "{source_name}/{path}"
  version: "1.0.0"      # Registry/版本控制
  ref: "main"           # Git 分支/tag
  path: "./local"       # 本地路径（优先级高于 source）
  enabled: true         # 启用/禁用
  auto_update: true     # 自动更新
  hot_reload: false     # 开发模式
  
  # AI 分析配置（自动生成，可覆盖）
  ai_config:
    priority: high
    triggers: [...]
    
  # 安全配置（自动生成，可覆盖）
  security:
    sandbox: false
    allowed_tools: [...]

# 简写格式（如果源已定义）
skill_name:
  source: claude/gstack/skill_name

# 极简格式（仅名称，从 default_source 查找）
skill_name: true
```

### 3.3 Source 类型定义

```yaml
# Local - 本地目录
source_name:
  type: local
  path: /absolute/or/~/relative/path
  trusted: true  # 可选，是否信任此源

# Registry - 远程 Registry
source_name:
  type: registry
  url: https://skills.registry.com/v1
  auth:
    type: bearer | basic | none
    token: env.ENV_VAR_NAME  # 从环境变量读取
    username: env.USERNAME_VAR
    password: env.PASSWORD_VAR
  cache_ttl: 3600  # 缓存时间（秒）

# Git - Git 仓库
source_name:
  type: git
  url: https://github.com/org/skills-repo
  # 或使用模板
  url_template: https://github.com/{org}/{skill_name}-skill
  default_ref: main
  auth:
    type: ssh | https | none
    key: ~/.ssh/id_rsa
  cache_ttl: 86400

# Inline - 内联定义（小型 skills）
source_name:
  type: inline
  content:
    name: skill_name
    version: "1.0.0"
    description: "..."
    allowed_tools: [Bash]
    instructions: "..."
```

---

## 4. CLI 命令设计

### 4.1 Skill 管理命令

```bash
# 添加 skill
opencode skill add <name> [--source <source>] [--from <url>]
# 示例：
opencode skill add qa                    # 从 default_source 添加
opencode skill add deploy --source company
opencode skill add my-skill --from https://github.com/user/skill

# 移除 skill
opencode skill remove <name> [--global]

# 列出 skills
opencode skill list [--all] [--format table|json|yaml]
# 输出示例：
# NAME           SOURCE                    STATUS    VERSION   LAST_CHECK
# qa             claude/gstack/qa          linked    -         -
# browse         claude/gstack/browse      linked    -         -
# custom-deploy  registry/company/deploy   linked    1.2.0     2024-01-15

# 检查 skill 详情
opencode skill inspect <name>
# 输出：完整配置、AI 分析、安全报告、触发场景

# 同步配置（创建/更新链接）
opencode skill sync [--dry-run]

# 检查更新
opencode skill check-updates
opencode skill update <name> [--all]

# 审核 skill 安全性
opencode skill audit <name>

# 开发模式（热重载）
opencode skill dev <path> [--name <alias>]
```

### 4.2 配置管理命令

```bash
# 初始化配置
opencode config init [--global|--project]

# 验证配置
opencode config validate

# 编辑配置
opencode config edit [--global]

# 查看生效配置（合并后）
opencode config show [--format yaml|json]

# 导入/导出
opencode config export > my-config.yaml
opencode config import my-config.yaml [--merge]
```

### 4.3 交互式工作流

```bash
$ opencode skill add custom-deploy

🔍 解析 skill 来源...
   源: registry/company/custom-deploy
   
📦 下载 skill...
   版本: 1.2.0
   路径: ~/.opencode/cache/skills/custom-deploy-1.2.0/

🤖 智能分析中...
   能力: 部署自动化
   优先级: HIGH（高频使用）
   触发场景: 3 个识别
   
🔒 安全审查...
   风险等级: MEDIUM
   警告: 需要网络访问 (api.github.com)
   警告: 需要执行 git 命令
   
⚙️  配置建议:
   • 建议沙箱运行（限制网络访问）
   • 可信任后开启完整权限

请选择安装方式:
[1] 沙箱安装 (推荐) 
[2] 完整安装 
[3] 查看详细报告
[4] 取消
> 1

✅ custom-deploy 已安装（沙箱模式）

💡 运行 `opencode skill inspect custom-deploy` 查看详情
💡 运行 `opencode skill approve custom-deploy` 解除沙箱限制
```

---

## 5. 技术架构

### 5.1 核心组件

```
┌────────────────────────────────────────────────────────────┐
│                     CLI Interface                          │
│         (opencode skill *, opencode config *)              │
└────────────────────────┬───────────────────────────────────┘
                         │
┌────────────────────────▼───────────────────────────────────┐
│                Configuration Manager                       │
│  • 加载配置（全局 + 项目级）                               │
│  • 验证配置格式                                            │
│  • 合并配置层级                                            │
│  • 检测配置变更                                            │
└────────────────────────┬───────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
┌────────────────┐ ┌──────────────┐ ┌──────────────┐
│  Link Manager  │ │   Resolver   │ │   Analyzer   │
│                │ │              │ │              │
│ • 创建软链接   │ │ • 解析来源   │ │ • LLM 分析   │
│ • 更新链接     │ │ • 下载缓存   │ │ • 安全审查   │
│ • 清理断裂链接 │ │ • 版本管理   │ │ • 配置生成   │
└────────────────┘ └──────────────┘ └──────────────┘
                         │
┌────────────────────────▼───────────────────────────────────┐
│                  Skill Sources                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │  Local   │ │ Registry │ │   Git    │ │  Inline  │      │
│  │ (已存在) │ │ (远程)   │ │ (仓库)   │ │ (内联)   │      │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │
└────────────────────────────────────────────────────────────┘
```

### 5.2 数据模型

```typescript
// 配置结构
interface OpencodeConfig {
  version: string;
  skill_sources: Record<string, SkillSource>;
  skills: Record<string, SkillConfig>;
  sync: SyncConfig;
  security: SecurityConfig;
  templates?: Record<string, SkillTemplate>;
}

interface SkillSource {
  type: 'local' | 'registry' | 'git' | 'inline';
  // 根据 type 有不同的字段
}

interface SkillConfig {
  // 引用方式（至少有一个）
  source?: string;           // source_name/path
  path?: string;             // 直接路径
  inline?: InlineSkill;      // 内联定义
  
  // 版本控制
  version?: string;
  ref?: string;
  
  // 启用状态
  enabled: boolean;
  
  // 更新策略
  auto_update: boolean | 'patch' | 'minor' | 'major';
  
  // 开发模式
  hot_reload?: boolean;
  
  // AI 分析结果（可覆盖）
  ai_config?: AIConfig;
  
  // 安全覆盖
  security?: SkillSecurityConfig;
}

interface SkillLink {
  name: string;
  source_path: string;       // skill 实际位置
  link_path: string;         // ~/.config/opencode/skills/{name}
  type: 'directory' | 'file';
  config: SkillConfig;
  status: 'active' | 'broken' | 'outdated';
  last_synced: Date;
}

// AI 分析结果
interface AIAnalysis {
  priority: 'critical' | 'high' | 'medium' | 'low';
  category: string;
  capabilities: string[];
  triggers: TriggerConfig[];
  suggests: SuggestConfig[];
  conflicts?: ConflictReport[];
}

// 安全报告
interface SecurityReport {
  overall_score: number;     // 0-10
  risk_level: 'low' | 'medium' | 'high' | 'critical';
  tool_analysis: ToolRisk[];
  recommendations: string[];
  sandbox_recommended: boolean;
}
```

### 5.3 目录结构

```
~/.config/opencode/
├── config.yaml              # 全局配置
├── skills/                  # 软链接目录
│   ├── qa → ~/.config/skills/gstack/qa
│   ├── browse → ~/.config/skills/gstack/browse
│   └── ...
├── cache/
│   ├── skills/             # 下载的 skills
│   │   ├── custom-deploy-1.2.0/
│   │   └── github-skill-{hash}/
│   └── registry/           # Registry 缓存
├── analytics/              # 使用统计
└── logs/                   # 操作日志

./.opencode/                # 项目级（在项目目录中）
├── config.yaml             # 项目配置
├── skills/                 # 项目本地 skills（可选）
│   └── custom-linter/
└── cache/                  # 项目特定缓存
```

---

## 6. 开发任务拆分

### Phase 1: 基础架构 (Week 1-2)
- [ ] **T1.1**: 配置格式 Schema 定义与验证
- [ ] **T1.2**: 配置加载与合并引擎
- [ ] **T1.3**: 配置变更检测机制
- [ ] **T1.4**: CLI 框架与基础命令

### Phase 2: Skill 解析与链接 (Week 2-3)
- [ ] **T2.1**: Skill Source 抽象（Local/Registry/Git/Inline）
- [ ] **T2.2**: Local Source 实现（Claude Code skills 兼容）
- [ ] **T2.3**: 软链接管理器（创建/更新/删除/检测断裂）
- [ ] **T2.4**: Registry Source 实现
- [ ] **T2.5**: Git Source 实现

### Phase 3: 智能分析 (Week 3-4)
- [ ] **T3.1**: SKILL.md 解析器（frontmatter + 指令）
- [ ] **T3.2**: LLM 分析引擎（能力识别、场景提取）
- [ ] **T3.3**: 优先级与触发词算法
- [ ] **T3.4**: Suggest 规则生成器

### Phase 4: 安全系统 (Week 4-5)
- [ ] **T4.1**: `allowed-tools` 静态分析
- [ ] **T4.2**: LLM 安全评估（风险维度分析）
- [ ] **T4.3**: 风险评分算法
- [ ] **T4.4**: 安全报告生成

### Phase 5: CLI 与交互 (Week 5-6)
- [ ] **T5.1**: `opencode skill` 命令族实现
- [ ] **T5.2**: `opencode config` 命令族实现
- [ ] **T5.3**: 交互式安装向导
- [ ] **T5.4**: 更新检测与通知

### Phase 6: 集成与优化 (Week 6-7)
- [ ] **T6.1**: 与现有 OpenCode 系统集成
- [ ] **T6.2**: 性能优化（并行下载、缓存策略）
- [ ] **T6.3**: 测试覆盖（单元测试 + 集成测试）
- [ ] **T6.4**: 文档编写

---

## 7. 与 Claude Code 的兼容性

### 7.1 SKILL.md 格式兼容

完全兼容现有的 Claude Code `SKILL.md` 格式：

```markdown
---
name: skill_name
version: 1.0.0
description: Skill description
allowed-tools:
  - Bash
  - Read
  - Write
---

# Skill Instructions

## Setup
...
```

### 7.2 软链接机制兼容

保持与现有 OpenCode 相同的软链接结构：

```
~/.config/opencode/skills/{skill_name} → {skill_source_path}
```

OpenCode 现有的 skill 发现机制无需修改。

### 7.3 跨平台使用

OpenCode 用户可以与 Claude Code 用户共享 skill：

1. **Claude Code 用户使用 OpenCode skills**：
   - 通过软链接将 `~/.config/skills/` 下的 skills 链接到 `~/.claude/skills/`
   
2. **OpenCode 用户使用 Claude Code**：
   - Claude Code 同样从 `~/.config/skills/` 读取 skills（通过 `~/.claude/skills/` 的软链接）
   - 所有 skills 统一存储在 `~/.config/skills/`

### 7.4 Migration 路径

**现有用户迁移：**

```bash
# 1. 初始化配置（自动检测现有软链接）
opencode config init --detect-existing

# 2. 自动将现有软链接转换为配置
# 生成 ~/.config/opencode/config.yaml:
# skills:
#   qa:
#     source: gstack/qa
#   ...

# 3. 后续通过配置管理，不再手动维护软链接
```

---

## 8. 风险评估

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| Claude Code skill 格式变更 | 低 | 高 | 监控官方变更，提供迁移脚本 |
| 软链接权限问题（Windows） | 中 | 中 | Windows 上使用 junction 或复制 |
| Registry 不可用 | 中 | 中 | 离线模式，使用本地缓存 |
| LLM 分析成本过高 | 中 | 低 | 缓存分析结果，增量更新 |
| 配置格式争议 | 低 | 中 | 早期社区 review，支持 TOML/YAML 双格式 |

---

## 9. 成功指标

- [ ] **Adoption**: 80%+ 新项目使用配置文件
- [ ] **迁移**: 现有项目 50%+ 完成配置化迁移
- [ ] **效率**: Skill 添加时间从 5 分钟降至 30 秒
- [ ] **安全**: 100% 非信任源 skills 经过安全审查
- [ ] **满意度**: 用户满意度 > 4.0/5.0

---

## 10. 附录

### A. 配置模板

```yaml
# minimal.yaml - 最小配置模板
skills:
  qa:
    source: claude/gstack/qa
  browse:
    source: claude/gstack/browse

# full.yaml - 完整配置模板
# [见 3.1 节]

# team.yaml - 团队配置模板
skill_sources:
  company:
    type: registry
    url: https://skills.company.com
skills:
  deploy:
    source: company/deploy
  security:
    source: company/security-scan
```

### B. API 文档

[待补充：Registry API 规范]

### C. 测试计划

[待补充：单元测试、集成测试、e2e 测试]

---

**版本历史:**
- v0.1 (2024-01-24): 初稿
- v0.2 (2024-01-24): 基于 Claude Code skill 架构重写
