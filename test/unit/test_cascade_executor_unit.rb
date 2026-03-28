# frozen_string_literal: true

require_relative '../test_helper'
require 'tmpdir'
require 'fileutils'
require_relative '../../lib/vibe/cascade_executor'

class TestCascadeExecutorUnit < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_add_registers_task
    ex = Vibe::CascadeExecutor.new
    ex.add('a', command: 'echo hello')
    assert_equal 1, ex.tasks.size
    assert_equal 'a', ex.tasks['a']['id']
    assert_equal 'echo hello', ex.tasks['a']['command']
  end

  def test_add_returns_self_for_chaining
    ex = Vibe::CascadeExecutor.new
    result = ex.add('a', command: 'echo hello')
    assert_same ex, result
  end

  def test_add_raises_on_duplicate
    ex = Vibe::CascadeExecutor.new
    ex.add('a', command: 'echo a')
    assert_raises(ArgumentError) { ex.add('a', command: 'echo dup') }
  end

  def test_validate_graph_no_cycles
    ex = Vibe::CascadeExecutor.new
    ex.add('a', command: 'echo a')
    ex.add('b', command: 'echo b', depends_on: ['a'])
    ex.add('c', command: 'echo c', depends_on: ['b'])
    ex.send(:validate_graph!)  # private method
    pass  # no exception = valid
  end

  def test_validate_graph_detects_cycle
    ex = Vibe::CascadeExecutor.new
    ex.add('a', command: 'echo a', depends_on: ['b'])
    ex.add('b', command: 'echo b', depends_on: ['a'])
    assert_raises(ArgumentError) { ex.send(:validate_graph!) }
  end

  def test_validate_graph_missing_dependency
    ex = Vibe::CascadeExecutor.new
    ex.add('a', command: 'echo a', depends_on: ['nonexistent'])
    assert_raises(ArgumentError) { ex.send(:validate_graph!) }
  end

  def test_topological_order_simple_chain
    ex = Vibe::CascadeExecutor.new
    ex.add('a', command: 'echo a')
    ex.add('b', command: 'echo b', depends_on: ['a'])
    ex.add('c', command: 'echo c', depends_on: ['b'])
    order = ex.topological_order
    assert_equal %w[a b c], order
  end

  def test_topological_order_parallel_tasks
    ex = Vibe::CascadeExecutor.new
    ex.add('a', command: 'echo a')
    ex.add('b', command: 'echo b')
    ex.add('c', command: 'echo c', depends_on: ['a', 'b'])
    order = ex.topological_order
    assert_equal 'c', order.last
    assert_equal 3, order.size
  end

  def test_topological_order_empty
    ex = Vibe::CascadeExecutor.new
    assert_equal [], ex.topological_order
  end

  def test_task_has_correct_default_status
    ex = Vibe::CascadeExecutor.new
    ex.add('t1', command: 'echo hi')
    task = ex.tasks['t1']
    assert_equal 'pending', task['status']
    assert_nil task['output']
    assert_nil task['exit_code']
  end

  def test_task_stores_description
    ex = Vibe::CascadeExecutor.new
    ex.add('t1', command: 'echo hi', description: 'My Task')
    assert_equal 'My Task', ex.tasks['t1']['description']
  end

  def test_task_default_description_is_id
    ex = Vibe::CascadeExecutor.new
    ex.add('my-task', command: 'echo hi')
    assert_equal 'my-task', ex.tasks['my-task']['description']
  end

  def test_task_stores_working_dir
    ex = Vibe::CascadeExecutor.new
    ex.add('t1', command: 'echo hi', working_dir: @tmpdir)
    assert_equal @tmpdir, ex.tasks['t1']['working_dir']
  end
end
