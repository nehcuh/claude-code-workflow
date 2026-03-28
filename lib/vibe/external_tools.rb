# frozen_string_literal: true

require 'json'
require 'yaml'
require 'rbconfig'
require_relative 'errors'
require_relative 'external_tools/superpowers'
require_relative 'external_tools/rtk'
require_relative 'external_tools/gstack'
require_relative 'external_tools/modern_cli_tools'

module Vibe
  # External tool detection and integration support.
  #
  # Host requirements:
  #   @repo_root [String] — absolute path to the workflow repository root
  module ExternalTools
    include Vibe::ExternalTools::Superpowers
    include Vibe::ExternalTools::RTK
    include Vibe::ExternalTools::GStack
    include Vibe::ExternalTools::ModernCLITools

    # Cross-platform command existence check.
    # Uses 'where' on Windows, 'which' on Unix.
    def cmd_exist?(cmd)
      finder = if RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin/i
                 'where'
               else
                 'which'
               end
      system(finder, cmd, out: File::NULL, err: File::NULL)
    end

    # Load integration config for a specific tool
    def load_integration_config(tool_name)
      config_path = File.join(@repo_root, "core/integrations/#{tool_name}.yaml")
      return nil unless File.exist?(config_path)

      YAML.safe_load(File.read(config_path), aliases: true)
    rescue StandardError => e
      warn "Failed to load integration config for #{tool_name}: #{e.message}"
      nil
    end

    # Get all available integration configs
    def list_integrations
      integrations_dir = File.join(@repo_root, 'core/integrations')
      return [] unless Dir.exist?(integrations_dir)

      names = Dir.glob(File.join(integrations_dir, '*.yaml')).map do |path|
        File.basename(path, '.yaml')
      end
      names.reject { |name| name == 'README' }
    end

    # --- Integration Status Summary ---

    def integration_status
      @integration_status ||= {
        superpowers: verify_superpowers,
        rtk: verify_rtk,
        gstack: verify_gstack
      }
    end

    # Clear cached integration status (call after install/configure actions)
    def reset_integration_status!
      @integration_status = nil
    end

    def all_integrations_installed?
      status = integration_status
      status.values.all? { |s| s[:installed] }
    end

    def missing_integrations
      status = integration_status
      status.reject { |_name, s| s[:installed] }.keys
    end

    def pending_integrations
      status = integration_status
      status.reject { |_name, s| s[:ready] }.keys
    end

    def all_integrations_ready?
      status = integration_status
      status.values.all? { |s| s[:ready] }
    end
  end
end
