# frozen_string_literal: true

module Inferno
  module SequenceUtilities
    def resolve_path(elements, path)
      Inferno::FHIRPATH_EVALUATOR.evaluate(elements, path)
    end

    def find_search_parameter_value_from_resource(resource, path)
      get_value_for_search_param(resolve_element_from_path(resource, path) { |el| get_value_for_search_param(el).present? })
    end

    def get_value_for_search_param(element, include_system = false)
      search_value = case element
                     when FHIR::Period
                       if element.start.present?
                         'gt' + (DateTime.xmlschema(element.start) - 1).xmlschema
                       else
                         end_datetime = get_fhir_datetime_range(element.end)[:end]
                         'lt' + (end_datetime + 1).xmlschema
                       end
                     when FHIR::Reference
                       element.reference
                     when FHIR::CodeableConcept
                       if include_system
                         coding_with_code = resolve_element_from_path(element, 'coding') { |coding| coding.code.present? }
                         coding_with_code.present? ? "#{coding_with_code.system}|#{coding_with_code.code}" : nil
                       else
                         resolve_element_from_path(element, 'coding.code')
                       end
                     when FHIR::Identifier
                       if include_system
                         "#{element.system}|#{element.value}"
                       else
                         element.value
                       end
                     when FHIR::Coding
                       if include_system
                         "#{element.system}|#{element.code}"
                       else
                         element.code
                       end
                     when FHIR::HumanName
                       element.family || element.given&.first || element.text
                     when FHIR::Address
                       element.text || element.city || element.state || element.postalCode || element.country
                     else
                       element
                     end
      escaped_value = search_value&.gsub(',', '\\,')
      escaped_value
    end
  end
end
