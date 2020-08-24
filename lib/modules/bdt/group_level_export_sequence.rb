# frozen_string_literal: true

require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTGroupSequence < BDTBase
      title 'Group-level export'

      description 'Verify the system is capable of performing a Group-Level Export that conforms to the SMART Bulk Data IG.'

      test_id_prefix 'Group'

      requires :bulk_url, :bulk_token_endpoint, :bulk_client_id, \
               :bulk_system_export_endpoint, :bulk_patient_export_endpoint, :bulk_group_export_endpoint, \
               :bulk_fastest_resource, :bulk_requires_auth, :bulk_since_param, :bulk_jwks_url_auth, :bulk_jwks_url_auth, \
               :bulk_private_key

      details %(
        Group-level export
      )

      test 'Requires Accept header in GET requests' do
        metadata do
          id '0'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The Accept header specifies the format of the optional OperationOutcome response to the kick-off request. Currently, only `application/fhir+json` is supported.
          )
          versions :r4
        end

        run_bdt('4.0')
      end
      test 'Requires Accept header in POST requests' do
        metadata do
          id '1'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The Accept header specifies the format of the optional OperationOutcome response to the kick-off request. Currently, only `application/fhir+json` is supported.
          )
          versions :r4
        end

        run_bdt('4.1')
      end
      test 'Requires Prefer header to equal respond-async in GET requests' do
        metadata do
          id '2'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The **Prefer** request header is required and specifies whether the response is immediate or asynchronous. The header MUST be set to **respond-async**. [Red More](https://github.com/smart-on-fhir/fhir-bulk-data-docs/blob/master/export.md#headers).
          )
          versions :r4
        end

        run_bdt('4.2')
      end
      test 'Requires Prefer header to equal respond-async in POST requests' do
        metadata do
          id '3'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The **Prefer** request header is required and specifies whether the response is immediate or asynchronous. The header MUST be set to **respond-async**. [Red More](https://github.com/smart-on-fhir/fhir-bulk-data-docs/blob/master/export.md#headers).
          )
          versions :r4
        end

        run_bdt('4.3')
      end
      test 'Accepts _outputFormat=application/fhir+ndjson in GET requests' do
        metadata do
          id '4.0'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that the server accepts `application/fhir+ndjson` as **_outputFormat** parameter
          )
          versions :r4
        end

        run_bdt('4.4')
      end
      test 'Accepts _outputFormat=application/fhir+ndjson in POST requests' do
        metadata do
          id '5.0'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that the server accepts `application/fhir+ndjson` as **_outputFormat** parameter
          )
          versions :r4
        end

        run_bdt('4.5')
      end
      test 'Accepts _outputFormat=application/ndjson in GET requests' do
        metadata do
          id '6.1'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that the server accepts `application/ndjson` as **_outputFormat** parameter
          )
          versions :r4
        end

        run_bdt('4.6')
      end
      test 'Accepts _outputFormat=application/ndjson in POST requests' do
        metadata do
          id '7.1'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that the server accepts `application/ndjson` as **_outputFormat** parameter
          )
          versions :r4
        end

        run_bdt('4.7')
      end
      test 'Accepts _outputFormat=ndjson in GET requests' do
        metadata do
          id '8.2'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that the server accepts `ndjson` as **_outputFormat** parameter
          )
          versions :r4
        end

        run_bdt('4.8')
      end
      test 'Accepts _outputFormat=ndjson in POST requests' do
        metadata do
          id '9.2'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that the server accepts `ndjson` as **_outputFormat** parameter
          )
          versions :r4
        end

        run_bdt('4.9')
      end
      test 'Rejects unsupported format "_outputFormat=application/xml" in GET requests' do
        metadata do
          id '04.0'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This tests if the server rejects `_outputFormat=application/xml` parameter, even though `application/xml` is valid mime type.
          )
          versions :r4
        end

        run_bdt('4.10')
      end
      test 'Rejects unsupported format "_outputFormat=application/xml" in POST requests' do
        metadata do
          id '04.0'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This tests if the server rejects `_outputFormat=application/xml` parameter, even though `application/xml` is valid mime type.
          )
          versions :r4
        end

        run_bdt('4.11')
      end
      test 'Rejects unsupported format "_outputFormat=text/html" in GET requests' do
        metadata do
          id '04.1'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This tests if the server rejects `_outputFormat=text/html` parameter, even though `text/html` is valid mime type.
          )
          versions :r4
        end

        run_bdt('4.12')
      end
      test 'Rejects unsupported format "_outputFormat=text/html" in POST requests' do
        metadata do
          id '04.1'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This tests if the server rejects `_outputFormat=text/html` parameter, even though `text/html` is valid mime type.
          )
          versions :r4
        end

        run_bdt('4.13')
      end
      test 'Rejects unsupported format "_outputFormat=x-custom" in GET requests' do
        metadata do
          id '04.2'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This tests if the server rejects `_outputFormat=x-custom` parameter, even though `x-custom` is valid mime type.
          )
          versions :r4
        end

        run_bdt('4.14')
      end
      test 'Rejects unsupported format "_outputFormat=x-custom" in POST requests' do
        metadata do
          id '04.2'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This tests if the server rejects `_outputFormat=x-custom` parameter, even though `x-custom` is valid mime type.
          )
          versions :r4
        end

        run_bdt('4.15')
      end
      test 'Rejects _since={invalid date} parameter in GET requests' do
        metadata do
          id '10'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should reject exports if the `_since` parameter is not a valid date
          )
          versions :r4
        end

        run_bdt('4.16')
      end
      test 'Rejects _since={invalid date} parameter in POST requests' do
        metadata do
          id '11'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should reject exports if the `_since` parameter is not a valid date
          )
          versions :r4
        end

        run_bdt('4.17')
      end
      test 'Rejects _since={future date} parameter in GET requests' do
        metadata do
          id '12'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should reject exports if the `_since` parameter is a date in the future
          )
          versions :r4
        end

        run_bdt('4.18')
      end
      test 'Rejects _since={future date} parameter in POST requests' do
        metadata do
          id '13'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should reject exports if the `_since` parameter is a date in the future
          )
          versions :r4
        end

        run_bdt('4.19')
      end
      test 'Validates the _type parameter in GET requests' do
        metadata do
          id '14'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that the request is rejected if the `_type` contains invalid resource type
          )
          versions :r4
        end

        run_bdt('4.20')
      end
      test 'Validates the _type parameter in POST requests' do
        metadata do
          id '15'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that the request is rejected if the `_type` contains invalid resource type
          )
          versions :r4
        end

        run_bdt('4.21')
      end
      test 'Accepts the _typeFilter parameter in GET requests' do
        metadata do
          id '16'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The `_typeFilter` parameter is optional so the servers should not reject it, even if they don't support it
          )
          versions :r4
        end

        run_bdt('4.22')
      end
      test 'Accepts the _typeFilter parameter in POST requests' do
        metadata do
          id '17'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The `_typeFilter` parameter is optional so the servers should not reject it, even if they don't support it
          )
          versions :r4
        end

        run_bdt('4.23')
      end
      test 'Can start an export from GET requests' do
        metadata do
          id '18'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that the server starts an export if called with valid parameters. The status code must be `202 Accepted` and a `Content-Location` header must be returned. The response body should be either empty, or a JSON OperationOutcome.
          )
          versions :r4
        end

        run_bdt('4.24')
      end
      test 'Can start an export from POST requests' do
        metadata do
          id '19'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that the server starts an export if called with valid parameters. The status code must be `202 Accepted` and a `Content-Location` header must be returned. The response body should be either empty, or a JSON OperationOutcome.
          )
          versions :r4
        end

        run_bdt('4.25')
      end
    end
  end
end
