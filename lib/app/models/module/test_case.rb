# frozen_string_literal: true

module Inferno
  class Module
    class TestCase
      attr_accessor :id
      attr_accessor :prefix
      attr_accessor :test_group
      attr_accessor :sequence
      attr_accessor :parameters

      def initialize(id, test_group, sequence, index, parameters)
        @id = id
        @sequence = sequence
        @test_group = test_group
        @parameters = parameters

        return unless test_group.prefix.present?

        index_as_string = 'A'.dup
        index.times { index_as_string.next! }
        @prefix = "#{test_group.prefix}#{index_as_string}-"
      end

      def title
        parameters[:title] || sequence.title
      end

      def description
        parameters[:description] || sequence.description
      end

      def variable_defaults
        parameters[:variable_defaults]
      end
    end
  end
end
