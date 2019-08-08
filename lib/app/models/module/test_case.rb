# frozen_string_literal: true

module Inferno
  class Module
    class TestCase
      attr_accessor :id
      attr_accessor :test_group
      attr_accessor :sequence
      attr_accessor :parameters

      def initialize(id, test_group, sequence, parameters)
        @id = id
        @sequence = sequence
        @test_group = test_group
        @parameters = parameters
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
