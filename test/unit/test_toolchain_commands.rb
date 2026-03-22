# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../../lib/vibe/cli/toolchain_commands'
require_relative '../../lib/vibe/errors'

class ToolchainCommandsTestHost
  include Vibe::ToolchainCommands
end

class TestToolchainCommands < Minitest::Test
  def setup
    @host = ToolchainCommandsTestHost.new
    @tmpdir = Dir.mktmpdir('vibe-toolchain-test')
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_module_exists
    assert Vibe.const_defined?(:ToolchainCommands)
  end

  def test_help_subcommand
    out, = capture_io { @host.run_toolchain_command(['help']) }
    assert_match(/Usage/, out)
    assert_match(/detect/, out)
    assert_match(/suggest/, out)
  end

  def test_nil_subcommand_shows_usage
    out, = capture_io { @host.run_toolchain_command([]) }
    assert_match(/Usage/, out)
  end

  def test_dash_h_shows_usage
    out, = capture_io { @host.run_toolchain_command(['-h']) }
    assert_match(/Usage/, out)
  end

  def test_unknown_subcommand_raises
    assert_raises(Vibe::ValidationError) do
      @host.run_toolchain_command(['bogus'])
    end
  end

  def test_detect_with_dir
    File.write(File.join(@tmpdir, 'package-lock.json'), '{}')
    out, = capture_io { @host.run_toolchain_command(['detect', @tmpdir]) }
    assert_match(/Toolchain Detection/, out)
    assert_match(/Primary language/, out)
  end

  def test_detect_empty_dir
    out, = capture_io { @host.run_toolchain_command(['detect', @tmpdir]) }
    assert_match(/Toolchain Detection/, out)
    assert_match(/unknown/, out)
  end

  def test_suggest_with_dir
    File.write(File.join(@tmpdir, 'package-lock.json'), '{}')
    out, = capture_io { @host.run_toolchain_command(['suggest', @tmpdir]) }
    assert_match(/Suggested Commands/, out)
  end

  def test_suggest_empty_dir
    out, = capture_io { @host.run_toolchain_command(['suggest', @tmpdir]) }
    assert_match(/No toolchain detected/, out)
  end

  def test_detect_shows_package_managers
    File.write(File.join(@tmpdir, 'Gemfile'), '')
    File.write(File.join(@tmpdir, 'Gemfile.lock'), '')
    out, = capture_io { @host.run_toolchain_command(['detect', @tmpdir]) }
    assert_match(/bundler/i, out)
  end

  def test_detect_shows_build_tools
    File.write(File.join(@tmpdir, 'Makefile'), '')
    out, = capture_io { @host.run_toolchain_command(['detect', @tmpdir]) }
    assert_match(/make/i, out)
  end
end
