# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/vibe/native_configs'
require_relative '../../lib/vibe/utils'

class TestNativeConfigs < Minitest::Test
  include Vibe::NativeConfigs
  include Vibe::Utils

  def test_base_claude_settings_config_has_permissions
    config = base_claude_settings_config
    assert config.key?('permissions')
    perms = config['permissions']
    assert_equal 'default', perms['defaultMode']
    assert perms['ask'].is_a?(Array)
    assert perms['deny'].is_a?(Array)
  end

  def test_base_claude_settings_deny_list
    deny = base_claude_settings_config['permissions']['deny']
    assert_includes deny, 'Bash(rm -rf:*)'
    assert_includes deny, 'Bash(shred:*)'
    assert_includes deny, 'Read(./.env)'
  end

  def test_base_claude_settings_ask_list
    ask = base_claude_settings_config['permissions']['ask']
    assert_includes ask, 'Bash(curl:*)'
    assert_includes ask, 'WebFetch'
  end

  def test_claude_settings_config_without_overlay
    manifest = {}
    config = claude_settings_config(manifest)
    assert config.key?('permissions')
  end

  def test_claude_settings_config_with_overlay
    manifest = {
      'native_config_overlay' => {
        'permissions' => { 'defaultMode' => 'strict' }
      }
    }
    config = claude_settings_config(manifest)
    assert_equal 'strict', config['permissions']['defaultMode']
  end

  def test_base_opencode_config_has_schema
    config = base_opencode_config
    assert_equal 'https://opencode.ai/config.json', config['$schema']
  end

  def test_base_opencode_config_has_instructions
    config = base_opencode_config
    assert config['instructions'].is_a?(Array)
    assert_includes config['instructions'], 'AGENTS.md'
  end

  def test_base_opencode_config_has_permissions
    config = base_opencode_config
    assert config.key?('permission')
    assert_equal 'allow', config['permission']['read']['*']
    assert_equal 'deny', config['permission']['read']['**/.env']
  end

  def test_base_opencode_config_bash_permissions
    config = base_opencode_config
    bash = config['permission']['bash']
    assert_equal 'ask', bash['*']
    assert_equal 'allow', bash['pwd']
    assert_equal 'deny', bash['rm *']
  end

  def test_opencode_config_without_overlay
    manifest = {}
    config = opencode_config(manifest)
    assert config.key?('$schema')
  end

  def test_opencode_config_with_overlay
    manifest = {
      'native_config_overlay' => {
        'permission' => { 'bash' => { '*' => 'deny' } }
      }
    }
    config = opencode_config(manifest)
    assert_equal 'deny', config['permission']['bash']['*']
  end

  def test_opencode_project_config_has_minimal_instructions
    manifest = {}
    config = opencode_project_config(manifest)
    assert config['instructions'].is_a?(Array)
    assert_includes config['instructions'], 'AGENTS.md'
  end

  def test_opencode_project_config_with_overlay
    manifest = {
      'native_config_overlay' => {
        'instructions' => ['custom.md']
      }
    }
    config = opencode_project_config(manifest)
    assert_includes config['instructions'], 'custom.md'
  end
end
