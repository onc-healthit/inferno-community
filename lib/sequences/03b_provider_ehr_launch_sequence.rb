class ProviderEHRLaunchSequence < SequenceBase

  description 'Provider EHR Launch Sequence'
  # modal_before_run
  child_test

  preconditions 'Client must be registered.' do 
    !@instance.client_id.nil?
  end

  test 'Launch url successfully hit' do
    wait_at_endpoint 'launch'
  end

  test 'iss supplied and is valid' do
    assert !@params['iss'].nil?, 'Expecting "iss" as a querystring parameter.'
    # check iss is proper url, ssl, etc?
  end

  test 'Launch params provided and is valid' do
    assert !@params['launch'].nil?, 'Expecting "launch" as a querystring parameter.'
    # check that launch is of the right form
  end

  test 'Client successfully redirected back to redirect url' do 

    # construct querystring to oauth and redirect after

    @instance.state = SecureRandom.uuid

    #TODO: FIGUREOUT SCOPES
    scopes = 'launch online_access openid patient/*.* profile'

    binding.pry

    oauth2_params = {
      'response_type' => 'code',
      'client_id' => @instance.client_id,
      'redirect_uri' => @instance.base_url + '/instance/' + @instance.id + '/' + @instance.client_endpoint_key + '/redirect',
      'scope' => scopes,
      'launch' => @params['launch'],
      'state' => @instance.state,
      'aud' => @params['iss']
    }

    binding.pry

    oauth2_auth_query = @instance.oauth_authorize_endpoint
    oauth2_params.each do |key,value|
      oauth2_auth_query += "#{key}=#{value}&"
    end

    puts "Launch Authz Query: #{oauth2_auth_query[0..-2]}"
    binding.pry
    redirect oauth2_auth_query[0..-2], 'redirect'

  end

  test 'Client redirected to redirect url.' do

    # By virtue of reaching this code, this tests passes
    assert true

  end

  test 'No error passed in querystring parameter.' do
    assert !@params['error'].nil?, "Error passed to redirect url: '#{@params['error']}'"
  end

  test 'Code parameter passed via querystring' do

  end

  test 'Token exchange endpoint responds.' do
    oauth2_params = {
      'grant_type' => 'authorization_code',
      'code' => params['code'],
      'redirect_uri' => @instance.base_url + '/instance/' + @instance.id + '/' + @instance.client_endpoint_key + '/redirect', # TODO don't hard code base URL
      'client_id' => @instance.client_id
    }

    # wrap in a rescue and do manual asserts?
    @token_response = RestClient.post(@instance.oauth_token_endpoint, oauth2_params)

  end

  test 'Data returned from token exchange contains token contains expected information.' do
    @token_response = JSON.parse(@token_response.body)

    #TODO add assertions here

    token = token_response['access_token']
    patient_id = token_response['patient']
    scopes = token_response['scope']
    @instance.update(token: token, patient_id: patient_id, scopes: scopes)

  end

end
