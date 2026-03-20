# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../lib/vibe/cascade_executor"

class TestCascadeExecutor < Minitest::Test
  def setup
    @ex = Vibe::CascadeExecutor.new
  end

  # ── add / validate ───────────────────────────────────────────────────────────

  def test_add_registers_task
    @ex.add("a", command: "exit 0")
    assert @ex.tasks.key?("a")
  end

  def test_add_raises_on_duplicate_id
    @ex.add("a", command: "exit 0")
    assert_raises(ArgumentError) { @ex.add("a", command: "exit 0") }
  end

  def test_validate_raises_on_unknown_dependency
    @ex.add("a", command: "exit 0", depends_on: ["nonexistent"])
    assert_raises(ArgumentError) { @ex.validate_graph! }
  end

  def test_validate_raises_on_cycle
    @ex.add("a", command: "exit 0", depends_on: ["b"])
    @ex.add("b", command: "exit 0", depends_on: ["a"])
    assert_raises(ArgumentError) { @ex.validate_graph! }
  end

  def test_validate_passes_for_valid_graph
    @ex.add("a", command: "exit 0")
    @ex.add("b", command: "exit 0", depends_on: ["a"])
    @ex.validate_graph!   # should not raise
  end

  # ── topological_order ────────────────────────────────────────────────────────

  def test_topological_order_single_chain
    @ex.add("a", command: "exit 0")
    @ex.add("b", command: "exit 0", depends_on: ["a"])
    @ex.add("c", command: "exit 0", depends_on: ["b"])

    order = @ex.topological_order
    assert_operator order.index("a"), :<, order.index("b")
    assert_operator order.index("b"), :<, order.index("c")
  end

  def test_topological_order_independent_tasks
    @ex.add("x", command: "exit 0")
    @ex.add("y", command: "exit 0")

    order = @ex.topological_order
    assert_includes order, "x"
    assert_includes order, "y"
  end

  # ── run: basic execution ─────────────────────────────────────────────────────

  def test_run_single_passing_task
    @ex.add("ok", command: "exit 0")
    result = @ex.run

    assert result[:success]
    assert_equal 1, result[:passed]
    assert_equal 0, result[:failed]
    assert_equal "completed", result[:tasks]["ok"]["status"]
  end

  def test_run_single_failing_task
    @ex.add("bad", command: "exit 1")
    result = @ex.run

    refute result[:success]
    assert_equal 1, result[:failed]
    assert_equal "failed", result[:tasks]["bad"]["status"]
  end

  def test_run_captures_output
    @ex.add("echo", command: "echo hello")
    result = @ex.run

    assert_includes result[:tasks]["echo"]["output"], "hello"
  end

  def test_run_records_exit_code
    @ex.add("ok",  command: "exit 0")
    @ex.add("bad", command: "exit 42")
    @ex.run

    assert_equal 0,  @ex.tasks["ok"]["exit_code"]
    assert_equal 42, @ex.tasks["bad"]["exit_code"]
  end

  # ── run: dependency ordering ──────────────────────────────────────────────────

  def test_run_respects_dependency_order
    order = []

    # We can't inject callbacks, so we use file-based sequencing
    tmpfile = Tempfile.new("cascade_order")
    tmpfile.close

    @ex.add("first",  command: "echo first  >> #{tmpfile.path}")
    @ex.add("second", command: "echo second >> #{tmpfile.path}", depends_on: ["first"])
    @ex.add("third",  command: "echo third  >> #{tmpfile.path}", depends_on: ["second"])
    @ex.run

    lines = File.readlines(tmpfile.path).map(&:strip)
    assert_equal %w[first second third], lines
  ensure
    tmpfile&.unlink
  end

  def test_run_parallel_independent_tasks
    # Both tasks should complete; order is non-deterministic
    @ex.add("a", command: "exit 0")
    @ex.add("b", command: "exit 0")
    result = @ex.run

    assert result[:success]
    assert_equal 2, result[:passed]
  end

  # ── run: failure propagation ──────────────────────────────────────────────────

  def test_run_skips_downstream_on_failure
    @ex.add("lint",  command: "exit 1")
    @ex.add("test",  command: "exit 0", depends_on: ["lint"])
    @ex.add("build", command: "exit 0", depends_on: ["test"])
    result = @ex.run

    assert_equal "failed",  result[:tasks]["lint"]["status"]
    assert_equal "skipped", result[:tasks]["test"]["status"]
    assert_equal "skipped", result[:tasks]["build"]["status"]
    assert_equal 2, result[:skipped]
  end

  def test_run_does_not_skip_unrelated_tasks_on_failure
    @ex.add("bad",       command: "exit 1")
    @ex.add("unrelated", command: "exit 0")
    result = @ex.run

    assert_equal "failed",    result[:tasks]["bad"]["status"]
    assert_equal "completed", result[:tasks]["unrelated"]["status"]
  end

  # ── run: summary ─────────────────────────────────────────────────────────────

  def test_run_summary_counts
    @ex.add("a", command: "exit 0")
    @ex.add("b", command: "exit 1")
    @ex.add("c", command: "exit 0", depends_on: ["b"])
    result = @ex.run

    assert_equal 3, result[:total]
    assert_equal 1, result[:passed]
    assert_equal 1, result[:failed]
    assert_equal 1, result[:skipped]
  end

  def test_run_timestamps_recorded
    @ex.add("t", command: "exit 0")
    @ex.run

    task = @ex.tasks["t"]
    refute_nil task["started_at"]
    refute_nil task["finished_at"]
  end
end

require "tempfile"
