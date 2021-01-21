# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsDeviceusestatementuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Device Use Statement (IPS) Tests'
      description 'Verify support for the server capabilities required by the Device Use Statement (IPS) profile.'
      details %(
      )
      test_id_prefix 'DUSUI'
      requires :device_use_statement_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct DeviceUseStatement resource from the DeviceUseStatement read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips'
          description %(
            This test will verify that DeviceUseStatement resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.device_use_statement_id
        @resource_found = validate_read_reply(FHIR::DeviceUseStatement.new(id: resource_id), FHIR::DeviceUseStatement)
        save_resource_references(versioned_resource_class('DeviceUseStatement'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns DeviceUseStatement resource that matches the Device Use Statement (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips'
          description %(
            This test will validate that the DeviceUseStatement resource returned from the server matches the Device Use Statement (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('DeviceUseStatement', 'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips')
      end
    end
  end
end
