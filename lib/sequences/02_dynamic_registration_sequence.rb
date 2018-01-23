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
      'initiate_login_uri' => "#{@instance.base_url}/instance/#{@instance.id} /#{@instance.client_endpoint_key}/launch",
      'redirect_uris' => ["#{@instance.base_url}/instance/#{@instance.id} /#{@instance.client_endpoint_key}/launch"],
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
    @instance.update(client_id: registration_response['client_id'], dynamically_registered: true, scopes: )
  end
end

  # redirect_id = params.delete('id')

  # registration_url = params.delete('registration_url')
#
  # @instance.update(oauth_register_endpoint: registration_url)
  # @instance.update(scopes: params['scope'])

  # params['redirect_uris'] = [params['redirect_uris']]
  # params['grant_types'] = params['grant_types'].split(',')
  # headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  # LoggedRestClient.clear_log
  # registration_response = LoggedRestClient.post(registration_url, params.to_json, headers)
  # registration_response = JSON.parse(registration_response.body)


  # if registration_response['error'] || registration_response['error_description']
  #   # TODO create RequestResponse
  #   # {
  #   #   "error": "invalid something",
  #   #   "error_description": "invalid something is all wrong."
  #   # }
  #   puts "DynamicRegistration Error:\n#{registration_response}"
  #   @instance.update(dynamically_registered: false)
  #   sequence_result = SequenceResult.new(name: 'DynamicRegistration', result: 'fail')
  #   @instance.sequence_results.push(sequence_result)
  # else
  #   # {
  #   #   "client_id"=>"91690316-d398-451d-8dd0-f00235f9c0f6",
  #   #   "client_id_issued_at"=>1515443975,
  #   #   "registration_access_token"=> "eyJraWQiOiJyc2ExIiwiYW ... W8nZ5w",
  #   #   "registration_client_uri"=>"https://sb-auth.smarthealthit.org/register/91690316-d398-451d-8dd0-f00235f9c0f6",
  #   #   "redirect_uris"=>["http://localhost:4567/instance/7YXIwijXt7l/7BPXU/redirect"],
  #   #   "client_name"=>"TestApp",
  #   #   "token_endpoint_auth_method"=>"none",
  #   #   "scope"=>"launch launch/patient openid user/*.* patient/*.* profile",
  #   #   "grant_types"=>["authorization_code"],
  #   #   "response_types"=>["code"],
  #   #   "initiate_login_uri"=>"http://localhost:4567/instance/7YXIwijXt7l/7BPXU/launch"
  #   # }
  #   puts "DynamicRegistration Success. Client ID: #{registration_response['client_id']}"
  #   @instance.update(client_id: registration_response['client_id'], dynamically_registered: true)
  #   sequence_result = DynamicRegistrationSequence.new(@instance, nil).start
  #   @instance.sequence_results.push(sequence_result)
  # end
