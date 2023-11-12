# frozen_string_literal: true

require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTAuthSequence < BDTBase
      title 'Authorization'

      description 'Verify that the bulk data export conforms to the SMART Backend Services specification.'

      test_id_prefix 'Auth'

      requires :bulk_url, :bulk_token_endpoint, :bulk_client_id, \
               :bulk_system_export_endpoint, :bulk_patient_export_endpoint, :bulk_group_export_endpoint, \
               :bulk_fastest_resource, :bulk_requires_auth, :bulk_since_param, :bulk_jwks_url_auth, :bulk_jwks_url_auth, \
               :bulk_private_key

      details %(
        Authorization
      )

      test 'Kick-off request at the system-level export endpoint requires authorization header' do
        metadata do
          id '01.0.0'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should require authorization header at the system-level export endpoint
          )
          versions :r4
        end

        run_bdt('0.0.0')
      end
      test 'Kick-off request at the system-level export endpoint rejects invalid token' do
        metadata do
          id '01.0.1'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should reject invalid tokens at the system-level export endpoint
          )
          versions :r4
        end

        run_bdt('0.0.1')
      end
      test 'Kick-off request at the patient-level export endpoint requires authorization header' do
        metadata do
          id '01.1.0'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should require authorization header at the patient-level export endpoint
          )
          versions :r4
        end

        run_bdt('0.1.0')
      end
      test 'Kick-off request at the patient-level export endpoint rejects invalid token' do
        metadata do
          id '01.1.1'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should reject invalid tokens at the patient-level export endpoint
          )
          versions :r4
        end

        run_bdt('0.1.1')
      end
      test 'Kick-off request at the group-level export endpoint requires authorization header' do
        metadata do
          id '01.2.0'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should require authorization header at the group-level export endpoint
          )
          versions :r4
        end

        run_bdt('0.2.0')
      end
      test 'Kick-off request at the group-level export endpoint rejects invalid token' do
        metadata do
          id '01.2.1'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should reject invalid tokens at the group-level export endpoint
          )
          versions :r4
        end

        run_bdt('0.2.1')
      end
      test 'Token endpoint requires "application/x-www-form-urlencoded" POSTs' do
        metadata do
          id '02'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            After generating an authentication JWT, the client requests a new access token via HTTP POST to the FHIR authorization server's token endpoint URL, using content-type `application/x-www-form-urlencoded`.
          )
          versions :r4
        end

        run_bdt('0.3.0')
      end
      test 'Token endpoint the "grant_type" parameter must be present' do
        metadata do
          id '03'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should reply with 400 Bad Request if the `grant_type parameter` is not sent by the client.
          )
          versions :r4
        end

        run_bdt('0.3.1')
      end
      test 'Token endpoint the "grant_type" must equal "client_credentials"' do
        metadata do
          id '04'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should reply with 400 Bad Request if the `grant_type parameter` is not `client_credentials`.
          )
          versions :r4
        end

        run_bdt('0.3.2')
      end
      test 'Token endpoint the "client_assertion_type" must be present' do
        metadata do
          id '05'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should reply with 400 Bad Request if the `client_assertion_type` parameter is not sent by the client.
          )
          versions :r4
        end

        run_bdt('0.3.3')
      end
      test 'Token endpoint the "client_assertion_type" must be jwt-bearer' do
        metadata do
          id '06'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should reply with 400 Bad Request if the `client_assertion_type` parameter is not equal to `urn:ietf:params:oauth:client-assertion-type:jwt-bearer`.
          )
          versions :r4
        end

        run_bdt('0.3.4')
      end
      test 'Token endpoint the client_assertion parameter must be a token' do
        metadata do
          id '07'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This test verifies that if the client sends something other then a JWT, the server will detect it and reject the request.
          )
          versions :r4
        end

        run_bdt('0.3.5')
      end
      test 'Token endpoint validates authenticationToken.aud' do
        metadata do
          id '08'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The `aud` claim of the authentication JWT must be the authorization server's "token URL" (the same URL to which this authentication JWT will be posted).
          )
          versions :r4
        end

        run_bdt('0.3.6')
      end
      test 'Token endpoint validates authenticationToken.iss' do
        metadata do
          id '09'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The `iss` claim of the authentication JWT must equal the registered `client_id`
          )
          versions :r4
        end

        run_bdt('0.3.7')
      end
      test 'Token endpoint only accept registered client IDs' do
        metadata do
          id '10'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verify that clients can't use random client id
          )
          versions :r4
        end

        run_bdt('0.3.8')
      end
      test 'Token endpoint requires scope' do
        metadata do
          id '11'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should reject requests to the token endpoint that do not specify a scope
          )
          versions :r4
        end

        run_bdt('0.3.9')
      end
      test 'Token endpoint rejects empty scope' do
        metadata do
          id '12'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            The server should reject requests to the token endpoint that are requesting an empty scope
          )
          versions :r4
        end

        run_bdt('0.3.10')
      end
      test 'Token endpoint validates scopes' do
        metadata do
          id '13'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This test verifies that only valid system scopes are accepted by the server
          )
          versions :r4
        end

        run_bdt('0.3.11')
      end
      test 'Token endpoint supports wildcard action scopes' do
        metadata do
          id '14'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that scopes like `system/Patient.*` are supported
          )
          versions :r4
        end

        run_bdt('0.3.12')
      end
      test 'Token endpoint rejects unknown action scopes' do
        metadata do
          id '15'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that scopes like `system/Patient.unknownAction` are rejected
          )
          versions :r4
        end

        run_bdt('0.3.13')
      end
      test 'Token endpoint supports wildcard resource scopes' do
        metadata do
          id '16'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that scopes like `system/*.read` are supported
          )
          versions :r4
        end

        run_bdt('0.3.14')
      end
      test 'Token endpoint rejects unknown resource scopes' do
        metadata do
          id '17'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verifies that scopes like `system/UnknownResource.read` are rejected
          )
          versions :r4
        end

        run_bdt('0.3.15')
      end
      test 'Token endpoint validates the jku token header' do
        metadata do
          id '18'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            When present, the `jku` authentication JWT header should match a value that the client supplied to the FHIR server at client registration time. This test attempts to authorize using `test-bad-jku` as `jku` header value and expects that to produce an error.
          )
          versions :r4
        end

        run_bdt('0.3.16')
      end
      test 'Token endpoint validates the token signature' do
        metadata do
          id '19'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            This test attempts to obtain an access token with a request that is completely valid, except that the authentication token is signed with unknown private key.
          )
          versions :r4
        end

        run_bdt('0.3.17')
      end
      test 'Token endpoint authorization using JWKS URL and ES384 keys' do
        metadata do
          id '20'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verify that the server supports JWKS URL authorization using ES384 keys. This would also prove that JWK keys rotation works because this test will create new key, every time it is executed.
          )
          versions :r4
        end

        run_bdt('0.3.18')
      end
      test 'Token endpoint authorization using JWKS URL and RS384 keys' do
        metadata do
          id '21'
          link 'http://hl7.org/fhir/uv/bulkdata/'
          description %(
            Verify that the server supports JWKS URL authorization using RS384 keys. This would also prove that JWK keys rotation works because this test will create new key, every time it is executed.
          )
          versions :r4
        end

        run_bdt('0.3.19')
      end
    end
  end
end
