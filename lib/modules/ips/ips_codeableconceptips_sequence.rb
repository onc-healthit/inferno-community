# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsCodeableconceptipsSequence < SequenceBase
      include Inferno::SequenceUtilities

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
    end
  end
end
