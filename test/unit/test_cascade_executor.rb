# frozen_string_literal: true

require 'minitest/autorun'
require 'tempfile'
require 'tmpdir'
require_relative '../../lib/vibe/cascade_executor'

class TestCascadeExecutor < Minitest::Test
  def setup
    @ex = Vibe::CascadeExecutor.new
    @tmpdirs = []
  end

  def teardown
    @tmpdirs.each { |d| FileUtils.rm_rf(d) }
  end

  def make_tmpdir
    d = Dir.mktmpdir
    @tmpdirs << d
    d
  end

  # Helper to access task fields cleanly
  def task_status(result, id)
    result[:tasks][id]['status']
  end

  def task_output(result, id)
    result[:tasks][id]['output']
  end

  def task_exit_code(result, id)
    result[:tasks][id]['exit_code']
  end

  # ── Initialization and Configuration ──────────────────────────────────────────

  def test_initialize_has_empty_tasks
    ex = Vibe::CascadeExecutor.new
    assert_empty ex.tasks
    assert_instance_of Hash, ex.tasks
  end

  def test_initialize_tasks_is_fresh_per_instance
    ex1 = Vibe::CascadeExecutor.new
    ex2 = Vibe::CascadeExecutor.new
    ex1.add('x', command: 'exit 0')
    refute_empty ex1.tasks
    assert_empty ex2.tasks
  end

  # ── STATUS constant ───────────────────────────────────────────────────────────

  def test_status_constant_has_expected_values
    expected = {
      pending: 'pending',
      running: 'running',
      completed: 'completed',
      failed: 'failed',
      skipped: 'skipped'
    }
    assert_equal expected, Vibe::CascadeExecutor::STATUS
  end

  def test_status_constant_is_frozen
    assert Vibe::CascadeExecutor::STATUS.frozen?
  end

  # ── add ───────────────────────────────────────────────────────────────────────

  def test_add_registers_task
    @ex.add('a', command: 'exit 0')
    assert @ex.tasks.key?('a')
  end

  def test_add_raises_on_duplicate_id
    @ex.add('a', command: 'exit 0')
    assert_raises(ArgumentError) { @ex.add('a', command: 'exit 0') }
  end

  def test_add_duplicate_id_error_message
    @ex.add('my_task', command: 'exit 0')
    err = assert_raises(ArgumentError) { @ex.add('my_task', command: 'exit 0') }
    assert_match(/Duplicate task id: my_task/, err.message)
  end

  def test_add_sets_default_status_to_pending
    @ex.add('a', command: 'exit 0')
    assert_equal 'pending', @ex.tasks['a']['status']
  end

  def test_add_sets_description_default_to_id
    @ex.add('my_task', command: 'exit 0')
    assert_equal 'my_task', @ex.tasks['my_task']['description']
  end

  def test_add_sets_custom_description
    @ex.add('a', command: 'exit 0', description: 'Run linter')
    assert_equal 'Run linter', @ex.tasks['a']['description']
  end

  def test_add_defaults_depends_on_to_empty_array
    @ex.add('a', command: 'exit 0')
    assert_equal [], @ex.tasks['a']['depends_on']
  end

  def test_add_wraps_single_depends_on_in_array
    @ex.add('a', command: 'exit 0')
    @ex.add('b', command: 'exit 0', depends_on: 'a')
    assert_equal ['a'], @ex.tasks['b']['depends_on']
  end

  def test_add_stores_multiple_dependencies
    @ex.add('a', command: 'exit 0')
    @ex.add('b', command: 'exit 0')
    @ex.add('c', command: 'exit 0', depends_on: %w[a b])
    assert_equal %w[a b], @ex.tasks['c']['depends_on']
  end

  def test_add_stores_working_dir
    tmpdir = make_tmpdir
    @ex.add('a', command: 'exit 0', working_dir: tmpdir)
    assert_equal tmpdir, @ex.tasks['a']['working_dir']
  end

  def test_add_working_dir_defaults_to_nil
    @ex.add('a', command: 'exit 0')
    assert_nil @ex.tasks['a']['working_dir']
  end

  def test_add_initializes_output_and_exit_code_as_nil
    @ex.add('a', command: 'exit 0')
    assert_nil @ex.tasks['a']['output']
    assert_nil @ex.tasks['a']['exit_code']
  end

  def test_add_initializes_timestamps_as_nil
    @ex.add('a', command: 'exit 0')
    assert_nil @ex.tasks['a']['started_at']
    assert_nil @ex.tasks['a']['finished_at']
  end

  def test_add_task_id_is_stored
    @ex.add('task_abc', command: 'exit 0')
    assert_equal 'task_abc', @ex.tasks['task_abc']['id']
  end

  def test_validate_raises_on_unknown_dependency
    @ex.add('a', command: 'exit 0', depends_on: ['nonexistent'])
    assert_raises(ArgumentError) { @ex.validate_graph! }
  end

  def test_validate_unknown_dependency_error_message
    @ex.add('a', command: 'exit 0', depends_on: ['ghost'])
    err = assert_raises(ArgumentError) { @ex.validate_graph! }
    assert_match(/Task 'a' depends on unknown task 'ghost'/, err.message)
  end

  def test_validate_cycle_error_message
    @ex.add('a', command: 'exit 0', depends_on: ['b'])
    @ex.add('b', command: 'exit 0', depends_on: ['a'])
    err = assert_raises(ArgumentError) { @ex.validate_graph! }
    assert_match(/Circular dependency/, err.message)
  end

  def test_validate_passes_for_empty_graph
    @ex.validate_graph! # no tasks at all
  end

  def test_validate_passes_for_diamond_dependency
    @ex.add('a', command: 'exit 0')
    @ex.add('b', command: 'exit 0', depends_on: ['a'])
    @ex.add('c', command: 'exit 0', depends_on: ['a'])
    @ex.add('d', command: 'exit 0', depends_on: %w[b c])
    @ex.validate_graph! # diamond shape is valid
  end

  def test_validate_self_referential_is_cycle
    @ex.add('a', command: 'exit 0', depends_on: ['a'])
    assert_raises(ArgumentError) { @ex.validate_graph! }
  end

  def test_validate_raises_on_cycle
    @ex.add('a', command: 'exit 0', depends_on: ['b'])
    @ex.add('b', command: 'exit 0', depends_on: ['a'])
    assert_raises(ArgumentError) { @ex.validate_graph! }
  end

  def test_validate_passes_for_valid_graph
    @ex.add('a', command: 'exit 0')
    @ex.add('b', command: 'exit 0', depends_on: ['a'])
    @ex.validate_graph! # should not raise
  end

  # ── topological_order ────────────────────────────────────────────────────────

  def test_topological_order_empty_graph
    assert_equal [], @ex.topological_order
  end

  def test_topological_order_single_task
    @ex.add('a', command: 'exit 0')
    assert_equal ['a'], @ex.topological_order
  end

  def test_topological_order_single_chain
    @ex.add('a', command: 'exit 0')
    @ex.add('b', command: 'exit 0', depends_on: ['a'])
    @ex.add('c', command: 'exit 0', depends_on: ['b'])

    order = @ex.topological_order
    assert_operator order.index('a'), :<, order.index('b')
    assert_operator order.index('b'), :<, order.index('c')
  end

  def test_topological_order_independent_tasks
    @ex.add('x', command: 'exit 0')
    @ex.add('y', command: 'exit 0')

    order = @ex.topological_order
    assert_includes order, 'x'
    assert_includes order, 'y'
    assert_equal 2, order.size
  end

  def test_topological_order_diamond_shape
    @ex.add('root', command: 'exit 0')
    @ex.add('left', command: 'exit 0', depends_on: ['root'])
    @ex.add('right', command: 'exit 0', depends_on: ['root'])
    @ex.add('merge', command: 'exit 0', depends_on: %w[left right])

    order = @ex.topological_order
    assert_operator order.index('root'), :<, order.index('left')
    assert_operator order.index('root'), :<, order.index('right')
    assert_operator order.index('left'), :<, order.index('merge')
    assert_operator order.index('right'), :<, order.index('merge')
  end

  def test_topological_order_includes_all_tasks
    %w[a b c d e].each { |id| @ex.add(id, command: 'exit 0') }
    @ex.add('f', command: 'exit 0', depends_on: %w[a b c d e])

    order = @ex.topological_order
    assert_equal 6, order.size
    %w[a b c d e f].each { |id| assert_includes order, id }
  end

  # ── run: basic execution ─────────────────────────────────────────────────────

  def test_run_empty_graph
    result = @ex.run
    assert result[:success]
    assert_equal 0, result[:total]
    assert_equal 0, result[:passed]
    assert_equal 0, result[:failed]
    assert_equal 0, result[:skipped]
  end

  def test_run_single_passing_task
    @ex.add('ok', command: 'exit 0')
    result = @ex.run

    assert result[:success]
    assert_equal 1, result[:passed]
    assert_equal 0, result[:failed]
    assert_equal 'completed', result[:tasks]['ok']['status']
  end

  def test_run_single_failing_task
    @ex.add('bad', command: 'exit 1')
    result = @ex.run

    refute result[:success]
    assert_equal 1, result[:failed]
    assert_equal 'failed', result[:tasks]['bad']['status']
  end

  def test_run_captures_output
    @ex.add('echo', command: 'echo hello')
    result = @ex.run

    assert_includes result[:tasks]['echo']['output'], 'hello'
  end

  def test_run_captures_stderr_output
    @ex.add('err', command: 'echo errmsg >&2')
    result = @ex.run

    # capture2e merges stdout and stderr
    assert_includes task_output(result, 'err'), 'errmsg'
  end

  def test_run_captures_stdout_and_stderr_combined
    @ex.add('both', command: 'echo out_msg && echo err_msg >&2')
    result = @ex.run

    output = task_output(result, 'both')
    assert_includes output, 'out_msg'
    assert_includes output, 'err_msg'
  end

  def test_run_records_exit_code_zero
    @ex.add('ok', command: 'exit 0')
    result = @ex.run
    assert_equal 0, task_exit_code(result, 'ok')
  end

  def test_run_records_nonzero_exit_code
    @ex.add('bad', command: 'exit 42')
    result = @ex.run
    assert_equal 42, task_exit_code(result, 'bad')
  end

  # ── run: dependency ordering ──────────────────────────────────────────────────

  def test_run_respects_dependency_order
    # We can't inject callbacks, so we use file-based sequencing
    tmpfile = Tempfile.new('cascade_order')
    tmpfile.close

    @ex.add('first',  command: "echo first  >> #{tmpfile.path}")
    @ex.add('second', command: "echo second >> #{tmpfile.path}", depends_on: ['first'])
    @ex.add('third',  command: "echo third  >> #{tmpfile.path}", depends_on: ['second'])
    @ex.run

    lines = File.readlines(tmpfile.path).map(&:strip)
    assert_equal %w[first second third], lines
  ensure
    tmpfile&.unlink
  end

  def test_run_parallel_independent_tasks
    # Both tasks should complete; order is non-deterministic
    @ex.add('a', command: 'exit 0')
    @ex.add('b', command: 'exit 0')
    result = @ex.run

    assert result[:success]
    assert_equal 2, result[:passed]
  end

  def test_run_diamond_dependency_all_complete
    @ex.add('root', command: 'exit 0')
    @ex.add('left', command: 'exit 0', depends_on: ['root'])
    @ex.add('right', command: 'exit 0', depends_on: ['root'])
    @ex.add('merge', command: 'exit 0', depends_on: %w[left right])
    result = @ex.run

    assert result[:success]
    assert_equal 4, result[:passed]
    assert_equal 0, result[:failed]
  end

  def test_run_diamond_dependency_preserves_order
    tmpfile = Tempfile.new('cascade_diamond')
    tmpfile.close

    path = tmpfile.path
    @ex.add('root', command: "echo root >> #{path}")
    @ex.add('left', command: "echo left >> #{path}", depends_on: ['root'])
    @ex.add('right', command: "echo right >> #{path}", depends_on: ['root'])
    @ex.add('merge', command: "echo merge >> #{path}", depends_on: %w[left right])
    @ex.run

    lines = File.readlines(path).map(&:strip)
    root_idx = lines.index('root')
    merge_idx = lines.index('merge')
    assert_operator root_idx, :<, lines.index('left')
    assert_operator root_idx, :<, lines.index('right')
    assert_operator lines.index('left'), :<, merge_idx
    assert_operator lines.index('right'), :<, merge_idx
  ensure
    tmpfile&.unlink
  end

  # ── run: failure propagation ──────────────────────────────────────────────────

  def test_run_skips_direct_downstream_on_failure
    @ex.add('lint', command: 'exit 1')
    @ex.add('test', command: 'exit 0', depends_on: ['lint'])
    result = @ex.run

    assert_equal 'failed',  task_status(result, 'lint')
    assert_equal 'skipped', task_status(result, 'test')
  end

  def test_run_skips_downstream_on_failure
    @ex.add('lint',  command: 'exit 1')
    @ex.add('test',  command: 'exit 0', depends_on: ['lint'])
    @ex.add('build', command: 'exit 0', depends_on: ['test'])
    result = @ex.run

    assert_equal 'failed',  result[:tasks]['lint']['status']
    assert_equal 'skipped', result[:tasks]['test']['status']
    assert_equal 'skipped', result[:tasks]['build']['status']
    assert_equal 2, result[:skipped]
  end

  def test_run_does_not_skip_unrelated_tasks_on_failure
    @ex.add('bad',       command: 'exit 1')
    @ex.add('unrelated', command: 'exit 0')
    result = @ex.run

    assert_equal 'failed',    task_status(result, 'bad')
    assert_equal 'completed', task_status(result, 'unrelated')
  end

  def test_run_partial_failure_with_independent_branches
    @ex.add('fail', command: 'exit 1')
    @ex.add('pass', command: 'exit 0')
    @ex.add('after_fail', command: 'exit 0', depends_on: ['fail'])
    @ex.add('after_pass', command: 'exit 0', depends_on: ['pass'])
    result = @ex.run

    assert_equal 'failed',    task_status(result, 'fail')
    assert_equal 'completed', task_status(result, 'pass')
    assert_equal 'skipped',   task_status(result, 'after_fail')
    assert_equal 'completed', task_status(result, 'after_pass')
  end

  def test_run_failure_in_middle_of_chain
    @ex.add('a', command: 'exit 0')
    @ex.add('b', command: 'exit 1', depends_on: ['a'])
    @ex.add('c', command: 'exit 0', depends_on: ['b'])
    result = @ex.run

    assert_equal 'completed', task_status(result, 'a')
    assert_equal 'failed',    task_status(result, 'b')
    assert_equal 'skipped',   task_status(result, 'c')
  end

  # ── run: summary ─────────────────────────────────────────────────────────────

  def test_run_summary_counts
    @ex.add('a', command: 'exit 0')
    @ex.add('b', command: 'exit 1')
    @ex.add('c', command: 'exit 0', depends_on: ['b'])
    result = @ex.run

    assert_equal 3, result[:total]
    assert_equal 1, result[:passed]
    assert_equal 1, result[:failed]
    assert_equal 1, result[:skipped]
  end

  def test_run_summary_all_pass
    @ex.add('a', command: 'exit 0')
    @ex.add('b', command: 'exit 0')
    result = @ex.run

    assert result[:success]
    assert_equal 2, result[:total]
    assert_equal 2, result[:passed]
    assert_equal 0, result[:failed]
    assert_equal 0, result[:skipped]
  end

  def test_run_summary_has_tasks_hash
    @ex.add('a', command: 'exit 0')
    result = @ex.run

    assert_instance_of Hash, result[:tasks]
    assert_equal @ex.tasks, result[:tasks]
  end

  def test_run_success_is_true_when_no_failures
    @ex.add('a', command: 'exit 0')
    result = @ex.run
    assert_equal true, result[:success]
  end

  def test_run_success_is_false_with_failures
    @ex.add('a', command: 'exit 1')
    result = @ex.run
    assert_equal false, result[:success]
  end

  # ── run: timestamps ──────────────────────────────────────────────────────────

  def test_run_timestamps_recorded
    @ex.add('t', command: 'exit 0')
    result = @ex.run

    task = result[:tasks]['t']
    refute_nil task['started_at']
    refute_nil task['finished_at']
  end

  def test_run_started_at_is_iso8601
    @ex.add('t', command: 'exit 0')
    result = @ex.run

    started = result[:tasks]['t']['started_at']
    parsed = Time.iso8601(started)
    assert_instance_of Time, parsed
  end

  def test_run_finished_at_is_iso8601
    @ex.add('t', command: 'exit 0')
    result = @ex.run

    finished = result[:tasks]['t']['finished_at']
    parsed = Time.iso8601(finished)
    assert_instance_of Time, parsed
  end

  def test_run_finished_at_after_started_at
    @ex.add('t', command: 'sleep 0.1')
    result = @ex.run

    task = result[:tasks]['t']
    started  = Time.iso8601(task['started_at'])
    finished = Time.iso8601(task['finished_at'])
    assert_operator finished, :>=, started
  end

  def test_run_started_at_is_iso8601
    @ex.add('t', command: 'exit 0')
    result = @ex.run

    started = result[:tasks]['t']['started_at']
    parsed = Time.iso8601(started)
    assert_instance_of Time, parsed
  end

  def test_run_finished_at_is_iso8601
    @ex.add('t', command: 'exit 0')
    result = @ex.run

    finished = result[:tasks]['t']['finished_at']
    parsed = Time.iso8601(finished)
    assert_instance_of Time, parsed
  end

  def test_run_finished_at_after_started_at
    @ex.add('t', command: 'sleep 0.1')
    result = @ex.run

    task = result[:tasks]['t']
    started  = Time.iso8601(task['started_at'])
    finished = Time.iso8601(task['finished_at'])
    assert_operator finished, :>=, started
  end

  # ── stop_on_failure option ────────────────────────────────────────────────────

  def test_run_stop_on_failure_true_is_default
    @ex.add('bad', command: 'exit 1')
    @ex.add('after', command: 'exit 0', depends_on: ['bad'])
    result = @ex.run

    # Default is stop_on_failure: true
    assert_equal 'skipped', task_status(result, 'after')
  end

  def test_run_stop_on_failure_false_does_not_skip_downstream
    @ex.add('bad', command: 'exit 1')
    @ex.add('after', command: 'exit 0', depends_on: ['bad'])
    result = @ex.run(stop_on_failure: false)

    # "after" depends on "bad", which failed.
    # With stop_on_failure: false, downstream is NOT pre-emptively skipped,
    # but "after" still cannot run (dependency failed = not completed).
    assert_equal 'failed', task_status(result, 'bad')
    refute_equal 'completed', task_status(result, 'after')
  end

  def test_run_stop_on_failure_false_runs_unrelated_independent_tasks
    @ex.add('bad',       command: 'exit 1')
    @ex.add('unrelated', command: 'exit 0')
    result = @ex.run(stop_on_failure: false)

    assert_equal 'failed',    task_status(result, 'bad')
    assert_equal 'completed', task_status(result, 'unrelated')
  end

  def test_run_stop_on_failure_false_keeps_pending_when_dep_failed
    # When stop_on_failure is false, skip_downstream is never called.
    # But dependent tasks still can not run because ready_tasks checks for :completed.
    @ex.add('a', command: 'exit 1')
    @ex.add('b', command: 'exit 0', depends_on: ['a'])
    @ex.add('c', command: 'exit 0', depends_on: ['b'])
    result = @ex.run(stop_on_failure: false)

    assert_equal 'failed',  task_status(result, 'a')
    # b stays pending because a never completed
    assert_equal 'pending', task_status(result, 'b')
    assert_equal 'pending', task_status(result, 'c')
  end

  # ── execute_task rescue path (graceful degradation) ──────────────────────────

  def test_run_records_exit_minus_one_on_task_exception
    # We use a non-existent working_dir to force Open3 to raise Errno::ENOENT
    @ex.add('boom', command: 'exit 0', working_dir: '/nonexistent_dir_xyz_abc')
    result = @ex.run

    assert_equal 'failed', task_status(result, 'boom')
    assert_equal(-1, task_exit_code(result, 'boom'))
    refute_nil task_output(result, 'boom')
  end

  def test_run_exception_records_error_message_as_output
    @ex.add('boom', command: 'exit 0', working_dir: '/nonexistent_dir_xyz_abc')
    result = @ex.run

    output = task_output(result, 'boom')
    assert_instance_of String, output
    assert output.length.positive?
  end

  def test_run_exception_records_finished_at_timestamp
    @ex.add('boom', command: 'exit 0', working_dir: '/nonexistent_dir_xyz_abc')
    result = @ex.run

    task = result[:tasks]['boom']
    refute_nil task['finished_at']
  end

  def test_run_bad_command_in_middle_does_not_crash_other_tasks
    @ex.add('ok1',  command: 'exit 0')
    @ex.add('bad',  command: 'exit 0', working_dir: '/nonexistent_dir_xyz_abc')
    @ex.add('ok2',  command: 'exit 0')
    result = @ex.run

    assert_equal 'completed', task_status(result, 'ok1')
    assert_equal 'failed',    task_status(result, 'bad')
    assert_equal 'completed', task_status(result, 'ok2')
  end

  # ── max_parallel ──────────────────────────────────────────────────────────────

  def test_run_with_max_parallel_one_serializes_execution
    tmpfile = Tempfile.new('cascade_parallel')
    tmpfile.close

    @ex.add('a', command: "echo a >> #{tmpfile.path}")
    @ex.add('b', command: "echo b >> #{tmpfile.path}")
    @ex.add('c', command: "echo c >> #{tmpfile.path}")
    result = @ex.run(max_parallel: 1)

    assert result[:success]
    assert_equal 3, result[:passed]
  ensure
    tmpfile&.unlink
  end

  def test_run_max_parallel_one_with_dependencies
    tmpfile = Tempfile.new('cascade_parallel_deps')
    tmpfile.close

    path = tmpfile.path
    @ex.add('a', command: "echo a >> #{path}")
    @ex.add('b', command: "echo b >> #{path}", depends_on: ['a'])
    @ex.add('c', command: "echo c >> #{path}", depends_on: ['b'])
    result = @ex.run(max_parallel: 1)

    assert result[:success]
    lines = File.readlines(path).map(&:strip)
    assert_equal %w[a b c], lines
  ensure
    tmpfile&.unlink
  end

  def test_run_max_parallel_two_with_many_tasks
    6.times { |i| @ex.add("t#{i}", command: 'exit 0') }
    result = @ex.run(max_parallel: 2)

    assert result[:success]
    assert_equal 6, result[:passed]
  end

  def test_run_max_parallel_with_dependencies_and_failure
    @ex.add('a', command: 'exit 1')
    @ex.add('b', command: 'exit 0', depends_on: ['a'])
    @ex.add('c', command: 'exit 0')
    result = @ex.run(max_parallel: 1)

    refute result[:success]
    assert_equal 'failed',    task_status(result, 'a')
    assert_equal 'skipped',   task_status(result, 'b')
    assert_equal 'completed', task_status(result, 'c')
  end

  # ── 3-node cycle detection ────────────────────────────────────────────────────

  def test_validate_raises_on_three_node_cycle
    @ex.add('a', command: 'exit 0', depends_on: ['c'])
    @ex.add('b', command: 'exit 0', depends_on: ['a'])
    @ex.add('c', command: 'exit 0', depends_on: ['b'])
    assert_raises(ArgumentError) { @ex.validate_graph! }
  end

  # ── working_dir at task level ─────────────────────────────────────────────────

  def test_run_task_with_working_dir
    tmpdir = make_tmpdir
    File.write(File.join(tmpdir, 'marker.txt'), 'exists')
    @ex.add('check', command: 'test -f marker.txt', working_dir: tmpdir)
    result = @ex.run
    assert_equal 'completed', task_status(result, 'check')
  end

  def test_run_task_with_working_dir_cwd_matters
    tmpdir = make_tmpdir
    @ex.add('pwd', command: 'pwd', working_dir: tmpdir)
    result = @ex.run

    output = task_output(result, 'pwd').strip
    # Resolve both paths to handle macOS /var -> /private/var symlink
    assert_equal File.realpath(tmpdir), File.realpath(output)
  end

  def test_run_task_without_working_dir_uses_default
    @ex.add('pwd', command: 'pwd')
    result = @ex.run

    output = task_output(result, 'pwd').strip
    assert_equal Dir.pwd, output
  end

  # ── add chaining ──────────────────────────────────────────────────────────────

  def test_add_returns_self_for_chaining
    result = @ex.add('a', command: 'exit 0').add('b', command: 'exit 0')
    assert_same @ex, result
  end

  # ── Mixed success and failure scenarios ───────────────────────────────────────

  def test_run_multiple_independent_all_pass
    %w[a b c d].each { |id| @ex.add(id, command: 'exit 0') }
    result = @ex.run

    assert result[:success]
    assert_equal 4, result[:passed]
    assert_equal 0, result[:failed]
    assert_equal 0, result[:skipped]
  end

  def test_run_multiple_independent_some_fail
    @ex.add('a', command: 'exit 0')
    @ex.add('b', command: 'exit 1')
    @ex.add('c', command: 'exit 0')
    @ex.add('d', command: 'exit 2')
    result = @ex.run

    refute result[:success]
    assert_equal 2, result[:passed]
    assert_equal 2, result[:failed]
  end

  def test_run_complex_dependency_graph
    @ex.add('root',  command: 'exit 0')
    @ex.add('left',  command: 'exit 0', depends_on: ['root'])
    @ex.add('mid',   command: 'exit 0', depends_on: ['root'])
    @ex.add('right', command: 'exit 0', depends_on: %w[root mid])
    @ex.add('merge', command: 'exit 0', depends_on: %w[left right])
    result = @ex.run

    assert result[:success]
    assert_equal 5, result[:passed]
  end

  def test_run_complex_graph_with_failure_in_branch
    @ex.add('root',  command: 'exit 0')
    @ex.add('left',  command: 'exit 1', depends_on: ['root'])
    @ex.add('right', command: 'exit 0', depends_on: ['root'])
    @ex.add('merge', command: 'exit 0', depends_on: %w[left right])
    result = @ex.run

    refute result[:success]
    assert_equal 'completed', task_status(result, 'root')
    assert_equal 'failed',    task_status(result, 'left')
    assert_equal 'completed', task_status(result, 'right')
    assert_equal 'skipped',   task_status(result, 'merge')
  end

  # ── Edge cases ────────────────────────────────────────────────────────────────

  def test_run_single_task_noop_command
    @ex.add('noop', command: 'true')
    result = @ex.run

    assert_equal 'completed', task_status(result, 'noop')
    assert_equal 0, task_exit_code(result, 'noop')
  end

  def test_run_command_with_special_characters
    @ex.add('special', command: 'echo "hello world"')
    result = @ex.run

    assert_equal 'completed', task_status(result, 'special')
    assert_includes task_output(result, 'special'), 'hello world'
  end

  def test_run_command_with_pipe
    @ex.add('pipe', command: 'echo "abc\ndef" | grep def')
    result = @ex.run

    assert_equal 'completed', task_status(result, 'pipe')
    assert_includes task_output(result, 'pipe'), 'def'
  end

  def test_run_command_with_env_variable
    @ex.add('env', command: 'FOO=bar; echo $FOO')
    result = @ex.run

    assert_includes task_output(result, 'env'), 'bar'
  end

  def test_run_long_chain_of_dependencies
    @ex.add('t0', command: 'exit 0')
    (1..9).each { |i| @ex.add("t#{i}", command: 'exit 0', depends_on: ["t#{i - 1}"]) }
    result = @ex.run

    assert result[:success]
    assert_equal 10, result[:passed]
  end

  def test_run_long_chain_failure_propagates_to_all_downstream
    @ex.add('t0', command: 'exit 0')
    @ex.add('t1', command: 'exit 0', depends_on: ['t0'])
    @ex.add('t2', command: 'exit 1', depends_on: ['t1'])
    @ex.add('t3', command: 'exit 0', depends_on: ['t2'])
    @ex.add('t4', command: 'exit 0', depends_on: ['t3'])
    result = @ex.run

    refute result[:success]
    assert_equal 'completed', task_status(result, 't0')
    assert_equal 'completed', task_status(result, 't1')
    assert_equal 'failed',    task_status(result, 't2')
    assert_equal 'skipped',   task_status(result, 't3')
    assert_equal 'skipped',   task_status(result, 't4')
    assert_equal 2, result[:passed]
    assert_equal 1, result[:failed]
    assert_equal 2, result[:skipped]
  end

  # ── Progress tracking via status transitions ──────────────────────────────────

  def test_run_transitions_pending_to_completed
    @ex.add('a', command: 'exit 0')
    assert_equal 'pending', @ex.tasks['a']['status']

    result = @ex.run
    assert_equal 'completed', task_status(result, 'a')
  end

  def test_run_transitions_pending_to_failed
    @ex.add('a', command: 'exit 1')
    assert_equal 'pending', @ex.tasks['a']['status']

    result = @ex.run
    assert_equal 'failed', task_status(result, 'a')
  end

  def test_run_transitions_pending_to_skipped_for_downstream
    @ex.add('a', command: 'exit 1')
    @ex.add('b', command: 'exit 0', depends_on: ['a'])
    assert_equal 'pending', @ex.tasks['b']['status']

    result = @ex.run
    assert_equal 'skipped', task_status(result, 'b')
  end

  # ── Re-running the same executor ─────────────────────────────────────────────

  def test_run_cannot_be_safely_rerun_after_completion
    @ex.add('a', command: 'exit 0')
    first_result = @ex.run

    # Second run: task 'a' is already completed, no new pending tasks
    # so it returns immediately with same state
    second_result = @ex.run

    assert_equal first_result[:passed], second_result[:passed]
  end

  # ── tasks attr_reader ────────────────────────────────────────────────────────

  def test_tasks_returns_the_internal_hash
    @ex.add('a', command: 'exit 0')
    tasks = @ex.tasks
    assert_same tasks, @ex.tasks # same object reference
  end

  def test_tasks_reflects_added_tasks
    assert_empty @ex.tasks

    @ex.add('a', command: 'exit 0')
    assert_equal 1, @ex.tasks.size

    @ex.add('b', command: 'exit 0')
    assert_equal 2, @ex.tasks.size
  end

  # ── Real-world-like scenarios ─────────────────────────────────────────────────

  def test_ci_pipeline_all_pass
    @ex.add('lint',   command: 'true',   description: 'Run linter')
    @ex.add('test',   command: 'true',   description: 'Run tests', depends_on: ['lint'])
    @ex.add('build',  command: 'true',   description: 'Build package', depends_on: ['test'])
    @ex.add('deploy', command: 'true',   description: 'Deploy', depends_on: ['build'])
    result = @ex.run

    assert result[:success]
    assert_equal 4, result[:passed]
    assert_equal 0, result[:failed]
    assert_equal 0, result[:skipped]
  end

  def test_ci_pipeline_lint_fails
    @ex.add('lint',   command: 'false',  description: 'Run linter')
    @ex.add('test',   command: 'true',   description: 'Run tests', depends_on: ['lint'])
    @ex.add('build',  command: 'true',   description: 'Build package', depends_on: ['test'])
    @ex.add('deploy', command: 'true',   description: 'Deploy', depends_on: ['build'])
    result = @ex.run

    refute result[:success]
    assert_equal 'failed',  task_status(result, 'lint')
    assert_equal 'skipped', task_status(result, 'test')
    assert_equal 'skipped', task_status(result, 'build')
    assert_equal 'skipped', task_status(result, 'deploy')
    assert_equal 3, result[:skipped]
  end

  def test_ci_pipeline_test_fails_build_skipped
    @ex.add('lint',   command: 'true',   description: 'Run linter')
    @ex.add('test',   command: 'false',  description: 'Run tests', depends_on: ['lint'])
    @ex.add('build',  command: 'true',   description: 'Build package', depends_on: ['test'])
    @ex.add('deploy', command: 'true',   description: 'Deploy', depends_on: ['build'])
    result = @ex.run

    refute result[:success]
    assert_equal 'completed', task_status(result, 'lint')
    assert_equal 'failed',    task_status(result, 'test')
    assert_equal 'skipped',   task_status(result, 'build')
    assert_equal 'skipped',   task_status(result, 'deploy')
  end

  def test_parallel_lint_and_security_scan
    @ex.add('lint',     command: 'true', description: 'Lint')
    @ex.add('security', command: 'true', description: 'Security scan')
    @ex.add('test',     command: 'true', description: 'Test', depends_on: %w[lint security])
    result = @ex.run

    assert result[:success]
    assert_equal 3, result[:passed]
  end

  def test_parallel_lint_fails_security_passes_test_skipped
    @ex.add('lint',     command: 'false', description: 'Lint')
    @ex.add('security', command: 'true',  description: 'Security scan')
    @ex.add('test',     command: 'true',  description: 'Test', depends_on: %w[lint security])
    result = @ex.run

    refute result[:success]
    assert_equal 'failed',    task_status(result, 'lint')
    assert_equal 'completed', task_status(result, 'security')
    assert_equal 'skipped',   task_status(result, 'test')
  end
end
