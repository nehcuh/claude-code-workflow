# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../../lib/vibe/rtk_installer'
require_relative '../../lib/vibe/user_interaction'

class RtkInstallerTestHost
  include Vibe::RtkInstaller
  include Vibe::UserInteraction

  attr_accessor :repo_root

  def initialize(repo_root)
    @repo_root = repo_root
  end

  def load_integration_config(_name)
    { 'installation_methods' => { 'manual' => { 'url' => 'https://example.com/releases' } } }
  end

  def reset_integration_status!; end

  def configure_rtk_hook
    true
  end

  def install_rtk_via_homebrew
    false
  end

  def read_yaml_abs(_path)
    { 'installation_methods' => { 'cargo' => { 'command' => 'cargo install rtk' } } }
  end
end

class TestRtkInstaller < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir('vibe-rtk-test')
    @host = RtkInstallerTestHost.new(@tmpdir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_module_exists
    assert Vibe.const_defined?(:RtkInstaller)
  end

  def test_install_rtk_manual_guide
    config = { 'installation_methods' => { 'manual' => { 'url' => 'https://example.com/releases' } } }
    out, = capture_io { @host.install_rtk_manual_guide(config) }
    assert_match(/Manual installation steps/, out)
    assert_match(%r{https://example.com/releases}, out)
    assert_match(/rtk init --global/, out)
  end

  def test_install_rtk_manual_guide_default_url
    config = { 'installation_methods' => {} }
    out, = capture_io { @host.install_rtk_manual_guide(config) }
    assert_match(/github.com/, out)
  end

  def test_configure_rtk_after_install_skipped
    @host.define_singleton_method(:ask_yes_no) { |_| false }
    out, = capture_io { @host.configure_rtk_after_install }
    assert_match(/Skipped hook configuration/, out)
  end

  def test_configure_rtk_after_install_success
    @host.define_singleton_method(:ask_yes_no) { |_| true }
    @host.define_singleton_method(:configure_rtk_hook) { true }
    out, = capture_io { @host.configure_rtk_after_install }
    assert_match(/Hook configured successfully/, out)
  end

  def test_configure_rtk_after_install_failure
    @host.define_singleton_method(:ask_yes_no) { |_| true }
    @host.define_singleton_method(:configure_rtk_hook) { false }
    out, = capture_io { @host.configure_rtk_after_install }
    assert_match(/Hook configuration failed/, out)
  end

  def test_install_rtk_via_homebrew_interactive_no_brew
    @host.define_singleton_method(:system) { |*_| false }
    out, = capture_io { @host.install_rtk_via_homebrew_interactive }
    assert_match(/Homebrew not found/, out)
  end
end
