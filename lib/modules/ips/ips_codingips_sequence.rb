# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsCodingipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Coding with translations Tests'
      description 'Verify support for the server capabilities required by the Coding with translations profile.'
      details %(
      )
      test_id_prefix 'CIPS'
      requires :coding_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Coding resource from the Coding read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Coding-uv-ips'
          description %(
            This test will verify that Coding resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.coding_id
        @resource_found = validate_read_reply(FHIR::Coding.new(id: resource_id), FHIR::Coding)
        save_resource_references(versioned_resource_class('Coding'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Coding-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Coding resource that matches the Coding with translations profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Coding-uv-ips'
          description %(
            This test will validate that the Coding resource returned from the server matches the Coding with translations profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Coding', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Coding-uv-ips')
      end
    end
  end
end
