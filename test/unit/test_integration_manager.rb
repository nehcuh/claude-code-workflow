# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'json'
require_relative '../../lib/vibe/integration_manager'
require_relative '../../lib/vibe/platform_utils'

# Test host that includes the module without side effects
class IntegrationManagerTestHost
  include Vibe::IntegrationManager
  include Vibe::PlatformUtils

  attr_accessor :repo_root, :target_platform

  def initialize(repo_root)
    @repo_root = repo_root
    @target_platform = 'claude-code'
  end

  # Stub out external callers
  def integration_status
    {
      superpowers: { installed: false, ready: false, skills_count: 0, location: nil },
      rtk: { installed: false, ready: false, hook_configured: false, binary: nil, version: nil },
      gstack: { installed: false, ready: false, skills_count: 0, location: nil, version: nil }
    }
  end

  def ask_yes_no(_question)
    false
  end

  def install_rtk_interactive
    false
  end

  def configure_rtk_hook; end
end

class TestIntegrationManager < Minitest::Test
  def setup
    @repo_root = Dir.mktmpdir('vibe-im-test')
    @host = IntegrationManagerTestHost.new(@repo_root)
  end

  def teardown
    FileUtils.rm_rf(@repo_root) if @repo_root && File.exist?(@repo_root)
  end

  # --- Module wiring ---

  def test_module_exists
    assert Vibe.const_defined?(:IntegrationManager)
  end

  def test_module_is_a_module
    assert Vibe::IntegrationManager.is_a?(Module)
  end

  # --- classify_integrations ---

  def test_classify_integrations_all_missing
    status = {
      superpowers: { installed: false, ready: false },
      rtk: { installed: false, ready: false },
      gstack: { installed: false, ready: false }
    }
    missing, pending = @host.send(:classify_integrations, status)
    assert_equal %i[superpowers rtk gstack], missing
    assert_empty pending
  end

  def test_classify_integrations_all_ready
    status = {
      superpowers: { installed: true, ready: true },
      rtk: { installed: true, ready: true },
      gstack: { installed: true, ready: true }
    }
    missing, pending = @host.send(:classify_integrations, status)
    assert_empty missing
    assert_empty pending
  end

  def test_classify_integrations_installed_but_not_ready
    status = {
      superpowers: { installed: true, ready: false },
      rtk: { installed: true, ready: false }
    }
    missing, pending = @host.send(:classify_integrations, status)
    assert_empty missing
    assert_equal %i[superpowers rtk], pending
  end

  def test_classify_integrations_mixed
    status = {
      superpowers: { installed: false, ready: false },
      rtk: { installed: true, ready: false },
      gstack: { installed: true, ready: true }
    }
    missing, pending = @host.send(:classify_integrations, status)
    assert_equal [:superpowers], missing
    assert_equal [:rtk], pending
  end

  # --- print_integration_summary ---

  def test_print_integration_summary_ready
    status = { superpowers: { ready: true, installed: true } }
    out, = capture_io { @host.send(:print_integration_summary, status) }
    assert_match(/✓/, out)
    assert_match(/Superpowers.*Ready/, out)
  end

  def test_print_integration_summary_not_installed
    status = { superpowers: { ready: false, installed: false } }
    out, = capture_io { @host.send(:print_integration_summary, status) }
    assert_match(/✗/, out)
    assert_match(/Not installed/, out)
  end

  def test_print_integration_summary_installed_not_ready
    status = { rtk: { ready: false, installed: true } }
    out, = capture_io { @host.send(:print_integration_summary, status) }
    assert_match(/⚠/, out)
    assert_match(/Installed but needs configuration/, out)
  end

  def test_print_integration_summary_unknown_name_capitalised
    status = { myplugin: { ready: false, installed: false } }
    out, = capture_io { @host.send(:print_integration_summary, status) }
    assert_match(/Myplugin/, out)
  end

  def test_print_integration_summary_all_three_labels
    status = {
      superpowers: { ready: true, installed: true },
      rtk: { ready: true, installed: true },
      gstack: { ready: false, installed: false }
    }
    out, = capture_io { @host.send(:print_integration_summary, status) }
    assert_match(/Superpowers/, out)
    assert_match(/RTK/, out)
    assert_match(/gstack/, out)
  end

  # --- platform_label ---

  def test_platform_label_claude_code
    assert_equal 'Claude Code', @host.send(:platform_label, 'claude-code')
  end

  def test_platform_label_opencode
    assert_equal 'OpenCode', @host.send(:platform_label, 'opencode')
  end

  def test_platform_label_unknown_capitalises
    assert_equal 'My Platform', @host.send(:platform_label, 'my-platform')
  end

  def test_platform_label_single_word
    assert_equal 'Custom', @host.send(:platform_label, 'custom')
  end

  # --- check_environment (I/O only, no side effects) ---

  def test_check_environment_with_platform
    out, = capture_io { @host.check_environment('claude-code') }
    assert_match(/Claude Code/, out)
  end

  def test_check_environment_without_platform
    # Use a fresh host with no target_platform set
    host = IntegrationManagerTestHost.new(@repo_root)
    host.instance_variable_set(:@target_platform, nil)
    out, = capture_io { host.check_environment }
    assert_match(/No target platform specified/, out)
  end

  def test_check_environment_prints_header
    out, = capture_io { @host.check_environment }
    assert_match(/Checking your environment/, out)
  end

  def test_check_environment_with_marker_file
    Dir.mktmpdir('vibe-env-test') do |dir|
      marker = File.join(dir, '.vibe-target.json')
      File.write(marker, JSON.generate({ 'target' => 'claude-code' }))
      # Stub Dir.pwd inside the test
      Dir.chdir(dir) do
        out, = capture_io { @host.check_environment('claude-code') }
        assert_match(/Current target.*claude-code/, out)
      end
    end
  end

  def test_check_environment_without_marker_file
    Dir.mktmpdir('vibe-nomarker-test') do |dir|
      Dir.chdir(dir) do
        out, = capture_io { @host.check_environment }
        assert_match(/No target marker found/, out)
      end
    end
  end

  # --- handle_superpowers (non-interactive path) ---

  def test_handle_superpowers_missing_non_interactive
    out, = capture_io do
      @host.send(:handle_superpowers, 'claude-code', [:superpowers], [], false)
    end
    assert_match(/Superpowers Skill Pack not detected/, out)
    assert_match(/interactive terminal/, out)
  end

  def test_handle_superpowers_pending_non_interactive
    out, = capture_io do
      @host.send(:handle_superpowers, 'claude-code', [], [:superpowers], false)
    end
    assert_match(/cloned but not linked/, out)
    assert_match(/interactive terminal/, out)
  end

  def test_handle_superpowers_nothing_to_do
    out, = capture_io do
      @host.send(:handle_superpowers, 'claude-code', [], [], false)
    end
    assert_empty out
  end

  # --- handle_gstack (non-interactive path) ---

  def test_handle_gstack_missing_non_interactive
    out, = capture_io do
      @host.send(:handle_gstack, 'claude-code', [:gstack], false)
    end
    assert_match(/gstack Skill Pack not detected/, out)
    assert_match(/interactive terminal/, out)
  end

  def test_handle_gstack_not_in_missing_list_does_nothing
    out, = capture_io do
      @host.send(:handle_gstack, 'claude-code', [], false)
    end
    assert_empty out
  end

  # --- handle_rtk (non-interactive path) ---

  def test_handle_rtk_missing_non_interactive
    out, = capture_io do
      @host.send(:handle_rtk, 'claude-code', [:rtk], [], {}, false)
    end
    assert_match(/RTK Token Optimizer not detected/, out)
    assert_match(/interactive terminal/, out)
  end

  def test_handle_rtk_nothing_to_do
    out, = capture_io do
      @host.send(:handle_rtk, 'claude-code', [], [], {}, false)
    end
    assert_empty out
  end

  def test_handle_rtk_pending_installed_hook_not_configured
    status = {
      rtk: { installed: true, ready: false, hook_configured: false }
    }
    out, = capture_io do
      @host.send(:handle_rtk, 'claude-code', [], [:rtk], status, false)
    end
    assert_match(/hook not configured/, out)
  end

  # --- check_and_suggest_integrations (full flow, non-interactive) ---

  def test_check_and_suggest_all_missing_non_interactive
    out, = capture_io do
      @host.check_and_suggest_integrations('claude-code')
    end
    assert_match(/Optional Integrations/, out)
    assert_match(/Superpowers Skill Pack not detected/, out)
    assert_match(/RTK Token Optimizer not detected/, out)
    assert_match(/gstack Skill Pack not detected/, out)
  end

  def test_check_and_suggest_sets_target_platform
    capture_io { @host.check_and_suggest_integrations('opencode') }
    assert_equal 'opencode', @host.target_platform
  end

  def test_check_and_suggest_returns_early_when_all_ready
    # Override integration_status to return all ready
    host = IntegrationManagerTestHost.new(@repo_root)
    def host.integration_status
      {
        superpowers: { installed: true, ready: true },
        rtk: { installed: true, ready: true },
        gstack: { installed: true, ready: true }
      }
    end
    out, = capture_io { host.check_and_suggest_integrations('claude-code') }
    # Should print summary but not suggest any installs
    refute_match(/not detected/, out)
  end
end
