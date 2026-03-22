# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../../lib/vibe/cli/task_commands'
require_relative '../../lib/vibe/errors'

class TaskCommandsTestHost
  include Vibe::TaskCommands
end

class TestTaskCommands < Minitest::Test
  def setup
    @host = TaskCommandsTestHost.new
  end

  def test_module_exists
    assert Vibe.const_defined?(:TaskCommands)
  end

  def test_help_subcommand
    out, = capture_io { @host.run_tasks_command(['help']) }
    assert_match(/Usage/, out)
    assert_match(/submit/, out)
    assert_match(/list/, out)
  end

  def test_nil_subcommand_shows_usage
    out, = capture_io { @host.run_tasks_command([]) }
    assert_match(/Usage/, out)
  end

  def test_dash_h_shows_usage
    out, = capture_io { @host.run_tasks_command(['-h']) }
    assert_match(/Usage/, out)
  end

  def test_unknown_subcommand_raises
    assert_raises(Vibe::ValidationError) { @host.run_tasks_command(['bogus']) }
  end

  def test_list_empty
    out, = capture_io { @host.run_tasks_command(['list']) }
    assert_match(/Background Tasks/, out)
  end

  def test_cleanup_runs
    out, = capture_io { @host.run_tasks_command(['cleanup']) }
    assert_match(/Task Cleanup/, out)
    assert_match(/Removed/, out)
  end

  def test_cleanup_with_custom_seconds
    out, = capture_io { @host.run_tasks_command(%w[cleanup 3600]) }
    assert_match(/1 hours/, out)
  end

  def test_submit_no_command_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_tasks_command(['submit']) }
    end
  end

  def test_status_no_id_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_tasks_command(['status']) }
    end
  end

  def test_cancel_no_id_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_tasks_command(['cancel']) }
    end
  end

  def test_status_unknown_id_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_tasks_command(%w[status nonexistent-id]) }
    end
  end

  def test_cancel_unknown_id_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_tasks_command(%w[cancel nonexistent-id]) }
    end
  end

  def test_parse_tasks_submit_options_command
    opts = @host.send(:parse_tasks_submit_options, ['echo hello'])
    assert_equal 'echo hello', opts[:command]
    assert_equal :normal, opts[:priority]
  end

  def test_parse_tasks_submit_options_priority
    opts = @host.send(:parse_tasks_submit_options, ['--priority', 'high', 'echo hi'])
    assert_equal :high, opts[:priority]
    assert_equal 'echo hi', opts[:command]
  end

  def test_parse_tasks_submit_options_desc
    opts = @host.send(:parse_tasks_submit_options, ['-d', 'my task', 'echo hi'])
    assert_equal 'my task', opts[:description]
  end

  def test_parse_tasks_submit_options_timeout
    opts = @host.send(:parse_tasks_submit_options, ['-t', '30', 'echo hi'])
    assert_equal 30, opts[:timeout]
  end

  def test_parse_tasks_list_options_status
    opts = @host.send(:parse_tasks_list_options, ['--status', 'running'])
    assert_equal 'running', opts[:status]
  end

  def test_parse_tasks_list_options_priority
    opts = @host.send(:parse_tasks_list_options, ['-p', 'high'])
    assert_equal :high, opts[:priority]
  end

  def test_submit_runs
    out, = capture_io { @host.run_tasks_command(['submit', 'echo hello']) }
    assert_match(/Task submitted/, out)
    assert_match(/echo hello/, out)
  end
end
