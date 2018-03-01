class TokenIntrospectionSequence < SequenceBase
 
  title 'OAuth 2.0 Token Introspection'

  description 'Verify token properties using token introspection at the authorization server'

  optional
  
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
          'The scopes we received alongside the token match those from the introspection response',
          :optional do

    expected_scopes = @instance.scopes.split(' ')
    actual_scopes = @introspection_response['scope'].split(' ')
    
    FHIR.logger.debug "Introspection: Expected scopes #{expected_scopes}, Actual scopes #{actual_scopes}"
    
    missing_scopes = (expected_scopes - actual_scopes)
    assert missing_scopes.empty?, "Introspection response did not include expected scopes: #{missing_scopes}"
    extra_scopes = (actual_scopes - expected_scopes)

    assert extra_scopes.empty?, "Introspection response included additional scopes: #{extra_scopes}"
    
  end
  
  test 'Token expiration',
          '',
          'The token should have a lifetime of at least 60 minutes' do
  
    expiration = Time.at(@introspection_response['exp']).to_datetime
    token_retrieved_at = @instance.token_retrieved_at
    now = DateTime.now

    max_token_seconds = 60 * 60 # one hour expiration?
    clock_slip = 5 # a few seconds of clock skew allowed

    assert (expiration - token_retrieved_at) < max_token_seconds, "Token does not have adequate lifetime of at least #{max_token_seconds} seconds"
    
    assert (now + Rational(clock_slip, (24 * 60 * 60))) < expiration, "Token has expired"
            
  end

end
