# frozen_string_literal: true

require_relative 'test_case'

module Inferno
  class Module
    class TestGroup
      attr_accessor :test_set
      attr_accessor :name
      attr_accessor :overview
      attr_accessor :input_instructions
      attr_accessor :lock_variables
      attr_accessor :id
      attr_accessor :test_cases
      attr_accessor :run_all
      attr_accessor :run_skipped

      def initialize(test_set, name, overview, input_instructions, lock_variables, run_all, run_skipped)
        @test_set = test_set
        @name = name
        @id = name.gsub(/[^0-9a-z]/i, '')
        @overview = overview
        @run_all = run_all
        @test_cases = []
        @test_case_names = {}
        @input_instructions = input_instructions
        @lock_variables = lock_variables || []
        @run_skipped = run_skipped
      end

      def add_test_case(sequence_name, parameters = {})
        current_name = "#{test_set.id}_#{@id}_#{sequence_name}"
        index = 1
        while @test_case_names.key?(current_name)
          index += 1
          current_name = "#{test_set.id}_#{@id}_#{sequence_name}_#{index}"
          raise 'Too many test cases using the same scenario' if index > 99
        end

        @test_case_names[current_name] = true

        sequence = Inferno::Sequence::SequenceBase.descendants.find { |seq| seq.sequence_name == sequence_name }

        raise "No such sequence: #{sequence_name}" if sequence.nil?

        new_test_case = TestCase.new(current_name, self, sequence, parameters)

        @test_cases << new_test_case

        new_test_case
      end
    end
  end
end
