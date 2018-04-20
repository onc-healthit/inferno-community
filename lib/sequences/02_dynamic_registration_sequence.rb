class DynamicRegistrationSequence < SequenceBase

  title 'Dynamic Registration'

  description 'Verify that the server supports the OAuth 2.0 Dynamic Client Registration Protocol.'

  optional

  modal_before_run

  preconditions 'OAuth endpoints are necessary' do
    !@instance.oauth_authorize_endpoint.nil? && !@instance.oauth_token_endpoint.nil?
  end

  test 'Client registration endpoint secured by transport layer security',
    'https://tools.ietf.org/html/rfc7591',
    'The client registration endpoint MUST be protected by a transport layer security.' do

    skip 'TLS tests have been disabled by configuration.' if @disable_tls_tests
    assert_tls_1_2 @instance.oauth_register_endpoint
    warning {
      assert_deny_previous_tls @instance.oauth_register_endpoint
    }
  end

  test 'Client registration endpoint accepts POST messages',
    'https://tools.ietf.org/html/rfc7591',
    'The client registration endpoint MUST accept HTTP POST messages with request parameters encoded in the entity body using the "application/json" format.' do
    # params['redirect_uris'] = [params['redirect_uris']]
    # params['grant_types'] = params['grant_types'].split(',')
    headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }

    params = {
      'client_name' => @instance.client_name,
      'initiate_login_uri' => "#{@instance.base_url}#{BASE_PATH}/#{@instance.id}/#{@instance.client_endpoint_key}/launch",
      'redirect_uris' => ["#{@instance.base_url}#{BASE_PATH}/#{@instance.id}/#{@instance.client_endpoint_key}/redirect"],
      'token_endpoint_auth_method' => 'none',
      'grant_types' => ['authorization_code'],
      'scope' => @instance.scopes,
    }

    binding.pry

    @registration_response = LoggedRestClient.post(@instance.oauth_register_endpoint, params.to_json, headers)
    @registration_response_body = JSON.parse(@registration_response.body)

  end

  test 'Registration endpoint does not respond with an error',
    'https://tools.ietf.org/html/rfc7591',
    'When an OAuth 2.0 error condition occurs, such as the client presenting an invalid initial access token, the authorization server returns an error response appropriate to the OAuth 2.0 token type.' do

      assert !@registration_response_body.has_key?('error') && !@registration_response_body.has_key?('error_description'),
                "Error returned.  Error: #{@registration_response_body['error']}, Description: #{@registration_response_body['error_description']}"

  end

  test 'Registration endpoint responds with HTTP 201 and body contains JSON with required fields',
    'https://tools.ietf.org/html/rfc7591',
    'The server responds with an HTTP 201 Created status code and a body of type "application/json" with content as described in Section 3.2.1.' do


    assert @registration_response.code == 201, "Expected HTTP 201 response from registration endpoint but received #{@registration_response.code}"
    assert @registration_response_body.has_key?('client_id') && @registration_response_body.has_key?('scope'), 'Registration response did not include client_id and scope fields in JSON body'


    # TODO: check all values, and not just client and scope

    @instance.update(client_id: @registration_response_body['client_id'], dynamically_registered: true, scopes: @registration_response_body['scope'])
  end

end
