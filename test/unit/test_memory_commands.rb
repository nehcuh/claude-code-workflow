# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'
require 'fileutils'
require 'yaml'
require_relative '../../lib/vibe/errors'
require_relative '../../lib/vibe/memory_trigger'
require_relative '../../lib/vibe/memory_autoload'
require_relative '../../lib/vibe/cli/memory_commands'

class TestMemoryCommands < Minitest::Test
  include Vibe::MemoryCommands
  include Vibe::MemoryAutoload

  def setup
    @tmpdir = Dir.mktmpdir
    @original_dir = Dir.pwd
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
    Dir.chdir(@original_dir)
  end

  def test_run_memory_command_stats
    output, _ = capture_io do
      run_memory_command(%w[stats])
    end
    assert_match(/Memory/, output)
  end

  def test_run_memory_command_autoload_status
    output, _ = capture_io do
      run_memory_command(%w[autoload status])
    end
    assert_match(/Memory Auto-Load/, output)
  end

  def test_run_memory_command_help
    output, _ = capture_io do
      run_memory_command(%w[help])
    end
    assert_match(/Usage/, output)
  end

  def test_run_memory_command_nil_shows_help
    output, _ = capture_io do
      run_memory_command([])
    end
    assert_match(/Usage/, output)
  end

  def test_run_memory_command_invalid_subcommand
    assert_raises(Vibe::ValidationError) do
      run_memory_command(%w[invalid_action])
    end
  end

  def test_parse_memory_record_options_problem_and_solution
    options = parse_memory_record_options(
      %w[--problem test_error --solution fix_applied]
    )
    assert_equal 'test_error', options[:problem]
    assert_equal 'fix_applied', options[:solution]
  end

  def test_parse_memory_record_options_all_flags
    options = parse_memory_record_options([
      '--problem', 'perf issue',
      '--solution', 'added caching',
      '--scenario', 'high traffic',
      '--command', 'cache warmup',
      '--files', 'config.yaml'
    ])
    assert_equal 'perf issue', options[:problem]
    assert_equal 'added caching', options[:solution]
    assert_equal 'high traffic', options[:scenario]
    assert_equal 'cache warmup', options[:command]
    assert_equal 'config.yaml', options[:files]
  end

  def test_parse_memory_record_options_missing_value_raises
    assert_raises(Vibe::ValidationError) do
      parse_memory_record_options(%w[--problem])
    end
  end

  def test_parse_memory_record_options_solution_missing_value_raises
    assert_raises(Vibe::ValidationError) do
      parse_memory_record_options(%w[--solution])
    end
  end

  def test_parse_memory_record_options_empty
    options = parse_memory_record_options([])
    assert_equal({}, options)
  end

  def test_memory_usage_returns_string
    usage = memory_usage
    assert_match(/record/, usage)
    assert_match(/stats/, usage)
    assert_match(/enable/, usage)
    assert_match(/disable/, usage)
  end

  def test_memory_autoload_usage_returns_string
    usage = memory_autoload_usage
    assert_match(/enable/, usage)
    assert_match(/disable/, usage)
    assert_match(/status/, usage)
  end

  def test_run_memory_enable_creates_config
    Dir.chdir(@tmpdir) do
      capture_io { run_memory_enable }
      config_path = File.join(@tmpdir, '.vibe', 'memory-trigger.yaml')
      assert File.exist?(config_path)
      config = YAML.safe_load(File.read(config_path))
      assert_equal true, config['enabled']
      assert_equal true, config['auto_record']
    end
  end

  def test_run_memory_disable_no_config
    Dir.chdir(@tmpdir) do
      output, _ = capture_io { run_memory_disable }
      assert_match(/No config found/, output)
    end
  end

  def test_run_memory_status_no_config
    Dir.chdir(@tmpdir) do
      output, _ = capture_io { run_memory_status }
      assert_match(/Not configured/, output)
    end
  end

  def test_run_memory_status_with_config
    Dir.chdir(@tmpdir) do
      config_dir = File.join(@tmpdir, '.vibe')
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, 'memory-trigger.yaml'), YAML.dump({
        'enabled' => true,
        'auto_record' => false,
        'min_occurrences' => 3
      }))
      output, _ = capture_io { run_memory_status }
      assert_match(/Enabled/, output)
      assert_match(/3/, output)
    end
  end
end
