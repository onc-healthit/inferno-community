# frozen_string_literal: true

module Inferno
  module Sequence
    class USCoreR4MedicationListSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Medication List Guidance Tests'

      description 'Verify that MedicationRequests can be queried according to the US Core R4 Medication List Guidance'

      test_id_prefix 'MLG'

      requires :token, :patient_id
      conformance_supports :MedicationRequest, :Medication

      details %(
        The #{title} Sequence tests that MedicationRequests and Medications can
        be retrieved according to the [US Core R4 Medication List
        Guidance](https://www.hl7.org/fhir/us/core/all-meds.html)
      )

      test :include_medications do
        metadata do
          id '01'
          name 'FHIR server supports including Medications in a MedicationRequest search'
          link 'https://www.hl7.org/fhir/us/core/all-meds.html#options-for-representing-medication'
          description %(
            When referencing the Medication resource, the resource may be...an
            external resource...if an external reference to Medication is used,
            the server SHALL support the include parameter for searching this
            element.
          )
        end

        search_params = {
          patient: @instance.patient_id,
          intent: 'order',
          # servers may not support searching for patient + intent without
          # status, but are required to support patient + intent + status
          status: 'active,on-hold,cancelled,entered-in-error,stopped,draft,unknown'
        }
        response = get_resource_by_params(FHIR::MedicationRequest, search_params)
        assert_response_ok(response)
        assert_bundle_response(response)
        medication_requests = fetch_all_bundled_resources(response.resource)

        skip_if medication_requests.blank?, 'No MedicationRequests were found'

        requests_with_external_references =
          medication_requests
            .select { |request| request.medicationReference.present? }
            .reject { |request| request.medicationReference.reference.start_with? '#' }

        omit 'No MedicationRequests use external Medication references' if requests_with_external_references.blank?

        search_params.merge!(_include: 'MedicationRequest:medication')
        response = get_resource_by_params(FHIR::MedicationRequest, search_params)
        assert_response_ok(response)
        assert_bundle_response(response)
        requests_with_medications = fetch_all_bundled_resources(response.resource)

        medications = requests_with_medications.select { |resource| resource.resourceType == 'Medication' }
        assert medications.present?, 'No Medications were included in the search results'
      end
    end
  end
end
