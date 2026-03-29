# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../../lib/vibe/skill_router'
require_relative '../../lib/vibe/cache_manager'
require_relative '../../lib/vibe/llm_client'
require 'json'

# Integration test for the complete 5-layer routing system
class SkillRouterIntegrationTest < Minitest::Test
  def setup
    @project_root = Dir.mktmpdir
    @registry = {
      'skills' => [
        {
          'id' => 'systematic-debugging',
          'namespace' => 'builtin',
          'intent' => 'Find root cause before attempting fixes',
          'description' => 'Systematic debugging workflow',
          'priority' => 'P0',
          'keywords' => ['debug', 'bug', 'error']
        },
        {
          'id' => 'gstack/investigate',
          'namespace' => 'gstack',
          'intent' => 'Systematic debugging with scope freeze',
          'description' => 'Root cause investigation',
          'priority' => 'P0',
          'keywords' => ['investigate', 'debug']
        },
        {
          'id' => 'gstack/review',
          'namespace' => 'gstack',
          'intent' => 'Pre-landing code review',
          'description' => 'Code review with security checks',
          'priority' => 'P0',
          'keywords' => ['review', '检查']
        }
      ]
    }

    @preferences = { 'skill_usage' => {}, 'word_to_skill' => {} }

    # Create components
    @cache = Vibe::CacheManager.new(
      cache_dir: Dir.mktmpdir,
      memory_cache_max_size: 100
    )
    @llm_client = MockLLMClient.new

    # Create router with all 5 layers
    @router = Vibe::SkillRouter.new(@project_root)
    @router.instance_variable_set(:@cache, @cache)
    @router.instance_variable_set(:@llm_client, @llm_client)
    @router.instance_variable_set(:@registry, @registry)
    @router.instance_variable_set(:@preferences, @preferences)

    # Mock AI Triage Layer
    @ai_triage_layer = MockAITriageLayer.new(@registry, @preferences)
    @router.instance_variable_set(:@ai_triage_layer, @ai_triage_layer)
  end

  def teardown
    FileUtils.rm_rf(@cache.cache_dir) if @cache
  end

  # Test 1: End-to-end routing with AI Layer 0
  def test_end_to_end_routing_with_ai
    input = "帮我调试这个生产环境的 bug，很紧急"
    context = { file_type: 'js', error_count: 5 }

    # Mock AI layer response
    @ai_triage_layer.mock_response = {
      matched: true,
      skill: 'gstack/investigate',
      confidence: :high,
      triage_source: :ai,
      intent: '调试',
      urgency: '紧急'
    }

    # Test routing
    result = @router.route(input, context)

    assert_equal true, result[:matched]
    assert_equal 'gstack/investigate', result[:skill]
    assert_equal :ai, result[:triage_source]

    # Verify statistics
    stats = @router.stats
    assert_equal 1, stats[:routing][:total_routes]
    assert_equal 1, stats[:routing][:layer_distribution][:layer_0_ai]
  end

  # Test 2: Fallback from AI to Layer 1
  def test_fallback_from_ai_to_explicit_layer
    input = "用 gstack 审查这段代码"
    context = {}

    # Mock AI layer to return nil (no match)
    @ai_triage_layer.mock_response = nil

    # Should still work via Layer 1 (explicit override)
    result = @router.route(input, context)

    # Note: The exact result depends on how ExplicitLayer is implemented
    # This test verifies that routing continues even if AI fails
    assert result # Should not crash
  end

  # Test 3: Cache performance
  def test_cache_performance_improves_subsequent_requests
    input = "调试这个 bug"
    context = { file_type: 'rb' }

    # First call - should hit AI
    @ai_triage_layer.mock_response = {
      matched: true,
      skill: 'systematic-debugging',
      confidence: :high
    }

    result1 = @router.route(input, context)
    assert_equal 1, @ai_triage_layer.call_count

    # Second call - should hit cache
    result2 = @router.route(input, context)
    assert_equal 1, @ai_triage_layer.call_count # No additional calls

    assert_equal result1[:skill], result2[:skill]
  end

  # Test 4: Statistics tracking
  def test_statistics_tracking_all_layers
    # Simulate requests through different layers
    requests = [
      { input: "AI request", layer: :layer_0_ai, context: {} },
      { input: "explicit command", layer: :layer_1_explicit, context: {} },
      { input: "scenario match", layer: :layer_2_scenario, context: {} },
      { input: "no match", layer: :no_match, context: {} }
    ]

    requests.each_with_index do |req, index|
      @ai_triage_layer.mock_response = req[:layer] == :layer_0_ai ?
        { matched: true, skill: 'systematic-debugging', confidence: :high } :
        nil

      @router.route(req[:input], req[:context])
    end

    stats = @router.stats
    assert_equal 4, stats[:routing][:total_routes]
    assert stats[:routing][:layer_distribution][:layer_0_ai] > 0
  end

  # Test 5: Dynamic enable/disable
  def test_dynamic_enable_disable
    # Initially enabled
    assert @router.ai_triage_enabled?

    # Disable
    @router.disable_ai_triage
    refute @router.ai_triage_enabled?

    # Re-enable
    @router.enable_ai_triage
    assert @router.ai_triage_enabled?
  end

  # Test 6: Cache management
  def test_cache_management
    # Set some cache entries
    @cache.set('test_key', { value: 'test_data' }, ttl: 3600)

    # Clear all cache
    @router.clear_ai_cache

    # Verify cache is cleared
    assert_nil @cache.get('test_key')
  end

  # Test 7: Circuit breaker functionality
  def test_circuit_breaker_opens_on_repeated_failures
    # Simulate 3 failures
    3.times do
      @ai_triage_layer.mock_response = nil # Force failure
      @router.route("test input", {})
    end

    # Circuit should be open now
    stats = @router.stats
    assert stats[:ai_triage][:circuit_state] == :open

    # Reset circuit breaker
    @router.reset_circuit_breaker

    # Circuit should be closed now
    stats = @router.stats
    assert stats[:ai_triage][:circuit_state] == :closed
  end

  private

  # Mock AI Triage Layer for testing
  class MockAITriageLayer
    attr_accessor :mock_response, :call_count

    def initialize(registry, preferences)
      @registry = registry
      @preferences = preferences
      @call_count = 0
      @circuit_open = false
    end

    def route(input, context)
      @call_count += 1

      return @mock_response if @mock_response
      return nil if @circuit_open
      { matched: false, reason: 'No mock response set' }
    end

    def stats
      {
        enabled: true,
        model: 'mock-model',
        circuit_state: @circuit_open ? :open : :closed,
        failure_count: 0
      }
    end

    def reset_circuit_breaker
      @circuit_open = false
    end

    def enabled?
      true
    end
  end

  # Mock LLM Client for testing
  class MockLLMClient
    attr_accessor :mock_response, :raise_error, :call_count

    def initialize
      @call_count = 0
      @mock_response = nil
      @raise_error = nil
    end

    def call(model:, prompt:, max_tokens: 300, temperature: 0.3)
      @call_count += 1

      raise @raise_error if @raise_error
      return @mock_response if @mock_response

      JSON.generate({
        'skill' => 'systematic-debugging',
        'confidence' => 0.8,
        'reasoning' => 'Mock response'
      })
    end

    def configured?
      true
    end

    def stats
      {
        configured: true,
        call_count: @call_count
      }
    end
  end
end
