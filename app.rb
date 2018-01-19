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

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'sqlite3:data/data.db')
DataMapper::Model.raise_on_save_failure = true 

require './lib/sequence_base'
['lib', 'models'].each do |dir|
  Dir.glob(File.join(File.dirname(File.absolute_path(__FILE__)),dir, '**','*.rb')).each do |file|
    require file
  end
end

#TODO clean up database stuff

DataMapper.finalize

[TestingInstance, SequenceResult, TestResult, Warning, RequestResponse, RequestResponseTestResult].each do |model|
  # model.auto_migrate!
  model.auto_upgrade!
end

enable :sessions
set :session_secret, SecureRandom.uuid

get '/' do
  status, headers, body = call! env.merge("PATH_INFO" => '/index')
end

get '/index' do
  erb :index
end

get '/instance/:id/?' do
  @instance = TestingInstance.get(params[:id])
  @sequences = [ ConformanceSequence, DynamicRegistrationSequence, LaunchSequence, PatientStandaloneLaunchSequence, ProviderEHRLaunchSequence, TokenIntrospectionSequence, ArgonautProfilesSequence, ArgonautSearchSequence ]
  @sequence_results = @instance.latest_results

  erb :details
end

post '/instance/?' do
  id = SecureRandomBase62.generate
  url = params['fhir_server']
  url = url.chomp('/') if url.end_with?('/')
  @instance = TestingInstance.new(id: id, url: url, name: params['name'], base_url: request.base_url)
  @instance.save
  redirect "/instance/#{id}/"
end

get '/instance/:id/test_result/:test_result_id/?' do
  @test_result = TestResult.get(params[:test_result_id])
  halt 404 if @test_result.sequence_result.testing_instance.id != params[:id]
  erb :test_result_details, layout: false
end

get '/instance/:id/sequence_result/:sequence_result_id/cancel' do

  @sequence_result = SequenceResult.get(params[:sequence_result_id])
  halt 404 if @sequence_result.testing_instance.id != params[:id]

  @sequence_result.result = 'cancel'
  @sequence_result.save!

  redirect "/instance/#{params[:id]}/##{@sequence_result.name}"

end


get '/instance/:id/:sequence/?' do
  instance = TestingInstance.get(params[:id])
  client = FHIR::Client.new(instance.url)
  klass = SequenceBase.subclasses.find{|x| x.to_s.start_with?(params[:sequence])}
  if klass
    sequence = klass.new(instance, client)

    sequence_result = sequence.start
    instance.sequence_results.push(sequence_result)
    instance.save!

    if sequence_result.redirect_to_url
      redirect sequence_result.redirect_to_url
    end
  end
  redirect "/instance/#{params[:id]}/##{params[:sequence]}"
end


# get '/instance/:id/Conformance/?' do
#   instance = TestingInstance.get(params[:id])
#   client = FHIR::Client.new(instance.url)
# 
#   sequence = ConformanceSequence.new(instance, client)
#   sequence_result = sequence.start
#   instance.sequence_results.push(sequence_result)
#   instance.save!
# 
#   redirect "/instance/#{params[:id]}/##{params[:sequence_id]}"
# end

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

  redirect "/instance/#{redirect_id}/#DynamicRegistration"
end

post '/instance/:id/dynamic_registration_skip/?' do
  instance = TestingInstance.get(params[:id])

  sequence_result = SequenceResult.new(id: SecureRandom.uuid, name: "DynamicRegistration", result: "skip")
  instance.sequence_results << sequence_result

  instance.client_id = params[:client_id]
  instance.dynamically_registered = false
  instance.save

  redirect "/instance/#{params[:id]}/"
end

post '/instance/:id/PatientStandaloneLaunch/?' do
  @instance = TestingInstance.get(params[:id])
  @instance.update(scopes: params['scopes'])
  redirect "/instance/#{params[:id]}/PatientStandaloneLaunch/"
end

get '/instance/:id/:key/:endpoint/?' do
  @instance = TestingInstance.get(params[:id])

  sequence_result = @instance.waiting_on_sequence
  
  if sequence_result.nil? || sequence_result.result != 'wait'
    redirect "/instance/#{params[:id]}/?error=No sequence is currently waiting on launch."
  else
    klass = SequenceBase.subclasses.find{|x| x.to_s.start_with?(sequence_result.name)}
    instance = TestingInstance.get(params[:id])
    client = FHIR::Client.new(instance.url)
    sequence = klass.new(instance, client, sequence_result)
    sequence_result = sequence.resume(params)
    sequence_result.save!

    if sequence_result.redirect_to_url
      redirect sequence_result.redirect_to_url
    end

    redirect "/instance/#{params[:id]}/##{sequence_result.name}"

  end
end
