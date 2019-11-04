# frozen_string_literal: true

require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTAuthTokenEndpointSequence < BDTBase
      group 'FIXME'

      title 'Auth Token Endpoint'

      description 'Token endpoint'

      test_id_prefix 'Auth_Token_endpoint'

      requires :token
      conformance_supports :CarePlan

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
      test 'Authorization using JWKS URL' do
        metadata do
          id '20'
          link 'http://bulkdatainfo'
          description %(

          )
          versions :r4
        end

        run_bdt('0.3.18')
      end
    end
  end
end
