# frozen_string_literal: true

module Vibe
  module DocRendering
    # Renders human-readable inspect output for the CLI.
    module InspectRenderer
      def render_inspect(payload)
        lines = []
        lines << 'Vibe inspection'
        lines << ''
        lines << "Repository root: #{payload['repo_root']}"
        lines << "Base portable behavior policies: #{payload['base_policy_count']}"
        lines << "Effective behavior policies: #{payload['effective_policy_count']}"
        lines << ''

        overlay = payload['overlay']
        if overlay
          lines << 'Requested overlay:'
          lines << "- name: #{overlay['name']}"
          lines << "- path: #{overlay['display_path']}"
          lines << '- target patches: ' \
                 "#{format_backtick_list(Array(overlay['target_patch_targets']))}"
        else
          lines << 'Requested overlay: none'
        end

        lines << ''
        marker = payload['current_repo_target']
        if marker
          lines << 'Current repo target marker:'
          lines << "- target: #{marker['target']}"
          lines << "- profile: #{marker['profile']}"
          lines << "- destination: #{marker['destination_root']}"
          lines << "- applied_at: #{marker['applied_at']}"
          if marker['overlay']
            lines << "- overlay: #{marker['overlay']['name']} " \
                     "(#{marker['overlay']['display_path']})"
          end
        else
          lines << 'Current repo target marker: none'
        end

        lines << ''
        lines << 'Targets:'

        payload['targets'].each do |target_info|
          lines << "- #{target_info['target']}"
          lines << "  default_profile: #{target_info['default_profile']} " \
                   "(#{target_info['profile_maturity']})"
          lines << "  generated_output: #{target_info['generated_output']}"
          lines << '  generated_manifest_present: ' \
                   "#{target_info['generated_manifest_present']}"
          resolved_overlay = target_info['overlay']
          resolved_overlay_name = resolved_overlay ? resolved_overlay['name'] : 'none'
          lines << "  resolved_overlay: #{resolved_overlay_name}"
          Array(target_info['profile_notes']).each do |note|
            lines << "  note: #{note}"
          end
        end

        lines.join("\n")
      end
    end
  end
end
