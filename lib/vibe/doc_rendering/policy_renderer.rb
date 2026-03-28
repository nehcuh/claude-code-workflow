# frozen_string_literal: true

module Vibe
  module DocRendering
    # Renders behavior and general workflow policy documents.
    module PolicyRenderer
      def render_behavior_doc(manifest)
        body = manifest['policies'].map do |policy|
          refs = Array(policy['source_refs']).map { |ref| "`#{ref}`" }.join(', ')
          refs = refs.empty? ? 'none' : refs
          [
            "- `#{policy['id']}` (#{policy['category']}, " \
            "#{policy['enforcement']}, " \
            "group: #{policy['target_render_group']})",
            "  - #{policy['summary']}",
            "  - source refs: #{refs}"
          ].join("\n")
        end.join("\n")

        source_note = if manifest['target'] != 'claude-code'
                        "\n> **Note:** Source refs refer to files in the portable " \
                        "workflow repository, not this generated output directory.\n"
                      else
                        ''
                      end

        <<~MD
          # Behavior policies

          Generated target: `#{manifest['target']}`
          Applied overlay: #{overlay_sentence(manifest)}
          #{source_note}
          #{body}
        MD
      end

      def render_general_doc(manifest)
        <<~MD
          # General workflow

          Generated target: `#{manifest['target']}`
          Generated profile: `#{manifest['profile']}`
          Applied overlay: #{overlay_sentence(manifest)}

          ## Working rules

          #{bullet_policy_summary(filtered_policies(manifest, %w[always_on routing safety]))}
        MD
      end
    end
  end
end
