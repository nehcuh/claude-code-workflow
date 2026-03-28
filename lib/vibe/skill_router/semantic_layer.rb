# frozen_string_literal: true

module Vibe
  class SkillRouter
    # Layer 3: Enhanced semantic matching
    #
    # Uses TF-IDF and cosine similarity to match user input against
    # skill intents and descriptions, boosted by preference history
    # and context relevance.
    class SemanticLayer
      include SemanticMatcher

      def initialize(registry, preferences)
        @registry = registry
        @preferences = preferences
      end

      # @param input [String] normalized user input
      # @param context [Hash] additional context
      # @return [Hash, nil] routing result or nil if no semantic match
      def enhanced_semantic_match(input, context)
        return nil unless @registry['skills']

        skills = @registry['skills']

        # Build candidate texts from intents and descriptions
        candidates = skills.map do |skill|
          {
            skill: skill,
            text: [skill['intent'], skill['description']].compact.join(' ').downcase
          }
        end

        # Use fuzzy matching for better typo tolerance
        matches = fuzzy_match(input, candidates.map { |c| c[:text] })

        # Filter by threshold and boost by user preferences
        best_match = nil
        best_score = 0

        matches.each_with_index do |match, idx|
          next if match[:score] < 0.25

          candidate = candidates[idx]
          skill = candidate[:skill]

          score = match[:score]

          # Boost by user preference history
          pref_boost = preference_boost(skill['id'])
          score *= (1 + pref_boost)

          # Boost by context relevance
          context_boost = context_skill_relevance(skill, context)
          score *= (1 + context_boost)

          if score > best_score
            best_score = score
            best_match = skill
          end
        end

        return nil unless best_match && best_score > 0.3

        {
          matched: true,
          skill: best_match['id'],
          source: best_match['namespace'],
          reason: "Semantic match: #{best_match['intent']}",
          confidence: semantic_score_to_confidence(best_score),
          semantic: true,
          similarity: best_score.round(3)
        }
      end

      private

      def context_skill_relevance(skill, context)
        return 0 unless context[:file_type] && skill['file_types']

        skill['file_types'].include?(context[:file_type]) ? 0.15 : 0
      end

      def preference_boost(skill_id)
        usage = @preferences['skill_usage'][skill_id]
        return 0 unless usage && usage[:count] > 0

        helpfulness = usage[:helpful].to_f / usage[:count]
        frequency_bonus = [Math.log(usage[:count]) * 0.05, 0.2].min

        helpfulness * frequency_bonus
      end

      def semantic_score_to_confidence(score)
        case score
        when 0.7..1.0 then :high
        when 0.5...0.7 then :medium
        when 0.3...0.5 then :low
        else :very_low
        end
      end
    end
  end
end
