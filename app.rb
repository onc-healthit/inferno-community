# You should never deactivate SSL Peer Verification
# except in terrible development situations using invalid certificates:
# require 'oauth2'
# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

require 'yaml'
require 'sinatra'
require 'fhir_client'
require 'rest-client'
require 'time_difference'
require 'pry'
require 'dm-core'
require 'dm-migrations'

DEFAULT_SCOPES = 'launch launch/patient online_access openid profile user/*.* patient/*.*'

DataMapper.setup(:default, 'sqlite3:data/data.db')

require './lib/sequences/base'
['lib', 'models'].each do |dir|
  Dir.glob(File.join(File.dirname(File.absolute_path(__FILE__)),dir, '**','*.rb')).each do |file|
    require file unless file=='base.rb'
  end
end

#TODO clean up database stuff

DataMapper.finalize
#
# # automatically create the post table
TestingInstance.auto_migrate!
TestingInstance.auto_upgrade!

SequenceResult.auto_migrate!
SequenceResult.auto_upgrade!

TestResult.auto_migrate!
TestResult.auto_upgrade!

RequestResponse.auto_migrate!
RequestResponse.auto_upgrade!

enable :sessions
set :session_secret, SecureRandom.uuid

# Root: redirect to /index
get '/' do
  status, headers, body = call! env.merge("PATH_INFO" => '/index')
end

# The index displays the available endpoints
get '/index' do
  # response = Crucible::App::Html.new
  # bullets = {
  #   "#{response.base_url}/index" => 'this page',
  #   "#{response.base_url}/app" => 'the app (also the redirect_uri after authz)',
  #   "#{response.base_url}/launch_ehr" => 'the ehr launch url',
  #   "#{response.base_url}/launch_sa" => 'the standalone launch url',
  #   "#{response.base_url}/config" => 'configure client ID and scopes'
  # }
  # response.open.echo_hash('End Points',bullets)

  # body response.instructions.close

  erb :index
end

get '/instance/:id/?' do
  @instance = TestingInstance.get(params[:id])
  @sequences = [ ConformanceSequence, DynamicRegistrationSequence, LaunchSequence, PatientStandaloneLaunchSequence, ProviderEHRLaunchSequence, ArgonautProfilesSequence ]
  @sequence_results = @instance.latest_results

  erb :details
end

post '/instance/?' do
  id = SecureRandomBase62.generate
  url = params['fhir_server']
  url = url.chomp('/') if url.end_with?('/')
  @instance = TestingInstance.new(id: id, url: url, name: params['name'])
  @instance.save
  redirect "/instance/#{id}/"
end

get '/instance/:id/:sequence/' do
  instance = TestingInstance.get(params[:id])
  client = FHIR::Client.new(instance.url)
  klass = SequenceBase.subclasses.find{|x| x.to_s.start_with?(params[:sequence])}
  if klass
    sequence = klass.new(instance, client)
    sequence_result = sequence.start
    instance.sequence_results.push(sequence_result)
    instance.save!
  end
  redirect "/instance/#{params[:id]}/?finished=#{params[:sequence_id]}"
end

get '/instance/:id/Conformance/?' do
  instance = TestingInstance.get(params[:id])
  client = FHIR::Client.new(instance.url)

  sequence = ConformanceSequence.new(instance, client)
  sequence_result = sequence.start
  instance.sequence_results.push(sequence_result)
  instance.save!

  redirect "/instance/#{params[:id]}/?finished=#{params[:sequence_id]}"
end

post '/instance/:id/ConformanceSkip/?' do
  instance = TestingInstance.get(params[:id])

  conformance_sequence_result = SequenceResult.new(id: SecureRandom.uuid, name: "Conformance", result: "skip")
  conformance_sequence_result.save

  instance.conformance_checked = false
  instance.oauth_authorize_endpoint = params[:conformance_authorize_endpoint]
  instance.oauth_token_endpoint = params[:conformance_token_endpoint]

  instance.sequence_results.push(conformance_sequence_result)
  instance.save!

  redirect "/instance/#{params[:id]}/"
end

post '/instance/:id/DynamicRegistration' do
  @instance = TestingInstance.get(params[:id])
  redirect_id = params.delete('id')

  registration_url = params.delete('registration_url')
  @instance.update(oauth_register_endpoint: registration_url)
  @instance.update(scopes: params['scope'])

  params['redirect_uris'] = [params['redirect_uris']]
  params['grant_types'] = params['grant_types'].split(',')
  headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
  registration_response = RestClient.post(registration_url, params.to_json, headers)
  registration_response = JSON.parse(registration_response.body)

  if registration_response['error'] || registration_response['error_description']
    # TODO create RequestResponse
    # {
    #   "error": "invalid something",
    #   "error_description": "invalid something is all wrong."
    # }
    puts "DynamicRegistration Error:\n#{registration_response}"
    @instance.update(dynamically_registered: false)
    sequence_result = SequenceResult.new(id: SecureRandom.uuid, name: 'DynamicRegistration', result: 'fail')
    @instance.sequence_results.push(sequence_result)
  else
    # {
    #   "client_id"=>"91690316-d398-451d-8dd0-f00235f9c0f6",
    #   "client_id_issued_at"=>1515443975,
    #   "registration_access_token"=> "eyJraWQiOiJyc2ExIiwiYW ... W8nZ5w",
    #   "registration_client_uri"=>"https://sb-auth.smarthealthit.org/register/91690316-d398-451d-8dd0-f00235f9c0f6",
    #   "redirect_uris"=>["http://localhost:4567/instance/7YXIwijXt7l/7BPXU/redirect"],
    #   "client_name"=>"TestApp",
    #   "token_endpoint_auth_method"=>"none",
    #   "scope"=>"launch launch/patient openid user/*.* patient/*.* profile",
    #   "grant_types"=>["authorization_code"],
    #   "response_types"=>["code"],
    #   "initiate_login_uri"=>"http://localhost:4567/instance/7YXIwijXt7l/7BPXU/launch"
    # }
    puts "DynamicRegistration Success. Client ID: #{registration_response['client_id']}"
    @instance.update(client_id: registration_response['client_id'], dynamically_registered: true)
    sequence_result = DynamicRegistrationSequence.new(@instance, nil).start
    @instance.sequence_results.push(sequence_result)
  end
  @instance.save!

  redirect "/instance/#{redirect_id}/"
end

post '/instance/:id/dynamic_registration_skip/?' do
  instance = TestingInstance.get(params[:id])

  sequence_result = SequenceResult.new(id: SecureRandom.uuid, name: "DynamicRegistration", result: "skip")
  sequence_result.save
  instance.sequence_results.push(sequence_result)

  instance.client_id = params[:client_id]
  instance.dynamically_registered = false
  instance.save!

  redirect "/instance/#{params[:id]}/"
end

post '/instance/:id/PatientStandaloneLaunch/?' do
  @instance = TestingInstance.get(params[:id])
  @instance.update(scopes: params['scopes'])
  @instance.update(launch_type: 'PatientStandaloneLaunch')

  session[:client_id] = @instance.client_id
  session[:fhir_url] = @instance.url
  session[:authorize_url] = @instance.oauth_authorize_endpoint
  session[:token_url] = @instance.oauth_token_endpoint
  session[:state] = SecureRandom.uuid
  oauth2_params = {
    'response_type' => 'code',
    'client_id' => @instance.client_id,
    'redirect_uri' => request.base_url + '/instance/' + @instance.id + '/' + @instance.client_endpoint_key + '/redirect', # TODO don't hard code base URL
    'scope' => @instance.scopes,
    'state' => session[:state],
    'aud' => @instance.url
  }
  oauth2_auth_query = "#{session[:authorize_url]}?"
  oauth2_params.each do |key,value|
    oauth2_auth_query += "#{key}=#{CGI.escape(value)}&"
  end
  puts "Launch Authz Query: #{oauth2_auth_query[0..-2]}"
  redirect oauth2_auth_query[0..-2]
end

get '/instance/:id/:key/launch/?' do
  # Provider EHR Launch Endpoint
  @instance = TestingInstance.get(params[:id])
  @instance.update(launch_type: 'ProviderEHRLaunch', scopes: 'launch online_access openid patient/*.* profile')

  if params && params['iss'] && params['launch']
    session[:client_id] = @instance.client_id
    # session[:fhir_url] = params['iss']
    session[:authorize_url] = @instance.oauth_authorize_endpoint
    session[:token_url] = @instance.oauth_token_endpoint
    session[:state] = SecureRandom.uuid
    oauth2_params = {
      'response_type' => 'code',
      'client_id' => @instance.client_id,
      'redirect_uri' => request.base_url + '/instance/' + @instance.id + '/' + @instance.client_endpoint_key + '/redirect', # TODO don't hard code base URL
      'scope' => @instance.scopes,
      'launch' => params['launch'],
      'state' => session[:state],
      'aud' => params['iss']
    }
    oauth2_auth_query = "#{session[:authorize_url]}?"
    oauth2_params.each do |key,value|
      oauth2_auth_query += "#{key}=#{CGI.escape(value)}&"
    end
    puts "Launch Authz Query: #{oauth2_auth_query[0..-2]}"
    redirect oauth2_auth_query[0..-2]
  else
    redirect "/instance/#{params[:id]}/#{params[:key]}/redirect?error=EHR Launch requires iss and launch parameters."
  end
end

get '/instance/:id/:key/redirect/?' do
  @instance = TestingInstance.get(params[:id])

  # test that launch is successful
  if params['error']
    launch_success_result = TestResult.new(id: SecureRandom.uuid, name: @instance.launch_type, result: 'fail')
  else
    launch_success_result = TestResult.new(id: SecureRandom.uuid, name: @instance.launch_type, result: 'pass')
    oauth2_params = {
      'grant_type' => 'authorization_code',
      'code' => params['code'],
      'redirect_uri' => 'http://localhost:4567/instance/' + @instance.id + '/' + @instance.client_endpoint_key + '/redirect', # TODO don't hard code base URL
      'client_id' => @instance.client_id
    }
    token_response = RestClient.post(@instance.oauth_token_endpoint, oauth2_params)
    token_response = JSON.parse(token_response.body)
    token = token_response['access_token']
    patient_id = token_response['patient']
    scopes = token_response['scope']
    @instance.update(token: token, patient_id: patient_id, scopes: scopes)
  end
  launch_success_result.save

  launch_request_response = RequestResponse.new(id: SecureRandom.uuid) # TODO fill out RequestResponse
  launch_request_response.test_results.push(launch_success_result)

  # store TestResult in SequenceResult
  launch_sequence_result = SequenceResult.new(id: SecureRandom.uuid, name: @instance.launch_type)
  launch_sequence_result.test_results.push(launch_success_result)

  passed_count = 0
  failed_count = 0
  warning_count = 0
  launch_sequence_result.test_results.each do |test_result|
    if test_result.result == 'pass'
      passed_count += 1
    elsif test_result.result == 'fail'
      failed_count += 1
    end

    unless test_result.warning.nil?
      warning_count += 1
    end
  end
  result = (failed_count.zero?) ? 'pass' : 'fail'
  launch_sequence_result.passed_count = passed_count
  launch_sequence_result.failed_count = failed_count
  launch_sequence_result.warning_count = warning_count
  launch_sequence_result.result = result
  launch_sequence_result.save

  # store SequenceResult in TestingInstance
  @instance.sequence_results.push(launch_sequence_result)
  @instance.save

  sequence = LaunchSequence.new(@instance, nil)
  sequence_result = sequence.start
  @instance.sequence_results.push(sequence_result)
  @instance.save!

  redirect "/instance/#{params[:id]}/"
end
