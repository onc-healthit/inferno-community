# frozen_string_literal: true

module Inferno
  module Sequence
    class MCODERequirementsMcodeCancerPatientSequence < SequenceBase
      title 'Cancer Patient Tests'

      description 'Verify support for the server capabilities required by the Cancer Patient.'

      details %(
      )

      test_id_prefix 'CP'
      requires :mcode_cancer_patient_id
      conformance_supports :Patient

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Patient resource from the Patient read interaction'
          link 'http://hl7.org/fhir/us/mcode/index.html'
          description %(
            Tests whether the Patient with the provided id can be resolved and read.
          )
          versions :r4
        end

        resource_id = @instance.mcode_cancer_patient_id
        read_response = validate_read_reply(FHIR::Patient.new(id: resource_id), FHIR::Patient)
        @resource_found = read_response.resource
        @raw_resource_found = read_response.response[:body]
      end

      test :validate_resources do
        metadata do
          id '02'
          name 'The Patient resource returned from the first Read test is valid according to the profile http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-patient.'
          link ''
          description %(

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?

        test_resource_against_profile('Patient', @raw_resource_found, 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-patient')
      end
    end
  end
end
