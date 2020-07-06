# frozen_string_literal: true

module Inferno
  module Sequence
    class MCODERequirementsMcodeCancerRelatedMedicationStatementSequence < SequenceBase
      title 'Cancer-Related Medication Statement Tests'

      description 'Verify support for the server capabilities required by the Cancer-Related Medication Statement.'

      details %(
      )

      test_id_prefix 'C-RMS'
      requires :mcode_cancer_related_medication_statement_id
      conformance_supports :MedicationStatement

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct MedicationStatement resource from the MedicationStatement read interaction'
          link 'http://hl7.org/fhir/us/mcode/index.html'
          description %(
            Tests whether the MedicationStatement with the provided id can be resolved and read.
          )
          versions :r4
        end

        resource_id = @instance.mcode_cancer_related_medication_statement_id
        read_response = validate_read_reply(FHIR::MedicationStatement.new(id: resource_id), FHIR::MedicationStatement)
        @resource_found = read_response.resource
        @raw_resource_found = read_response.response[:body]
      end

      test :validate_resources do
        metadata do
          id '02'
          name 'The MedicationStatement resource returned from the first Read test is valid according to the profile http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-related-medication-statement.'
          link ''
          description %(

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?

        test_resource_against_profile('MedicationStatement', @raw_resource_found, 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-related-medication-statement')
      end
    end
  end
end
