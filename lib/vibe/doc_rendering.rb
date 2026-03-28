# frozen_string_literal: true

require_relative 'doc_rendering/inspect_renderer'
require_relative 'doc_rendering/target_summary_renderer'
require_relative 'doc_rendering/policy_renderer'
require_relative 'doc_rendering/routing_renderer'
require_relative 'doc_rendering/skills_renderer'
require_relative 'doc_rendering/safety_renderer'
require_relative 'doc_rendering/execution_renderer'
require_relative 'doc_rendering/task_routing_renderer'
require_relative 'doc_rendering/test_standards_renderer'
require_relative 'doc_rendering/tools_renderer'

module Vibe
  # Markdown document renderers for inspect output, target summaries, and
  # per-concern documentation files (behavior, routing, skills, safety, etc.).
  #
  # Depends on methods from:
  #   Vibe::Utils          — format_backtick_list
  #   Vibe::OverlaySupport — overlay_sentence
  module DocRendering
    include InspectRenderer
    include TargetSummaryRenderer
    include PolicyRenderer
    include RoutingRenderer
    include SkillsRenderer
    include SafetyRenderer
    include ExecutionRenderer
    include TaskRoutingRenderer
    include TestStandardsRenderer
    include ToolsRenderer

    def initialize_yaml_cache
      @initialize_yaml_cache ||= {}
    end

    def load_yaml_cached(path)
      initialize_yaml_cache
      @initialize_yaml_cache[path] ||= read_yaml_abs(path)
    end

    def filtered_policies(manifest, groups)
      manifest['policies'].select do |policy|
        groups.include?(policy['target_render_group'])
      end
    end

    def mandatory_skills(manifest)
      manifest['skills'].select { |skill| skill['trigger_mode'] == 'mandatory' }
    end

    def optional_skills(manifest)
      manifest['skills'].reject { |skill| skill['trigger_mode'] == 'mandatory' }
    end

    def bullet_mapping(mapping)
      mapping.map { |tier, executor| "- `#{tier}` → `#{executor}`" }.join("\n")
    end

    def bullet_skill_summary(skills)
      return '- none' if skills.empty?

      skills.map do |skill|
        "- `#{skill['id']}` (`#{skill['priority']}`, " \
        "`#{skill['trigger_mode']}`) — #{skill['intent']}"
      end.join("\n")
    end

    def bullet_policy_summary(policies)
      return '- none' if policies.empty?

      policies.map do |policy|
        "- `#{policy['id']}` (`#{policy['enforcement']}`) — #{policy['summary']}"
      end.join("\n")
    end

    def bullet_target_actions(manifest)
      manifest.fetch('security').fetch('target_actions').map do |severity, action|
        "- `#{severity}` — #{action}"
      end.join("\n")
    end

    def indent_bullets(title, items)
      values = Array(items)
      return "  #{title}: none" if values.empty?

      ["  #{title}:"].concat(values.map { |item| "    - #{item}" }).join("\n")
    end

    def render_overlay_block(manifest)
      overlay = manifest['overlay']
      return '- none' if overlay.nil?

      patch_keys = Array(overlay['target_patch_keys'])

      [
        "- Name: `#{overlay['name']}`",
        "- Path: `#{overlay['display_path']}`",
        '- Profile mapping overrides: ' \
        "#{format_backtick_list((overlay['profile_mapping_overrides'] || {}).keys.sort)}",
        "- Extra profile notes: `#{overlay['profile_note_append_count']}`",
        "- Policy patches: `#{overlay['policy_patch_count']}`",
        "- Native patch keys: #{format_backtick_list(patch_keys)}"
      ].join("\n")
    end

    def render_native_overlay_block(manifest)
      patch = manifest['native_config_overlay']
      return '- none' if patch.nil? || patch.empty?

      patch.map do |key, value|
        detail = if value.is_a?(Hash)
                   value.keys.sort.map { |item| "`#{item}`" }.join(', ')
                 elsif value.is_a?(Array)
                   value.map { |item| "`#{item}`" }.join(', ')
                 else
                   "`#{value}`"
                 end
        detail = '`none`' if detail.nil? || detail.empty?
        "- `#{key}` → #{detail}"
      end.join("\n")
    end
  end
end
