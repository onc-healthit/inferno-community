# frozen_string_literal: true

require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTDownloadSequence < BDTBase
      title 'Download Endpoint'

      description 'Verify the Download Endpoint conforms to the SMART Bulk Data IG for Export.'

      test_id_prefix 'Download'

      requires :bulk_url, :bulk_token_endpoint, :bulk_client_id, \
               :bulk_system_export_endpoint, :bulk_patient_export_endpoint, :bulk_group_export_endpoint, \
               :bulk_fastest_resource, :bulk_requires_auth, :bulk_since_param, :bulk_jwks_url_auth, :bulk_jwks_url_auth, \
               :bulk_private_key

      details %(
        Download Endpoint
      )

      test 'Requires valid access token if the requiresAccessToken field in the status body is true' do
        metadata do
          id '01'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            If the `requiresAccessToken` field in the Complete Status body is set to true, the request MUST include a valid access token.
          )
          versions :r4
        end

        run_bdt('1.0')
      end
      test 'Does not require access token if the requiresAccessToken field in the status body is not true' do
        metadata do
          id '02'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that files can be downloaded without authorization if the `requiresAccessToken` field in the complete status body is not set to true
          )
          versions :r4
        end

        run_bdt('1.1')
      end
      test 'Generates valid file response' do
        metadata do
          id '04'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Runs a set of assertions to verify that:
- The server returns HTTP status of **200 OK**.
- The server returns a `Content-Type` header that matches the file format being delivered. For files in ndjson format, MUST be `application/fhir+ndjson`.
- The response body is valid FHIR **ndjson** (unless other format is requested).
- An `Accept` header might be sent (optional, defaults to `application/fhir+ndjson`).
          )
          versions :r4
        end

        run_bdt('1.2')
      end
      test 'Rejects a download if the client scopes do not cover that resource type' do
        metadata do
          id '05'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            If the download endpoint requires authorization, it should also verify that the client has been granted access to the resource type that it attempts to download. This test makes an export and then it re-authorizes before downloading the first file, so that the download request is made with a token that does not provide access to the downloaded resource.
          )
          versions :r4
        end

        run_bdt('1.3')
      end
      test 'Supports binary file attachments in DocumentReference resources' do
        metadata do
          id '06'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This test verifies that:
1. The server can export `DocumentReference` resources (if available)
2. If `DocumentReference` attachments contain a `data` property it should be `base64Binary`
3. If `DocumentReference` attachments contain an `url` property it should be an absolute url
4. The attachment url should be downloadable
5. If `requiresAccessToken` is set to true in the status response, then the attachment url should NOT be downloadable without an access token.

See: [https://github.com/HL7/bulk-data/blob/master/spec/export/index.md#attachments](https://github.com/HL7/bulk-data/blob/master/spec/export/index.md#attachments)
          )
          versions :r4
        end

        run_bdt('1.4')
      end
      test 'Requesting deleted files returns 404 responses' do
        metadata do
          id '07'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            If the export has been completed, a server MAY send a DELETE request to the status endpoint as a signal that a client is done retrieving files and that it is safe for the sever to remove those from storage. Following the delete request, when subsequent requests are made to the download location, the server SHALL return a 404 error and an associated FHIR OperationOutcome in JSON format.
          )
          versions :r4
        end

        run_bdt('1.5')
      end
    end
  end
end
