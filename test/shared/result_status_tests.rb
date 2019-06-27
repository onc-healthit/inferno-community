# frozen_string_literal: true

module Inferno
  module ResultStatusTests
    def test_result_setters
      Inferno::ResultStatuses::STATUS_LIST.each do |status|
        @result.send("#{status}!")
        assert(@result.result == status)
      end
    end

    def test_result_equality
      Inferno::ResultStatuses::STATUS_LIST.each do |status|
        assert(!@result.send("#{status}?"))
        @result.send("#{status}!")
        assert(@result.send("#{status}?"))
      end
    end
  end
end
