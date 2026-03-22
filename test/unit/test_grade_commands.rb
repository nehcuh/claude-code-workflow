# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../../lib/vibe/cli/grade_commands'
require_relative '../../lib/vibe/errors'

class GradeCommandsTestHost
  include Vibe::GradeCommands
end

class TestGradeCommands < Minitest::Test
  def setup
    @host = GradeCommandsTestHost.new
  end

  def test_module_exists
    assert Vibe.const_defined?(:GradeCommands)
  end

  def test_help_subcommand
    out, = capture_io { @host.run_grade_command(['help']) }
    assert_match(/Usage/, out)
    assert_match(/run/, out)
    assert_match(/summary/, out)
  end

  def test_nil_subcommand_shows_usage
    out, = capture_io { @host.run_grade_command([]) }
    assert_match(/Usage/, out)
  end

  def test_dash_h_shows_usage
    out, = capture_io { @host.run_grade_command(['-h']) }
    assert_match(/Usage/, out)
  end

  def test_unknown_subcommand_raises
    assert_raises(Vibe::ValidationError) do
      @host.run_grade_command(['bogus'])
    end
  end

  def test_summary_runs
    out, = capture_io { @host.run_grade_command(['summary']) }
    assert_match(/Grading Summary/, out)
    assert_match(/Total runs/, out)
  end

  def test_colorize_grade_pass
    assert_match(/PASS/, @host.send(:colorize_grade, 'pass'))
  end

  def test_colorize_grade_fail
    assert_match(/FAIL/, @host.send(:colorize_grade, 'fail'))
  end

  def test_colorize_grade_warning
    assert_match(/WARNING/, @host.send(:colorize_grade, 'warning'))
  end

  def test_colorize_grade_skip
    assert_match(/SKIP/, @host.send(:colorize_grade, 'skip'))
  end

  def test_colorize_grade_unknown
    assert_equal 'other', @host.send(:colorize_grade, 'other')
  end

  def test_parse_grade_run_options_type_and_command
    opts = @host.send(:parse_grade_run_options, ['--type', 'unit_test', 'ruby test/'])
    assert_equal 'unit_test', opts[:type]
    assert_equal 'ruby test/', opts[:command]
  end

  def test_parse_grade_run_options_desc
    opts = @host.send(:parse_grade_run_options, ['-d', 'my desc', '--type', 'linter', 'rubocop'])
    assert_equal 'my desc', opts[:description]
  end

  def test_parse_grade_run_options_dir
    opts = @host.send(:parse_grade_run_options, ['--dir', '/tmp', '--type', 'linter', 'rubocop'])
    assert_equal '/tmp', opts[:working_dir]
  end

  def test_run_grade_run_missing_args_exits
    assert_raises(SystemExit) do
      capture_io { @host.send(:run_grade_run, []) }
    end
  end

  def test_pass_at_k_missing_config_exits
    assert_raises(SystemExit) do
      capture_io { @host.send(:run_grade_pass_at_k, []) }
    end
  end

  def test_pass_at_k_nonexistent_file_exits
    assert_raises(SystemExit) do
      capture_io { @host.send(:run_grade_pass_at_k, ['/nonexistent/file.yaml']) }
    end
  end
end
