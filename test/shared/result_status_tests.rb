# frozen_string_literal: true

module Inferno
  module ResultStatusTests
    def test_result_setters
      statuses = ['fail', 'error', 'pass', 'skip', 'wait', 'todo']

      statuses.each do |status|
        @result.send("#{status}!")
        assert(@result.result == status)
      end
    end
  end
end
