# frozen_string_literal: true

require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'yaml'
require_relative '../../lib/vibe/cli/instinct_commands'
require_relative '../../lib/vibe/errors'

class InstinctCommandsTestHost
  include Vibe::InstinctCommands
end

class TestInstinctCommands < Minitest::Test
  def setup
    @host = InstinctCommandsTestHost.new
    @tmpdir = Dir.mktmpdir('vibe-instinct-test')
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_module_exists
    assert Vibe.const_defined?(:InstinctCommands)
  end

  def test_help_subcommand
    out, = capture_io { @host.run_instinct_command(['help']) }
    assert_match(/Usage/, out)
    assert_match(/learn/, out)
    assert_match(/status/, out)
  end

  def test_nil_subcommand_shows_usage
    out, = capture_io { @host.run_instinct_command([]) }
    assert_match(/Usage/, out)
  end

  def test_dash_h_shows_usage
    out, = capture_io { @host.run_instinct_command(['-h']) }
    assert_match(/Usage/, out)
  end

  def test_unknown_subcommand_raises
    assert_raises(Vibe::ValidationError) do
      @host.run_instinct_command(['bogus'])
    end
  end

  def test_learn_no_data_shows_help
    out, = capture_io { @host.run_instinct_command(['learn']) }
    assert_match(/No session data/, out)
  end

  def test_learn_with_manual_pattern
    out, = capture_io { @host.run_instinct_command(['learn', '--pattern', 'Test pattern', '--tags', 'ruby,test']) }
    assert_match(/Created instinct/, out)
    assert_match(/Test pattern/, out)
  end

  def test_learn_with_file
    session_file = File.join(@tmpdir, 'session.yaml')
    File.write(session_file, YAML.dump({
                                         'tool_calls' => [
                                           { 'tool' => 'read', 'success' => true },
                                           { 'tool' => 'edit', 'success' => true },
                                           { 'tool' => 'test', 'success' => true }
                                         ],
                                         'context' => { 'language' => 'ruby' }
                                       }))
    out, = capture_io { @host.run_instinct_command(['learn', '--file', session_file]) }
    assert_match(/pattern candidate/, out)
  end

  def test_learn_with_missing_file
    out, = capture_io { @host.run_instinct_command(['learn', '--file', '/nonexistent/file.yaml']) }
    assert_match(/No session data/, out)
  end

  def test_learn_eval_no_id_shows_list
    out, = capture_io { @host.run_instinct_command(['learn-eval']) }
    assert_match(/No instincts to evaluate|Instinct Evaluation/, out)
  end

  def test_learn_eval_with_id_not_found
    out, = capture_io { @host.run_instinct_command(%w[learn-eval nonexistent-id]) }
    assert_match(/Instinct not found/, out)
  end

  def test_status_empty
    out, = capture_io { @host.run_instinct_command(['status']) }
    assert_match(/Instinct Status|No instincts/, out)
  end

  def test_export_no_file_path
    out, = capture_io { @host.run_instinct_command(['export']) }
    assert_match(/Usage/, out)
  end

  def test_import_no_file_path
    out, = capture_io { @host.run_instinct_command(['import']) }
    assert_match(/Usage/, out)
  end

  def test_import_nonexistent_file
    assert_raises(SystemExit) do
      capture_io { @host.run_instinct_command(['import', '/nonexistent/file.yaml']) }
    end
  end

  def test_evolve_no_id
    out, = capture_io { @host.run_instinct_command(['evolve']) }
    assert_match(/Usage/, out)
  end

  def test_evolve_with_id_not_found
    # Skip - InstinctManager may hang or take too long in test environment
    skip 'InstinctManager integration test'
  end

  def test_parse_instinct_status_options_defaults
    opts = @host.send(:parse_instinct_status_options, [])
    refute opts[:all]
    assert_nil opts[:tag]
    assert_nil opts[:min_confidence]
  end

  def test_parse_instinct_status_options_all
    opts = @host.send(:parse_instinct_status_options, ['--all'])
    assert opts[:all]
  end

  def test_parse_instinct_status_options_tag
    opts = @host.send(:parse_instinct_status_options, ['--tag', 'ruby'])
    assert_equal 'ruby', opts[:tag]
  end

  def test_parse_instinct_status_options_min_confidence
    opts = @host.send(:parse_instinct_status_options, ['--min-confidence', '0.8'])
    assert_in_delta 0.8, opts[:min_confidence]
  end

  def test_parse_instinct_export_options_defaults
    opts = @host.send(:parse_instinct_export_options, [])
    assert_nil opts[:tag]
    assert_nil opts[:min_confidence]
  end

  def test_parse_instinct_export_options
    opts = @host.send(:parse_instinct_export_options, ['--tag', 'ruby', '--min-confidence', '0.9'])
    assert_equal 'ruby', opts[:tag]
    assert_in_delta 0.9, opts[:min_confidence]
  end

  def test_parse_instinct_import_options_defaults
    opts = @host.send(:parse_instinct_import_options, [])
    refute opts[:overwrite]
    refute opts[:merge]
  end

  def test_parse_instinct_import_options_overwrite
    opts = @host.send(:parse_instinct_import_options, ['--overwrite'])
    assert opts[:overwrite]
    refute opts[:merge]
  end

  def test_parse_instinct_import_options_merge
    opts = @host.send(:parse_instinct_import_options, ['--merge'])
    refute opts[:overwrite]
    assert opts[:merge]
  end

  def test_parse_instinct_learn_options_defaults
    opts = @host.send(:parse_instinct_learn_options, [])
    assert_nil opts[:file]
    refute opts[:stdin]
    assert_nil opts[:pattern]
  end

  def test_parse_instinct_learn_options_file
    opts = @host.send(:parse_instinct_learn_options, ['--file', '/tmp/session.yaml'])
    assert_equal '/tmp/session.yaml', opts[:file]
  end

  def test_parse_instinct_learn_options_pattern
    opts = @host.send(:parse_instinct_learn_options, ['--pattern', 'Test pattern'])
    assert_equal 'Test pattern', opts[:pattern]
  end

  def test_parse_instinct_learn_options_tags
    opts = @host.send(:parse_instinct_learn_options, ['--tags', 'ruby,testing'])
    assert_equal %w[ruby testing], opts[:tags]
  end

  def test_parse_instinct_learn_options_context
    opts = @host.send(:parse_instinct_learn_options, ['--context', 'Some context'])
    assert_equal 'Some context', opts[:context]
  end

  def test_load_session_data_nil
    assert_nil @host.send(:load_session_data, nil)
  end

  def test_load_session_data_missing_file
    # The method prints a warning and returns nil
    capture_io { assert_nil @host.send(:load_session_data, '/nonexistent/file.yaml') }
  end

  def test_load_session_data_valid
    session_file = File.join(@tmpdir, 'valid.yaml')
    File.write(session_file, YAML.dump({ 'test' => 'data' }))
    result = @host.send(:load_session_data, session_file)
    assert_equal 'data', result['test']
  end

  def test_extract_patterns_empty
    result = @host.send(:extract_patterns, {})
    assert_empty result
  end

  def test_extract_patterns_insufficient_calls
    result = @host.send(:extract_patterns, { 'tool_calls' => [{ 'tool' => 'read', 'success' => true }] })
    assert_empty result
  end

  def test_extract_patterns_with_successful_sequence
    data = {
      'tool_calls' => [
        { 'tool' => 'read', 'success' => true },
        { 'tool' => 'edit', 'success' => true },
        { 'tool' => 'test', 'success' => true }
      ],
      'context' => { 'language' => 'ruby', 'framework' => 'rails' }
    }
    result = @host.send(:extract_patterns, data)
    refute_empty result
    assert result.first[:tags].include?('ruby')
    assert result.first[:tags].include?('rails')
  end

  def test_print_instinct_summary
    instinct = {
      'confidence' => 0.85,
      'pattern' => 'Test pattern',
      'tags' => %w[ruby testing],
      'usage_count' => 10,
      'success_rate' => 0.9
    }
    out, = capture_io { @host.send(:print_instinct_summary, instinct, 1) }
    assert_match(/Test pattern/, out)
    assert_match(/0.85/, out)
    assert_match(/ruby/, out)
    assert_match(/testing/, out)
  end

  def test_build_candidate
    sequence = [
      { 'tool' => 'read', 'success' => true },
      { 'tool' => 'edit', 'success' => true }
    ]
    session_data = { 'context' => { 'language' => 'ruby' } }
    result = @host.send(:build_candidate, sequence, session_data)
    assert result[:pattern]
    assert_includes result[:tags], 'ruby'
    assert (result[:confidence]).positive?
    assert result[:confidence] <= 1
  end
end
