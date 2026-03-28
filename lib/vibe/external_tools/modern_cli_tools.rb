# frozen_string_literal: true

require 'rbconfig'

module Vibe
  module ExternalTools
    # Modern CLI tools detection and verification (eza, bat, fd, etc.).
    module ModernCLITools
      # Detect all modern CLI tools defined in modern-cli.yaml
      # @return [Array<Hash>] Array of tool detection results
      def detect_modern_cli_tools
        config = load_integration_config('modern-cli')
        return [] unless config

        tools = config['tools'] || []
        tools.map { |tool| detect_single_modern_tool(tool) }.compact
      end

      # Detect a single modern CLI tool, checking primary binary then alternatives
      # @param tool_def [Hash] Tool definition from YAML
      # @return [Hash] Detection result
      def detect_single_modern_tool(tool_def)
        binary = tool_def.dig('detection', 'binary')
        alternatives = tool_def.dig('detection', 'alternatives') || []

        found_binary = if cmd_exist?(binary)
                         binary
                       else
                         alternatives.find { |alt| cmd_exist?(alt) }
                       end

        build_modern_tool_result(tool_def, found_binary || binary, !found_binary.nil?)
      end

      # Build structured detection result for a tool
      # @param tool_def [Hash] Tool definition from YAML
      # @param binary [String] Binary name that was found (or primary if not found)
      # @param available [Boolean] Whether the tool was found in PATH
      # @return [Hash] Detection result
      def build_modern_tool_result(tool_def, binary, available)
        result = {
          traditional: tool_def['traditional'],
          modern: tool_def['modern'],
          category: tool_def['category'],
          available: available,
          binary: binary,
          usage_notes: tool_def['usage_notes'],
          use_cases: tool_def['use_cases'] || []
        }
        result[:path] = which_tool(binary) if available
        result
      end

      # Locate a command binary by scanning PATH entries directly (no subprocess).
      # Works on Windows (checks PATHEXT extensions) and Unix.
      # @param cmd [String] Command name
      # @return [String, nil] Full path to binary, or nil if not found
      def which_tool(cmd)
        exts = if RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin/i
                 (ENV['PATHEXT'] || '.exe;.bat;.cmd').split(';')
               else
                 ['']
               end

        ENV['PATH'].split(File::PATH_SEPARATOR).each do |dir|
          exts.each do |ext|
            exe = File.join(dir, "#{cmd}#{ext}")
            return exe if File.executable?(exe) && File.file?(exe)
          end
        end
        nil
      rescue StandardError
        nil
      end

      # Verify modern CLI tools status for a given platform
      # @return [Hash] Verification result with available/unavailable breakdown
      def verify_modern_cli_tools(_target_platform = nil)
        detected = detect_modern_cli_tools
        available = detected.select { |t| t[:available] }

        {
          installed: available.any?,
          ready: available.any?,
          available_tools: available,
          unavailable_tools: detected.reject { |t| t[:available] },
          total_count: detected.size,
          available_count: available.size
        }
      end
    end
  end
end
