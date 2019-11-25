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
      attr_accessor :test_case_names
      attr_accessor :tags

      def initialize(test_set, group)
        @test_set = test_set
        @name = group[:name]
        @id = name.gsub(/[^0-9a-z]/i, '')
        @overview = group[:overview]
        @run_all = group[:run_all] || false
        @test_cases = []
        @test_case_names = Set.new
        @input_instructions = group[:input_instructions]
        @lock_variables = group[:lock_variables] || []
        @run_skipped = group[:run_skipped] || false
        @tags = group[:tags]&.map do |tag|
          Tag.new(tag[:name], tag[:description], tag[:url])
        end || []

        group[:sequences].each do |sequence|
          if sequence.instance_of?(String)
            add_test_case(sequence)
          else
            add_test_case(sequence[:sequence], sequence)
          end
        end
      end

      def add_test_case(sequence_name, parameters = {})
        current_name = "#{test_set.id}_#{id}_#{sequence_name}"
        index = 1
        while test_case_names.include? current_name
          index += 1
          current_name = "#{test_set.id}_#{id}_#{sequence_name}_#{index}"
          raise 'Too many test cases using the same scenario' if index > 99
        end

        test_case_names << current_name

        sequence = Inferno::Sequence::SequenceBase.descendants.find { |seq| seq.sequence_name == sequence_name }

        raise "No such sequence: #{sequence_name}" if sequence.nil?

        new_test_case = TestCase.new(current_name, self, sequence, parameters)

        test_cases << new_test_case

        new_test_case
      end

      def sequences
        test_cases.flat_map(&:sequence)
      end
    end
  end
end
