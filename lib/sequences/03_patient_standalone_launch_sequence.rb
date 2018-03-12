class PatientStandaloneLaunchSequence < SequenceBase

  title 'Patient Standalone Launch Sequence'
  description 'Demonstrate Patient Standalone Launch Sequence'
  modal_before_run

  preconditions 'Client must be registered.' do
    !@instance.client_id.nil?
  end

  test 'Client browser redirected from OAuth server to app redirect uri',
    'http://www.hl7.org/fhir/smart-app-launch/',
    'Client browser redirected from OAuth server to redirect uri of client app as described in SMART authorization sequence.'  do

    @instance.state = SecureRandom.uuid

    oauth2_params = {
      'response_type' => 'code',
      'client_id' => @instance.client_id,
      'redirect_uri' => @instance.base_url + '/smart/' + @instance.id + '/' + @instance.client_endpoint_key + '/redirect',
      'scope' => @instance.scopes,
      'state' => @instance.state,
      'aud' => @instance.url
    }

    oauth2_auth_query = @instance.oauth_authorize_endpoint

    if @instance.oauth_authorize_endpoint.include? '?'
      oauth2_auth_query += "&"
    else
      oauth2_auth_query += "?"
    end

    oauth2_params.each do |key,value|
      oauth2_auth_query += "#{key}=#{CGI.escape(value)}&"
    end

    redirect oauth2_auth_query[0..-2], 'redirect'
  end

  test 'Client app received code parameter and correct state paramater from OAuth server at redirect uri.',
    'http://www.hl7.org/fhir/smart-app-launch/',
    'Code and state are required querystring parameters.  State must be the exact value received from the client.'  do

    assert @params['error'].nil?, "Error returned from authorization server:  code #{@params['error']}, description: #{@params['error_description']}"
    assert @params['state'] == @instance.state, "OAuth server state querystring parameter (#{@params['state']}) did not match state from app #{@instance.state}"
    assert !@params['code'].nil?, "Expected code to be submitted in request"
  end

  test 'OAuth Token exchange endpoint responds to POST using content type application/x-www-form-urlencoded.',
    'http://www.hl7.org/fhir/smart-app-launch/',
    'After obtaining an authorization code, the app trades the code for an access token via HTTP POST to the EHR authorization server’s token endpoint URL, using content-type application/x-www-form-urlencoded, as described in section 4.1.3 of RFC6749' do

    oauth2_params = {
      'grant_type' => 'authorization_code',
      'code' => @params['code'],
      'redirect_uri' => @instance.base_url + '/smart/' + @instance.id + '/' + @instance.client_endpoint_key + '/redirect',
      'client_id' => @instance.client_id
    }

    @token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params)

  end

  test 'Data returned from token exchange contains required information encoded in JSON.',
    'http://www.hl7.org/fhir/smart-app-launch/',
    'The authorization servers response MUST include the HTTP Cache-Control response header field with a value of no-store, as well as the Pragma response header field with a value of no-cache. '\
    'The EHR authorization server SHALL return a JSON structure that includes an access token or a message indicating that the authorization request has been denied. '\
    'access_token, token_type, and scope are required. access_token must be Bearer.' do

    @token_response_headers = @token_response.headers
    @token_response_body = JSON.parse(@token_response.body)

    assert @token_response_body.has_key?('access_token'), "Token response did not contain access_token as required"

    token_retrieved_at = DateTime.now

    @instance.save!
    @instance.update(token: @token_response_body['access_token'], patient_id: @token_response_body['patient'], token_retrieved_at: token_retrieved_at)

    [:cache_control, :pragma].each do |key|
      assert @token_response_headers.has_key?(key), "Token response headers did not contain #{key} as required"
    end

    assert @token_response_headers[:cache_control].downcase.include?('no-store'), 'Token response header must have cache_control containing no-store.'
    assert @token_response_headers[:pragma].downcase.include?('no-cache'), 'Token response header must have pragma containing no-cache.'

    ['token_type', 'scope'].each do |key|
      assert @token_response_body.has_key?(key), "Token response did not contain #{key} as required"
    end

    #case insentitive per https://tools.ietf.org/html/rfc6749#section-5.1
    assert @token_response_body['token_type'].downcase == 'bearer', 'Token type must be Bearer.'

    expected_scopes = @instance.scopes.split(' ')
    actual_scopes = @token_response_body['scope'].split(' ')

    warning {
      missing_scopes = (expected_scopes - actual_scopes)
      assert missing_scopes.empty?, "Token exchange response did not include expected scopes: #{missing_scopes}"

      assert @token_response_body.has_key?('patient'), 'No patient id provided in token exchange.'
    }

    scopes = @token_response_body['scope'] || @instance.scopes

    @instance.save!
    @instance.update(scopes: scopes)

  end

end
