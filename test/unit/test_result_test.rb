# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../lib/app/models/test_result'
require_relative '../shared/result_status_tests'

class TestResultTest < MiniTest::Test
  include Inferno::ResultStatusTests

  def setup
    @result = Inferno::Models::TestResult.new
  end
end
