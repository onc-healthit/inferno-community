# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsRangeipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Range (IPS) Tests'
      description 'Verify support for the server capabilities required by the Range (IPS) profile.'
      details %(
      )
      test_id_prefix 'RIPS'
      requires :range_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Range resource from the Range read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Range-uv-ips'
          description %(
            This test will verify that Range resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.range_id
        @resource_found = validate_read_reply(FHIR::Range.new(id: resource_id), FHIR::Range)
        save_resource_references(versioned_resource_class('Range'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Range-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Range resource that matches the Range (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Range-uv-ips'
          description %(
            This test will validate that the Range resource returned from the server matches the Range (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Range', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Range-uv-ips')
      end
    end
  end
end
