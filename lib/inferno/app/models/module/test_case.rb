# frozen_string_literal: true

module Inferno
  class Module
    class TestCase
      attr_accessor :id
      attr_accessor :parameters
      attr_accessor :sequence
      attr_accessor :test_group

      def initialize(id, test_group, sequence, parameters)
        @id = id
        @sequence = sequence
        @parameters = parameters
        @test_group = test_group
      end

      def description
        parameters[:description] || sequence.description
      end

      def prefix
        return unless parameters.key?(:prefix)

        "#{parameters[:prefix]}-"
      end

      def title
        parameters[:title] || sequence.title
      end

      def variable_defaults
        parameters[:variable_defaults]
      end
    end
  end
end
