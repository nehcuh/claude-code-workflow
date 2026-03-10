# frozen_string_literal: true

require_relative "platform_utils"
require_relative "user_interaction"
require_relative "integration_manager"

module Vibe
  # Quickstart setup for Claude Code.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  #
  # Dependencies:
  #   - Vibe::PlatformUtils — for platform-related utilities
  #   - Vibe::UserInteraction — for user prompts
  #   - Vibe::IntegrationManager — for integration suggestions
  module QuickstartRunner
    include PlatformUtils
    include UserInteraction
    include IntegrationManager

    # Run quickstart setup for Claude Code
    # @param options [Hash] Options hash with :force key
    def run_quickstart(options = {})
      puts "\n⚡ Quickstart: Claude Code Setup"
      puts "=" * 50
      puts

      claude_home = File.expand_path("~/.claude")
      is_update = Dir.exist?(claude_home)

      if is_update
        puts "Claude Code configuration already exists at #{claude_home}."
        unless options[:force] || ask_yes_no("Would you like to overwrite it with the latest Vibe template?")
          puts "\nQuickstart cancelled. No changes made."
          return
        end
      else
        puts "Setting up Claude Code workflow in #{claude_home}..."
      end

      # Execute the use command logic
      begin
        target = "claude-code"
        profile_name, profile = resolve_profile(target, nil)
        destination_root = claude_home
        output_root = resolve_output_root_for_use(
          target: target,
          destination_root: destination_root,
          explicit_output: nil
        )
        overlay = resolve_overlay(explicit_path: nil, search_roots: [destination_root, @repo_root])

        manifest = build_target(
          target: target,
          profile_name: profile_name,
          profile: profile,
          output_root: output_root,
          overlay: overlay
        )

        FileUtils.mkdir_p(destination_root)
        copy_tree_contents(output_root, destination_root)

        write_marker(
          File.join(destination_root, ".vibe-target.json"),
          destination_root: destination_root,
          manifest: manifest,
          output_root: output_root,
          mode: "quickstart"
        )

        puts "\n✅ Success! Claude Code workflow has been #{is_update ? 'updated' : 'installed'}."
        puts

        # Check and suggest optional integrations (skip if @skip_integrations is set)
        check_and_suggest_integrations("claude-code") unless @skip_integrations

        puts "Next steps:"
        puts "1. Open #{File.join(claude_home, 'CLAUDE.md')} and customize these sections:"
        puts "   - User Info (name, project routes)"
        puts "   - Sub-project Memory Routes (map your projects to memory files)"
        puts "2. (Optional) Run `bin/vibe init` to install Superpowers or RTK."
        puts "3. Start a new session: claude"
        puts
      rescue StandardError => e
        puts "\n❌ Quickstart failed: #{e.message}"
        raise e
      end
    end
  end
end
