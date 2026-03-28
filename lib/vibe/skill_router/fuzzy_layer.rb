# frozen_string_literal: true

module Vibe
  class SkillRouter
    # Layer 4: Fuzzy fallback with user preferences
    #
    # Falls back to personalized skill recommendations based on
    # the user's past usage history when no other layer matched.
    class FuzzyLayer
      include SemanticMatcher

      def initialize(registry, preferences)
        @registry = registry
        @preferences = preferences
      end

      # @param input [String] normalized user input
      # @param context [Hash] additional context (unused but kept for API consistency)
      # @return [Hash, nil] routing result or nil if no fuzzy match
      def fuzzy_fallback_match(input, _context)
        # Check user preferences
        personalized = personalized_skills_for_input(input)

        return nil if personalized.empty?

        best_skill_id, best_data = personalized.first

        # Find skill details
        skill = @registry['skills']&.find { |s| s['id'] == best_skill_id }
        return nil unless skill

        {
          matched: true,
          skill: skill['id'],
          source: skill['namespace'],
          reason: "Based on your usage history: #{best_data[:reasons].first}",
          confidence: :medium,
          personalized: true,
          usage_count: best_data[:reasons].size
        }
      end

      private

      def personalized_skills_for_input(input)
        words = tokenize(input.downcase)
        skill_scores = Hash.new { |h, k| h[k] = { score: 0, reasons: [] } }

        words.each do |word|
          next if STOP_WORDS.include?(word)

          matches = @preferences['word_to_skill'][word]
          next unless matches

          matches.each do |skill_id, stats|
            helpfulness = stats[:count] > 0 ? stats[:helpful].to_f / stats[:count] : 0
            skill_scores[skill_id][:score] += helpfulness * Math.log(stats[:count] + 1)
            skill_scores[skill_id][:reasons] << "Matched word '#{word}' (#{stats[:count]}x used)"
          end
        end

        skill_scores.sort_by { |_, v| -v[:score] }.first(5).to_h
      end
    end
  end
end
