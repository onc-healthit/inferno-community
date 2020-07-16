# frozen_string_literal: true

require_relative 'test_group'

module Inferno
  class Module
    class TestSet
      attr_accessor :id
      attr_accessor :view
      attr_accessor :groups

      def initialize(id, test_set)
        @id = id
        @view = test_set[:view]
        @groups = test_set[:tests].map { |group| TestGroup.new(self, group) }
      end

      def sequences
        groups.flat_map(&:sequences)
      end

      def test_cases
        groups.flat_map(&:test_cases)
      end

      def test_case_by_id(test_case_id)
        test_cases.find { |tc| tc.id == test_case_id }
      end

      def variable_required_by(variable)
        sequences.select { |sequence| (sequence.requires.include? variable) || (sequence.new_requires.include? variable) }
      end

      def variable_defined_by(variable)
        sequences.select { |sequence| sequence.defines.include? variable }
      end
    end
  end
end
