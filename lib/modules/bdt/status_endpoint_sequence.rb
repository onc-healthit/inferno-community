# frozen_string_literal: true

require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTStatusSequence < BDTBase
      title 'Status Endpoint'

      description 'Verify the status endpoint conforms to the SMART Bulk Data IG for Export.'

      test_id_prefix 'Status'

      requires :bulk_url, :bulk_token_endpoint, :bulk_client_id, \
               :bulk_system_export_endpoint, :bulk_patient_export_endpoint, :bulk_group_export_endpoint, \
               :bulk_fastest_resource, :bulk_requires_auth, :bulk_since_param, :bulk_jwks_url_auth, :bulk_jwks_url_auth, \
               :bulk_public_key, :bulk_private_key

      details %(
        Status Endpoint
      )

      test 'Responds with 202 for active transaction IDs' do
        metadata do
          id '01'
          link 'http://bulkdatainfo'
          description %(
            <p>The status endpoint should return <b>202</b> status code until the export is completed.</p>See <a target="_blank" href="https://github.com/HL7/bulk-data/blob/master/spec/export/index.md#response---in-progress-status">https://github.com/HL7/bulk-data/blob/master/spec/export/index.md#response---in-progress-status</a>
          )
          versions :r4
        end

        run_bdt('5.0')
      end
      test 'Replies properly in case of error' do
        metadata do
          id '02'
          link 'http://bulkdatainfo'
          description %(
            Runs a set of assertions to verify that:<ul><li>The returned HTTP status code is 5XX</li><li>The server returns a FHIR OperationOutcome resource in JSON format</li></ul><p>Note that even if some of the requested resources cannot successfully be exported, the overall export operation MAY still succeed. In this case, the Response.error array of the completion response MUST be populated (see below) with one or more files in ndjson format containing FHIR OperationOutcome resources to indicate what went wrong.</p>See <a target="_blank" href="https://github.com/HL7/bulk-data/blob/master/spec/export/index.md#response---error-status-1">https://github.com/HL7/bulk-data/blob/master/spec/export/index.md#response---error-status-1</a>
          )
          versions :r4
        end

        run_bdt('5.1')
      end
      test 'Generates valid status response' do
        metadata do
          id '03'
          link 'http://bulkdatainfo'
          description %(
            Runs a set of assertions to verify that:<ul><li>The status endpoint should return <b>200</b> status code when the export is completed</li><li>The status endpoint should respond with <b>JSON</b></li><li>The <code>expires</code> header (if set) must be valid date in the future</li><li>The JSON response contains <code>transactionTime</code> which is a valid <a target="_blank" href="http://hl7.org/fhir/datatypes.html#instant">FHIR instant</a></li><li>The JSON response contains the kick-off URL in <code>request</code> property</li><li>The JSON response contains <code>requiresAccessToken</code> boolean property</li><li>The JSON response contains an <code>output</code> array in which:<ul><li>Every item has valid <code>type</code> property</li><li>Every item has valid <code>url</code> property</li><li>Every item may a <code>count</code> number property</li></ul></li><li>The JSON response contains an <code>error</code> array in which:<ul><li>Every item has valid <code>type</code> property</li><li>Every item has valid <code>url</code> property</li><li>Every item may a <code>count</code> number property</li></ul></li></ul>
          )
          versions :r4
        end

        run_bdt('5.2')
      end
    end
  end
end
