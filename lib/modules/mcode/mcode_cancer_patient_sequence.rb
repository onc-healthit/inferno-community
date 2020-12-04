# frozen_string_literal: true

module Inferno
  module Sequence
    class McodeCancerPatientSequence < SequenceBase
      title 'mCODE Cancer Patient'

      description 'Verify support for the server capabilities required by the Cancer Patient.'

      details %(
      )

      test_id_prefix 'MCODECP'
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

      test :validate_meta do
        metadata do
          id '02'
          name 'The Patient resource returned from the first Read test has a meta.profile of http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-patient.'
          link ''
          description %(
          )
          versions :r4
        end

        skip 'No resource found from Read test.' unless @resource_found.present?

          assert @raw_resource_found.meta.profile = 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-patient'
      end

      test :validate_resource do
        metadata do
          id '03'
          name 'The Patient resource returned from the first Read test is valid according to the profile http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-patient.'
          link ''
          description %(
          )
          versions :r4
        end

        skip 'No resource found from Read test.' unless @resource_found.present?

        test_resource_against_profile('Patient', @raw_resource_found, 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-patient')
      end

      test 'Server returns expected results from Patient when searching by identifier' do
        metadata do
          id '04'
          name 'The Patient http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-patient supports search on the server.'
          link ''
          description %(
            A server has exposed a FHIR Patient search endpoint supporting the following search parameters: identifier.
          )
          versions :r4
        end

        assert !@raw_resource_found.nil?, 'No resource found from Read test.'
        identifier = @raw_resource_found.try(:identifier).try(:first).try(:value)
        assert !identifier.nil?, 'Patient identifier not returned from search.'
        search_params = { identifier: identifier }
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
      end
    end
  end
end