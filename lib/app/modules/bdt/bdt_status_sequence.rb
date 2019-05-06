
require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTStatusSequence < BDTBase

      group 'FIXME'

      title 'Status'

      description 'Status Endpoint'

      test_id_prefix 'Status'

      requires :token
      conformance_supports :CarePlan

      details %(
        Status
      )
      
      test 'Responds with 202 for active transaction IDs' do
        metadata {
          id '01'
          link 'http://bulkdatainfo'
          desc %(
            <p>The status endpoint should return <b>202</b> status code until the export is completed.</p>See <a target="_blank" href="https://github.com/smart-on-fhir/fhir-bulk-data-docs/blob/master/export.md#response---in-progress-status">https://github.com/smart-on-fhir/fhir-bulk-data-docs/blob/master/export.md#response---in-progress-status</a>
          )
          versions :r4
        }

        run_bdt('5.0')

      end
      test 'Replies properly in case of error' do
        metadata {
          id '02'
          link 'http://bulkdatainfo'
          desc %(
            Runs a set of assertions to verify that:<ul><li>The returned HTTP status code is 5XX</li><li>The server returns a FHIR OperationOutcome resource in JSON format</li></ul><p>Note that even if some of the requested resources cannot successfully be exported, the overall export operation MAY still succeed. In this case, the Response.error array of the completion response MUST be populated (see below) with one or more files in ndjson format containing FHIR OperationOutcome resources to indicate what went wrong.</p>See <a target="_blank" href="https://github.com/smart-on-fhir/fhir-bulk-data-docs/blob/master/export.md#response---error-status-1">https://github.com/smart-on-fhir/fhir-bulk-data-docs/blob/master/export.md#response---error-status-1</a>
          )
          versions :r4
        }

        run_bdt('5.1')

      end
      test 'Generates valid status response' do
        metadata {
          id '03'
          link 'http://bulkdatainfo'
          desc %(
            Runs a set of assertions to verify that:<ul><li>The status endpoint should return <b>200</b> status code when the export is completed</li><li>The status endpoint should respond with <b>JSON</b></li><li>The <code>expires</code> header (if set) must be valid date in the future</li><li>The JSON response contains <code>transactionTime</code> which is a valid <a target="_blank" href="http://hl7.org/fhir/datatypes.html#instant">FHIR instant</a></li><li>The JSON response contains the kick-off URL in <code>request</code> property</li><li>The JSON response contains <code>requiresAccessToken</code> boolean property</li><li>The JSON response contains an <code>output</code> array in which:<ul><li>Every item has valid <code>type</code> property</li><li>Every item has valid <code>url</code> property</li><li>Every item may a <code>count</code> number property</li></ul></li><li>The JSON response contains an <code>error</code> array in which:<ul><li>Every item has valid <code>type</code> property</li><li>Every item has valid <code>url</code> property</li><li>Every item may a <code>count</code> number property</li></ul></li></ul>
          )
          versions :r4
        }

        run_bdt('5.2')

      end

    end
  end
end