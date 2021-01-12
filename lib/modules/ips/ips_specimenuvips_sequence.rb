# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsSpecimenuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Specimen (IPS) Tests'
      description 'Verify support for the server capabilities required by the Specimen (IPS) profile.'
      details %(
      )
      test_id_prefix 'SUI'
      requires :specimen_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Specimen resource from the Specimen read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Specimen-uv-ips'
          description %(
            This test will verify that Specimen resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.specimen_id
        @resource_found = validate_read_reply(FHIR::Specimen.new(id: resource_id), FHIR::Specimen)
        save_resource_references(versioned_resource_class('Specimen'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Specimen-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Specimen resource that matches the Specimen (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Specimen-uv-ips'
          description %(
            This test will validate that the Specimen resource returned from the server matches the Specimen (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Specimen', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Specimen-uv-ips')
      end
    end
  end
end
