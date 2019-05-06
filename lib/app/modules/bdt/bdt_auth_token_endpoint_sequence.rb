
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
        metadata {
          id '02'
          link 'http://bulkdatainfo'
          desc %(
            After generating an authentication JWT, the client requests a new access token via HTTP POST to the FHIR authorization server's token endpoint URL, using content-type <code>application/x-www-form-urlencoded</code>.
          )
          versions :r4
        }

        run_bdt('0.3.0')

      end
      test 'The "grant_type" parameter must be present' do
        metadata {
          id '03'
          link 'http://bulkdatainfo'
          desc %(
            The server should reply with 400 Bad Request if the grant_type parameter is not sent by the client.
          )
          versions :r4
        }

        run_bdt('0.3.1')

      end
      test 'The "grant_type" must equal "client_credentials"' do
        metadata {
          id '04'
          link 'http://bulkdatainfo'
          desc %(
            The server should reply with 400 Bad Request if the grant_type parameter is not <code>client_credentials</code>.
          )
          versions :r4
        }

        run_bdt('0.3.2')

      end
      test 'The "client_assertion_type" must be present' do
        metadata {
          id '05'
          link 'http://bulkdatainfo'
          desc %(
            The server should reply with 400 Bad Request if the client_assertion_type parameter is not sent by the client.
          )
          versions :r4
        }

        run_bdt('0.3.3')

      end
      test 'The "client_assertion_type" must be jwt-bearer' do
        metadata {
          id '06'
          link 'http://bulkdatainfo'
          desc %(
            The server should reply with 400 Bad Request if the client_assertion_type parameter is not equal to <code>urn:ietf:params:oauth:client-assertion-type:jwt-bearer</code>
          )
          versions :r4
        }

        run_bdt('0.3.4')

      end
      test 'The client_assertion parameter must be a token' do
        metadata {
          id '07'
          link 'http://bulkdatainfo'
          desc %(
            This test verifies that if the client sends something other then a JWT, the server will detect it and reject the request.
          )
          versions :r4
        }

        run_bdt('0.3.5')

      end
      test 'Validates authenticationToken.aud' do
        metadata {
          id '08'
          link 'http://bulkdatainfo'
          desc %(
            The <code>aud</code> claim of the authentication JWT must be the authorization server's "token URL" (the same URL to which this authentication JWT will be posted)
          )
          versions :r4
        }

        run_bdt('0.3.6')

      end
      test 'Validates authenticationToken.iss' do
        metadata {
          id '09'
          link 'http://bulkdatainfo'
          desc %(
            The <code>iss</code> claim of the authentication JWT must equal the registered <code>client_id</code>
          )
          versions :r4
        }

        run_bdt('0.3.7')

      end
      test 'Only accept registered client IDs' do
        metadata {
          id '10'
          link 'http://bulkdatainfo'
          desc %(
            Verify that clients can't use random client id
          )
          versions :r4
        }

        run_bdt('0.3.8')

      end
      test 'Requires scope' do
        metadata {
          id '11'
          link 'http://bulkdatainfo'
          desc %(
            
          )
          versions :r4
        }

        run_bdt('0.3.9')

      end
      test 'Rejects empty scope' do
        metadata {
          id '12'
          link 'http://bulkdatainfo'
          desc %(
            
          )
          versions :r4
        }

        run_bdt('0.3.10')

      end
      test 'Validates scopes' do
        metadata {
          id '13'
          link 'http://bulkdatainfo'
          desc %(
            This test verifies that only valid system scopes are accepted by the server
          )
          versions :r4
        }

        run_bdt('0.3.11')

      end
      test 'Supports wildcard action scopes' do
        metadata {
          id '14'
          link 'http://bulkdatainfo'
          desc %(
            Verifies that scopes like <code>system/Patient.*</code> are supported
          )
          versions :r4
        }

        run_bdt('0.3.12')

      end
      test 'Rejects unknown action scopes' do
        metadata {
          id '15'
          link 'http://bulkdatainfo'
          desc %(
            Verifies that scopes like <code>system/Patient.unknownAction</code> are rejected
          )
          versions :r4
        }

        run_bdt('0.3.13')

      end
      test 'Supports wildcard resource scopes' do
        metadata {
          id '16'
          link 'http://bulkdatainfo'
          desc %(
            Verifies that scopes like <code>system/*.read</code> are supported
          )
          versions :r4
        }

        run_bdt('0.3.14')

      end
      test 'Rejects unknown resource scopes' do
        metadata {
          id '17'
          link 'http://bulkdatainfo'
          desc %(
            Verifies that scopes like <code>system/UnknownResource.read</code> are rejected
          )
          versions :r4
        }

        run_bdt('0.3.15')

      end
      test 'validates the jku token header' do
        metadata {
          id '18'
          link 'http://bulkdatainfo'
          desc %(
            
          )
          versions :r4
        }

        run_bdt('0.3.16')

      end
      test 'Validates the token signature' do
        metadata {
          id '19'
          link 'http://bulkdatainfo'
          desc %(
            This test attempts to obtain an access token with a request that is completely valid, except that the authentication token is signed with unknown private key.
          )
          versions :r4
        }

        run_bdt('0.3.17')

      end
      test 'Authorization using JWKS URL' do
        metadata {
          id '20'
          link 'http://bulkdatainfo'
          desc %(
            
          )
          versions :r4
        }

        run_bdt('0.3.18')

      end

    end
  end
end