# 深度优化计划 - 进行中

**目标**: 根据Claude Code评审意见，解决技术债务和代码异味

**开始日期**: 2026-03-11

**状态**: Phase 1完成，Phase 2进行中

---

## 已完成 ✅

### Phase 1: 立即修复 (P0)

#### 1.1 移除未使用的Container类 ✅
- [x] 移除了lib/vibe/container.rb（保留占位文件说明）
- [x] 移除了bin/vibe中对Container的引用
- [x] 移除了test/test_vibe_container.rb
- [x] 更新了README.md（10 modules → 9 modules）
- **结果**: 代码行数减少70行，无功能损失

#### 1.2 重构install_rtk方法命名 ✅
- [x] 统一命名为清晰的接口:
  - `install_rtk_interactive` - 主入口（替代install_rtk_with_choice）
  - `install_rtk_via_homebrew_interactive` - Homebrew方式
  - `install_rtk_via_cargo_interactive` - Cargo方式
  - `install_rtk_manual_guide` - 手动安装指导
- [x] 保留`install_rtk`作为向后兼容的别名
- [x] 更新了测试文件
- **结果**: 命名清晰，向后兼容

#### 1.3 修正文档不一致 ✅
- [x] 更新了CHANGELOG.md（62.76% → 62.99% → 63.79%）
- [x] 更新了README.md（移除了Container相关描述）
- **结果**: 文档与实际代码一致

### Phase 2: 代码重构 (P1) - 部分完成

#### 2.1 添加基础功能 ✅

##### 2.1.1 添加--version命令 ✅
- [x] 创建了lib/vibe/version.rb
- [x] 在bin/vibe中添加了--version/-v支持
- **验证**: `vibe --version` 输出 "vibe 0.7.0"

##### 2.1.2 添加Rakefile ✅
- [x] 创建了Rakefile
- [x] 添加了test、validate、coverage、clean、build任务
- [x] 设置default任务为test
- **验证**: `rake test` 正常工作

---

## 当前指标 📊

| 指标 | 优化前 | 当前 | 目标 | 状态 |
|------|--------|------|------|------|
| 测试通过率 | 100% | 100% | 100% | ✅ |
| 行覆盖率 | 54.51% | **63.79%** | 60%+ | ✅ |
| 分支覆盖率 | 40% | 28.52% | 50%+ | 🟡 |
| 代码行数 | 3,733 | 3,663 | N/A | ✅ |
| 模块数量 | 10 | 9 | N/A | ✅ |
| 测试数量 | 170 | 165 | N/A | ✅ |

**注意**: 测试数量从170降到165是因为移除了test_vibe_container.rb

---

## 待完成 ⏳

### Phase 2: 代码重构 (P1) - 剩余任务

#### 2.2 拆分init_support.rb
**问题**: 700+行，职责过多

**建议拆分**:
```
lib/vibe/
  init_support.rb           # 保留核心接口
  platform_installer.rb     # 平台安装逻辑
  integration_detector.rb   # 集成检测
  rtk_manager.rb           # RTK安装和管理
  superpowers_manager.rb   # Superpowers安装
  quickstart_runner.rb     # 快速启动流程
```

**行动**:
- [ ] 分析init_support.rb的依赖关系
- [ ] 逐步提取各个模块
- [ ] 保持向后兼容的接口
- [ ] 更新测试文件

**验收标准**:
- [ ] 每个文件<300行
- [ ] 职责单一
- [ ] 所有测试通过
- [ ] 无循环依赖

---

### Phase 3: 提升测试覆盖率 (P2)

**目标**:
- 分支覆盖率: 28.52% → 50%+

**行动**:
- [ ] 识别关键未覆盖路径
- [ ] 为错误处理路径添加测试
- [ ] 为边界条件添加测试
- [ ] 为失败场景添加测试

---

### Phase 4: 可选优化 (P3)

#### 4.1 添加vibe remove命令
**行动**:
- [ ] 设计remove命令接口
- [ ] 实现配置清理逻辑
- [ ] 添加安全确认
- [ ] 添加测试

#### 4.2 生成API文档
**行动**:
- [ ] 添加YARD文档注释
- [ ] 配置文档生成
- [ ] 发布到GitHub Pages

---

## 下一步行动

**建议**: 继续Phase 2.2，拆分init_support.rb

**理由**:
1. 行覆盖率已达到目标(63.79% > 60%)
2. 可以恢复覆盖率阈值到60%
3. 拆分大文件是改善代码质量的关键

**预计时间**: 2-3天
