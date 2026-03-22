# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative '../../lib/vibe/integration_setup'
require_relative '../../lib/vibe/platform_utils'

class IntegrationSetupTestHost
  include Vibe::IntegrationSetup
  include Vibe::PlatformUtils

  attr_accessor :repo_root, :target_platform

  def initialize(repo_root)
    @repo_root = repo_root
    @target_platform = 'claude-code'
  end

  def verify_superpowers
    { ready: false, installed: false }
  end

  def verify_rtk
    { ready: false, installed: false, hook_configured: false, binary: nil }
  end

  def verify_gstack
    { ready: false, installed: false }
  end

  def recommended_integration_list
    []
  end

  def load_integration_config(_name)
    { 'description' => 'Test integration', 'benefits' => ['Benefit 1'] }
  end

  def display_summary; end

  def pending_integrations
    []
  end

  def ask_yes_no(_question)
    false
  end

  def ensure_interactive_setup_available!; end

  def install_superpowers(_config); end

  def install_rtk_interactive(_config = nil); end

  def configure_rtk_hook; end
end

class TestIntegrationSetup < Minitest::Test
  def setup
    @repo_root = Dir.mktmpdir('vibe-setup-test')
    @host = IntegrationSetupTestHost.new(@repo_root)
  end

  def teardown
    FileUtils.rm_rf(@repo_root) if @repo_root && File.exist?(@repo_root)
  end

  def test_module_exists
    assert Vibe.const_defined?(:IntegrationSetup)
  end

  def test_module_includes_platform_utils
    assert Vibe::IntegrationSetup.include?(Vibe::PlatformUtils)
  end

  def test_setup_status_message_superpowers_ready
    info = { ready: true, method: 'symlink' }
    result = @host.setup_status_message('superpowers', info)
    assert_match(/Already installed/, result)
  end

  def test_setup_status_message_superpowers_not_installed
    info = { ready: false, installed: false }
    result = @host.setup_status_message('superpowers', info)
    assert_equal 'Not installed', result
  end

  def test_setup_status_message_rtk_ready
    info = { ready: true, installed: true, hook_configured: true }
    result = @host.setup_status_message('rtk', info)
    assert_match(/Already installed/, result)
  end

  def test_setup_status_message_rtk_installed_no_hook
    info = { ready: false, installed: true, hook_configured: false }
    result = @host.setup_status_message('rtk', info)
    assert_match(/hook not configured/, result)
  end

  def test_setup_status_message_rtk_hook_no_binary
    info = { ready: false, installed: false, hook_configured: true }
    result = @host.setup_status_message('rtk', info)
    assert_match(/binary was not found/, result)
  end

  def test_setup_status_message_rtk_not_installed
    info = { ready: false, installed: false, hook_configured: false }
    result = @host.setup_status_message('rtk', info)
    assert_equal 'Not installed', result
  end

  def test_setup_status_message_gstack_ready
    info = { ready: true, location: '/some/path' }
    result = @host.setup_status_message('gstack', info)
    assert_match(/Already installed/, result)
  end

  def test_setup_status_message_unknown
    info = { ready: false }
    result = @host.setup_status_message('unknown', info)
    assert_equal 'Not installed', result
  end

  def test_display_integration_description
    config = { 'description' => 'Test desc', 'benefits' => %w[Fast Easy] }
    out, = capture_io { @host.display_integration_description(config) }
    assert_match(/Test desc/, out)
    assert_match(/Fast/, out)
    assert_match(/Easy/, out)
  end

  def test_display_integration_description_no_benefits
    config = { 'description' => 'Test desc' }
    out, = capture_io { @host.display_integration_description(config) }
    assert_match(/Test desc/, out)
  end

  def test_setup_integration_unknown
    out, = capture_io { @host.setup_integration('unknown_tool', 'Unknown', 1, 1) }
    assert_match(/Unknown integration/, out)
  end

  def test_setup_integration_ready
    @host.define_singleton_method(:verify_superpowers) { { ready: true, method: 'symlink' } }
    out, = capture_io { @host.setup_integration('superpowers', 'Superpowers', 1, 1) }
    assert_match(/Already installed/, out)
  end

  def test_setup_integration_skipped
    out, = capture_io { @host.setup_integration('superpowers', 'Superpowers', 1, 1) }
    assert_match(/Skipped/, out)
  end

  def test_install_integration_unknown
    out, = capture_io { @host.install_integration('unknown', {}) }
    assert_match(/not implemented/, out)
  end

  def test_complete_integration_setup_rtk_with_binary
    info = { installed: true, hook_configured: false, binary: '/usr/bin/rtk' }
    out, = capture_io { @host.complete_integration_setup('rtk', info) }
    assert_match(%r{/usr/bin/rtk}, out)
  end

  def test_complete_integration_setup_rtk_no_binary
    info = { installed: true, hook_configured: false, binary: nil }
    out, = capture_io { @host.complete_integration_setup('rtk', info) }
    assert_match(/Not configured/, out)
  end
end
