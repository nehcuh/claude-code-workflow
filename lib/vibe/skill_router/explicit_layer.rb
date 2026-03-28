# frozen_string_literal: true

module Vibe
  class SkillRouter
    # Layer 1: Explicit user override
    #
    # Checks for user-specified skill source overrides via keywords
    # (e.g. "用 gstack" or "用 superpowers").
    class ExplicitLayer
      def initialize(routing_config)
        @routing_config = routing_config
      end

      # @param input [String] normalized user input
      # @return [Hash, nil] routing result or nil if no override matched
      def check_explicit_override(input)
        return nil unless @routing_config['user_override']&.dig('enabled')

        keywords = @routing_config['user_override']['keywords'] || {}

        keywords.each do |keyword, description|
          if input.include?(keyword.downcase)
            source = keyword.split.last
            return {
              matched: true,
              skill: nil,
              source: source,
              reason: "User explicit override: #{description}",
              confidence: :absolute,
              override: true
            }
          end
        end

        nil
      end
    end
  end
end
