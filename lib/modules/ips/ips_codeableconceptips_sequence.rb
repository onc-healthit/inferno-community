# frozen_string_literal: true

require_relative './profile_definitions/ips_codeableconceptips_sequence_definitions'

module Inferno
  module Sequence
    class IpsCodeableconceptipsSequence < SequenceBase
      include Inferno::SequenceUtilities
      include Inferno::IpsProfileDefinitions

      title 'Codeable Concept (IPS) Tests'
      description 'Verify support for the server capabilities required by the Codeable Concept (IPS) profile.'
      details %(
      )
      test_id_prefix 'CCIPS'
      requires :codeable_concept_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct CodeableConcept resource from the CodeableConcept read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/CodeableConcept-uv-ips'
          description %(
            This test will verify that CodeableConcept resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.codeable_concept_id
        @resource_found = validate_read_reply(FHIR::CodeableConcept.new(id: resource_id), FHIR::CodeableConcept)
        save_resource_references(versioned_resource_class('CodeableConcept'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/CodeableConcept-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns CodeableConcept resource that matches the Codeable Concept (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/CodeableConcept-uv-ips'
          description %(
            This test will validate that the CodeableConcept resource returned from the server matches the Codeable Concept (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('CodeableConcept', 'http://hl7.org/fhir/uv/ips/StructureDefinition/CodeableConcept-uv-ips')
      end

      test :must_support do
        metadata do
          id '03'
          name 'All must support elements are provided in the CodeableConcept resources returned.'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/CodeableConcept-uv-ips'
          optional
          description %(

            This will look through the CodeableConcept resource for the following must support elements:

            * CodeableConcept
            * coding
            * text

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        must_supports = IpsCodeableconceptipsSequenceDefinition::MUST_SUPPORTS

        missing_must_support_elements = must_supports[:elements].reject do |element|
          value_found = resolve_element_from_path(@resource_found, element[:path]) do |value|
            value_without_extensions = value.respond_to?(:to_hash) ? value.to_hash.reject { |key, _| key == 'extension' } : value
            (value_without_extensions.present? || value_without_extensions == false) && (element[:fixed_value].blank? || value == element[:fixed_value])
          end

          # Note that false.present? => false, which is why we need to add this extra check
          value_found.present? || value_found == false
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the provided resource"
        @instance.save!
      end
    end
  end
end
