# frozen_string_literal: true

module Inferno
  module Sequence
    class DynamicRegistrationSequence < SequenceBase
      title 'Dynamic Registration'

      description 'Verify that the server supports the OAuth 2.0 Dynamic Client Registration Protocol.'

      details %(
        # Background

        The #{title} Sequence tests the authorization server to dynamically register OAuth 2.0 clients using
        the [OAuth 2.0 Dynamic Client Registration Protocol](https://tools.ietf.org/html/rfc7591).  This
        functionality is *OPTIONAL* but is recommended by the [SMART App Launch Framework](http://hl7.org/fhir/smart-app-launch/).

        # Test Methodology

        This sequence tests tests this functionality by dynamically an app for Inferno to use in later sequences.
        Inferno will make a `POST` request to the Dynamic Registration endpoint provided and validate the response.

        For more information see:

        * [SMART App Launch Framework](http://hl7.org/fhir/smart-app-launch/)
        * [OAuth 2.0 Dynamic Client Registration Protocol](https://tools.ietf.org/html/rfc7591)

      )

      test_id_prefix 'DR'

      optional

      show_uris

      requires :oauth_register_endpoint, :client_name, :initiate_login_uri, :redirect_uris, :scopes, :confidential_client, :initiate_login_uri, :redirect_uris, :dynamic_registration_token
      defines :client_id, :client_secret

      test 'Client registration endpoint secured by transport layer security' do
        metadata do
          id '01'
          link 'https://www.hl7.org/fhir/security.html'
          desc %(
            The client registration endpoint MUST be protected by a transport layer security.
          )
        end

        skip_if_tls_disabled
        skip_if_url_invalid @instance.oauth_register_endpoint, 'OAuth 2.0 Dynamic Registration Endpoint'

        assert_tls_1_2 @instance.oauth_register_endpoint
        warning do
          assert_deny_previous_tls @instance.oauth_register_endpoint
        end
      end

      test 'Client registration endpoint accepts POST messages' do
        metadata do
          id '02'
          link 'https://tools.ietf.org/html/rfc7591'
          desc %(
            The client registration endpoint MUST accept HTTP POST messages with request parameters encoded in the entity body using the "application/json" format.
          )
        end

        skip_if_url_invalid @instance.oauth_register_endpoint, 'OAuth 2.0 Dynamic Registration Endpoint'

        headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
        headers['Authorization'] = "Bearer #{@instance.dynamic_registration_token}" unless @instance.dynamic_registration_token.blank?

        params = {
          'client_name' => @instance.client_name,
          'initiate_login_uri' => @instance.initiate_login_uri,
          'redirect_uris' => [@instance.redirect_uris],
          'grant_types' => ['authorization_code'],
          'scope' => @instance.scopes
        }

        skip_if_url_invalid @instance.oauth_register_endpoint, 'OAuth 2.0 Dynamic Registration Endpoint'

        params['token_endpoint_auth_method'] = if @instance.confidential_client
                                                 'client_secret_basic'
                                               else
                                                 'none'
                                               end

        @registration_response = LoggedRestClient.post(@instance.oauth_register_endpoint, params.to_json, headers)
        @registration_response_body = JSON.parse(@registration_response.body)
      end

      test 'Registration endpoint does not respond with an error' do
        metadata do
          id '03'
          link 'https://tools.ietf.org/html/rfc7591'
          desc %(
            When an OAuth 2.0 error condition occurs, such as the client presenting an invalid initial access token, the authorization server returns an error response appropriate to the OAuth 2.0 token type.
          )
        end

        skip_if_url_invalid @instance.oauth_register_endpoint, 'OAuth 2.0 Dynamic Registration Endpoint'

        assert !@registration_response_body.key?('error') && !@registration_response_body.key?('error_description'),
               "Error returned.  Error: #{@registration_response_body['error']}, Description: #{@registration_response_body['error_description']}"
      end

      test 'Registration endpoint responds with HTTP 201 and body contains JSON with required fields' do
        metadata do
          id '04'
          link 'https://tools.ietf.org/html/rfc7591'
          desc %(
            The server responds with an HTTP 201 Created status code and a body of type "application/json" with content as described in Section 3.2.1.
          )
        end

        skip_if_url_invalid @instance.oauth_register_endpoint, 'OAuth 2.0 Dynamic Registration Endpoint'

        assert @registration_response.code == 201, "Expected HTTP 201 response from registration endpoint but received #{@registration_response.code}"
        assert @registration_response_body.key?('client_id') && @registration_response_body.key?('scope'), 'Registration response did not include client_id and scope fields in JSON body'

        # TODO: check all values, and not just client and scope

        update_params = {
          client_id: @registration_response_body['client_id'],
          dynamically_registered: true,
          scopes: @registration_response_body['scope']
        }

        update_params[:client_secret] = @registration_response_body['client_secret'] if @instance.confidential_client

        @instance.update(update_params)
      end
    end
  end
end
