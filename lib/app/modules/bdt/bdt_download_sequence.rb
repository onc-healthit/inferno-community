
require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTDownloadSequence < BDTBase

      group 'FIXME'

      title 'Download'

      description 'Download Endpoint'

      test_id_prefix 'Download'

      requires :token
      conformance_supports :CarePlan

      details %(
        Download
      )
      
      test 'Requires valid access token if the requiresAccessToken field in the status body is true' do
        metadata {
          id '01'
          link 'http://bulkdatainfo'
          desc %(
            If the <code>requiresAccessToken</code> field in the Complete Status body is set to true, the request MUST include a valid access token.
          )
          versions :r4
        }

        run_bdt('1.0')

      end
      test 'Does not require access token if the requiresAccessToken field in the status body is not true' do
        metadata {
          id '02'
          link 'http://bulkdatainfo'
          desc %(
            Verifies that files can be downloaded without authorization if the <code>requiresAccessToken</code> field in the complete status body is not set to true
          )
          versions :r4
        }

        run_bdt('1.1')

      end
      test 'Replies properly in case of error' do
        metadata {
          id '03'
          link 'http://bulkdatainfo'
          desc %(
            The server should return HTTP Status Code of 4XX or 5XX
          )
          versions :r4
        }

        run_bdt('1.2')

      end
      test 'Generates valid file response' do
        metadata {
          id '04'
          link 'http://bulkdatainfo'
          desc %(
            Runs a set of assertions to verify that:<ul><li>The server returns HTTP status of <b>200 OK</b></li><li>The server returns a <code>Content-Type</code> header that matches the file format being delivered. For files in ndjson format, MUST be <code>application/fhir+ndjson</code></li><li>The response body is valid FHIR <b>ndjson</b> (unless other format is requested)</li><li>An <code>Accept</code> header might be sent (optional, defaults to <code>application/fhir+ndjson</code>)</li></ul>
          )
          versions :r4
        }

        run_bdt('1.3')

      end

    end
  end
end