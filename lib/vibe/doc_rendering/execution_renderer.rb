# frozen_string_literal: true

module Vibe
  module DocRendering
    # Renders the execution policy document.
    module ExecutionRenderer
      def render_execution_policy_doc(manifest)
        <<~MD
          # Execution policy

          Generated target: `#{manifest['target']}`
          Active profile: `#{manifest['profile']}`
          Applied overlay: #{overlay_sentence(manifest)}

          ## Default execution flow

          1. Classify the task by capability tier.
          2. Pick the mapped executor from the active profile.
          3. Apply mandatory portable skills before claiming completion.
          4. If risk appears, follow the generated safety policy.
          5. For critical work, prefer maker-checker flow with `independent_verifier`.

          ## Always-on behavior policies

          #{bullet_policy_summary(filtered_policies(manifest, ['always_on']))}

          ## Mandatory portable skills

          #{bullet_skill_summary(mandatory_skills(manifest))}

          ## Optional portable skills

          #{bullet_skill_summary(optional_skills(manifest))}

          ## Safety actions

          #{bullet_target_actions(manifest)}
        MD
      end
    end
  end
end
