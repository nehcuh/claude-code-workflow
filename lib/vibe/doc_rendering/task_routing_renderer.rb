# frozen_string_literal: true

module Vibe
  module DocRendering
    # Renders the task complexity routing document.
    module TaskRoutingRenderer
      def render_task_routing_doc(manifest)
        return '' unless task_routing_doc

        complexity_sections = task_routing_doc.fetch('complexity_levels',
                                                     {}).map do |level, config|
          criteria = config.fetch('criteria', {}).map { |k, v| "  - #{k}: #{v}" }.join("\n")
          examples = config.fetch('examples', []).map { |ex| "  - #{ex}" }.join("\n")
          requirements = config.fetch('process_requirements', {}).map do |k, v|
            "  - #{k}: #{v}"
          end.join("\n")

          <<~SECTION.chomp
            ### #{level.capitalize}

            #{config['description']}

            **Criteria:**
            #{criteria}

            **Examples:**
            #{examples}

            **Process Requirements:**
            #{requirements}

            **Time Estimate:** #{config['time_estimate']}
          SECTION
        end.join("\n\n")

        auto_rules = task_routing_doc.fetch('auto_detection', {}).fetch('rules',
                                                                        []).map do |rule|
          "- #{rule['condition']} → `#{rule['complexity']}` (#{rule['reason']})"
        end.join("\n")

        <<~MD
          # Task Complexity Routing

          Generated target: `#{manifest['target']}`
          Applied overlay: #{overlay_sentence(manifest)}

          This document defines how to route tasks by complexity level to balance quality and efficiency.

          ## Complexity Levels

          #{complexity_sections}

          ## Auto-Detection Rules

          #{auto_rules}

          ## Override Policy

          Users can override complexity classification with justification:
          - "this is urgent, skip full process"
          - "treat this as trivial"
          - "this needs full review despite being small"
        MD
      end
    end
  end
end
