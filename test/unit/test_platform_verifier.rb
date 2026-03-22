# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'json'
require_relative '../../lib/vibe/platform_verifier'
require_relative '../../lib/vibe/platform_utils'

class PlatformVerifierTestHost
  include Vibe::PlatformVerifier
  include Vibe::PlatformUtils

  attr_accessor :repo_root, :target_platform

  def initialize(repo_root)
    @repo_root = repo_root
    @target_platform = 'claude-code'
  end
end

class TestPlatformVerifier < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir('vibe-verifier-test')
    @host = PlatformVerifierTestHost.new(@tmpdir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
  end

  def test_module_exists
    assert Vibe.const_defined?(:PlatformVerifier)
  end

  def test_module_is_a_module
    assert Vibe::PlatformVerifier.is_a?(Module)
  end

  def test_module_includes_platform_utils
    assert Vibe::PlatformVerifier.include?(Vibe::PlatformUtils)
  end

  def test_module_has_required_methods
    %i[verify_platform_installation suggest_platform_setup verify_all_platforms].each do |m|
      assert Vibe::PlatformVerifier.instance_methods(false).include?(m)
    end
  end

  def test_verify_platform_installation_not_found
    # Use a platform whose destination won't exist in tmpdir
    @host.define_singleton_method(:default_global_destination) { |_| '/nonexistent/path' }
    out, = capture_io { @host.verify_platform_installation('claude-code') }
    assert_match(/not found/, out)
  end

  def test_verify_platform_installation_found_no_marker
    dest = File.join(@tmpdir, 'claude')
    FileUtils.mkdir_p(dest)
    @host.define_singleton_method(:default_global_destination) { |_| dest }
    out, = capture_io { @host.verify_platform_installation('claude-code') }
    assert_match(/found/, out)
  end

  def test_verify_platform_installation_found_with_marker
    dest = File.join(@tmpdir, 'claude')
    FileUtils.mkdir_p(dest)
    marker = File.join(dest, '.vibe-target.json')
    File.write(marker, JSON.generate('profile' => 'default', 'mode' => 'global'))
    @host.define_singleton_method(:default_global_destination) { |_| dest }
    out, = capture_io { @host.verify_platform_installation('claude-code') }
    assert_match(/found/, out)
    assert_match(/default/, out)
  end

  def test_suggest_platform_setup_output
    @host.define_singleton_method(:default_global_destination) { |_| '/some/path' }
    out, = capture_io { @host.suggest_platform_setup('claude-code') }
    assert_match(/Suggested setup/, out)
    assert_match(/vibe init/, out)
  end

  def test_verify_all_platforms_output
    @host.define_singleton_method(:default_global_destination) { |_| '/nonexistent' }
    out, = capture_io { @host.verify_all_platforms }
    assert_match(/Not installed/, out)
  end

  def test_verify_all_platforms_with_installed
    dest = File.join(@tmpdir, 'claude')
    FileUtils.mkdir_p(dest)
    @host.define_singleton_method(:default_global_destination) do |target|
      target == 'claude-code' ? dest : '/nonexistent'
    end
    out, = capture_io { @host.verify_all_platforms }
    assert_match(/Installed/, out)
  end
end
