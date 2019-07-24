# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/app/models/sequence_result'
require_relative '../shared/result_status_tests'
require_relative '../../lib/app/utils/result_statuses'

class SequenceResultTest < MiniTest::Test
  include Inferno::ResultStatusTests

  def setup
    @result = Inferno::Models::SequenceResult.new
  end

  def test_reset!
    result = Inferno::Models::SequenceResult.new
    result.required_passed = 20
    result.required_total = 15
    result.error_count = 2
    result.todo_count = 3
    result.skip_count = 6
    result.optional_passed = 2
    result.optional_total = 3
    result.required_omitted = 4
    result.optional_omitted = 300

    result.reset!

    assert_equal 0, result.required_passed
    assert_equal 0, result.required_total
    assert_equal 0, result.error_count
    assert_equal 0, result.todo_count
    assert_equal 0, result.skip_count
    assert_equal 0, result.optional_passed
    assert_equal 0, result.optional_total
    assert_equal 0, result.required_omitted
    assert_equal 0, result.optional_omitted
  end

  def test_result_count
    result = Inferno::Models::SequenceResult.new
    result.test_results << Inferno::Models::TestResult.new
    result.test_results << Inferno::Models::TestResult.new

    assert_equal 2, result.result_count
  end

  def test_total_omitted
    result = Inferno::Models::SequenceResult.new

    result.required_omitted = 4
    result.optional_omitted = 300

    assert_equal 304, result.total_omitted
  end

  def test_update_result_counts
    sequence_result = Inferno::Models::SequenceResult.new

    test_result1 = Inferno::Models::TestResult.new
    test_result1.required = true
    test_result1.result = Inferno::ResultStatuses::PASS
    sequence_result.test_results << test_result1

    test_result2 = Inferno::Models::TestResult.new
    test_result2.required = false
    test_result2.result = Inferno::ResultStatuses::PASS
    sequence_result.test_results << test_result2

    test_result3 = Inferno::Models::TestResult.new
    test_result3.required = true
    test_result3.result = Inferno::ResultStatuses::OMIT
    sequence_result.test_results << test_result3

    test_result4 = Inferno::Models::TestResult.new
    test_result4.required = false
    test_result4.result = Inferno::ResultStatuses::OMIT
    sequence_result.test_results << test_result4

    test_result5 = Inferno::Models::TestResult.new
    test_result5.required = true
    test_result5.result = Inferno::ResultStatuses::TODO
    sequence_result.test_results << test_result5

    test_result6 = Inferno::Models::TestResult.new
    test_result6.required = true
    test_result6.result = Inferno::ResultStatuses::ERROR
    sequence_result.test_results << test_result6

    test_result7 = Inferno::Models::TestResult.new
    test_result7.required = false
    test_result7.result = Inferno::ResultStatuses::SKIP
    sequence_result.test_results << test_result7

    test_result8 = Inferno::Models::TestResult.new
    test_result8.required = false
    test_result8.result = Inferno::ResultStatuses::WAIT
    sequence_result.test_results << test_result8

    sequence_result.update_result_counts

    assert_equal 1, sequence_result.required_passed
    assert_equal 4, sequence_result.required_total
    assert_equal 1, sequence_result.error_count
    assert_equal 1, sequence_result.todo_count
    assert_equal 1, sequence_result.skip_count
    assert_equal 1, sequence_result.optional_passed
    assert_equal 4, sequence_result.optional_total
    assert_equal 1, sequence_result.required_omitted
    assert_equal 1, sequence_result.optional_omitted
  end

  def test_sequence_result_result_pass
    sequence_result = Inferno::Models::SequenceResult.new

    test_result1 = Inferno::Models::TestResult.new
    test_result1.required = true
    test_result1.result = Inferno::ResultStatuses::PASS
    sequence_result.test_results << test_result1

    test_result2 = Inferno::Models::TestResult.new
    test_result2.required = true
    test_result2.result = Inferno::ResultStatuses::TODO
    sequence_result.test_results << test_result2

    sequence_result.update_result_counts

    assert_equal Inferno::ResultStatuses::PASS, sequence_result.result
  end

  def test_sequence_result_result_pass_even_with_omit
    sequence_result = Inferno::Models::SequenceResult.new
    sequence_result.test_results = []

    test_result1 = Inferno::Models::TestResult.new
    test_result1.required = true
    test_result1.result = Inferno::ResultStatuses::PASS
    sequence_result.test_results << test_result1

    test_result2 = Inferno::Models::TestResult.new
    test_result2.required = true
    test_result2.result = Inferno::ResultStatuses::OMIT
    sequence_result.test_results << test_result2

    sequence_result.update_result_counts

    assert_equal Inferno::ResultStatuses::PASS, sequence_result.result
  end

  def test_sequence_result_result_pass_when_skip_test_is_optional
    sequence_result = Inferno::Models::SequenceResult.new
    sequence_result.test_results = []

    test_result1 = Inferno::Models::TestResult.new
    test_result1.required = true
    test_result1.result = Inferno::ResultStatuses::PASS
    sequence_result.test_results << test_result1

    test_result2 = Inferno::Models::TestResult.new
    test_result2.required = false
    test_result2.result = Inferno::ResultStatuses::SKIP
    sequence_result.test_results << test_result2

    sequence_result.update_result_counts

    assert_equal Inferno::ResultStatuses::PASS, sequence_result.result
  end

  def test_sequence_result_result_skip_when_skip_test_is_required
    sequence_result = Inferno::Models::SequenceResult.new

    test_result1 = Inferno::Models::TestResult.new
    test_result1.required = true
    test_result1.result = Inferno::ResultStatuses::PASS
    sequence_result.test_results << test_result1

    test_result2 = Inferno::Models::TestResult.new
    test_result2.required = true
    test_result2.result = Inferno::ResultStatuses::SKIP
    sequence_result.test_results << test_result2

    sequence_result.update_result_counts

    assert_equal Inferno::ResultStatuses::SKIP, sequence_result.result
  end

  def test_sequence_result_result_required_skip_when_no_pass_tests
    sequence_result = Inferno::Models::SequenceResult.new

    test_result1 = Inferno::Models::TestResult.new
    test_result1.required = true
    test_result1.result = Inferno::ResultStatuses::SKIP
    sequence_result.test_results << test_result1

    sequence_result.update_result_counts

    assert_equal Inferno::ResultStatuses::SKIP, sequence_result.result
  end

  def test_sequence_result_result_optional_skip_when_no_pass_tests
    sequence_result = Inferno::Models::SequenceResult.new

    test_result1 = Inferno::Models::TestResult.new
    test_result1.required = false
    test_result1.result = Inferno::ResultStatuses::SKIP
    sequence_result.test_results << test_result1

    sequence_result.update_result_counts

    assert_equal Inferno::ResultStatuses::PASS, sequence_result.result
  end

  def test_sequence_result_fail
    sequence_result = Inferno::Models::SequenceResult.new

    test_result1 = Inferno::Models::TestResult.new
    test_result1.required = true
    test_result1.result = Inferno::ResultStatuses::PASS
    sequence_result.test_results << test_result1

    test_result2 = Inferno::Models::TestResult.new
    test_result2.required = true
    test_result2.result = Inferno::ResultStatuses::SKIP
    sequence_result.test_results << test_result2

    test_result3 = Inferno::Models::TestResult.new
    test_result3.required = true
    test_result3.result = Inferno::ResultStatuses::FAIL
    sequence_result.test_results << test_result3

    sequence_result.update_result_counts

    assert_equal Inferno::ResultStatuses::FAIL, sequence_result.result
  end

  def test_sequence_result_pass_when_fail_optional
    sequence_result = Inferno::Models::SequenceResult.new

    test_result1 = Inferno::Models::TestResult.new
    test_result1.required = true
    test_result1.result = Inferno::ResultStatuses::PASS
    sequence_result.test_results << test_result1

    test_result2 = Inferno::Models::TestResult.new
    test_result2.required = false
    test_result2.result = Inferno::ResultStatuses::FAIL
    sequence_result.test_results << test_result2

    sequence_result.update_result_counts

    assert_equal Inferno::ResultStatuses::PASS, sequence_result.result
  end

  def test_sequence_result_error
    sequence_result = Inferno::Models::SequenceResult.new

    test_result1 = Inferno::Models::TestResult.new
    test_result1.required = true
    test_result1.result = Inferno::ResultStatuses::PASS
    sequence_result.test_results << test_result1

    test_result2 = Inferno::Models::TestResult.new
    test_result2.required = true
    test_result2.result = Inferno::ResultStatuses::SKIP
    sequence_result.test_results << test_result2

    test_result3 = Inferno::Models::TestResult.new
    test_result3.required = true
    test_result3.result = Inferno::ResultStatuses::ERROR
    sequence_result.test_results << test_result3

    sequence_result.update_result_counts

    assert_equal Inferno::ResultStatuses::ERROR, sequence_result.result
  end

  def test_sequence_result_pass_when_error_optional
    sequence_result = Inferno::Models::SequenceResult.new

    test_result1 = Inferno::Models::TestResult.new
    test_result1.required = true
    test_result1.result = Inferno::ResultStatuses::PASS
    sequence_result.test_results << test_result1

    test_result2 = Inferno::Models::TestResult.new
    test_result2.required = false
    test_result2.result = Inferno::ResultStatuses::ERROR
    sequence_result.test_results << test_result2

    sequence_result.update_result_counts

    assert_equal Inferno::ResultStatuses::PASS, sequence_result.result
  end

  def test_sequence_result_pass_fail_vs_error
    sequence_result = Inferno::Models::SequenceResult.new

    test_result1 = Inferno::Models::TestResult.new
    test_result1.required = true
    test_result1.result = Inferno::ResultStatuses::FAIL
    sequence_result.test_results << test_result1

    test_result2 = Inferno::Models::TestResult.new
    test_result2.required = true
    test_result2.result = Inferno::ResultStatuses::ERROR
    sequence_result.test_results << test_result2

    sequence_result.update_result_counts

    assert_equal Inferno::ResultStatuses::ERROR, sequence_result.result
  end
end
