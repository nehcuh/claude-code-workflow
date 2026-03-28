# frozen_string_literal: true

require 'json'
require 'open3'
require 'rbconfig'

module Vibe
  module ExternalTools
    # RTK (Rust Token Killer) detection and verification.
    module RTK
      def detect_rtk
        skip_integrations = defined?(@skip_integrations) ? @skip_integrations : false
        return :not_installed if skip_integrations

        # Method 1: Check if rtk binary is in PATH
        return :installed if cmd_exist?('rtk')

        # Method 2: Check Claude settings.json for hook
        return :hook_configured if rtk_hook_configured?

        :not_installed
      end

      def rtk_version
        return nil unless detect_rtk == :installed

        version_output, status = Open3.capture2('rtk', '--version', err: File::NULL)
        status.success? && !version_output.strip.empty? ? version_output.strip : nil
      rescue StandardError => e
        warn "Warning: Failed to get RTK version: #{e.message}" if ENV['VIBE_DEBUG']
        nil
      end

      def rtk_binary_path
        return nil unless detect_rtk == :installed

        finder = if RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin/i
                   'where'
                 else
                   'which'
                 end
        path_output, status = Open3.capture2(finder, 'rtk', err: File::NULL)
        status.success? ? path_output.strip : nil
      rescue StandardError => e
        warn "Warning: Failed to get RTK binary path: #{e.message}" if ENV['VIBE_DEBUG']
        nil
      end

      def rtk_hook_configured?
        settings_path = File.expand_path('~/.claude/settings.json')
        return false unless File.exist?(settings_path)

        begin
          settings = JSON.parse(File.read(settings_path))

          # Check new PreToolUse hook format (RTK 0.27+)
          pre_tool_use = settings.dig('hooks', 'PreToolUse')
          if pre_tool_use.is_a?(Array)
            pre_tool_use.each do |hook_config|
              next unless hook_config['matcher'] == 'Bash'

              hooks = hook_config['hooks']
              next unless hooks.is_a?(Array)

              hooks.each do |h|
                return true if h['command']&.include?('rtk')
              end
            end
          end

          # Fallback: check old bashCommandPrepare format
          hook = settings.dig('hooks', 'bashCommandPrepare')
          hook.is_a?(String) && hook.include?('rtk')
        rescue JSON::ParserError
          false
        end
      end

      def install_rtk_via_homebrew
        return false unless cmd_exist?('brew')

        puts 'Installing RTK via Homebrew...'
        system('brew', 'install', 'rtk')
      end

      def configure_rtk_hook
        return false unless detect_rtk == :installed

        puts 'Configuring RTK hook...'
        system('rtk', 'init', '--global')
      end

      def verify_rtk(target_platform = nil)
        current_platform = defined?(@target_platform) ? @target_platform : nil
        platform = target_platform || current_platform

        status = detect_rtk
        hook_configured = rtk_hook_configured?
        binary_installed = (status == :installed)

        # For non-claude-code platforms, hook is not required
        rtk_needs_hook = platform.nil? || platform == 'claude-code'
        ready = binary_installed && (rtk_needs_hook ? hook_configured : true)

        {
          installed: binary_installed,
          ready: ready,
          status: status,
          binary: binary_installed ? rtk_binary_path : nil,
          version: binary_installed ? rtk_version : nil,
          hook_configured: hook_configured
        }
      end
    end
  end
end
