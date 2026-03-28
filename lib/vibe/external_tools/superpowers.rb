# frozen_string_literal: true

require 'pathname'

module Vibe
  module ExternalTools
    # Superpowers skill pack detection and verification.
    module Superpowers
      # Platform-specific superpowers paths.
      # skills_dir: directory where individual skill symlinks are created.
      # skills_source: the superpowers skills source directory that symlinks point into.
      # Note: Symlink naming format is {repo}-{skill} (e.g., superpowers-brainstorming)
      SUPERPOWERS_PLATFORM_PATHS = {
        'claude-code' => {
          plugin: '~/.claude/plugins/superpowers',
          skills_dir: '~/.config/claude/skills',
          skills_source: '~/.config/skills/superpowers/skills'
        },
        'opencode' => {
          plugin: '~/.config/opencode/plugins/superpowers.js',
          skills_dir: '~/.config/opencode/skills',
          skills_source: '~/.config/skills/superpowers/skills'
        }
      }.freeze

      def detect_superpowers(target_platform = nil)
        skip_integrations = defined?(@skip_integrations) ? @skip_integrations : false
        return :not_installed if skip_integrations

        current_platform = defined?(@target_platform) ? @target_platform : nil
        platform = target_platform || current_platform

        # Platform-specific detection
        if platform && SUPERPOWERS_PLATFORM_PATHS[platform]
          paths = SUPERPOWERS_PLATFORM_PATHS[platform]

          if paths[:plugin]
            expanded = File.expand_path(paths[:plugin])
            return :platform_plugin if File.exist?(expanded) || Dir.exist?(expanded)
          end

          if paths[:skills_dir] && paths[:skills_source]
            skills_dir = File.expand_path(paths[:skills_dir])
            source_dir = File.expand_path(paths[:skills_source])
            if Dir.exist?(skills_dir) && superpowers_symlinks_in(skills_dir,
                                                                 source_dir).any?
              return :platform_skills
            end
          end
        end

        # Cross-platform fallback: check common locations
        claude_plugins = File.expand_path('~/.claude/plugins/superpowers')
        return :claude_plugin if Dir.exist?(claude_plugins)

        # Check XDG-compliant shared location
        shared_clone = File.expand_path('~/.config/skills/superpowers')
        return :shared_clone if Dir.exist?(shared_clone)

        local_clone = File.expand_path('~/superpowers')
        return :local_clone if Dir.exist?(local_clone)

        :not_installed
      end

      def superpowers_location(target_platform = nil)
        current_platform = defined?(@target_platform) ? @target_platform : nil
        platform = target_platform || current_platform

        case detect_superpowers(platform)
        when :platform_plugin
          paths = SUPERPOWERS_PLATFORM_PATHS[platform]
          File.expand_path(paths[:plugin]) if paths
        when :platform_skills
          paths = SUPERPOWERS_PLATFORM_PATHS[platform]
          File.expand_path(paths[:skills_dir]) if paths
        when :claude_plugin
          File.expand_path('~/.claude/plugins/superpowers')
        when :shared_clone
          File.expand_path('~/.config/skills/superpowers')
        when :local_clone
          File.expand_path('~/superpowers')
        end
      end

      def superpowers_skills_count(target_platform = nil)
        current_platform = defined?(@target_platform) ? @target_platform : nil
        platform = target_platform || current_platform

        if platform && SUPERPOWERS_PLATFORM_PATHS[platform]
          paths = SUPERPOWERS_PLATFORM_PATHS[platform]
          if paths[:skills_dir] && paths[:skills_source]
            skills_dir = File.expand_path(paths[:skills_dir])
            source_dir = File.expand_path(paths[:skills_source])
            links = superpowers_symlinks_in(skills_dir, source_dir)
            return links.size if links.any?
          end
        end

        # Fallback: count skills in the shared clone
        shared_skills = File.expand_path('~/.config/skills/superpowers/skills')
        return Dir.children(shared_skills).size if Dir.exist?(shared_skills)

        0
      end

      # Returns entries in skills_dir whose symlink targets are inside source_dir.
      # Handles both relative and absolute symlink paths, and skips broken symlinks.
      # Supports new naming format: {repo}-{skill} (e.g., superpowers-brainstorming)
      def superpowers_symlinks_in(skills_dir, source_dir)
        return [] unless Dir.exist?(skills_dir)

        normalized_source = File.expand_path(source_dir)

        Dir.children(skills_dir).select do |entry|
          link_path = File.join(skills_dir, entry)
          next false unless File.symlink?(link_path)

          begin
            # Resolve symlink target to absolute path
            target = File.readlink(link_path)
            # Handle relative symlinks by resolving from the link's directory
            absolute_target = if Pathname.new(target).absolute?
                                target
                              else
                                File.expand_path(
                                  target, skills_dir
                                )
                              end

            # Check if target is inside source_dir
            # Also verify the entry name follows the expected pattern (superpowers-*)
            absolute_target.start_with?(normalized_source) && entry.start_with?('superpowers-')
          rescue Errno::ENOENT, Errno::ELOOP
            # Skip broken or circular symlinks
            warn "Warning: Broken symlink detected: #{link_path}" if ENV['VIBE_DEBUG']
            false
          end
        end
      end

      def verify_superpowers(target_platform = nil)
        current_platform = defined?(@target_platform) ? @target_platform : nil
        platform = target_platform || current_platform

        status = detect_superpowers(platform)
        return { installed: false } if status == :not_installed

        location = superpowers_location(platform)

        # For platform-specific detection, it's both installed and ready
        if %i[platform_plugin platform_skills].include?(status)
          return {
            installed: true,
            ready: true,
            method: status,
            location: location,
            skills_count: superpowers_skills_count(platform)
          }
        end

        # For fallback detection (shared_clone, local_clone, etc.):
        # platform is "ready" only if we can confirm platform-specific integration exists.
        # Unknown platforms (no entry in SUPERPOWERS_PLATFORM_PATHS) are assumed ready.
        platform_ready = platform.nil? || !SUPERPOWERS_PLATFORM_PATHS.key?(platform)

        # If platform has specific paths, check if they're actually configured
        if platform && SUPERPOWERS_PLATFORM_PATHS.key?(platform)
          paths = SUPERPOWERS_PLATFORM_PATHS[platform]
          if paths[:plugin]
            expanded = File.expand_path(paths[:plugin])
            platform_ready = true if File.exist?(expanded) || Dir.exist?(expanded)
          end
          if !platform_ready && paths[:skills_dir] && paths[:skills_source]
            skills_dir = File.expand_path(paths[:skills_dir])
            source_dir = File.expand_path(paths[:skills_source])
            platform_ready = true if superpowers_symlinks_in(skills_dir, source_dir).any?
          end
        end

        {
          installed: true,
          ready: platform_ready,
          method: status,
          location: location,
          skills_count: superpowers_skills_count(platform),
          platform_configured: platform_ready
        }
      end
    end
  end
end
