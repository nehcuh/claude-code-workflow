# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/vibe/skill_router_commands'
require_relative '../../lib/vibe/skill_router'
require_relative '../../lib/vibe/user_interaction'
require 'tmpdir'
require 'fileutils'

class TestSkillRouterCommands < Minitest::Test
  include Vibe::SkillRouterCommands

  def setup
    @tmpdir = Dir.mktmpdir
    @original_dir = Dir.pwd
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
    Dir.chdir(@original_dir)
  end

  def test_cmd_route_empty_argv_returns_1
    output, _ = capture_io { cmd_route([]) }
    assert_match(/Usage/, output)
  end

  def test_cmd_route_help_flag
    output, _ = capture_io { cmd_route(%w[--help]) }
    # --help is treated as user input, routed to skill matching
    assert_match(/输入/, output)
  end

  def test_cmd_route_with_input
    output, _ = capture_io { cmd_route(%w[review my code]) }
    assert_match(/输入/, output)
  end

  def test_cmd_route_with_chinese_input
    output, _ = capture_io { cmd_route(['帮我评审代码']) }
    assert_match(/输入/, output)
  end

  def test_cmd_route_context
    Dir.chdir(@tmpdir) do
      File.write(File.join(@tmpdir, 'Gemfile'), "source 'https://rubygems.org'")
      output, _ = capture_io { cmd_route_context }
      assert_match(/项目类型/, output)
    end
  end

  def test_cmd_route_context_with_tests
    Dir.chdir(@tmpdir) do
      File.write(File.join(@tmpdir, 'Gemfile'), "source 'https://rubygems.org'")
      FileUtils.mkdir_p(File.join(@tmpdir, 'test'))
      output, _ = capture_io { cmd_route_context }
      assert_match(/test-driven-development|superpowers/, output)
    end
  end

  def test_cmd_route_context_with_views
    Dir.chdir(@tmpdir) do
      File.write(File.join(@tmpdir, 'Gemfile'), "source 'https://rubygems.org'")
      FileUtils.mkdir_p(File.join(@tmpdir, 'app', 'views', 'home'))
      File.write(File.join(@tmpdir, 'app', 'views', 'home', 'index.html.erb'), '<h1>Hello</h1>')
      output, _ = capture_io { cmd_route_context }
      assert_match(/browser_qa|\/qa/, output)
    end
  end

  def test_cmd_route_context_no_suggestions
    Dir.chdir(@tmpdir) do
      output, _ = capture_io { cmd_route_context }
      assert_match(/未检测到/, output)
    end
  end

  def test_detect_project_type_ruby
    Dir.chdir(@tmpdir) do
      File.write(File.join(@tmpdir, 'Gemfile'), "source 'https://rubygems.org'")
      assert_equal 'Ruby', detect_project_type
    end
  end

  def test_detect_project_type_node
    Dir.chdir(@tmpdir) do
      File.write(File.join(@tmpdir, 'package.json'), '{}')
      assert_equal 'Node.js', detect_project_type
    end
  end

  def test_detect_project_type_python
    Dir.chdir(@tmpdir) do
      File.write(File.join(@tmpdir, 'requirements.txt'), 'flask')
      assert_equal 'Python', detect_project_type
    end
  end

  def test_detect_project_type_go
    Dir.chdir(@tmpdir) do
      File.write(File.join(@tmpdir, 'go.mod'), 'module example')
      assert_equal 'Go', detect_project_type
    end
  end

  def test_detect_project_type_rust
    Dir.chdir(@tmpdir) do
      File.write(File.join(@tmpdir, 'Cargo.toml'), '[package]')
      assert_equal 'Rust', detect_project_type
    end
  end

  def test_detect_project_type_unknown
    Dir.chdir(@tmpdir) do
      assert_equal 'Unknown', detect_project_type
    end
  end

  def test_skill_path_external
    result = skill_path('/review')
    assert_match(/superpowers|gstack|skills/, result)
    assert_match(/SKILL\.md/, result)
  end

  def test_skill_path_builtin
    result = skill_path('my-skill')
    assert_match(/skills\/my-skill/, result)
  end

  def test_git_uncommitted_changes_no_git
    Dir.chdir(@tmpdir) do
      refute git_uncommitted_changes?
    end
  end
end
