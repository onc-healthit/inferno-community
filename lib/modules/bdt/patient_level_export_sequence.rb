# frozen_string_literal: true

require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTPatientSequence < BDTBase
      title 'Patient-level export'

      description 'Verify the system is capable of performing a Patient-Level Export that conforms to the SMART Bulk Data IG.'

      test_id_prefix 'Patient'

      requires :bulk_url, :bulk_token_endpoint, :bulk_client_id, \
               :bulk_system_export_endpoint, :bulk_patient_export_endpoint, :bulk_group_export_endpoint, \
               :bulk_fastest_resource, :bulk_requires_auth, :bulk_since_param, :bulk_jwks_url_auth, :bulk_jwks_url_auth, \
               :bulk_public_key, :bulk_private_key

      details %(
        Patient-level export
      )

      test 'Requires Accept header' do
        metadata do
          id '01'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The Accept header specifies the format of the optional OperationOutcome response to the kick-off request. Currently, only `application/fhir+json` is supported.
          )
          versions :r4
        end

        run_bdt('2.0')
      end
      test 'Requires Prefer header to equal respond-async' do
        metadata do
          id '02'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The **Prefer** request header is required and specifies whether the response is immediate or asynchronous. The header MUST be set to **respond-async**. [Red More](https://github.com/smart-on-fhir/fhir-bulk-data-docs/blob/master/export.md#headers).
          )
          versions :r4
        end

        run_bdt('2.1')
      end
      test 'Accepts _outputFormat=application/fhir+ndjson' do
        metadata do
          id '03.0'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that the server accepts `application/fhir+ndjson` as **_outputFormat** parameter
          )
          versions :r4
        end

        run_bdt('2.2')
      end
      test 'Accepts _outputFormat=application/ndjson' do
        metadata do
          id '03.1'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that the server accepts `application/ndjson` as **_outputFormat** parameter
          )
          versions :r4
        end

        run_bdt('2.3')
      end
      test 'Accepts _outputFormat=ndjson' do
        metadata do
          id '03.2'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that the server accepts `ndjson` as **_outputFormat** parameter
          )
          versions :r4
        end

        run_bdt('2.4')
      end
      test 'Rejects unsupported format "_outputFormat=application/xml"' do
        metadata do
          id '04.0'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This tests if the server rejects `_outputFormat=application/xml` parameter, even though `application/xml` is valid mime type.
          )
          versions :r4
        end

        run_bdt('2.5')
      end
      test 'Rejects unsupported format "_outputFormat=text/html"' do
        metadata do
          id '04.1'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This tests if the server rejects `_outputFormat=text/html` parameter, even though `text/html` is valid mime type.
          )
          versions :r4
        end

        run_bdt('2.6')
      end
      test 'Rejects unsupported format "_outputFormat=x-custom"' do
        metadata do
          id '04.2'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This tests if the server rejects `_outputFormat=x-custom` parameter, even though `x-custom` is valid mime type.
          )
          versions :r4
        end

        run_bdt('2.7')
      end
      test 'Rejects _since={invalid date} parameter' do
        metadata do
          id '05'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should reject exports if the `_since` parameter is not a valid date
          )
          versions :r4
        end

        run_bdt('2.8')
      end
      test 'Rejects _since={future date} parameter' do
        metadata do
          id '06'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should reject exports if the `_since` parameter is a date in the future
          )
          versions :r4
        end

        run_bdt('2.9')
      end
      test 'Validates the _type parameter' do
        metadata do
          id '07'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that the request is rejected if the `_type` contains invalid resource type
          )
          versions :r4
        end

        run_bdt('2.10')
      end
      test 'Accepts the _typeFilter parameter' do
        metadata do
          id '08'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The `_typeFilter` parameter is optional so the servers should not reject it, even if they don't support it
          )
          versions :r4
        end

        run_bdt('2.11')
      end
      test 'Response - Success' do
        metadata do
          id '09'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that the server starts an export if called with valid parameters. The status code must be `202 Accepted` and a `Content-Location` header must be returned. The response body should be either empty, or a JSON OperationOutcome.
          )
          versions :r4
        end

        run_bdt('2.12')
      end
    end
  end
end
