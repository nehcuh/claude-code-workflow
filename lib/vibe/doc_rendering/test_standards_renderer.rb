# frozen_string_literal: true

module Vibe
  module DocRendering
    # Renders the test coverage standards document.
    module TestStandardsRenderer
      def render_test_standards_doc(manifest)
        return '' unless test_standards_doc

        coverage_sections = test_standards_doc.fetch('coverage_by_complexity',
                                                     {}).map do |level, config|
          <<~SECTION.chomp
            ### #{level.capitalize}

            #{config['description']}

            - Unit coverage: #{config['unit_coverage']}%
            - Integration coverage: #{config['integration_coverage']}%
            - Manual verification: #{config['manual_verification']}
          SECTION
        end.join("\n\n")

        critical_paths = test_standards_doc.fetch('critical_paths', []).map do |path|
          pattern = path['path_pattern'] || path['function_pattern']
          "- `#{pattern}` → #{path['coverage']}% (#{path['reason']})"
        end.join("\n")

        test_types = test_standards_doc.fetch('test_types', {}).map do |type, config|
          required = config.fetch('required_for', []).map { |r| "`#{r}`" }.join(', ')
          examples = config.fetch('examples', []).map { |ex| "  - #{ex}" }.join("\n")

          section = <<~SECTION.chomp
            ### #{type.capitalize}

            #{config['description']}

            **Required for:** #{required}
          SECTION

          if config['must_cover']
            must_cover = config['must_cover'].map { |item| "  - #{item}" }.join("\n")
            section += "\n\n**Must Cover:**\n#{must_cover}"
          end

          section += "\n\n**Examples:**\n#{examples}" unless examples.empty?
          section
        end.join("\n\n")

        <<~MD
          # Test Coverage Standards

          Generated target: `#{manifest['target']}`
          Applied overlay: #{overlay_sentence(manifest)}

          This document defines minimum test requirements by task complexity and code type.

          ## Coverage by Complexity

          #{coverage_sections}

          ## Critical Paths

          These paths require 100% coverage regardless of complexity:

          #{critical_paths}

          ## Test Types

          #{test_types}

          ## Exemptions

          - Documentation-only changes: 0% coverage
          - Test code itself: optional coverage
          - Generated code: optional coverage
        MD
      end
    end
  end
end
