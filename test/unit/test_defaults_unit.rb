# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/vibe/defaults'

class TestDefaultsUnit < Minitest::Test
  def test_confidence_high
    assert_equal 0.8, Vibe::Defaults::CONFIDENCE_HIGH
  end

  def test_confidence_medium
    assert_equal 0.6, Vibe::Defaults::CONFIDENCE_MEDIUM
  end

  def test_confidence_low
    assert_equal 0.4, Vibe::Defaults::CONFIDENCE_LOW
  end

  def test_confidence_very_high
    assert_equal 0.9, Vibe::Defaults::CONFIDENCE_VERY_HIGH
  end

  def test_confidence_default
    assert_equal 0.5, Vibe::Defaults::CONFIDENCE_DEFAULT
  end

  def test_semantic_min_score
    assert_equal 0.5, Vibe::Defaults::SEMANTIC_MIN_SCORE
  end

  def test_semantic_high
    assert_equal 0.7, Vibe::Defaults::SEMANTIC_HIGH
  end

  def test_semantic_low
    assert_equal 0.3, Vibe::Defaults::SEMANTIC_LOW
  end

  def test_char_similarity_weight
    assert_equal 0.7, Vibe::Defaults::CHAR_SIMILARITY_WEIGHT
  end

  def test_scenario_very_high
    assert_equal 0.8, Vibe::Defaults::SCENARIO_VERY_HIGH
  end

  def test_scenario_medium
    assert_equal 0.4, Vibe::Defaults::SCENARIO_MEDIUM
  end

  def test_min_occurrences
    assert_equal 3, Vibe::Defaults::MIN_OCCURRENCES
  end

  def test_min_success_rate
    assert_equal 0.7, Vibe::Defaults::MIN_SUCCESS_RATE
  end

  def test_min_sequence_length
    assert_equal 3, Vibe::Defaults::MIN_SEQUENCE_LENGTH
  end

  def test_scan_recent_sessions
    assert_equal 20, Vibe::Defaults::SCAN_RECENT_SESSIONS
  end

  def test_trigger_min_occurrences
    assert_equal 2, Vibe::Defaults::TRIGGER_MIN_OCCURRENCES
  end

  def test_trigger_max_entries
    assert_equal 100, Vibe::Defaults::TRIGGER_MAX_ENTRIES
  end

  def test_trigger_max_cache_age_days
    assert_equal 30, Vibe::Defaults::TRIGGER_MAX_CACHE_AGE_DAYS
  end

  def test_clone_timeout
    assert_equal 60, Vibe::Defaults::CLONE_TIMEOUT
  end

  def test_confidence_label_high
    assert_equal 'High', Vibe::Defaults.confidence_label(0.85)
  end

  def test_confidence_label_exactly_high_threshold
    assert_equal 'High', Vibe::Defaults.confidence_label(0.8)
  end

  def test_confidence_label_medium
    assert_equal 'Medium', Vibe::Defaults.confidence_label(0.7)
  end

  def test_confidence_label_exactly_medium_threshold
    assert_equal 'Medium', Vibe::Defaults.confidence_label(0.6)
  end

  def test_confidence_label_low
    assert_equal 'Low', Vibe::Defaults.confidence_label(0.3)
  end

  def test_confidence_label_just_below_medium
    assert_equal 'Low', Vibe::Defaults.confidence_label(0.59)
  end

  def test_confidence_label_zero
    assert_equal 'Low', Vibe::Defaults.confidence_label(0.0)
  end

  def test_confidence_label_one
    assert_equal 'High', Vibe::Defaults.confidence_label(1.0)
  end

  def test_all_constants_are_numeric
    Vibe::Defaults.constants.each do |name|
      val = Vibe::Defaults.const_get(name)
      assert_kind_of Numeric, val, "Expected #{name} to be Numeric, got #{val.class}"
    end
  end

  def test_no_nil_constants
    Vibe::Defaults.constants.each do |name|
      val = Vibe::Defaults.const_get(name)
      refute_nil val, "Constant #{name} should not be nil"
    end
  end
end
