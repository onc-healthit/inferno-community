# frozen_string_literal: true

require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTAuthTokenEndpointSequence < BDTBase
      title 'Auth Token Endpoint'

      description 'Token endpoint'

      test_id_prefix 'Auth_Token_endpoint'

      requires :bulk_url, :bulk_token_endpoint, :bulk_client_id, \
               :bulk_system_export_endpoint, :bulk_patient_export_endpoint, :bulk_group_export_endpoint, \
               :bulk_fastest_resource, :bulk_requires_auth, :bulk_since_param, :bulk_jwks_url_auth, :bulk_jwks_url_auth, \
               :bulk_public_key, :bulk_private_key

      details %(
        Auth Token Endpoint
      )

      test 'Requires "application/x-www-form-urlencoded" POSTs' do
        metadata do
          id '02'
          link 'http://bulkdatainfo'
          description %(
            After generating an authentication JWT, the client requests a new access token via HTTP POST to the FHIR authorization server's token endpoint URL, using content-type <code>application/x-www-form-urlencoded</code>.
          )
          versions :r4
        end

        run_bdt('0.3.0')
      end
      test 'The "grant_type" parameter must be present' do
        metadata do
          id '03'
          link 'http://bulkdatainfo'
          description %(
            The server should reply with 400 Bad Request if the grant_type parameter is not sent by the client.
          )
          versions :r4
        end

        run_bdt('0.3.1')
      end
      test 'The "grant_type" must equal "client_credentials"' do
        metadata do
          id '04'
          link 'http://bulkdatainfo'
          description %(
            The server should reply with 400 Bad Request if the grant_type parameter is not <code>client_credentials</code>.
          )
          versions :r4
        end

        run_bdt('0.3.2')
      end
      test 'The "client_assertion_type" must be present' do
        metadata do
          id '05'
          link 'http://bulkdatainfo'
          description %(
            The server should reply with 400 Bad Request if the client_assertion_type parameter is not sent by the client.
          )
          versions :r4
        end

        run_bdt('0.3.3')
      end
      test 'The "client_assertion_type" must be jwt-bearer' do
        metadata do
          id '06'
          link 'http://bulkdatainfo'
          description %(
            The server should reply with 400 Bad Request if the client_assertion_type parameter is not equal to <code>urn:ietf:params:oauth:client-assertion-type:jwt-bearer</code>
          )
          versions :r4
        end

        run_bdt('0.3.4')
      end
      test 'The client_assertion parameter must be a token' do
        metadata do
          id '07'
          link 'http://bulkdatainfo'
          description %(
            This test verifies that if the client sends something other then a JWT, the server will detect it and reject the request.
          )
          versions :r4
        end

        run_bdt('0.3.5')
      end
      test 'Validates authenticationToken.aud' do
        metadata do
          id '08'
          link 'http://bulkdatainfo'
          description %(
            The <code>aud</code> claim of the authentication JWT must be the authorization server's "token URL" (the same URL to which this authentication JWT will be posted)
          )
          versions :r4
        end

        run_bdt('0.3.6')
      end
      test 'Validates authenticationToken.iss' do
        metadata do
          id '09'
          link 'http://bulkdatainfo'
          description %(
            The <code>iss</code> claim of the authentication JWT must equal the registered <code>client_id</code>
          )
          versions :r4
        end

        run_bdt('0.3.7')
      end
      test 'Only accept registered client IDs' do
        metadata do
          id '10'
          link 'http://bulkdatainfo'
          description %(
            Verify that clients can't use random client id
          )
          versions :r4
        end

        run_bdt('0.3.8')
      end
      test 'Requires scope' do
        metadata do
          id '11'
          link 'http://bulkdatainfo'
          description %(
            The server should reject requests to the token endpoint that do not specify a scope
          )
          versions :r4
        end

        run_bdt('0.3.9')
      end
      test 'Rejects empty scope' do
        metadata do
          id '12'
          link 'http://bulkdatainfo'
          description %(
            The server should reject requests to the token endpoint that are requesting an empty scope
          )
          versions :r4
        end

        run_bdt('0.3.10')
      end
      test 'Validates scopes' do
        metadata do
          id '13'
          link 'http://bulkdatainfo'
          description %(
            This test verifies that only valid system scopes are accepted by the server
          )
          versions :r4
        end

        run_bdt('0.3.11')
      end
      test 'Supports wildcard action scopes' do
        metadata do
          id '14'
          link 'http://bulkdatainfo'
          description %(
            Verifies that scopes like <code>system/Patient.*</code> are supported
          )
          versions :r4
        end

        run_bdt('0.3.12')
      end
      test 'Rejects unknown action scopes' do
        metadata do
          id '15'
          link 'http://bulkdatainfo'
          description %(
            Verifies that scopes like <code>system/Patient.unknownAction</code> are rejected
          )
          versions :r4
        end

        run_bdt('0.3.13')
      end
      test 'Supports wildcard resource scopes' do
        metadata do
          id '16'
          link 'http://bulkdatainfo'
          description %(
            Verifies that scopes like <code>system/*.read</code> are supported
          )
          versions :r4
        end

        run_bdt('0.3.14')
      end
      test 'Rejects unknown resource scopes' do
        metadata do
          id '17'
          link 'http://bulkdatainfo'
          description %(
            Verifies that scopes like <code>system/UnknownResource.read</code> are rejected
          )
          versions :r4
        end

        run_bdt('0.3.15')
      end
      test 'validates the jku token header' do
        metadata do
          id '18'
          link 'http://bulkdatainfo'
          description %(
            When present, the <code>jky</code> authentication JWT header should match a value that the client supplied to the FHIR server at client registration time. This test attempts to authorize using <code>test-bad-jku</code> as <code>jky</code> header value and expects that to produce an error.
          )
          versions :r4
        end

        run_bdt('0.3.16')
      end
      test 'Validates the token signature' do
        metadata do
          id '19'
          link 'http://bulkdatainfo'
          description %(
            This test attempts to obtain an access token with a request that is completely valid, except that the authentication token is signed with unknown private key.
          )
          versions :r4
        end

        run_bdt('0.3.17')
      end
      test 'Authorization using JWKS URL and ES384 keys' do
        metadata do
          id '20'
          link 'http://bulkdatainfo'
          description %(
            Verify that the server supports JWKS URL authorization using ES384 keys. This would also prove that JWK keys rotation works because this test will create new key, every time it is executed.
          )
          versions :r4
        end

        run_bdt('0.3.18')
      end
      test 'Authorization using JWKS URL and RS384 keys' do
        metadata do
          id '21'
          link 'http://bulkdatainfo'
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
