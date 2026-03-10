# frozen_string_literal: true

require_relative "user_interaction"

module Vibe
  # Superpowers Skill Pack installation.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  #
  # Dependencies:
  #   - Vibe::UserInteraction — for user prompts
  module SuperpowersInstaller
    include UserInteraction

    # Install Superpowers with interactive method selection
    # @param config [Hash] Integration configuration
    def install_superpowers(config)
      puts
      puts "   Installation method:"
      puts "   1) Claude Code plugin (recommended)"
      puts "   2) Manual clone and symlink"
      puts

      choice = ask_choice("   Choose [1-2]", ["1", "2"])

      case choice
      when "1"
        install_superpowers_plugin(config)
      when "2"
        install_superpowers_manual(config)
      end
    end

    # Install Superpowers as Claude Code plugin
    # @param config [Hash] Integration configuration
    def install_superpowers_plugin(config)
      puts
      puts "   ℹ️  Run these commands in your Claude Code session:"
      puts

      commands = config.dig("installation_methods", "claude-code", "commands") || []
      commands.each do |cmd|
        puts "      #{cmd}"
      end

      puts
      puts "   After installation, run: bin/vibe init --verify"
    end

    # Manual installation instructions for Superpowers
    # @param config [Hash] Integration configuration
    def install_superpowers_manual(config)
      puts
      puts "   Manual installation steps:"
      puts

      steps = config.dig("installation_methods", "manual", "steps") || []
      steps.each_with_index do |step, i|
        puts "   #{i + 1}. #{step}"
      end

      puts
      puts "   After installation, run: bin/vibe init --verify"
    end
  end
end
