# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsAllergyintoleranceuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Allergy Intolerance (IPS) Tests'
      description 'Verify support for the server capabilities required by the Allergy Intolerance (IPS) profile.'
      details %(
      )
      test_id_prefix 'AIUI'
      requires :allergy_intolerance_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct AllergyIntolerance resource from the AllergyIntolerance read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/AllergyIntolerance-uv-ips'
          description %(
            This test will verify that AllergyIntolerance resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.allergy_intolerance_id
        @resource_found = validate_read_reply(FHIR::AllergyIntolerance.new(id: resource_id), FHIR::AllergyIntolerance)
        save_resource_references(versioned_resource_class('AllergyIntolerance'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/AllergyIntolerance-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns AllergyIntolerance resource that matches the Allergy Intolerance (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/AllergyIntolerance-uv-ips'
          description %(
            This test will validate that the AllergyIntolerance resource returned from the server matches the Allergy Intolerance (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('AllergyIntolerance', 'http://hl7.org/fhir/uv/ips/StructureDefinition/AllergyIntolerance-uv-ips')
      end
    end
  end
end
