# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../../lib/vibe/cli/checkpoint_commands'
require_relative '../../lib/vibe/errors'

class CheckpointCommandsTestHost
  include Vibe::CheckpointCommands
end

class TestCheckpointCommands < Minitest::Test
  def setup
    @host = CheckpointCommandsTestHost.new
    @tmpdir = Dir.mktmpdir('vibe-checkpoint-test')
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_module_exists
    assert Vibe.const_defined?(:CheckpointCommands)
  end

  def test_help_subcommand
    out, = capture_io { @host.run_checkpoint_command(['help']) }
    assert_match(/Usage/, out)
    assert_match(/create/, out)
    assert_match(/rollback/, out)
  end

  def test_nil_subcommand_shows_usage
    out, = capture_io { @host.run_checkpoint_command([]) }
    assert_match(/Usage/, out)
  end

  def test_dash_h_shows_usage
    out, = capture_io { @host.run_checkpoint_command(['-h']) }
    assert_match(/Usage/, out)
  end

  def test_unknown_subcommand_raises
    assert_raises(Vibe::ValidationError) { @host.run_checkpoint_command(['bogus']) }
  end

  def test_list_runs
    out, = capture_io { @host.run_checkpoint_command(['list']) }
    assert_match(/Checkpoints/, out)
  end

  def test_cleanup_runs
    out, = capture_io { @host.run_checkpoint_command(['cleanup']) }
    assert_match(/Checkpoint Cleanup/, out)
    assert_match(/Removed/, out)
  end

  def test_cleanup_with_count
    out, = capture_io { @host.run_checkpoint_command(%w[cleanup 5]) }
    assert_match(/Kept: 5/, out)
  end

  def test_create_no_description_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_checkpoint_command(['create']) }
    end
  end

  def test_create_no_files_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_checkpoint_command(['create', 'my checkpoint']) }
    end
  end

  def test_create_missing_file_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_checkpoint_command(['create', 'desc', '/nonexistent/file.rb']) }
    end
  end

  def test_create_with_real_file
    path = File.join(@tmpdir, 'test.rb')
    File.write(path, 'puts "hello"')
    out, = capture_io { @host.run_checkpoint_command(['create', 'test checkpoint', path]) }
    assert_match(/Checkpoint created/, out)
    assert_match(/test checkpoint/, out)
  end

  def test_rollback_no_id_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_checkpoint_command(['rollback']) }
    end
  end

  def test_compare_missing_ids_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_checkpoint_command(%w[compare id1]) }
    end
  end

  def test_delete_no_id_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_checkpoint_command(['delete']) }
    end
  end

  def test_delete_nonexistent_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_checkpoint_command(%w[delete nonexistent-id]) }
    end
  end

  def test_parse_duration_hours
    assert_equal 3600, @host.send(:parse_duration, '1h')
  end

  def test_parse_duration_days
    assert_equal 86_400, @host.send(:parse_duration, '1d')
  end

  def test_parse_duration_weeks
    assert_equal 604_800, @host.send(:parse_duration, '1w')
  end

  def test_parse_duration_invalid
    assert_nil @host.send(:parse_duration, 'invalid')
  end

  def test_parse_checkpoint_list_options_limit
    opts = @host.send(:parse_checkpoint_list_options, ['--limit', '5'])
    assert_equal 5, opts[:limit]
  end

  def test_parse_checkpoint_rollback_options_dry_run
    opts = @host.send(:parse_checkpoint_rollback_options, ['--dry-run', 'abc123'])
    assert opts[:dry_run]
    assert_equal 'abc123', opts[:id]
  end
end
