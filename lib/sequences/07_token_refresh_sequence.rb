class TokenRefreshSequence < SequenceBase

  title 'Token Refresh'
  description 'Demonstrate token refresh capability'
  test_id_prefix 'TR'
  # modal_before_run
  #
  requires :refresh_token, :client_id, :oauth_token_endpoint

  preconditions 'No refresh token available.' do
    !@instance.refresh_token.nil?
  end

  test '01', '', 'Refresh token exchange fails when supplied invalid Refresh Token or Client ID.',
    'https://tools.ietf.org/html/rfc6749',
    'If the request failed verification or is invalid, the authorization server returns an error response.' do

    oauth2_params = {
      'grant_type' => 'refresh_token',
      'refresh_token' => 'INVALID REFRESH TOKEN',
      'client_id' => @instance.client_id
    }

    token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params)
    assert_response_bad_or_unauthorized token_response

    oauth2_params = {
      'grant_type' => 'refresh_token',
      'refresh_token' => @instance.refresh_token,
      'client_id' => 'INVALID_CLIENT_ID'
    }

    token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params)
    assert_response_bad_or_unauthorized token_response

  end

  test '02', '', 'Server successfully exchanges refresh token at OAuth token endpoint',
    'https://tools.ietf.org/html/rfc6749',
    'Server successfully exchanges refresh token at OAuth token endpoint.' do

    oauth2_params = {
      'grant_type' => 'refresh_token',
      'refresh_token' => @instance.refresh_token,
      'client_id' => @instance.client_id
    }

    @token_response = LoggedRestClient.post(@instance.oauth_token_endpoint, oauth2_params)
    assert_response_ok(@token_response)

  end

  test '03', '', 'Data returned from refresh token exchange contains required information encoded in JSON.',
    'http://www.hl7.org/fhir/smart-app-launch/',
    'The authorization servers response MUST include the HTTP Cache-Control response header field with a value of no-store, as well as the Pragma response header field with a value of no-cache. '\
    'The EHR authorization server SHALL return a JSON structure that includes an access token or a message indicating that the authorization request has been denied. '\
    'access_token, token_type, and scope are required. access_token must be Bearer.' do

    @token_response_headers = @token_response.headers
    @token_response_body = JSON.parse(@token_response.body)

    assert @token_response_body.has_key?('access_token'), "Token response did not contain access_token as required"

    token_retrieved_at = DateTime.now

    @instance.resource_references.each(&:destroy)
    @instance.resource_references << ResourceReference.new({resource_type: 'Patient', resource_id: @token_response_body['patient']}) if @token_response_body.key?('patient')

    @instance.save!

    @instance.update(token: @token_response_body['access_token'], token_retrieved_at: token_retrieved_at)

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

    if @token_response_body.has_key?('id_token')
      @instance.save!
      @instance.update(id_token: @token_response_body['id_token'])
    end

    if @token_response_body.has_key?('refresh_token')
      @instance.save!
      @instance.update(refresh_token: @token_response_body['refresh_token'])
    end

  end

end
