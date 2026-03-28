# frozen_string_literal: true

require_relative '../defaults'

module Vibe
  class SkillRouter
    # Layer 2: Scenario-based matching
    #
    # Matches user input against routing rules and exclusive skills
    # defined in the routing configuration, with context-aware scoring.
    class ScenarioLayer
      def initialize(routing_config, preferences)
        @routing_config = routing_config
        @preferences = preferences
      end

      # @param input [String] normalized user input
      # @param context [Hash] additional context (error_count, recent_files, etc.)
      # @return [Hash, nil] routing result or nil if no scenario matched
      def match_scenario(input, context)
        # First check routing_rules
        rules = @routing_config['routing_rules'] || []

        scored_rules = rules.map do |rule|
          score = calculate_scenario_score(rule, input, context)
          [rule, score]
        end.sort_by { |_, score| -score }

        best_rule, best_score = scored_rules.first

        if best_rule && best_score > 0.15
          primary = best_rule['primary']
          return {
            matched: true,
            skill: primary['skill'],
            source: primary['source'],
            scenario: best_rule['scenario'],
            reason: primary['reason'],
            confidence: score_to_confidence(best_score),
            alternatives: format_alternatives(best_rule['alternatives']),
            context_boost: context_boost_description(context)
          }
        end

        # Then check exclusive_skills
        exclusive_skills = @routing_config['exclusive_skills'] || []
        exclusive_skills.each do |exclusive|
          keywords = Array(exclusive['keywords']).map(&:downcase)
          next if keywords.empty?

          matched_keyword = keywords.find { |kw| input.include?(kw) }
          next unless matched_keyword

          return {
            matched: true,
            skill: exclusive['skill'],
            source: exclusive['source'],
            scenario: exclusive['scenario'],
            reason: exclusive['reason'],
            confidence: :high,
            exclusive: true
          }
        end

        nil
      end

      private

      def calculate_scenario_score(rule, input, context)
        keywords = Array(rule['keywords']).map(&:downcase)
        return 0 if keywords.empty?

        # Keyword matching
        keyword_matches = keywords.select { |kw| input.include?(kw) }
        keyword_score = keyword_matches.size.to_f / keywords.size

        # Boost by context relevance
        context_score = 0
        if rule['context_conditions']
          context_score = evaluate_context_conditions(rule['context_conditions'], context)
        end

        # Boost by recency/frequency
        recency_boost = 0
        if rule['scenario'] && @preferences['context_patterns'][rule['scenario']]
          recency_boost = 0.1 * @preferences['context_patterns'][rule['scenario']]['count'].to_i
          recency_boost = [recency_boost, 0.3].min
        end

        keyword_score * (1 + context_score) + recency_boost
      end

      def evaluate_context_conditions(conditions, context)
        score = 0

        conditions.each do |condition|
          case condition['type']
          when 'file_extension'
            if context[:recent_files]&.any? { |f| f.end_with?(condition['value']) }
              score += 0.2
            end
          when 'error_present'
            score += 0.3 if context[:error_count].to_i > 0
          when 'task_type'
            score += 0.15 if context[:current_task] == condition['value']
          end
        end

        score
      end

      def score_to_confidence(score)
        case score
        when Defaults::SCENARIO_VERY_HIGH..1.0 then :very_high
        when Defaults::CONFIDENCE_MEDIUM...Defaults::SCENARIO_VERY_HIGH then :high
        when Defaults::SCENARIO_MEDIUM...Defaults::CONFIDENCE_MEDIUM then :medium
        when 0.3...0.4 then :low
        else :very_low
        end
      end

      def format_alternatives(alternatives)
        Array(alternatives).map do |alt|
          {
            skill: alt['skill'],
            source: alt['source'],
            trigger: alt['trigger']
          }
        end
      end

      def context_boost_description(context)
        boosts = []
        boosts << "errors detected" if context[:error_count].to_i > 0
        boosts << "#{context[:file_type]} files" if context[:file_type]
        boosts << "#{context[:recent_files].size} recent files" if context[:recent_files]&.size&.> 3

        boosts.empty? ? nil : boosts.join(', ')
      end
    end
  end
end
