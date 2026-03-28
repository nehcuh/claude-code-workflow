# frozen_string_literal: true

module Vibe
  module DocRendering
    # Renders routing profile and model configuration documents.
    module RoutingRenderer
      def render_routing_doc(manifest)
        tier_descriptions = manifest['tiers'].map do |tier_id, tier|
          [
            "- `#{tier_id}` — #{tier['description']} (role: `#{tier['default_role']}`)",
            indent_bullets('Route when', tier['route_when']),
            indent_bullets('Avoid when', tier['avoid_when'])
          ].join("\n")
        end.join("\n\n")

        routing_defaults = manifest['routing_defaults'].map do |key, value|
          if value.is_a?(Array)
            items = value.map { |item| "  - `#{item}`" }.join("\n")
            "- `#{key}`:\n#{items}"
          else
            "- `#{key}` = `#{value}`"
          end
        end.join("\n")

        model_config_note = render_model_config_note(manifest['target'],
                                                     manifest['profile_mapping'])

        <<~MD
          # Routing profile

          Generated target: `#{manifest['target']}`
          Active profile: `#{manifest['profile']}`
          Applied overlay: #{overlay_sentence(manifest)}

          ## Routing behavior policies

          #{bullet_policy_summary(filtered_policies(manifest, ['routing']))}

          ## Capability tiers

          #{tier_descriptions}

          ## Active mapping

          #{bullet_mapping(manifest['profile_mapping'])}

          #{model_config_note}

          ## Routing defaults

          #{routing_defaults}
        MD
      end

      def render_model_config_note(target, _profile_mapping)
        # Look up config note from providers.yaml profile data
        providers.fetch('profiles', {}).each_value do |profile|
          next unless profile['target'] == target

          note = profile['model_config_note']
          return note.strip if note && !note.strip.empty?
        end
        ''
      end
    end
  end
end
