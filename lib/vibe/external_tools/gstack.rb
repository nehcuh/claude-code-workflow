# frozen_string_literal: true

module Vibe
  module ExternalTools
    # gstack skill pack detection and verification.
    module GStack
      # Only check unified storage location - individual skill symlinks are created
      # per-platform with naming format: gstack-{skill} (e.g., gstack-autoplan)
      GSTACK_DETECTION_PATHS = [
        '~/.config/skills/gstack' # Unified storage location (only real location)
      ].freeze

      # Platform-specific paths for skill symlinks
      GSTACK_PLATFORM_SYMLINK_PATHS = {
        'claude-code' => '~/.config/claude/skills',
        'opencode' => '~/.config/opencode/skills'
      }.freeze

      GSTACK_MARKER_FILES = %w[SKILL.md VERSION setup].freeze

      def detect_gstack
        skip_integrations = defined?(@skip_integrations) ? @skip_integrations : false
        return :not_installed if skip_integrations

        GSTACK_DETECTION_PATHS.each do |path|
          expanded = File.expand_path(path)
          return :installed if Dir.exist?(expanded) && gstack_markers_present?(expanded)
        end

        :not_installed
      end

      def gstack_location
        GSTACK_DETECTION_PATHS.each do |path|
          expanded = File.expand_path(path)
          return expanded if Dir.exist?(expanded) && gstack_markers_present?(expanded)
        end
        nil
      end

      def gstack_skills_count
        location = gstack_location
        return 0 unless location

        # Count subdirectories that contain a SKILL.md
        Dir.children(location).count do |entry|
          skill_path = File.join(location, entry, 'SKILL.md')
          File.directory?(File.join(location, entry)) && File.exist?(skill_path)
        end
      end

      def gstack_version
        location = gstack_location
        return nil unless location

        version_file = File.join(location, 'VERSION')
        return nil unless File.exist?(version_file)

        File.read(version_file).strip
      rescue StandardError
        nil
      end

      def verify_gstack(_target_platform = nil)
        status = detect_gstack
        return { installed: false, ready: false } if status == :not_installed

        location = gstack_location
        browse_ready = bun_available?

        {
          installed: true,
          ready: true,
          location: location,
          version: gstack_version,
          skills_count: gstack_skills_count,
          browse_ready: browse_ready
        }
      end

      private

      def bun_available?
        cmd_exist?('bun')
      end

      def gstack_markers_present?(dir)
        GSTACK_MARKER_FILES.all? { |f| File.exist?(File.join(dir, f)) }
      end

      public
    end
  end
end
