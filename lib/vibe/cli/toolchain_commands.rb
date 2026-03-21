# frozen_string_literal: true

require_relative '../toolchain_detector'

module Vibe
  module ToolchainCommands
    def run_toolchain_command(argv)
      subcommand = argv.shift

      case subcommand
      when 'detect'  then run_toolchain_detect(argv)
      when 'suggest' then run_toolchain_suggest(argv)
      when nil, 'help', '--help', '-h' then puts toolchain_usage
      else
        raise Vibe::ValidationError,
              "Unknown toolchain subcommand: #{subcommand}\n\n#{toolchain_usage}"
      end
    end

    def run_toolchain_detect(argv)
      dir = argv.shift || Dir.pwd
      detector = ToolchainDetector.new(dir)
      result = detector.detect

      puts "\n🔍 Toolchain Detection: #{dir}\n#{'=' * 60}"
      puts "Primary language: #{result[:primary_language]}"
      puts

      print_toolchain_section('Package managers', result[:package_managers])
      print_toolchain_section('Build tools',      result[:build_tools])
      print_toolchain_section('Test frameworks',  result[:test_frameworks])
    end

    def run_toolchain_suggest(argv)
      dir = argv.shift || Dir.pwd
      detector = ToolchainDetector.new(dir)
      cmds = detector.suggested_commands

      puts "\n💡 Suggested Commands: #{dir}\n#{'=' * 60}"

      if cmds.empty?
        puts 'No toolchain detected in this directory.'
        return
      end

      cmds.each do |action, cmd|
        puts "  #{action}: #{cmd}"
      end
      puts
    end

    private

    def print_toolchain_section(title, items)
      return if items.empty?

      puts "#{title}:"
      items.each do |item|
        files = item[:matched_files].join(', ')
        puts "  ✅ #{item[:name]}  [#{item[:ecosystem]}]  (#{files})"
      end
      puts
    end

    def toolchain_usage
      <<~USAGE
        Usage: vibe toolchain <subcommand> [dir]

        Subcommands:
          detect  [dir]   Detect toolchain in directory (default: cwd)
          suggest [dir]   Show suggested commands for detected toolchain

        Examples:
          vibe toolchain detect
          vibe toolchain detect ~/my-project
          vibe toolchain suggest
      USAGE
    end
  end
end
