# frozen_string_literal: true

module Vibe
  # Platform-related utility methods.
  #
  # Host requirements:
  #   None (self-contained utilities)
  module PlatformUtils
    # Normalize platform name to internal target name
    # @param platform [String] Platform name (e.g., "claude", "claude-code")
    # @return [String] Normalized platform name
    def normalize_target(platform)
      case platform.to_s.downcase
      when "claude-code", "claude"
        "claude-code"
      when "opencode"
        "opencode"
      when "kimi-code", "kimi"
        "kimi-code"
      when "cursor"
        "cursor"
      when "codex-cli", "codex"
        "codex-cli"
      when "vscode", "vs-code"
        "vscode"
      when "warp"
        "warp"
      when "antigravity"
        "antigravity"
      else
        platform.to_s.downcase
      end
    end

    # Get human-readable platform label
    # @param platform [String] Platform name
    # @return [String] Human-readable label
    def platform_label(platform)
      case normalize_target(platform)
      when "claude-code"
        "Claude Code"
      when "opencode"
        "OpenCode"
      when "kimi-code"
        "Kimi Code"
      when "cursor"
        "Cursor"
      when "codex-cli"
        "Codex CLI"
      when "vscode"
        "VS Code"
      when "warp"
        "Warp"
      when "antigravity"
        "Antigravity"
      else
        platform.to_s.capitalize
      end
    end

    # Get default global destination directory for a target
    # @param target [String] Target name
    # @return [String] Absolute path to global config directory
    def default_global_destination(target)
      case target
      when "claude-code"
        File.expand_path("~/.claude")
      when "opencode"
        File.expand_path("~/.opencode")
      when "kimi-code"
        File.expand_path("~/.kimi")
      when "cursor"
        File.expand_path("~/.cursor")
      when "codex-cli"
        File.expand_path("~/.codex")
      else
        File.expand_path("~/.#{target}")
      end
    end

    # Get config entrypoint filename for a target
    # @param target [String] Target name
    # @return [String] Entrypoint filename
    def config_entrypoint(target)
      case target
      when "claude-code"
        "CLAUDE.md"
      when "opencode"
        "opencode.json"
      when "kimi-code"
        "KIMI.md"
      else
        "config.md"
      end
    end

    # Get platform-specific command name
    # @param platform [String] Platform name
    # @return [String] Command name
    def platform_command(platform)
      case normalize_target(platform)
      when "claude-code" then "claude"
      when "codex-cli" then "codex"
      when "kimi-code" then "kimi"
      when "vscode" then "code"
      else normalize_target(platform)
      end
    end
  end
end
