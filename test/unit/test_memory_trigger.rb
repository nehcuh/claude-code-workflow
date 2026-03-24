# frozen_string_literal: true

require_relative '../test_helper'
require 'vibe/memory_trigger'
require 'tmpdir'
require 'fileutils'

class MemoryTriggerTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @memory_path = File.join(@tmpdir, 'memory', 'project-knowledge.md')
    FileUtils.mkdir_p(File.dirname(@memory_path))

    # Create initial memory file
    File.write(@memory_path, <<~CONTENT)
      # Project Knowledge

      ## Technical Pitfalls

      ### P001: Example pitfall
      - **场景**: Example scenario
      - **问题**: Example problem
      - **解决**: Example solution
      - **遇到次数**: 1

      ## Reusable Patterns

      ## Solutions
    CONTENT

    @trigger = Vibe::MemoryTrigger.new(@memory_path, config: { auto_record: true, min_occurrences: 2 })
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_initialization
    assert_instance_of Vibe::MemoryTrigger, @trigger
    assert_equal @memory_path, @trigger.memory_path
  end

  def test_record_error_below_threshold
    error_info = {
      command: 'bundle install',
      exit_code: 1,
      output: 'Could not find gem',
      problem: 'Gem not found',
      solution: 'Run bundle update'
    }

    # First occurrence - should not record
    result = @trigger.record_error(error_info)
    refute result, 'Should not record on first occurrence'

    content = File.read(@memory_path)
    refute_includes content, 'P002', 'Should not create new entry'
  end

  def test_record_error_above_threshold
    error_info = {
      command: 'bundle install',
      exit_code: 1,
      output: 'Could not find gem',
      problem: 'Gem not found',
      solution: 'Run bundle update',
      scenario: 'Installing dependencies'
    }

    # First occurrence
    @trigger.record_error(error_info)

    # Second occurrence - should record
    result = @trigger.record_error(error_info)
    assert result, 'Should record on second occurrence'

    content = File.read(@memory_path)
    assert_includes content, 'P002', 'Should create new entry'
    assert_includes content, 'Gem not found', 'Should include problem'
    assert_includes content, 'Run bundle update', 'Should include solution'
    assert_includes content, '**遇到次数**: 2', 'Should track occurrence count'
  end

  def test_record_solution
    solution_info = {
      problem: 'Slow test suite',
      solution: 'Use parallel test execution',
      scenario: 'Running tests'
    }

    result = @trigger.record_solution(solution_info)
    assert result, 'Should record solution'

    content = File.read(@memory_path)
    assert_includes content, 'Slow test suite', 'Should include problem'
    assert_includes content, 'Use parallel test execution', 'Should include solution'
  end

  def test_record_pattern
    pattern_info = {
      name: 'Database migration pattern',
      description: 'Always backup before migration',
      usage: 'Run backup script first',
      scenario: 'Database migrations'
    }

    result = @trigger.record_pattern(pattern_info)
    assert result, 'Should record pattern'

    content = File.read(@memory_path)
    assert_includes content, 'Database migration pattern', 'Should include pattern name'
    assert_includes content, 'Always backup before migration', 'Should include description'
  end

  def test_stats
    error_info = {
      command: 'test command',
      exit_code: 1,
      output: 'test error',
      problem: 'Test problem',
      solution: 'Test solution'
    }

    @trigger.record_error(error_info)

    stats = @trigger.stats
    assert_equal 1, stats[:total_errors], 'Should track total errors'
    assert_equal 1, stats[:recorded_errors], 'Should track recorded errors'
    assert_instance_of Array, stats[:top_errors], 'Should return top errors'
  end

  def test_error_signature_generation
    error1 = {
      command: 'bundle install',
      output: 'Error at /path/to/file.rb:123'
    }

    error2 = {
      command: 'bundle install',
      output: 'Error at /different/path/file.rb:456'
    }

    # Record both errors
    @trigger.record_error(error1)
    @trigger.record_error(error2)

    # Should be treated as same error (paths normalized)
    stats = @trigger.stats
    assert_equal 1, stats[:total_errors], 'Should normalize file paths in signatures'
  end

  def test_auto_numbering
    # Record multiple errors to test auto-numbering
    3.times do |i|
      error_info = {
        command: "command_#{i}",
        exit_code: 1,
        output: "error #{i}",
        problem: "Problem #{i}",
        solution: "Solution #{i}"
      }

      # Record twice to trigger auto-record
      2.times { @trigger.record_error(error_info) }
    end

    content = File.read(@memory_path)
    assert_includes content, 'P002', 'Should have P002'
    assert_includes content, 'P003', 'Should have P003'
    assert_includes content, 'P004', 'Should have P004'
  end

  def test_error_cache_persistence
    error_info = {
      command: 'test command',
      exit_code: 1,
      output: 'test error',
      problem: 'Test problem',
      solution: 'Test solution'
    }

    @trigger.record_error(error_info)

    # Create new instance - should load cache
    new_trigger = Vibe::MemoryTrigger.new(@memory_path, config: { auto_record: true, min_occurrences: 2 })

    # Second occurrence should trigger recording
    result = new_trigger.record_error(error_info)
    assert result, 'Should load cache and record on second occurrence'
  end

  def test_force_record_bypasses_threshold
    error_info = {
      command: 'manual',
      problem: 'Direct problem',
      solution: 'Direct solution'
    }

    # Should record immediately without needing min_occurrences
    result = @trigger.force_record(error_info)
    assert result, 'force_record should return true'

    content = File.read(@memory_path)
    assert_includes content, 'Direct problem', 'Should write entry immediately'
  end

  def test_cache_cleanup_by_age
    # Insert a cache entry with an old timestamp
    old_entry = {
      'count' => 1,
      'first_seen' => (Time.now - 40 * 86_400).iso8601,
      'last_seen'  => (Time.now - 40 * 86_400).iso8601,
      'info' => { 'command' => 'old cmd' }
    }
    cache_path = File.join(File.dirname(@memory_path), '.error_cache.yaml')
    File.write(cache_path, YAML.dump('old_sig' => old_entry))

    # New trigger loads cache and runs cleanup
    trigger = Vibe::MemoryTrigger.new(@memory_path,
                                      config: { auto_record: true,
                                                min_occurrences: 2,
                                                max_cache_age_days: 30,
                                                max_cache_entries: 1000 })

    assert_equal 0, trigger.stats[:total_errors], 'Old cache entry should be cleaned up'
  end

  def test_cache_cleanup_by_size
    # Fill cache beyond max_cache_entries limit
    cache = {}
    110.times do |i|
      cache["sig_#{i}"] = {
        'count' => 1,
        'first_seen' => Time.now.iso8601,
        'last_seen' => (Time.now - i).iso8601,
        'info' => {}
      }
    end
    cache_path = File.join(File.dirname(@memory_path), '.error_cache.yaml')
    File.write(cache_path, YAML.dump(cache))

    trigger = Vibe::MemoryTrigger.new(@memory_path,
                                      config: { auto_record: true,
                                                min_occurrences: 2,
                                                max_cache_age_days: 30,
                                                max_cache_entries: 100 })

    assert trigger.stats[:total_errors] <= 100, 'Cache should be trimmed to max_cache_entries'
  end
end
