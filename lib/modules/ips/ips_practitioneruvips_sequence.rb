# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsPractitioneruvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Practitioner (IPS) Tests'
      description 'Verify support for the server capabilities required by the Practitioner (IPS) profile.'
      details %(
      )
      test_id_prefix 'PUI'
      requires :practitioner_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Practitioner resource from the Practitioner read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Practitioner-uv-ips'
          description %(
            This test will verify that Practitioner resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.practitioner_id
        @resource_found = validate_read_reply(FHIR::Practitioner.new(id: resource_id), FHIR::Practitioner)
        save_resource_references(versioned_resource_class('Practitioner'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Practitioner-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Practitioner resource that matches the Practitioner (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Practitioner-uv-ips'
          description %(
            This test will validate that the Practitioner resource returned from the server matches the Practitioner (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Practitioner', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Practitioner-uv-ips')
      end
    end
  end
end
