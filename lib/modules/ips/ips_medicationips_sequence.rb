# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsMedicationipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Medication (IPS) Tests'
      description 'Verify support for the server capabilities required by the Medication (IPS) profile.'
      details %(
      )
      test_id_prefix 'MIPS'
      requires :medication_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Medication resource from the Medication read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Medication-uv-ips'
          description %(
            This test will verify that Medication resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.medication_id
        @resource_found = validate_read_reply(FHIR::Medication.new(id: resource_id), FHIR::Medication)
        save_resource_references(versioned_resource_class('Medication'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Medication-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Medication resource that matches the Medication (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Medication-uv-ips'
          description %(
            This test will validate that the Medication resource returned from the server matches the Medication (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Medication', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Medication-uv-ips')
      end
    end
  end
end
