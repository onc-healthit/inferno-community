# frozen_string_literal: true

require_relative './generic_generator_utilities'

module Inferno
  module Generator
    class SearchParameterMetadata
      include Inferno::Generator::GenericGeneratorUtilties

      attr_reader :search_parameter_json
      attr_writer :url,
                  :code,
                  :type,
                  :expression,
                  :multiple_or,
                  :multiple_or_expectation,
                  :multiple_and,
                  :multiple_and_expectation,
                  :modifiers,
                  :comparators

      def initialize(search_parameter_json)
        @search_parameter_json = search_parameter_json
      end

      def url
        @url ||= @search_parameter_json['url']
      end

      def code
        @code ||= @search_parameter_json['code']
      end

      def type
        @type ||= @search_parameter_json['type']
      end

      def expression
        @expression ||= expression_without_fhir_path(@search_parameter_json['expression'])
      end

      def expression_without_fhir_path(path)
        # handle some fhir path stuff. Remove this once fhir path server is added
        as_type = path.scan(/.as\((.*?)\)/).flatten.first
        path = path.gsub(/.as\((.*?)\)/, as_type.upcase_first) if as_type.present?
        path.gsub(/.where\((.*)/, '')
      end

      # whether multiple or is allowed
      def multiple_or
        @multiple_or ||= @search_parameter_json['multipleOr']
      end

      # expectation if multiple or is allowed - unsure if this is generic or just us core specific
      def multiple_or_expectation
        @multiple_or_expectation ||= @search_parameter_json.dig('_multipleOr', 'extension')
                                         &.find { |ext| ext['url'] == EXPECTATION_URL }
                                         &.dig('valueCode')
      end

      # whether multiple and is allowed
      def multiple_and
        @multiple_and ||= @search_parameter_json['multipleAnd']
      end

      # expectation if multiple and is allowed - unsure if this is generic or just us core specific
      def multiple_and_expectation
        @multiple_and_expectation ||= @search_parameter_json.dig('_multipleAnd', 'extension')
                                          &.find { |ext| ext['url'] == EXPECTATION_URL }
                                          &.dig('valueCode')
      end

      def comparators
        return [] if @search_parameter_json['comparator'].nil?

        @comparators ||= @search_parameter_json['comparator'].each_with_index.map do |comparator, index|
          expectation_extension = @search_parameter_json['_comparator'] # unsure if this is us core specific
          expectation = expectation_extension[index]['extension'].find { |ext| ext['url'] == EXPECTATION_URL }['valueCode'] unless expectation_extension.nil?
          { comparator: comparator, expectation: expectation }
        end
      end

      def modifiers
        return [] if @search_parameter_json['modifier'].nil?

        @modifiers ||= @search_parameter_json['modifier'].each_with_index.map do |modifier, index|
          expectation_extension = @search_parameter_json['_modifier'] # unsure if this is us core specific
          expectation = expectation_extension[index]['extension'].find { |ext| ext['url'] == EXPECTATION_URL }['valueCode'] unless expectation_extension.nil?
          { modifier: modifier, expectation: expectation }
        end
      end
    end
  end
end
