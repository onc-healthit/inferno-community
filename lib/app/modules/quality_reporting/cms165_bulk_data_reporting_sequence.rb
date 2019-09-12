# frozen_string_literal: true

require_relative '../../utils/measure_operations'

module Inferno
  module Sequence
    class CMS165BulkDataReportingSequence < SequenceBase
      include MeasureOperations

      title 'CMS165 Bulk Data Reporting'

      test_id_prefix 'CMS165Bulk'

      description 'Tests measure operations for CMS165 (Controlling High Blood Pressure). <br/><br/>'\
                  'Prior to running tests, you must: <br/>'\
                  '1) POST '\
                  '<a href="/inferno/resources/quality_reporting/Bundle/cms165vs-bundle.json">the CMS165 ValueSet Bundle</a> '\
                  'to your FHIR server, and observe the status codes in the response to ensure all resources '\
                  'saved sucessfully. <br/>'\
                  '2) POST '\
                  '<a href="/inferno/resources/quality_reporting/Bundle/cms165-bundle.json">this Bundle</a> '\
                  'to your FHIR server, and observe the status codes in the response to ensure all resources '\
                  'saved sucessfully.'

      # These values are based on the content of the CMS165 bundle used for this module.
      measure_id = 'MitreTestScript-measure-exm165-FHIR3'

      test 'Bulk Data Submit Data' do
        metadata do
          id '01'
          link 'https://hl7.org/fhir/STU3/measure-operations.html#evaluate-measure'
          desc 'Run the $evaluate-measure operation for an individual that should be in the IPP and Denominator'
        end

        params_file_path = File.expand_path('../../../../resources/quality_reporting/Parameters/cms165-submit-data-params.json', __dir__)
        submit_data_payload = File.read(params_file_path)

        # Initial async submit data call to kick off the job
        async_submit_data_response = async_submit_data(measure_id, submit_data_payload)
        assert_response_accepted(async_submit_data_response)

        # Use the content-location in the response to check the status of the import
        # Check the status on loop until the job is finished
        content_loc = async_submit_data_response.response[:headers]['Content-Location']
        loop do
          status_response = @client.get(content_loc)
          break if [200, 201].include?(status_response.code)

          assert_response_accepted(status_response)
        end

        # Check that the submitted resources are GETable
        patient_get_response = @client.get('Patient/bc4159a4-6ff2-4a5b-be3a-d9c4778642c2-1')
        assert_response_ok(patient_get_response)

        condition_get_response = @client.get('Condition/bc4159a4-6ff2-4a5b-be3a-d9c4778642c2-2')
        assert_response_ok(condition_get_response)

        encounter_get_response = @client.get('Encounter/bc4159a4-6ff2-4a5b-be3a-d9c4778642c2-3')
        assert_response_ok(encounter_get_response)

        observation_get_response = @client.get('Observation/bc4159a4-6ff2-4a5b-be3a-d9c4778642c2-4')
        assert_response_ok(observation_get_response)
      end
    end
  end
end
