# frozen_string_literal: true

require_relative './ips_shared_bundle_tests'

module Inferno
  module Sequence
    class IpsSummaryOperationSequence < SequenceBase
      include Inferno::SequenceUtilities
      include SharedIpsBundleTests

      title 'Summary Operation (IPS) Tests'
      description 'Verify support for the $summary operation required by the Specimen (IPS) profile.'
      details %(
      )
      test_id_prefix 'SO'
      requires :patient_id

      support_operation(index: '01',
                        resource_type: 'Patient',
                        operation_name: 'summary',
                        operation_definition: 'http://hl7.org/fhir/OperationDefinition/Patient-summary')

      test :run_operation do
        metadata do
          id '02'
          name 'IPS Server returns Bundle resource for Patient/id/$summary operation'
          link 'http://build.fhir.org/ig/HL7/fhir-ips/index.html'
          description %(
            IPS Server return valid IPS Bundle resource as successful result of $summary operation

            POST [base]/Patient/id/$summary
          )
        end

        headers = { 'Accept' => 'application/fhir+json' }

        response = @client.post("Patient/#{@instance.patient_id}/$summary", nil, headers)

        assert_response_ok response
        assert_valid_json(response.body)
        @bundle = FHIR.from_contents(response.body)
      end

      resource_validate_bundle(index: '03')
      resource_validate_medication_statement(index: '04')
      resource_validate_allergy_intolerance(index: '05')
      resource_validate_condition(index: '06')
      resource_validate_composition(index: '07')
    end
  end
end
