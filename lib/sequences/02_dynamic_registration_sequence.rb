class DynamicRegistrationSequence < SequenceBase

  title 'Dynamic Registration'

  description 'OAuth 2.0 Dynamic Client Registration Protocol'

  modal_before_run

  preconditions 'OAuth endpoints are necessary.' do 
    !@instance.oauth_authorize_endpoint.nil? && !@instance.oauth_token_endpoint.nil?
  end

  test 'OAuth 2.0 Dynamic Client Registration Protocol' do
    # params['redirect_uris'] = [params['redirect_uris']]
    # params['grant_types'] = params['grant_types'].split(',')
    headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }

    params = {
      'client_name' => @instance.client_name,
      'initiate_login_uri' => "#{@instance.base_url}/smart/#{@instance.id} /#{@instance.client_endpoint_key}/launch",
      'redirect_uris' => ["#{@instance.base_url}/smart/#{@instance.id}/#{@instance.client_endpoint_key}/redirect"],
      'token_endpoint_auth_method' => 'none',
      'grant_types' => ['authorization_code'],
      'scope' => @instance.scopes,
    }

    registration_response = LoggedRestClient.post(@instance.oauth_register_endpoint, params.to_json, headers)
    registration_response = JSON.parse(registration_response.body)
    if registration_response['error'] || registration_response['error_description']
      # check error

    end

    # check to make sure that values are the same as what what submitted
    @instance.update(client_id: registration_response['client_id'], dynamically_registered: true, scopes: registration_response['scope'])
  end
end
