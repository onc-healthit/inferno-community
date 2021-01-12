# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsCompositionuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Composition (IPS) Tests'
      description 'Verify support for the server capabilities required by the Composition (IPS) profile.'
      details %(
      )
      test_id_prefix 'CUI'
      requires :composition_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Composition resource from the Composition read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips'
          description %(
            This test will verify that Composition resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.composition_id
        @resource_found = validate_read_reply(FHIR::Composition.new(id: resource_id), FHIR::Composition)
        save_resource_references(versioned_resource_class('Composition'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Composition resource that matches the Composition (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips'
          description %(
            This test will validate that the Composition resource returned from the server matches the Composition (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Composition', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips')
      end
    end
  end
end
