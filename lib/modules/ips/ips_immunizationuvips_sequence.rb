# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsImmunizationuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Immunization (IPS) Tests'
      description 'Verify support for the server capabilities required by the Immunization (IPS) profile.'
      details %(
      )
      test_id_prefix 'IUI'
      requires :immunization_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Immunization resource from the Immunization read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips'
          description %(
            This test will verify that Immunization resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.immunization_id
        @resource_found = validate_read_reply(FHIR::Immunization.new(id: resource_id), FHIR::Immunization)
        save_resource_references(versioned_resource_class('Immunization'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Immunization resource that matches the Immunization (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips'
          description %(
            This test will validate that the Immunization resource returned from the server matches the Immunization (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Immunization', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips')
      end
    end
  end
end
