# frozen_string_literal: true

# CLI commands for token optimization
# These methods are included in VibeCLI class

require_relative "../token_optimizer"

module Vibe
  module TokenCommands
    # Main entry point for 'vibe token' subcommand
    def run_token_command(argv)
      subcommand = argv.shift

      case subcommand
      when "analyze"
        run_token_analyze(argv)
      when "optimize"
        run_token_optimize(argv)
      when "stats"
        run_token_stats(argv)
      when nil, "help", "--help", "-h"
        puts token_usage
      else
        raise Vibe::ValidationError, "Unknown token subcommand: #{subcommand}\n\n#{token_usage}"
      end
    end

    # vibe token analyze - Analyze token usage of a file
    def run_token_analyze(argv)
      file_path = argv.shift

      unless file_path
        puts "Error: File path required"
        puts
        puts token_usage
        exit 1
      end

      unless File.exist?(file_path)
        puts "Error: File not found: #{file_path}"
        exit 1
      end

      content = File.read(file_path)
      optimizer = TokenOptimizer.new
      result = optimizer.analyze(content)

      puts "\n📊 Token Analysis: #{file_path}\n"
      puts "=" * 60
      puts
      puts "Total tokens: #{result[:total_tokens]}"
      puts "Total words: #{result[:total_words]}"
      puts "Total lines: #{result[:total_lines]}"
      puts "Whitespace ratio: #{result[:whitespace_ratio]}%"
      puts

      if result[:sections].any?
        puts "Sections:"
        result[:sections].each do |section|
          puts "  #{section[:title]} - #{section[:tokens]} tokens (#{section[:lines]} lines)"
        end
        puts
      end

      if result[:redundancies].any?
        puts "⚠️  Redundancies detected:"
        result[:redundancies].take(5).each do |r|
          preview = r[:line].length > 60 ? r[:line][0..60] + "..." : r[:line]
          puts "  [#{r[:count]}x] #{preview}"
        end
        puts "  ... and #{result[:redundancies].size - 5} more" if result[:redundancies].size > 5
        puts
      end
    end

    # vibe token optimize - Optimize file content
    def run_token_optimize(argv)
      options = parse_token_optimize_options(argv)

      unless options[:file]
        puts "Error: File path required"
        puts
        puts token_usage
        exit 1
      end

      unless File.exist?(options[:file])
        puts "Error: File not found: #{options[:file]}"
        exit 1
      end

      content = File.read(options[:file])
      optimizer = TokenOptimizer.new

      optimize_options = {
        remove_redundancies: options[:remove_redundancies],
        compress_whitespace: options[:compress_whitespace],
        selective_load: options[:sections]
      }

      result = optimizer.optimize(content, optimize_options)

      puts "\n⚡ Token Optimization: #{options[:file]}\n"
      puts "=" * 60
      puts
      puts "Original tokens: #{result[:original_tokens]}"
      puts "Optimized tokens: #{result[:optimized_tokens]}"
      puts "Savings: #{result[:savings_tokens]} tokens (#{result[:savings_percent]}%)"
      puts

      if options[:output]
        File.write(options[:output], result[:content])
        puts "✅ Optimized content written to: #{options[:output]}"
      elsif options[:in_place]
        File.write(options[:file], result[:content])
        puts "✅ File optimized in place"
      else
        puts "Preview (use --output or --in-place to save):"
        puts
        puts result[:content]
      end
    end

    # vibe token stats - Show token usage statistics
    def run_token_stats(argv)
      # TODO: Implement token usage tracking and statistics
      puts "\n📈 Token Usage Statistics\n"
      puts "=" * 60
      puts
      puts "Feature coming soon!"
      puts
      puts "This will show:"
      puts "  - Total tokens used per session"
      puts "  - Breakdown by skill/command"
      puts "  - Cost estimates"
      puts "  - Optimization savings"
    end

    private

    def parse_token_optimize_options(argv)
      options = {
        file: nil,
        output: nil,
        in_place: false,
        remove_redundancies: false,
        compress_whitespace: false,
        sections: nil
      }

      while (arg = argv.shift)
        case arg
        when "--output", "-o"
          options[:output] = argv.shift
        when "--in-place", "-i"
          options[:in_place] = true
        when "--remove-redundancies", "-r"
          options[:remove_redundancies] = true
        when "--compress", "-c"
          options[:compress_whitespace] = true
        when "--sections", "-s"
          options[:sections] = argv.shift&.split(",")
        else
          options[:file] = arg
        end
      end

      options
    end

    def token_usage
      <<~USAGE
        Usage: vibe token <subcommand> [options]

        Subcommands:
          analyze <file>              Analyze token usage of a file
          optimize <file> [options]   Optimize file content to reduce tokens
          stats                       Show token usage statistics

        Options for 'optimize':
          -o, --output <file>         Write optimized content to file
          -i, --in-place              Optimize file in place
          -r, --remove-redundancies   Remove duplicate content
          -c, --compress              Compress whitespace
          -s, --sections <list>       Only load specified sections (comma-separated)

        Examples:
          vibe token analyze ~/.claude/CLAUDE.md
          vibe token optimize config.md -r -c -o config.optimized.md
          vibe token optimize rules.md -i --sections "Memory,Skills"
          vibe token stats
      USAGE
    end
  end
end
