# frozen_string_literal: true

# CLI commands for checkpoint management
# These methods are included in VibeCLI class

require_relative "../checkpoint_manager"

module Vibe
  module CheckpointCommands
    # Main entry point for 'vibe checkpoint' subcommand
    def run_checkpoint_command(argv)
      subcommand = argv.shift

      case subcommand
      when "create"
        run_checkpoint_create(argv)
      when "list"
        run_checkpoint_list(argv)
      when "rollback"
        run_checkpoint_rollback(argv)
      when "compare"
        run_checkpoint_compare(argv)
      when "delete"
        run_checkpoint_delete(argv)
      when "cleanup"
        run_checkpoint_cleanup(argv)
      when nil, "help", "--help", "-h"
        puts checkpoint_usage
      else
        raise Vibe::ValidationError, "Unknown checkpoint subcommand: #{subcommand}\n\n#{checkpoint_usage}"
      end
    end

    # vibe checkpoint create - Create a new checkpoint
    def run_checkpoint_create(argv)
      description = argv.shift
      files = argv

      unless description
        puts "Error: Description required"
        puts
        puts checkpoint_usage
        exit 1
      end

      if files.empty?
        puts "Error: At least one file required"
        puts
        puts checkpoint_usage
        exit 1
      end

      # Validate files exist
      missing = files.reject { |f| File.exist?(f) }
      if missing.any?
        puts "Error: Files not found:"
        missing.each { |f| puts "  - #{f}" }
        exit 1
      end

      manager = CheckpointManager.new
      checkpoint_id = manager.create(description, files)

      puts "\n✅ Checkpoint created: #{checkpoint_id}\n"
      puts "=" * 60
      puts
      puts "Description: #{description}"
      puts "Files: #{files.size}"
      files.each { |f| puts "  - #{f}" }
      puts
    end

    # vibe checkpoint list - List all checkpoints
    def run_checkpoint_list(argv)
      options = parse_checkpoint_list_options(argv)
      manager = CheckpointManager.new

      filters = {}
      filters[:limit] = options[:limit] if options[:limit]
      filters[:since] = Time.now - options[:since] if options[:since]

      checkpoints = manager.list(filters)

      puts "\n📋 Checkpoints\n"
      puts "=" * 60
      puts

      if checkpoints.empty?
        puts "No checkpoints found."
        puts
        return
      end

      checkpoints.each do |cp|
        puts "ID: #{cp['id']}"
        puts "Description: #{cp['description']}"
        puts "Created: #{cp['created_at']}"
        puts "Files: #{cp['files'].size}"
        puts
      end

      puts "Total: #{checkpoints.size} checkpoint(s)"
      puts
    end

    # vibe checkpoint rollback - Rollback to a checkpoint
    def run_checkpoint_rollback(argv)
      options = parse_checkpoint_rollback_options(argv)

      unless options[:id]
        puts "Error: Checkpoint ID required"
        puts
        puts checkpoint_usage
        exit 1
      end

      manager = CheckpointManager.new

      begin
        result = manager.rollback(options[:id], dry_run: options[:dry_run])

        if options[:dry_run]
          puts "\n🔍 Rollback Preview (dry-run)\n"
        else
          puts "\n✅ Rollback Complete\n"
        end

        puts "=" * 60
        puts
        puts "Checkpoint: #{result[:checkpoint_id]}"
        puts "Description: #{result[:description]}"
        puts
        puts "Changes:"
        result[:changes].each do |change|
          puts "  [#{change[:action]}] #{change[:file]}"
        end
        puts
      rescue StandardError => e
        puts "Error: #{e.message}"
        exit 1
      end
    end

    # vibe checkpoint compare - Compare two checkpoints
    def run_checkpoint_compare(argv)
      id1 = argv.shift
      id2 = argv.shift

      unless id1 && id2
        puts "Error: Two checkpoint IDs required"
        puts
        puts checkpoint_usage
        exit 1
      end

      manager = CheckpointManager.new

      begin
        result = manager.compare(id1, id2)

        puts "\n🔍 Checkpoint Comparison\n"
        puts "=" * 60
        puts
        puts "Checkpoint 1: #{result[:checkpoint1][:id]}"
        puts "  Created: #{result[:checkpoint1][:created_at]}"
        puts
        puts "Checkpoint 2: #{result[:checkpoint2][:id]}"
        puts "  Created: #{result[:checkpoint2][:created_at]}"
        puts
        puts "Differences: #{result[:total_changes]}"
        puts

        if result[:differences].any?
          result[:differences].each do |diff|
            case diff[:status]
            when "modified"
              puts "  [M] #{diff[:file]} (#{diff[:size_change] > 0 ? '+' : ''}#{diff[:size_change]} bytes)"
            when "added"
              puts "  [A] #{diff[:file]} (+#{diff[:size]} bytes)"
            when "removed"
              puts "  [D] #{diff[:file]}"
            end
          end
          puts
        end
      rescue StandardError => e
        puts "Error: #{e.message}"
        exit 1
      end
    end

    # vibe checkpoint delete - Delete a checkpoint
    def run_checkpoint_delete(argv)
      checkpoint_id = argv.shift

      unless checkpoint_id
        puts "Error: Checkpoint ID required"
        puts
        puts checkpoint_usage
        exit 1
      end

      manager = CheckpointManager.new

      if manager.delete(checkpoint_id)
        puts "\n✅ Checkpoint deleted: #{checkpoint_id}\n"
      else
        puts "Error: Checkpoint not found: #{checkpoint_id}"
        exit 1
      end
    end

    # vibe checkpoint cleanup - Clean up old checkpoints
    def run_checkpoint_cleanup(argv)
      keep_count = argv.shift&.to_i || 10

      manager = CheckpointManager.new
      removed = manager.cleanup(keep_count)

      puts "\n🧹 Checkpoint Cleanup\n"
      puts "=" * 60
      puts
      puts "Removed: #{removed} checkpoint(s)"
      puts "Kept: #{keep_count} most recent"
      puts
    end

    private

    def parse_checkpoint_list_options(argv)
      options = { limit: nil, since: nil }

      while (arg = argv.shift)
        case arg
        when "--limit", "-n"
          options[:limit] = argv.shift&.to_i
        when "--since"
          # Parse duration like "1h", "2d", "1w"
          duration_str = argv.shift
          options[:since] = parse_duration(duration_str) if duration_str
        end
      end

      options
    end

    def parse_checkpoint_rollback_options(argv)
      options = { id: nil, dry_run: false }

      while (arg = argv.shift)
        case arg
        when "--dry-run", "-n"
          options[:dry_run] = true
        else
          options[:id] = arg
        end
      end

      options
    end

    def parse_duration(str)
      match = str.match(/^(\d+)([hdw])$/)
      return nil unless match

      value = match[1].to_i
      unit = match[2]

      case unit
      when "h" then value * 3600
      when "d" then value * 86400
      when "w" then value * 604800
      end
    end

    def checkpoint_usage
      <<~USAGE
        Usage: vibe checkpoint <subcommand> [options]

        Subcommands:
          create <desc> <files...>    Create a new checkpoint
          list [options]              List all checkpoints
          rollback <id> [options]     Rollback to a checkpoint
          compare <id1> <id2>         Compare two checkpoints
          delete <id>                 Delete a checkpoint
          cleanup [keep_count]        Clean up old checkpoints (default: keep 10)

        Options for 'list':
          -n, --limit <count>         Limit number of results
          --since <duration>          Only show recent (e.g., 1h, 2d, 1w)

        Options for 'rollback':
          -n, --dry-run               Preview changes without applying

        Examples:
          vibe checkpoint create "Before refactor" lib/vibe/*.rb
          vibe checkpoint list --limit 5
          vibe checkpoint rollback abc123 --dry-run
          vibe checkpoint compare abc123 def456
          vibe checkpoint delete abc123
          vibe checkpoint cleanup 5
      USAGE
    end
  end
end
