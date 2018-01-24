class TokenIntrospectionSequence < SequenceBase
 
  title 'OAuth 2.0 Token Introspection'

  description 'Access tokens can be introspected at the authorization server'
  
  modal_before_run

  preconditions 'Client must be authorized.' do 
    !@instance.token.nil?
  end

  test 'Call token introspection endpoint',
          'https://tools.ietf.org/html/rfc7662',
          'A resource server is capable of calling the introspection endpoint' do
    
    headers = { 'Accept' => 'application/json', 'Content-type' => 'application/x-www-form-urlencoded' }
    
    params = {
      'token' => @instance.introspect_token,
      'client_id' => @instance.resource_id,
      'client_secret' => @instance.resource_secret
    }
    
    @introspection_response = LoggedRestClient.post(@instance.oauth_introspection_endpoint, params, headers)
    @introspection_response = JSON.parse(@introspection_response.body)
    
    FHIR.logger.debug "Introspection response: #{@introspection_response}"

    assert !(@introspection_response['error'] || @introspection_response['error_description']), 'Got an error from the introspection endpoint'

  end

  test 'Access token is active',
          'https://tools.ietf.org/html/rfc7662',
          'A current access token is listed as "active"' do
    
    active = @introspection_response['active']
    
    assert active, 'Token is not active, try the test again with a valid token'
  end

  test 'Scopes match',
          'https://tools.ietf.org/html/rfc7662',
          'The scopes we received alongside the token match those from the introspection response' do

    expected_scopes = @instance.scopes.split(' ')
    actual_scopes = @introspection_response['scope'].split(' ')
    
    FHIR.logger.debug "Introspection: Expected scopes #{expected_scopes}, Actual scopes #{actual_scopes}"
    
    warning {
      missing_scopes = (expected_scopes - actual_scopes)
      assert missing_scopes.empty?, "Introspection response did not include expected scopes: #{missing_scopes}"
    }
    extra_scopes = (actual_scopes - expected_scopes)
    assert extra_scopes.empty?, "Introspection response included additional scopes: #{extra_scopes}"
    
  end 

end
