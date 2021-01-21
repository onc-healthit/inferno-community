# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsSimplequantityipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'SimpleQuantity (IPS) Tests'
      description 'Verify support for the server capabilities required by the SimpleQuantity (IPS) profile.'
      details %(
      )
      test_id_prefix 'SQIPS'
      requires :quantity_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Quantity resource from the Quantity read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/SimpleQuantity-uv-ips'
          description %(
            This test will verify that Quantity resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.quantity_id
        @resource_found = validate_read_reply(FHIR::Quantity.new(id: resource_id), FHIR::Quantity)
        save_resource_references(versioned_resource_class('Quantity'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/SimpleQuantity-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Quantity resource that matches the SimpleQuantity (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/SimpleQuantity-uv-ips'
          description %(
            This test will validate that the Quantity resource returned from the server matches the SimpleQuantity (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Quantity', 'http://hl7.org/fhir/uv/ips/StructureDefinition/SimpleQuantity-uv-ips')
      end
    end
  end
end
