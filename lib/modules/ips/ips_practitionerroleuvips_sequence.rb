# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsPractitionerroleuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'PractitionerRole (IPS) Tests'
      description 'Verify support for the server capabilities required by the PractitionerRole (IPS) profile.'
      details %(
      )
      test_id_prefix 'PRUI'
      requires :practitioner_role_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct PractitionerRole resource from the PractitionerRole read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/PractitionerRole-uv-ips'
          description %(
            This test will verify that PractitionerRole resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.practitioner_role_id
        @resource_found = validate_read_reply(FHIR::PractitionerRole.new(id: resource_id), FHIR::PractitionerRole)
        save_resource_references(versioned_resource_class('PractitionerRole'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/PractitionerRole-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns PractitionerRole resource that matches the PractitionerRole (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/PractitionerRole-uv-ips'
          description %(
            This test will validate that the PractitionerRole resource returned from the server matches the PractitionerRole (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('PractitionerRole', 'http://hl7.org/fhir/uv/ips/StructureDefinition/PractitionerRole-uv-ips')
      end
    end
  end
end
