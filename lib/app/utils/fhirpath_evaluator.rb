# frozen_string_literal: true

require 'rest-client'
require 'json'
require 'fhir_models'

module Inferno
  class FHIRPathEvaluator
    # @param fhirpath_url [String] the base url for the FHIRPath /evaluate endpoint
    def initialize(fhirpath_url)
      raise ArgumentError, 'FHIRPath URL is unset' if fhirpath_url.blank?

      @fhirpath_url = fhirpath_url
    end

    # Evaluates the given FHIRPath expression against the given elements by posting each element
    # to the FHIRPath wrapper.
    # @param elements [Array]
    # @param path [String]
    def evaluate(elements, path)
      elements = Array.wrap(elements)
      return elements if path.blank?

      types = elements.map { |e| e.class.name.demodulize }
      Inferno.logger.info("Evaluating path '#{path}' on types: #{types}")

      elements.flat_map do |element|
        type = type_path(element)
        Inferno.logger.info("POST #{@fhirpath_url}/evaluate?path=#{path}&type=#{type}")
        result = RestClient.post "#{@fhirpath_url}/evaluate", element.to_json, params: { path: path, type: type }
        collection = JSON.parse(result.body)

        collection.map { |container| deserialize(container['element'], container['type']) }
      end.compact
    end

    private

    # Examples:
    # type_path(FHIR::Patient.new) -> 'Patient'
    # type_path(FHIR::Patient::Contact.new) -> 'Patient.contact'
    # type_path(FHIR::RiskEvidenceSynthesis::Certainty::CertaintySubcomponent.new)
    #   -> 'RiskEvidenceSynthesis.certainty.certaintySubcomponent'
    def type_path(element)
      parts = element.class.name.split('::').drop(1)
      # Assumes that BackboneElements are named by capitalizing path components
      parts[1..-1].each { |part| part[0] = part[0].downcase }
      parts.join('.')
    end

    def deserialize(element, type)
      if element.is_a?(Hash)
        first_component, *rest_components = type.split('.')
        klass = FHIR.const_get(first_component)
        rest_components.each do |component|
          klass = FHIR.const_get(klass::METADATA[component]['type'])
        end
        klass.new(element)
      else
        element
      end
    end
  end
end
