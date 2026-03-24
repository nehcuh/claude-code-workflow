# frozen_string_literal: true

# CLI commands for memory trigger subsystem
# These methods are included in VibeCLI class

require_relative '../memory_trigger'

module Vibe
  # CLI commands for the memory trigger subsystem, included in VibeCLI.
  module MemoryCommands
    # Main entry point for 'vibe memory' subcommand
    def run_memory_command(argv)
      subcommand = argv.shift

      case subcommand
      when 'record'
        run_memory_record(argv)
      when 'stats'
        run_memory_stats
      when 'enable'
        run_memory_enable
      when 'disable'
        run_memory_disable
      when 'status'
        run_memory_status
      when nil, 'help', '--help', '-h'
        puts memory_usage
      else
        raise Vibe::ValidationError,
              "Unknown memory subcommand: #{subcommand}\n\n#{memory_usage}"
      end
    end

    # vibe memory record - Record an error manually
    def run_memory_record(argv)
      options = parse_memory_record_options(argv)

      if options[:problem].nil? || options[:solution].nil?
        puts '❌ Error: --problem and --solution are required'
        puts memory_usage
        exit 1
      end

      trigger = MemoryTrigger.new

      error_info = {
        command: options[:command] || 'manual',
        problem: options[:problem],
        solution: options[:solution],
        scenario: options[:scenario],
        files: options[:files]&.split(',') || []
      }

      # Use force_record to bypass threshold
      trigger.force_record(error_info)
      puts '✅ Error recorded to memory/project-knowledge.md'
    end

    # vibe memory stats - Show statistics
    def run_memory_stats
      trigger = MemoryTrigger.new
      stats = trigger.stats

      puts '📊 Memory Trigger Statistics'
      puts
      puts "Total errors tracked: #{stats[:total_errors]}"
      puts "Recorded errors: #{stats[:recorded_errors]}"
      puts

      if stats[:top_errors].any?
        puts 'Top errors:'
        stats[:top_errors].each_with_index do |error, i|
          puts "  #{i + 1}. #{error[:signature]} (#{error[:count]} occurrences)"
        end
      else
        puts 'No errors tracked yet'
      end
    end

    # vibe memory enable - Enable auto trigger
    def run_memory_enable
      config_path = File.join(Dir.pwd, '.vibe', 'memory-trigger.yaml')
      FileUtils.mkdir_p(File.dirname(config_path))

      config = {
        'enabled' => true,
        'auto_record' => true,
        'min_occurrences' => 2
      }

      File.write(config_path, YAML.dump(config))
      puts '✅ Auto memory trigger enabled'
      puts "   Config: #{config_path}"
    end

    # vibe memory disable - Disable auto trigger
    def run_memory_disable
      config_path = File.join(Dir.pwd, '.vibe', 'memory-trigger.yaml')

      if File.exist?(config_path)
        config = YAML.safe_load(File.read(config_path), aliases: true) || {}
        config['enabled'] = false
        File.write(config_path, YAML.dump(config))
        puts '✅ Auto memory trigger disabled'
      else
        puts '⚠️  No config found (already disabled)'
      end
    end

    # vibe memory status - Show current status
    def run_memory_status
      config_path = File.join(Dir.pwd, '.vibe', 'memory-trigger.yaml')

      if File.exist?(config_path)
        config = YAML.safe_load(File.read(config_path), aliases: true) || {}
        enabled = config['enabled']
        auto_record = config['auto_record']
        min_occurrences = config['min_occurrences']

        puts '📋 Memory Trigger Status'
        puts
        puts "Enabled: #{enabled ? '✅ Yes' : '❌ No'}"
        puts "Auto-record: #{auto_record ? '✅ Yes' : '❌ No'}"
        puts "Min occurrences: #{min_occurrences}"
      else
        puts '📋 Memory Trigger Status: ❌ Not configured'
        puts
        puts 'Run `vibe memory enable` to enable auto memory trigger'
      end
    end

    private

    def parse_memory_record_options(argv)
      options = {}
      i = 0
      while i < argv.length
        case argv[i]
        when '--problem'
          raise Vibe::ValidationError, '--problem requires a value' if argv[i + 1].nil?
          options[:problem] = argv[i + 1]
          i += 2
        when '--solution'
          raise Vibe::ValidationError, '--solution requires a value' if argv[i + 1].nil?
          options[:solution] = argv[i + 1]
          i += 2
        when '--scenario'
          raise Vibe::ValidationError, '--scenario requires a value' if argv[i + 1].nil?
          options[:scenario] = argv[i + 1]
          i += 2
        when '--command'
          raise Vibe::ValidationError, '--command requires a value' if argv[i + 1].nil?
          options[:command] = argv[i + 1]
          i += 2
        when '--files'
          raise Vibe::ValidationError, '--files requires a value' if argv[i + 1].nil?
          options[:files] = argv[i + 1]
          i += 2
        else
          i += 1
        end
      end
      options
    end

    def memory_usage
      <<~USAGE
        Usage: vibe memory <command> [options]

        Commands:
          record    Record an error manually
          stats     Show memory trigger statistics
          enable    Enable auto memory trigger
          disable   Disable auto memory trigger
          status    Show current status

        Examples:
          vibe memory record --problem "Test failed" --solution "Fix assertion"
          vibe memory stats
          vibe memory enable
      USAGE
    end
  end
end

