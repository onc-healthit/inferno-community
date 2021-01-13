# frozen_string_literal: true

require_relative 'bcp_13'
require_relative 'bcp47'

module Inferno
  class Terminology
    class Codesystem
      attr_accessor :codesystem_model

      def initialize(cs_model)
        @codesystem_model = cs_model
      end

      def all_codes_in_concept(concepts)
        cs_set = Set.new
        load_codes = lambda do |concept|
          concept.each do |concept_code|
            cs_set.add(system: codesystem_model.url, code: concept_code.code)
            load_codes.call(concept_code.concept) unless concept_code.concept.empty?
          end
        end
        load_codes.call(concepts.flatten)
        cs_set
      end

      def find_concept(concept_code, starting_concept = codesystem_model.concept)
        next_concepts = []
        starting_concept = [starting_concept].flatten
        starting_concept.each do |cs_concept|
          return cs_concept if cs_concept.code == concept_code

          next_concepts.push(*cs_concept.concept) unless cs_concept.concept.empty?
        end
        next_concepts.each { |next_concept| find_concept(concept_code, next_concept) }
      end

      def filter_codes(filter = nil)
        return all_codes_in_concept(codesystem_model.concept) if filter.nil?

        unless (filter.op == 'is-a') && (codesystem_model.hierarchyMeaning == 'is-a') && (filter.property == 'concept')
          raise Inferno::Terminology::ValueSet::FilterOperationException, filter.to_s
        end

        parent_concept = find_concept(filter.value)
        all_codes_in_concept([parent_concept])
      end
    end
  end
end
