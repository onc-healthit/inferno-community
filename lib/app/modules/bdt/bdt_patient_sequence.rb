
require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTPatientSequence < BDTBase

      group 'FIXME'

      title 'Patient'

      description 'Patient-level export'

      test_id_prefix 'Patient'

      requires :token
      conformance_supports :CarePlan

      details %(
        Patient
      )
      
      test 'Requires Accept header' do
        metadata {
          id '01'
          link 'http://bulkdatainfo'
          desc %(
            The Accept header specifies the format of the optional OperationOutcome response to the kick-off request. Currently, only <code>application/fhir+json</code> is supported.
          )
          versions :r4
        }

        run_bdt('2.0')

      end
      test 'Requires Prefer header to equal respond-async' do
        metadata {
          id '02'
          link 'http://bulkdatainfo'
          desc %(
            The <b>Prefer</b> request header is required and specifies whether the response is immediate or asynchronous. The header MUST be set to <b>respond-async</b>. <a href="https://github.com/smart-on-fhir/fhir-bulk-data-docs/blob/master/export.md#headers" target="_blank">Red More</a>
          )
          versions :r4
        }

        run_bdt('2.1')

      end
      test 'Accepts _outputFormat=application/fhir+ndjson' do
        metadata {
          id '03.0'
          link 'http://bulkdatainfo'
          desc %(
            Verifies that the server accepts <code>application/fhir+ndjson</code> as <b>_outputFormat</b> parameter
          )
          versions :r4
        }

        run_bdt('2.2')

      end
      test 'Accepts _outputFormat=application/ndjson' do
        metadata {
          id '03.1'
          link 'http://bulkdatainfo'
          desc %(
            Verifies that the server accepts <code>application/ndjson</code> as <b>_outputFormat</b> parameter
          )
          versions :r4
        }

        run_bdt('2.3')

      end
      test 'Accepts _outputFormat=ndjson' do
        metadata {
          id '03.2'
          link 'http://bulkdatainfo'
          desc %(
            Verifies that the server accepts <code>ndjson</code> as <b>_outputFormat</b> parameter
          )
          versions :r4
        }

        run_bdt('2.4')

      end
      test 'Rejects unsupported format "_outputFormat=application/xml"' do
        metadata {
          id '04.0'
          link 'http://bulkdatainfo'
          desc %(
            This tests if the server rejects <code>_outputFormat=application/xml</code> parameter, even though <code>application/xml</code> is valid mime type.
          )
          versions :r4
        }

        run_bdt('2.5')

      end
      test 'Rejects unsupported format "_outputFormat=text/html"' do
        metadata {
          id '04.1'
          link 'http://bulkdatainfo'
          desc %(
            This tests if the server rejects <code>_outputFormat=text/html</code> parameter, even though <code>text/html</code> is valid mime type.
          )
          versions :r4
        }

        run_bdt('2.6')

      end
      test 'Rejects unsupported format "_outputFormat=x-custom"' do
        metadata {
          id '04.2'
          link 'http://bulkdatainfo'
          desc %(
            This tests if the server rejects <code>_outputFormat=x-custom</code> parameter, even though <code>x-custom</code> is valid mime type.
          )
          versions :r4
        }

        run_bdt('2.7')

      end
      test 'Rejects _since={invalid date} parameter' do
        metadata {
          id '05'
          link 'http://bulkdatainfo'
          desc %(
            The server should reject exports if the <code>_since</code> parameter is not a valid date
          )
          versions :r4
        }

        run_bdt('2.8')

      end
      test 'Rejects _since={future date} parameter' do
        metadata {
          id '06'
          link 'http://bulkdatainfo'
          desc %(
            The server should reject exports if the <code>_since</code> parameter is a date in the future
          )
          versions :r4
        }

        run_bdt('2.9')

      end
      test 'Validates the _type parameter' do
        metadata {
          id '07'
          link 'http://bulkdatainfo'
          desc %(
            Verifies that the request is rejected if the <code>_type</code> contains invalid resource type
          )
          versions :r4
        }

        run_bdt('2.10')

      end
      test 'Accepts the _typeFilter parameter' do
        metadata {
          id '08'
          link 'http://bulkdatainfo'
          desc %(
            The <code>_typeFilter</code> parameter is optional so the servers should not reject it, even if they don't support it
          )
          versions :r4
        }

        run_bdt('2.11')

      end
      test 'Response - Success' do
        metadata {
          id '09'
          link 'http://bulkdatainfo'
          desc %(
            Verifies that the server starts an export if called with valid parameters. The status code must be <code>202 Accepted</code> and a <code>Content-Location</code> header must be returned. The response body should be either empty, or a JSON OperationOutcome.
          )
          versions :r4
        }

        run_bdt('2.12')

      end

    end
  end
end