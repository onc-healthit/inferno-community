# frozen_string_literal: true

module Inferno
  module Sequence
    class McodeCancerPatientListSequence < SequenceBase
      title 'mCODE Cancer Patient List'

      description 'Verify support for the server capabilities required by the mCODE spec to return a list of mCODE Cancer Patients.'

      details %(
      )

      test_id_prefix 'MCODECPLIST'
      conformance_supports :Patient

      @resource_found = nil

      test 'Server supports returning list of mCODE patients' do
        metadata do
          id '02'
          name 'Server returns valid results for Patient search by patient+identifier.'
          link ''
          description %(
            A server SHALL support searching by patient+identifier to retrieve a list of mCODE Cancer Patients.
          )
          versions :r4
        end

        # Search parameter of profiles that match the mCODE Cancer Patient URL.
        search_params = { '_profile': 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-patient' }
        # Get the reply of a bundle of patients based on the search parameter.
        reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
        reply = perform_search_with_status(reply, search_params) if reply.code == 400
        # Assert that the reponse is present and is a bundle.
        assert_response_ok(reply)
        assert_bundle_response(reply)
        # Loop through the entries of the bundle reply.
        reply&.resource&.entry do |entry|
          # Read the current entry.
          resource_id = entry.resource&.resource_id&
          read_response = validate_read_reply(FHIR::Patient.new(id: resource_id), FHIR::Patient)
          @resource_found = read_response.resource
          @raw_resource_found = read_response.response[:body]
          # Validate that the current resource is an mCODE Cancer Patient.
          test_resource_against_profile('Patient', @raw_resource_found, 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-patient')
        end
      end
    end
  end
end