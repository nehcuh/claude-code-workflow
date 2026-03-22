# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'yaml'
require_relative '../../lib/vibe/integration_recommendations'
require_relative '../../lib/vibe/platform_utils'

class IntegrationRecommendationsTestHost
  include Vibe::IntegrationRecommendations
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
    { ready: false, installed: false }
  end

  def verify_gstack
    { ready: false, installed: false }
  end

  def load_integration_config(_name)
    nil
  end

  def install_integration(_name, _config)
    true
  end

  def ask_yes_no(_question)
    false
  end
end

class TestIntegrationRecommendations < Minitest::Test
  def setup
    @repo_root = Dir.mktmpdir('vibe-recommendations-test')
    @host = IntegrationRecommendationsTestHost.new(@repo_root)
    setup_recommended_yaml
  end

  def teardown
    FileUtils.rm_rf(@repo_root) if @repo_root && File.exist?(@repo_root)
  end

  def setup_recommended_yaml
    core_dir = File.join(@repo_root, 'core', 'integrations')
    FileUtils.mkdir_p(core_dir)
    yaml_content = {
      'category_order' => %w[skill_packs tools],
      'categories' => {
        'skill_packs' => [
          { 'name' => 'superpowers', 'priority' => 'P1', 'reason' => 'Advanced workflows' }
        ],
        'tools' => [
          { 'name' => 'rtk', 'priority' => 'P2', 'reason' => 'Token optimization' }
        ]
      },
      'category_metadata' => {
        'skill_packs' => { 'icon' => '🎯', 'label' => 'Skill Packs', 'description' => 'Workflow skills' },
        'tools' => { 'icon' => '🔧', 'label' => 'Tools', 'description' => 'Dev tools' }
      }
    }
    File.write(File.join(core_dir, 'recommended.yaml'), yaml_content.to_yaml)
  end

  def test_module_exists
    assert Vibe.const_defined?(:IntegrationRecommendations)
  end

  def test_load_recommended_integrations_returns_hash
    result = @host.load_recommended_integrations
    assert result.is_a?(Hash)
    assert result.key?('categories')
  end

  def test_load_recommended_integrations_returns_nil_when_missing
    @host.repo_root = '/nonexistent/path'
    result = @host.load_recommended_integrations
    assert_nil result
  end

  def test_recommended_integration_list_returns_array
    result = @host.recommended_integration_list
    assert result.is_a?(Array)
    assert !result.empty?
  end

  def test_recommended_integration_list_contains_names
    result = @host.recommended_integration_list
    names = result.map { |i| i['name'] }
    assert_includes names, 'superpowers'
    assert_includes names, 'rtk'
  end

  def test_integration_label_superpowers
    assert_equal 'Superpowers Skill Pack', @host.integration_label('superpowers')
  end

  def test_integration_label_rtk
    assert_equal 'RTK (Token Optimizer)', @host.integration_label('rtk')
  end

  def test_integration_label_gstack
    assert_equal 'gstack Skill Pack', @host.integration_label('gstack')
  end

  def test_integration_label_unknown
    assert_equal 'My Tool', @host.integration_label('my_tool')
  end

  def test_suggest_integrations_shows_missing
    out, = capture_io { @host.suggest_integrations }
    assert_match(/recommended/, out)
  end

  def test_suggest_integrations_all_ready
    @host.define_singleton_method(:verify_superpowers) { { ready: true } }
    @host.define_singleton_method(:verify_rtk) { { ready: true } }
    @host.define_singleton_method(:verify_gstack) { { ready: true } }
    out, = capture_io { @host.suggest_integrations }
    assert_match(/All recommended integrations are already installed/, out)
  end

  def test_suggest_integrations_no_config
    @host.repo_root = '/nonexistent/path'
    out, = capture_io { @host.suggest_integrations }
    assert_match(/Could not load recommendations/, out)
  end

  def test_display_integration_suggestion
    integration = { 'name' => 'superpowers', 'priority' => 'P1', 'reason' => 'Test reason' }
    out, = capture_io { @host.display_integration_suggestion(integration) }
    assert_match(/superpowers/, out)
    assert_match(/Essential/, out)
    assert_match(/Test reason/, out)
  end

  def test_display_integration_suggestion_p2
    integration = { 'name' => 'rtk', 'priority' => 'P2', 'reason' => 'Token savings' }
    out, = capture_io { @host.display_integration_suggestion(integration) }
    assert_match(/Recommended/, out)
  end

  def test_display_integration_suggestion_p3
    integration = { 'name' => 'gstack', 'priority' => 'P3', 'reason' => 'Optional tool' }
    out, = capture_io { @host.display_integration_suggestion(integration) }
    assert_match(/Optional/, out)
  end

  def test_detect_best_installation_method_unknown
    config = { 'installation_methods' => { 'manual' => {} } }
    result = @host.detect_best_installation_method('unknown_tool', config)
    assert_equal 'Manual', result
  end

  def test_detect_best_installation_method_empty_config
    config = { 'installation_methods' => {} }
    result = @host.detect_best_installation_method('unknown_tool', config)
    assert_nil result
  end

  def test_install_recommended_no_config
    @host.repo_root = '/nonexistent/path'
    out, = capture_io { @host.install_recommended }
    assert_match(/Could not load recommendations/, out)
  end

  def test_install_recommended_all_ready
    @host.define_singleton_method(:verify_superpowers) { { ready: true } }
    @host.define_singleton_method(:verify_rtk) { { ready: true } }
    @host.define_singleton_method(:verify_gstack) { { ready: true } }
    out, = capture_io { @host.install_recommended }
    assert_match(/All recommended integrations are already installed/, out)
  end

  def test_get_recommended_integration_list_alias
    assert_equal @host.recommended_integration_list, @host.get_recommended_integration_list
  end
end
