# Project Optimization Plan

**Goal**: Fix all P0 and P1 issues identified in code review

**Status**: In Progress

---

## Phase 1: Fix Test Failures (P0) ⏳

### 1.1 Fix test_vibe_init.rb failures (4 failures)

**Task**: 
- Fix `test_bin_vibe_init_verify_allows_non_interactive_stdin`
- Fix `test_bin_vibe_init_with_platform_flag`
- Fix `test_bin_vibe_init_rejects_non_interactive_stdin_with_clear_message`
- Fix `test_bin_vibe_init_with_platform_equals_syntax`

**Root Causes**:
- Non-interactive stdin handling incorrect
- Error messages don't match expectations
- Platform flag output format mismatch

**Acceptance Criteria**:
- [ ] All 4 tests pass
- [ ] No regression in other tests

---

### 1.2 Fix test_vibe_cli.rb errors (3 errors)

**Task**:
- Fix `test_run_quickstart_installation` - interactive terminal requirement
- Fix `test_run_quickstart_identifies_existing_config` - `install_rtk` argument error
- Fix `test_switch_warp_uses_external_staging_when_repo_root_is_destination` - unexpected arguments

**Root Causes**:
- `install_rtk` called with wrong number of arguments
- `switch` command argument parsing issue
- Quickstart requires interactive terminal

**Acceptance Criteria**:
- [ ] All 3 errors resolved
- [ ] No regression in other tests

---

## Phase 2: Improve Test Coverage (P0) ⏳

### 2.1 Analyze coverage gaps

**Task**: Identify uncovered code paths

**Current Coverage**:
- Line: 55.84% (target: 60%)
- Branch: 40.8% (needs improvement)

**Acceptance Criteria**:
- [ ] Coverage report analyzed
- [ ] Critical uncovered paths identified

---

### 2.2 Add missing tests

**Task**: Write tests for uncovered code

**Acceptance Criteria**:
- [ ] Line coverage >= 60%
- [ ] Branch coverage improved
- [ ] All tests passing

---

## Phase 3: Fix Code Quality Issues (P1) ⏳

### 3.1 Fix constant re-initialization warnings

**Task**: Use `defined?` guard for constants in `bin/vibe`

**Files to modify**:
- `bin/vibe`

**Acceptance Criteria**:
- [ ] No "already initialized constant" warnings
- [ ] Tests still pass

---

### 3.2 Add RuboCop configuration

**Task**: Create `.rubocop.yml` with sensible defaults

**Acceptance Criteria**:
- [ ] `.rubocop.yml` created
- [ ] `bundle exec rubocop` runs without errors
- [ ] No critical offenses

---

### 3.3 Add CI/CD configuration

**Task**: Create GitHub Actions workflow

**Acceptance Criteria**:
- [ ] `.github/workflows/test.yml` created
- [ ] Runs tests on push/PR
- [ ] Reports coverage

---

## Phase 4: Cleanup (P2) ⏸️

### 4.1 Evaluate container.rb necessity

**Status**: Deferred - not blocking

---

## Progress Log

### Session 1 - 2026-03-10

**Started**: Initial setup and planning

**Actions**:
- Created task_plan.md
- Reviewed test failures
- Identified root causes

**Next**: Fix test_vibe_init.rb failures
