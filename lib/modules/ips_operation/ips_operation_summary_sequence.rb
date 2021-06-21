# frozen_string_literal: true

require_relative './ips_shared_bundle_tests'

module Inferno
  module Sequence
    class IpsSummaryOperationSequence < SequenceBase
      include Inferno::SequenceUtilities
      include SharedIpsBundleTests

      title 'Summary Operation (IPS) Tests'
      description 'Verify support for the $summary operation required by the International Patient Summary (IPS) profile.'
      details %(
      )
      test_id_prefix 'SO'
      requires :patient_id, :ips_query_parameters, :ips_query_method

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

        url = 'Patient/'

        url += "#{@instance.patient_id}/" unless @instance.patient_id.blank?

        url += '$summary'

        url += "?#{@instance.ips_query_parameters}" unless @instance.ips_query_parameters.blank?

        response = if @instance.ips_query_method&.downcase == 'get'
                     @client.get(url, headers)
                   else
                     @client.post(url, nil, headers)
                   end

        assert_response_ok response
        assert_valid_json(response.body)
        @bundle = FHIR.from_contents(response.body)
      end

      resource_validate_bundle(index: '03')
      resource_validate_composition(index: '04')
      resource_validate_medication_statement(index: '05')
      resource_validate_allergy_intolerance(index: '06')
      resource_validate_condition(index: '07')
      resource_validate_device(index: '08')
      resource_validate_device_use_statement(index: '09')
      resource_validate_diagnostic_report(index: '10')
      resource_validate_immunization(index: '11')
      resource_validate_medication(index: '12')
      resource_validate_organization(index: '13')
      resource_validate_patient(index: '14')
      resource_validate_practitioner(index: '15')
      resource_validate_practitioner_role(index: '16')
      resource_validate_procedure(index: '17')
      resource_validate_observation(index: '18')
    end
  end
end
