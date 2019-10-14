# frozen_string_literal: true

require_relative '../../utils/measure_operations'
require_relative '../../utils/bulk_data/ndjson_factory'

module Inferno
  module Sequence
    class CMS165BulkDataReportingSequence < SequenceBase
      include MeasureOperations
      include WebUtils

      title 'CMS165 Bulk Data Reporting'

      test_id_prefix 'CMS165Bulk'

      description 'Tests measure operations for CMS165 (Controlling High Blood Pressure). <br/><br/>'\
                  'Prior to running tests, you must: <br/>'\
                  '1) POST '\
                  '<a href="/inferno/resources/quality_reporting/Bundle/cms165-bundle.json">CMS165 Measure and Value Set Bundle</a> '\
                  'to your FHIR server, and observe the status codes in the response to ensure all resources '\
                  'saved sucessfully.'

      # These values are based on the content of the CMS165 bundle used for this module.
      # measure_id = 'MitreTestScript-measure-exm165-FHIR3'

      test 'Bulk Data Import' do
        metadata do
          id '01'
          link 'https://github.com/smart-on-fhir/bulk-import/blob/master/import.md'
          desc 'Run bulk data $import operation for CMS165'
        end

        BUNDLES = [
          '../../../../test/fixtures/Brett333_Gutmann970_2a29169c-f0b7-415b-aaf9-43ba107006ad.json',
          '../../../../test/fixtures/Bud153_Renner328_0f3ae208-5a0f-4bb4-ba0d-267725ef964b.json'
        ].freeze

        # Generate a URL for the ndjson to give to the server based on the service type in config.yml
        ndjson_service = NDJsonFactory.get_service(Inferno::NDJSON_SERVICE_TYPE, BUNDLES.map { |p| File.expand_path p, __dir__ }, @instance)
        ndjson_service.generate_ndjson

        # Initial async submit data call to kick off the job
        submit_data_payload = ndjson_service.generate_bulk_data_params
        async_submit_data_response = async_submit_data(submit_data_payload)
        assert_response_accepted(async_submit_data_response)

        # Check the status on loop until the job is finished
        content_loc = async_submit_data_response.headers[:content_location]
        polling_response = get_with_retry(content_loc, 180, @client)

        # Once the loop breaks, should receive 200 OK
        assert_response_ok(polling_response)
      end
    end
  end
end
