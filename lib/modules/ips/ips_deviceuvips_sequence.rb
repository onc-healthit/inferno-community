# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsDeviceuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Device (IPS) Tests'
      description 'Verify support for the server capabilities required by the Device (IPS) profile.'
      details %(
      )
      test_id_prefix 'DUI'
      requires :device_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Device resource from the Device read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Device-uv-ips'
          description %(
            This test will verify that Device resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.device_id
        @resource_found = validate_read_reply(FHIR::Device.new(id: resource_id), FHIR::Device)
        save_resource_references(versioned_resource_class('Device'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Device-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Device resource that matches the Device (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Device-uv-ips'
          description %(
            This test will validate that the Device resource returned from the server matches the Device (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Device', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Device-uv-ips')
      end
    end
  end
end
