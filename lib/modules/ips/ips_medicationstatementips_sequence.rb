# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsMedicationstatementipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Medication Statement (IPS) Tests'
      description 'Verify support for the server capabilities required by the Medication Statement (IPS) profile.'
      details %(
      )
      test_id_prefix 'MSIPS'
      requires :medication_statement_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct MedicationStatement resource from the MedicationStatement read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips'
          description %(
            This test will verify that MedicationStatement resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.medication_statement_id
        @resource_found = validate_read_reply(FHIR::MedicationStatement.new(id: resource_id), FHIR::MedicationStatement)
        save_resource_references(versioned_resource_class('MedicationStatement'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns MedicationStatement resource that matches the Medication Statement (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips'
          description %(
            This test will validate that the MedicationStatement resource returned from the server matches the Medication Statement (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('MedicationStatement', 'http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips')
      end
    end
  end
end
