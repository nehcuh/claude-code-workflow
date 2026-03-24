# frozen_string_literal: true

require 'yaml'
require 'time'
require 'fileutils'
require_relative 'utils'

module Vibe
  # Automatic memory trigger system - captures errors and patterns
  # and writes them to memory/project-knowledge.md
  class MemoryTrigger
    include Utils
    attr_reader :memory_path, :config

    DEFAULT_CONFIG = {
      min_occurrences: 2,        # Minimum occurrences to record
      auto_record: true,         # Auto-record without confirmation
      categories: %w[pitfall pattern solution],
      max_entries_per_category: 100
    }.freeze

    def initialize(memory_path = nil, config: {})
      @memory_path = memory_path || default_memory_path
      @config = DEFAULT_CONFIG.merge(config)
      @error_cache = load_error_cache
      ensure_memory_directory
    end

    # Record an error occurrence
    # @param error_info [Hash] Error information
    #   - :command [String] Command that failed
    #   - :exit_code [Integer] Exit code
    #   - :output [String] Error output
    #   - :context [Hash] Additional context
    # @return [Boolean] True if recorded
    def record_error(error_info)
      signature = generate_error_signature(error_info)

      # Update error cache
      @error_cache[signature] ||= {
        'count' => 0,
        'first_seen' => Time.now.iso8601,
        'last_seen' => Time.now.iso8601,
        'info' => error_info
      }

      @error_cache[signature]['count'] += 1
      @error_cache[signature]['last_seen'] = Time.now.iso8601
      save_error_cache

      # Auto-record if threshold met
      if should_record?(signature)
        write_to_memory(error_info, @error_cache[signature])
        true
      else
        false
      end
    end

    # Record a successful solution
    # @param solution_info [Hash] Solution information
    #   - :problem [String] Problem description
    #   - :solution [String] Solution description
    #   - :context [Hash] Additional context
    # @return [Boolean] True if recorded
    def record_solution(solution_info)
      write_to_memory(solution_info, nil, category: 'solution')
      true
    end

    # Record a reusable pattern
    # @param pattern_info [Hash] Pattern information
    #   - :name [String] Pattern name
    #   - :description [String] Pattern description
    #   - :usage [String] Usage instructions
    # @return [Boolean] True if recorded
    def record_pattern(pattern_info)
      write_to_memory(pattern_info, nil, category: 'pattern')
      true
    end

    # Get error statistics
    # @return [Hash] Error statistics
    def stats
      {
        total_errors: @error_cache.size,
        recorded_errors: count_recorded_errors,
        top_errors: top_errors(5)
      }
    end

    private

    def default_memory_path
      File.join(Dir.pwd, 'memory', 'project-knowledge.md')
    end

    def ensure_memory_directory
      dir = File.dirname(@memory_path)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
    end

    def load_error_cache
      cache_path = File.join(File.dirname(@memory_path), '.error_cache.yaml')
      return {} unless File.exist?(cache_path)

      YAML.safe_load(File.read(cache_path), permitted_classes: [Time, Symbol],
                                            aliases: true) || {}
    rescue StandardError => e
      warn "Failed to load error cache: #{e.message}"
      {}
    end

    def save_error_cache
      cache_path = File.join(File.dirname(@memory_path), '.error_cache.yaml')
      File.write(cache_path, YAML.dump(@error_cache))
    rescue StandardError => e
      warn "Failed to save error cache: #{e.message}"
    end

    def generate_error_signature(error_info)
      # Generate a unique signature based on command and error pattern
      command = error_info[:command] || error_info['command']
      output = error_info[:output] || error_info['output'] || ''

      # Extract key error patterns
      error_pattern = extract_error_pattern(output)

      "#{command}:#{error_pattern}"
    end

    def extract_error_pattern(output)
      # Extract meaningful error patterns from output
      # Remove file paths, line numbers, timestamps
      pattern = output.to_s
                      .gsub(%r{/[^\s]+}, '<path>')
                      .gsub(/:\d+/, ':<line>')
                      .gsub(/\d{4}-\d{2}-\d{2}/, '<date>')
                      .gsub(/\d+\.\d+s/, '<time>')

      # Take first 100 chars
      pattern[0..100]
    end

    def should_record?(signature)
      return false unless @config[:auto_record]

      count = @error_cache[signature]['count']
      count >= @config[:min_occurrences]
    end

    def write_to_memory(info, cache_info, category: 'pitfall')
      content = File.read(@memory_path)

      # Get next entry number
      entry_number = next_entry_number(content)

      # Generate entry
      entry = generate_entry(entry_number, info, cache_info, category)

      # Insert entry
      updated_content = insert_entry(content, entry, category)

      File.write(@memory_path, updated_content)
    rescue StandardError => e
      warn "Failed to write to memory: #{e.message}"
      false
    end

    def next_entry_number(content)
      # Find highest P### number
      numbers = content.scan(/### P(\d+):/).map { |m| m[0].to_i }
      numbers.empty? ? 1 : numbers.max + 1
    end

    def generate_entry(number, info, cache_info, category)
      case category
      when 'pitfall'
        generate_pitfall_entry(number, info, cache_info)
      when 'pattern'
        generate_pattern_entry(number, info)
      when 'solution'
        generate_solution_entry(number, info)
      else
        raise ArgumentError, "Unknown category: #{category}"
      end
    end

    def generate_pitfall_entry(number, info, cache_info)
      command = info[:command] || info['command']
      problem = info[:problem] || info['problem'] || 'Unknown problem'
      solution = info[:solution] || info['solution'] || 'No solution provided'
      files = info[:files] || info['files'] || []
      count = cache_info ? cache_info['count'] : 1

      entry = "\n### P#{format('%03d', number)}: #{problem}\n"
      entry += "- **场景**: #{info[:scenario] || info['scenario'] || command}\n"
      entry += "- **问题**: #{problem}\n"
      entry += "- **解决**: #{solution}\n"
      entry += "- **影响文件**: #{files.join(', ')}\n" unless files.empty?
      entry += "- **遇到次数**: #{count}\n"

      entry
    end

    def generate_pattern_entry(number, info)
      name = info[:name] || info['name']
      description = info[:description] || info['description']

      entry = "\n### #{name}\n"
      entry += "- **适用场景**: #{info[:scenario] || info['scenario']}\n"
      entry += "- **方法**: #{description}\n"
      entry += "- **使用次数**: 1\n"

      entry
    end

    def generate_solution_entry(number, info)
      problem = info[:problem] || info['problem']
      solution = info[:solution] || info['solution']

      entry = "\n### 解决方案 #{format('%03d', number)}: #{problem}\n"
      entry += "- **问题**: #{problem}\n"
      entry += "- **解决**: #{solution}\n"
      entry += "- **记录时间**: #{Time.now.strftime('%Y-%m-%d')}\n"

      entry
    end

    def insert_entry(content, entry, category)
      # Find the appropriate section
      section_header = case category
                       when 'pitfall'
                         '## Technical Pitfalls'
                       when 'pattern'
                         '## Reusable Patterns'
                       when 'solution'
                         '## Solutions'
                       end

      # If section doesn't exist, create it
      unless content.include?(section_header)
        content += "\n\n#{section_header}\n"
      end

      # Insert entry after section header
      content.sub(section_header, "#{section_header}#{entry}")
    end

    def count_recorded_errors
      content = File.read(@memory_path)
      content.scan(/### P\d+:/).size
    rescue StandardError
      0
    end

    def top_errors(limit)
      @error_cache.sort_by { |_, v| -v['count'] }.first(limit).map do |sig, data|
        {
          signature: sig,
          count: data['count'],
          last_seen: data['last_seen']
        }
      end
    end
  end
end
