# frozen_string_literal: true

module Vibe
  module DocRendering
    # Renders the target summary markdown document.
    module TargetSummaryRenderer
      def render_target_summary(manifest)
        <<~MD
          # Generated target summary

          - Target: `#{manifest['target']}`
          - Profile: `#{manifest['profile']}`
          - Profile maturity: `#{manifest['profile_maturity']}`
          - Generated at: `#{manifest['generated_at']}`
          - Applied overlay: #{overlay_sentence(manifest)}

          ## Capability mapping

          #{bullet_mapping(manifest['profile_mapping'])}

          ## Overlay

          #{render_overlay_block(manifest)}

          ## Behavior policies

          #{bullet_policy_summary(manifest['policies'])}

          ## Skills

          #{bullet_skill_summary(manifest['skills'])}
        MD
      end
    end
  end
end
