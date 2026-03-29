#!/usr/bin/env ruby
# frozen_string_literal: true

# Multi-Provider Setup Verification Script
#
# This script verifies that your multi-provider setup is correctly configured.

require_relative '../lib/vibe/llm_provider/factory'
require_relative '../lib/vibe/skill_router/ai_triage_layer'
require 'json'

puts "╔════════════════════════════════════════════════════════════════╗"
puts "║     🔍 Multi-Provider Setup Verification                          ║"
puts "╚════════════════════════════════════════════════════════════════╝"
puts

all_checks_passed = true

# Check 1: Environment Variables
puts "📋 Check 1: Environment Variables"
puts "=" * 60

anthropic_key = ENV['ANTHROPIC_API_KEY']
openai_key = ENV['OPENAI_API_KEY']

if anthropic_key && !anthropic_key.empty?
  puts "✅ ANTHROPIC_API_KEY: Set (#{anthropic_key[0..7]}...)"
else
  puts "⚠️  ANTHROPIC_API_KEY: Not set"
end

if openai_key && !openai_key.empty?
  puts "✅ OPENAI_API_KEY: Set (#{openai_key[0..7]}...)"
else
  puts "⚠️  OPENAI_API_KEY: Not set"
end

if !anthropic_key && !openai_key
  puts
  puts "❌ ERROR: No API keys configured!"
  puts "   Please set at least one:"
  puts "   export ANTHROPIC_API_KEY=sk-ant-xxxxx"
  puts "   export OPENAI_API_KEY=sk-xxxxx"
  all_checks_passed = false
end

puts

# Check 2: Provider Detection
puts "🔍 Check 2: Provider Detection"
puts "=" * 60

available_providers = Vibe::LLMProvider::Factory.available_providers

if available_providers.empty?
  puts "❌ ERROR: No providers detected!"
  puts "   Please set API keys (see Check 1)"
  all_checks_passed = false
else
  puts "✅ Available Providers: #{available_providers.join(', ').upcase}"

  recommended = Vibe::LLMProvider::Factory.recommended_provider
  puts "📋 Recommended: #{recommended.upcase}"
end

puts

# Check 3: OpenCode Configuration
puts "📁 Check 3: OpenCode Configuration"
puts "=" * 60

opencode_provider = Vibe::LLMProvider::Factory.detect_opencode_provider

if opencode_provider
  puts "✅ OpenCode Config Detected: #{opencode_provider.upcase}"

  # Verify provider matches available
  if available_providers.include?(opencode_provider)
    puts "✅ Configured provider is available"
  else
    puts "⚠️  WARNING: Configured provider (#{opencode_provider}) not available!"
    puts "   Please set the corresponding API key"
    all_checks_passed = false
  end
else
  puts "ℹ️  No OpenCode configuration detected (optional)"
end

puts

# Check 4: Provider Creation
puts "🏭 Check 4: Provider Creation"
puts "=" * 60

available_providers.each do |provider_name|
  begin
    provider = Vibe::LLMProvider.create(provider: provider_name.to_sym)
    stats = provider.stats

    if stats[:configured]
      puts "✅ #{provider_name.upcase} Provider: Created and configured"
      puts "   ├─ Provider: #{stats[:provider]}"
      puts "   ├─ Base URL: #{stats[:base_url]}"
      puts "   └─ Models: #{provider.supported_models.size} available"
    else
      puts "⚠️  #{provider_name.upcase} Provider: Created but not configured"
      puts "   (API key may be missing or invalid)"
    end
  rescue => e
    puts "❌ #{provider_name.upcase} Provider: Failed to create"
    puts "   Error: #{e.message}"
    all_checks_passed = false
  end
end

puts

# Check 5: AI Triage Layer
puts "🧠 Check 5: AI Triage Layer"
puts "=" * 60

begin
  registry = { 'skills' => [] }
  preferences = { 'skill_usage' => {}, 'word_to_skill' => {} }

  # Try to create AI triage layer with auto-detected provider
  ai_layer = Vibe::SkillRouter::AITriageLayer.new(registry, preferences)
  stats = ai_layer.stats

  if stats[:enabled]
    puts "✅ AI Triage Layer: ENABLED"
    puts "   ├─ Provider: #{stats[:provider]}"
    puts "   ├─ Model: #{stats[:model]}"
    puts "   ├─ Configured: #{stats[:provider_configured]}"
    puts "   └─ Circuit State: #{stats[:circuit_state]}"
  else
    puts "⚠️  AI Triage Layer: DISABLED"
    if stats[:disabled_reason]
      puts "   Reason: #{stats[:disabled_reason]}"
    end
    puts "   ℹ️  System will use Layers 1-4 (algorithmic fallback)"
  end

  # Check cache
  cache_stats = stats[:cache_stats]
  if cache_stats
    puts
    puts "   📦 Cache Status:"
    puts "   ├─ Memory: #{cache_stats[:memory_cache_size]} items"
    puts "   ├─ File: #{cache_stats[:file_cache_size]} items"
    puts "   └─ Total: #{cache_stats[:total_hits]} hits, #{cache_stats[:total_misses]} misses"
  end
rescue => e
  puts "❌ AI Triage Layer: Failed to initialize"
  puts "   Error: #{e.message}"
  all_checks_passed = false
end

puts

# Check 6: Routing Accuracy Estimate
puts "📊 Check 6: Routing Accuracy Estimate"
puts "=" * 60

if available_providers.empty?
  puts "⚠️  No providers available"
  puts "   Expected Accuracy: 70% (Layers 1-4 only)"
else
  puts "✅ Providers available"
  puts "   Expected Accuracy: 95% (Layers 0-4)"
  puts
  puts "   Layer Breakdown:"
  puts "   ├─ Layer 0 (AI Triage): 95% accuracy, ~50-150ms"
  puts "   ├─ Layer 1 (Explicit): 100% accuracy, <1ms"
  puts "   ├─ Layer 2 (Scenario): 85% accuracy, <5ms"
  puts "   ├─ Layer 3 (Semantic): 75% accuracy, <10ms"
  puts "   └─ Layer 4 (Fuzzy): 60% accuracy, <15ms"
end

puts

# Final Summary
puts "╔════════════════════════════════════════════════════════════════╗"
puts "║                          Summary                                  ║"
puts "╚════════════════════════════════════════════════════════════════╝"
puts

if all_checks_passed
  puts "✅ All checks PASSED! Your multi-provider setup is ready."
  puts
  puts "🚀 You can now use the AI-powered skill routing system!"
  puts
  puts "Next Steps:"
  puts "1. Start Claude: claude"
  puts "2. Try a request: '帮我调试这个 bug'"
  puts "3. Check stats: router.stats"
  exit 0
else
  puts "⚠️  Some checks FAILED. Please fix the issues above."
  puts
  puts "Common Fixes:"
  puts "1. Set API key: export ANTHROPIC_API_KEY=sk-ant-xxxxx"
  puts "2. Or: export OPENAI_API_KEY=sk-xxxxx"
  puts "3. Update opencode.json if using OpenCode"
  puts "4. Run this script again: ruby examples/verify_multi_provider_setup.rb"
  exit 1
end
