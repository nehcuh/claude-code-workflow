# frozen_string_literal: true

module Vibe
  module DocRendering
    # Renders the safety policy document.
    module SafetyRenderer
      def render_safety_doc(manifest)
        target_actions = manifest.fetch('security').fetch('target_actions')
        severity_lines = manifest.fetch('security')
                                 .fetch('severity_levels')
                                 .map do |severity, rule|
          examples = Array(rule['examples']).map { |example| "  - #{example}" }.join("\n")
          "- `#{severity}` — #{rule['meaning']}\n#{examples}"
        end.join("\n")

        action_lines = target_actions.map do |severity, action|
          "- `#{severity}` — #{action}"
        end.join("\n")

        signal_lines = manifest.fetch('security')
                               .fetch('signal_categories')
                               .map do |category|
          indicators = Array(category['indicators'])
                       .map { |indicator| "`#{indicator}`" }
                       .join(', ')
          upgrades = Array(category['upgrade_to_p0_when'])
                     .map { |item| "`#{item}`" }
                     .join(', ')
          line = "- `#{category['id']}` (base: `#{category['base_severity']}`) " \
                 "— indicators: #{indicators}"
          line += " | upgrade when: #{upgrades}" unless upgrades.empty?
          line
        end.join("\n")

        adjudication = manifest.fetch('security')
                               .fetch('adjudication_factors')
                               .map do |item|
          "- `#{item}`"
        end.join("\n")

        <<~MD
          # Safety policy

          Applied overlay: #{overlay_sentence(manifest)}

          ## Safety behavior policy

          #{bullet_policy_summary(filtered_policies(manifest, ['safety']))}

          ## Native config overlay

          #{render_native_overlay_block(manifest)}

          ## Severity semantics

          #{severity_lines}

          ## Target actions

          #{action_lines}

          ## Signal categories

          #{signal_lines}

          ## Adjudication factors

          #{adjudication}
        MD
      end
    end
  end
end
