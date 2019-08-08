# frozen_string_literal: true

module Inferno
  class Module
    class TestSet
      attr_accessor :id
      attr_accessor :view
      attr_accessor :groups

      def initialize(id, view)
        @id = id
        @view = view
        @groups = []
      end

      def sequences
        @groups.flat_map { |group| group.test_cases.map(&:sequence) }
      end

      def test_cases
        @groups.flat_map(&:test_cases)
      end

      def test_case_by_id(test_case_id)
        test_cases.find { |tc| tc.id == test_case_id }
      end

      def variable_required_by(variable)
        sequences.select { |sequence| sequence.requires.include? variable }
      end

      def variable_defined_by(variable)
        sequences.select { |sequence| sequence.defines.include? variable }
      end
    end
  end
end
