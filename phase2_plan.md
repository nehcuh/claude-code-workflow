# Phase 2 优化计划 - 拆分 init_support.rb

**目标**: 将 700+ 行的 init_support.rb 拆分为职责单一的模块

**开始日期**: 2026-03-11

**预计完成**: 2-3 天

---

## 当前状态分析

**文件**: `lib/vibe/init_support.rb`
**行数**: ~700+ 行
**问题**: 职责过多，包含以下功能：
1. 平台安装逻辑 (run_init, install_global_config)
2. 平台验证逻辑 (verify_platform_installation, verify_all_platforms)
3. 集成检测 (check_and_suggest_integrations, integration_status)
4. RTK 安装 (install_rtk, install_rtk_interactive, 多个 install_rtk_* 方法)
5. Superpowers 安装 (superpowers 相关方法)
6. 快速启动 (run_quickstart)
7. 用户交互 (ask_yes_no, ask_choice, open_url)
8. 平台工具方法 (normalize_target, platform_label, default_global_destination)

---

## 拆分方案

### 目标结构

```
lib/vibe/
  init_support.rb              # 保留核心接口和协调逻辑 (~100行)
  platform_installer.rb        # 平台安装逻辑
  platform_verifier.rb         # 平台验证逻辑
  integration_manager.rb       # 集成检测和管理
  rtk_installer.rb            # RTK 安装逻辑
  superpowers_installer.rb    # Superpowers 安装逻辑
  quickstart_runner.rb        # 快速启动流程
  user_interaction.rb         # 用户交互工具方法
  platform_utils.rb           # 平台相关工具方法
```

### 模块职责

#### 1. platform_utils.rb
**职责**: 平台相关的工具方法
**方法**:
- normalize_target
- platform_label
- default_global_destination
- config_entrypoint
- platform_command

#### 2. user_interaction.rb
**职责**: 用户交互工具
**方法**:
- ask_yes_no
- ask_choice
- open_url
- ensure_interactive_setup_available!
- read_prompt_response!

#### 3. platform_verifier.rb
**职责**: 平台验证
**方法**:
- verify_platform_installation
- verify_all_platforms
- suggest_platform_setup

#### 4. platform_installer.rb
**职责**: 平台安装
**方法**:
- install_global_config
- (可能包含一些辅助方法)

#### 5. rtk_installer.rb
**职责**: RTK 安装
**方法**:
- install_rtk
- install_rtk_interactive
- install_rtk_via_homebrew_interactive
- install_rtk_via_cargo_interactive
- install_rtk_manual_guide
- configure_rtk_after_install
- configure_rtk_hook
- rtk_hook_configured?

#### 6. superpowers_installer.rb
**职责**: Superpowers 安装
**方法**:
- (从 external_tools.rb 迁移相关方法)
- 或保持 external_tools.rb 中的实现

#### 7. integration_manager.rb
**职责**: 集成检测和管理
**方法**:
- integration_status
- check_and_suggest_integrations
- check_environment
- load_integration_config (从 external_tools.rb)
- list_integrations (从 external_tools.rb)

#### 8. quickstart_runner.rb
**职责**: 快速启动流程
**方法**:
- run_quickstart
- (可能包含一些辅助方法)

#### 9. init_support.rb (保留)
**职责**: 核心接口和协调逻辑
**方法**:
- run_init (主入口)
- 协调其他模块的调用

---

## 实施步骤

### Step 1: 创建基础模块
- [ ] 创建 platform_utils.rb
- [ ] 创建 user_interaction.rb
- [ ] 运行测试确保无破坏

### Step 2: 迁移验证和安装逻辑
- [ ] 创建 platform_verifier.rb
- [ ] 创建 platform_installer.rb
- [ ] 运行测试

### Step 3: 迁移 RTK 相关逻辑
- [ ] 创建 rtk_installer.rb
- [ ] 迁移所有 install_rtk_* 方法
- [ ] 运行测试

### Step 4: 迁移集成管理逻辑
- [ ] 创建 integration_manager.rb
- [ ] 迁移集成检测方法
- [ ] 运行测试

### Step 5: 迁移快速启动逻辑
- [ ] 创建 quickstart_runner.rb
- [ ] 迁移 run_quickstart
- [ ] 运行测试

### Step 6: 清理和重构 init_support.rb
- [ ] 保留核心接口
- [ ] 添加对其他模块的引用
- [ ] 运行所有测试

---

## 依赖关系分析

### 依赖图

```
init_support.rb
  ├── platform_utils.rb (基础工具)
  ├── user_interaction.rb (基础工具)
  ├── platform_verifier.rb
  │   └── platform_utils.rb
  ├── platform_installer.rb
  │   ├── platform_utils.rb
  │   └── user_interaction.rb
  ├── rtk_installer.rb
  │   ├── user_interaction.rb
  │   └── integration_manager.rb (for load_integration_config)
  ├── integration_manager.rb
  │   ├── platform_utils.rb
  │   └── user_interaction.rb
  └── quickstart_runner.rb
      ├── platform_utils.rb
      ├── platform_installer.rb
      └── integration_manager.rb
```

### 关键依赖
1. **platform_utils.rb** 和 **user_interaction.rb** 是基础模块，被多个其他模块依赖
2. **integration_manager.rb** 提供 load_integration_config，被 rtk_installer.rb 使用
3. **init_support.rb** 作为协调者，依赖所有其他模块

---

## 验收标准

- [ ] 每个新文件 < 300 行
- [ ] 所有测试通过 (165 runs, 0 failures, 0 errors)
- [ ] 覆盖率保持在 60%+
- [ ] 无循环依赖
- [ ] 向后兼容（对外接口不变）
- [ ] 代码职责单一，符合 SRP 原则

---

## 风险和对策

### 风险 1: 破坏现有功能
**对策**: 每完成一个模块就运行测试，确保无回归

### 风险 2: 循环依赖
**对策**: 仔细规划依赖关系，基础模块不依赖其他业务模块

### 风险 3: 测试覆盖率下降
**对策**: 保持测试文件不变，确保拆分后的代码仍被原有测试覆盖

---

## 进度追踪

### 2026-03-11 Session 2

**计划**:
- [ ] 创建 platform_utils.rb
- [ ] 创建 user_interaction.rb
- [ ] 迁移基础工具方法

**下一步**: 开始 Step 1
