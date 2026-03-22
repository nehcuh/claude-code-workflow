# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'yaml'
require_relative '../../lib/vibe/cli/parallel_commands'
require_relative '../../lib/vibe/errors'

class ParallelCommandsTestHost
  include Vibe::ParallelCommands
end

class TestParallelCommands < Minitest::Test
  def setup
    @host = ParallelCommandsTestHost.new
    @tmpdir = Dir.mktmpdir('vibe-parallel-test')
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_module_exists
    assert Vibe.const_defined?(:ParallelCommands)
  end

  # ── worktree routing ──────────────────────────────────────────────────────

  def test_worktree_help
    out, = capture_io { @host.run_worktree_command(['help']) }
    assert_match(/Usage/, out)
    assert_match(/create/, out)
  end

  def test_worktree_nil_shows_usage
    out, = capture_io { @host.run_worktree_command([]) }
    assert_match(/Usage/, out)
  end

  def test_worktree_unknown_raises
    assert_raises(Vibe::ValidationError) { @host.run_worktree_command(['bogus']) }
  end

  def test_worktree_list_empty
    out, = capture_io { @host.run_worktree_command(['list']) }
    assert_match(/Worktrees/, out)
  end

  def test_worktree_status
    out, = capture_io { @host.run_worktree_command(['status']) }
    assert_match(/Worktree Status/, out)
    assert_match(/Total/, out)
  end

  def test_worktree_cleanup
    out, = capture_io { @host.run_worktree_command(['cleanup']) }
    assert_match(/Removed/, out)
  end

  def test_worktree_create_no_name_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_worktree_command(['create']) }
    end
  end

  def test_worktree_finish_no_id_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_worktree_command(['finish']) }
    end
  end

  def test_worktree_remove_no_id_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_worktree_command(['remove']) }
    end
  end

  def test_worktree_finish_unknown_id_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_worktree_command(%w[finish nonexistent-id]) }
    end
  end

  def test_worktree_remove_unknown_id_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_worktree_command(%w[remove nonexistent-id]) }
    end
  end

  # ── cascade routing ───────────────────────────────────────────────────────

  def test_cascade_help
    out, = capture_io { @host.run_cascade_command(['help']) }
    assert_match(/Usage/, out)
    assert_match(/run/, out)
    assert_match(/plan/, out)
  end

  def test_cascade_nil_shows_usage
    out, = capture_io { @host.run_cascade_command([]) }
    assert_match(/Usage/, out)
  end

  def test_cascade_unknown_raises
    assert_raises(Vibe::ValidationError) { @host.run_cascade_command(['bogus']) }
  end

  def test_cascade_run_no_config_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_cascade_command(['run']) }
    end
  end

  def test_cascade_plan_no_config_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_cascade_command(['plan']) }
    end
  end

  def test_cascade_plan_with_config
    config = {
      'tasks' => [
        { 'id' => 'lint', 'command' => 'echo lint', 'depends_on' => [] },
        { 'id' => 'test', 'command' => 'echo test', 'depends_on' => ['lint'] }
      ]
    }
    config_file = File.join(@tmpdir, 'cascade.yaml')
    File.write(config_file, config.to_yaml)

    out, = capture_io { @host.run_cascade_command(['plan', config_file]) }
    assert_match(/Cascade Plan/, out)
    assert_match(/lint/, out)
    assert_match(/test/, out)
  end

  def test_build_executor_from_config
    config = {
      'tasks' => [
        { 'id' => 'a', 'command' => 'echo a', 'depends_on' => [] },
        { 'id' => 'b', 'command' => 'echo b', 'depends_on' => ['a'] }
      ]
    }
    executor = @host.send(:build_executor_from_config, config)
    assert_equal 2, executor.tasks.size
    assert executor.tasks.key?('a')
    assert executor.tasks.key?('b')
  end
end
