class ProviderEHRLaunchSequence < SequenceBase

  title 'Provider EHR Launch Sequence'

  description 'Provider EHR Launch Sequence'
  # modal_before_run

  preconditions 'Client must be registered.' do 
    !@instance.client_id.nil?
  end

  test 'Launch url successfully hit' do
    wait_at_endpoint 'launch'
  end

  test 'iss supplied and is valid' do
    assert !@params['iss'].nil?, 'Expecting "iss" as a querystring parameter.'

    warning {
      assert @params['iss'] == @instance.url, "'iss' param [#{@params['iss']}] does not match url of testing instance [#{@instance.url}]"
    }
  end

  test 'Launch params provided and is valid' do
    assert !@params['launch'].nil?, 'Expecting "launch" as a querystring parameter.'
    # check that launch is of the right form
  end

  test 'Client successfully redirected back to redirect url' do 

    # construct querystring to oauth and redirect after
    @instance.state = SecureRandom.uuid

    #TODO: FIGUREOUT SCOPES
    scopes = 'launch openid patient/*.* profile'

    oauth2_params = {
      'response_type' => 'code',
      'client_id' => @instance.client_id,
      'redirect_uri' => @instance.base_url + '/smart/' + @instance.id + '/' + @instance.client_endpoint_key + '/redirect',
      'scope' => scopes,
      'launch' => @params['launch'],
      'state' => @instance.state,
      'aud' => @params['iss']
    }

    oauth2_auth_query = @instance.oauth_authorize_endpoint + "?"
    oauth2_params.each do |key,value|
      oauth2_auth_query += "#{key}=#{CGI.escape(value)}&"
    end

    redirect oauth2_auth_query[0..-2], 'redirect'
  end

  test 'OAuth Server hit redirect url proper values' do
    assert @params['error'].nil?, "Error returned from authorization server:  code #{@params['error']}, description: #{@params['error_description']}"
    assert !@params['code'].nil?, "Expected code to be submitted in request"
  end

  test 'Token exchange endpoint responds.' do
    oauth2_params = {
      'grant_type' => 'authorization_code',
      'code' => @params['code'],
      'redirect_uri' => @instance.base_url + '/smart/' + @instance.id + '/' + @instance.client_endpoint_key + '/redirect',
      'client_id' => @instance.client_id
    }

    # wrap in a rescue and do manual asserts?
    @token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params)

  end

  test 'Data returned from token exchange contains token contains expected information.' do
    @token_response = JSON.parse(@token_response.body)

    #TODO add assertions here

    token = @token_response['access_token']
    patient_id = @token_response['patient']
    scopes = @token_response['scope']
    token_retrieved_at = DateTime.now
    
    @instance.save! #investigate why this is dirty
    @instance.update(token: token, patient_id: patient_id, scopes: scopes, token_retrieved_at: token_retrieved_at)

  end

end
