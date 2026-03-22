# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require_relative '../../lib/vibe/integration_verifier'
require_relative '../../lib/vibe/platform_utils'

class IntegrationVerifierTestHost
  include Vibe::IntegrationVerifier
  include Vibe::PlatformUtils

  attr_accessor :repo_root, :target_platform

  def initialize(repo_root)
    @repo_root = repo_root
    @target_platform = 'claude-code'
  end

  def integration_status
    {
      superpowers: { installed: false, ready: false, skills_count: 0, location: nil },
      rtk: { installed: false, ready: false, hook_configured: false, binary: nil, version: nil },
      gstack: { installed: false, ready: false, skills_count: 0, location: nil, version: nil }
    }
  end

  def all_integrations_ready?
    integration_status.values.all? { |info| info[:ready] }
  end
end

class TestIntegrationVerifier < Minitest::Test
  def setup
    @repo_root = Dir.mktmpdir('vibe-verifier-test')
    @host = IntegrationVerifierTestHost.new(@repo_root)
  end

  def teardown
    FileUtils.rm_rf(@repo_root) if @repo_root && File.exist?(@repo_root)
  end

  def test_module_exists
    assert Vibe.const_defined?(:IntegrationVerifier)
  end

  def test_module_is_a_module
    assert Vibe::IntegrationVerifier.is_a?(Module)
  end

  def test_verify_integration_display_ready
    info = { ready: true, location: '/some/path', skills_count: 5 }
    out, = capture_io { @host.verify_integration_display(:superpowers, info) }
    assert_match(/✓/, out)
    assert_match(/Superpowers/, out)
    assert_match(/Ready/, out)
  end

  def test_verify_integration_display_not_installed
    info = { ready: false, installed: false, hook_configured: false }
    out, = capture_io { @host.verify_integration_display(:superpowers, info) }
    assert_match(/✗/, out)
    assert_match(/Not installed/, out)
  end

  def test_verify_integration_display_rtk_installed_no_hook
    info = { ready: false, installed: true, hook_configured: false, binary: '/usr/bin/rtk', version: '1.0' }
    out, = capture_io { @host.verify_integration_display(:rtk, info) }
    assert_match(/!/, out)
    assert_match(/RTK/, out)
    assert_match(/hook not configured/, out)
  end

  def test_verify_integration_display_rtk_hook_no_binary
    info = { ready: false, installed: false, hook_configured: true, binary: nil, version: nil }
    out, = capture_io { @host.verify_integration_display(:rtk, info) }
    assert_match(/!/, out)
    assert_match(/binary was not found/, out)
  end

  def test_verify_integration_display_gstack_ready
    info = { ready: true, location: '/some/path', skills_count: 10, version: '1.0' }
    out, = capture_io { @host.verify_integration_display(:gstack, info) }
    assert_match(/✓/, out)
    assert_match(/gstack/, out)
  end

  def test_display_summary_not_installed
    out, = capture_io { @host.display_summary }
    assert_match(/Superpowers/, out)
    assert_match(/RTK/, out)
    assert_match(/gstack/, out)
  end

  def test_display_summary_ready
    @host.define_singleton_method(:integration_status) do
      {
        superpowers: { ready: true, installed: true },
        rtk: { ready: true, installed: true, hook_configured: true },
        gstack: { ready: true, installed: true }
      }
    end
    out, = capture_io { @host.display_summary }
    assert_match(/✓ Superpowers: Ready/, out)
    assert_match(/✓ RTK: Ready/, out)
    assert_match(/✓ gstack: Ready/, out)
  end

  def test_display_summary_rtk_installed_no_hook
    @host.define_singleton_method(:integration_status) do
      {
        superpowers: { ready: false, installed: false },
        rtk: { ready: false, installed: true, hook_configured: false },
        gstack: { ready: false, installed: false }
      }
    end
    out, = capture_io { @host.display_summary }
    assert_match(/hook not configured/, out)
  end

  def test_verify_integrations_all_ready
    @host.define_singleton_method(:integration_status) do
      {
        superpowers: { ready: true, installed: true, skills_count: 5, location: '/path' },
        rtk: { ready: true, installed: true, hook_configured: true, binary: '/bin/rtk', version: '1.0' },
        gstack: { ready: true, installed: true, skills_count: 3, location: '/path', version: '1.0' }
      }
    end
    @host.define_singleton_method(:all_integrations_ready?) { true }
    out, = capture_io { @host.verify_integrations }
    assert_match(/All integrations verified/, out)
  end

  def test_verify_integrations_some_missing
    out, = capture_io { @host.verify_integrations }
    assert_match(/Some integrations still need/, out)
  end
end
