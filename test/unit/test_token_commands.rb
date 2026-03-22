# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../../lib/vibe/cli/token_commands'
require_relative '../../lib/vibe/errors'

class TokenCommandsTestHost
  include Vibe::TokenCommands
end

class TestTokenCommands < Minitest::Test
  def setup
    @host = TokenCommandsTestHost.new
    @tmpdir = Dir.mktmpdir('vibe-token-test')
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_module_exists
    assert Vibe.const_defined?(:TokenCommands)
  end

  def test_help_subcommand
    out, = capture_io { @host.run_token_command(['help']) }
    assert_match(/Usage/, out)
    assert_match(/analyze/, out)
    assert_match(/optimize/, out)
  end

  def test_nil_subcommand_shows_usage
    out, = capture_io { @host.run_token_command([]) }
    assert_match(/Usage/, out)
  end

  def test_dash_h_shows_usage
    out, = capture_io { @host.run_token_command(['-h']) }
    assert_match(/Usage/, out)
  end

  def test_unknown_subcommand_raises
    assert_raises(Vibe::ValidationError) { @host.run_token_command(['bogus']) }
  end

  def test_stats_no_file
    @host.define_singleton_method(:token_stats_path) { '/nonexistent/path/token-stats.json' }
    out, = capture_io { @host.run_token_command(['stats']) }
    assert_match(/Token Usage Statistics/, out)
    assert_match(/No stats recorded yet/, out)
  ensure
    @host.singleton_class.remove_method(:token_stats_path)
  end

  def test_analyze_no_file_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_token_command(['analyze']) }
    end
  end

  def test_analyze_nonexistent_file_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_token_command(['analyze', '/nonexistent/file.md']) }
    end
  end

  def test_analyze_file
    path = File.join(@tmpdir, 'test.md')
    File.write(path, "# Hello\n\nThis is a test file with some content.\n")
    out, = capture_io { @host.run_token_command(['analyze', path]) }
    assert_match(/Token Analysis/, out)
    assert_match(/Total tokens/, out)
  end

  def test_optimize_no_file_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_token_command(['optimize']) }
    end
  end

  def test_optimize_nonexistent_file_exits
    assert_raises(SystemExit) do
      capture_io { @host.run_token_command(['optimize', '/nonexistent/file.md']) }
    end
  end

  def test_optimize_preview
    path = File.join(@tmpdir, 'test.md')
    File.write(path, "# Hello\n\nThis is a test.\n\nThis is a test.\n")
    out, = capture_io { @host.run_token_command(['optimize', path]) }
    assert_match(/Token Optimization/, out)
    assert_match(/Original tokens/, out)
  end

  def test_optimize_to_output_file
    path = File.join(@tmpdir, 'input.md')
    out_path = File.join(@tmpdir, 'output.md')
    File.write(path, "# Hello\n\nContent here.\n")
    capture_io { @host.run_token_command(['optimize', path, '--output', out_path]) }
    assert File.exist?(out_path)
  end

  def test_optimize_in_place
    path = File.join(@tmpdir, 'inplace.md')
    File.write(path, "# Hello\n\nContent here.\n")
    capture_io { @host.run_token_command(['optimize', path, '--in-place']) }
    assert File.exist?(path)
  end

  def test_parse_token_optimize_options_file
    opts = @host.send(:parse_token_optimize_options, ['/some/file.md'])
    assert_equal '/some/file.md', opts[:file]
    refute opts[:in_place]
  end

  def test_parse_token_optimize_options_flags
    opts = @host.send(:parse_token_optimize_options, ['-r', '-c', '-i', 'file.md'])
    assert opts[:remove_redundancies]
    assert opts[:compress_whitespace]
    assert opts[:in_place]
  end

  def test_parse_token_optimize_options_sections
    opts = @host.send(:parse_token_optimize_options, ['--sections', 'Memory,Skills', 'file.md'])
    assert_equal %w[Memory Skills], opts[:sections]
  end
end
