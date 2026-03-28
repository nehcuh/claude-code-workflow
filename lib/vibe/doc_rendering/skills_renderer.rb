# frozen_string_literal: true

module Vibe
  module DocRendering
    # Renders portable skills documentation and trigger tables.
    module SkillsRenderer
      def render_skills_doc(manifest)
        skill_lines = manifest['skills'].map do |skill|
          support = skill['target_support'] || 'not-modeled'
          "- `#{skill['id']}` (`#{skill['namespace']}`, `#{skill['priority']}`, " \
          "`#{skill['trigger_mode']}`, support: `#{support}`) — #{skill['intent']}"
        end.join("\n")

        # Generate trigger scenarios table for suggest-mode external skills
        trigger_section = generate_skill_trigger_table(manifest)

        result = <<~MD
          # Portable skills

          Generated target: `#{manifest['target']}`
          Applied overlay: #{overlay_sentence(manifest)}

          #{skill_lines}
        MD

        # Only append trigger section if it's not empty
        result += trigger_section unless trigger_section.empty?
        result
      end

      def generate_skill_trigger_table(manifest)
        # Filter for suggest-mode external skills
        suggest_skills = manifest['skills'].select do |skill|
          skill['trigger_mode'] == 'suggest' && skill['namespace'] != 'builtin'
        end

        return '' if suggest_skills.empty?

        # Load trigger contexts from integration configs
        trigger_contexts = {}

        if respond_to?(:superpowers_doc)
          begin
            superpowers_config = superpowers_doc
            Array(superpowers_config['skills']).each do |skill|
              key = skill['registry_id'] || skill['id']
              trigger_contexts[key] = skill['trigger_context'] if skill['trigger_context']
            end
          rescue Vibe::ConfigurationError, Errno::ENOENT
            # superpowers.yaml not available
          end
        end

        # Build trigger table rows
        rows = suggest_skills.map do |skill|
          context = trigger_contexts[skill['id']] || 'See documentation'
          "| #{context} | `#{skill['id']}` | Auto-suggested when applicable |"
        end

        return '' if rows.empty?

        <<~TABLE


          ## When to Use External Skills

          The following external skills are automatically suggested in relevant scenarios:

          | Scenario | Skill | Notes |
          |----------|-------|-------|
          #{rows.join("\n")}
        TABLE
      end
    end
  end
end
