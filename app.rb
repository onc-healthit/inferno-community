require 'yaml'
require 'sinatra'
require 'fhir_client'
require 'rest-client'
require 'time_difference'
require 'pry'
require 'dm-core'
require 'dm-migrations'

# You should never deactivate SSL Peer Verification
# except in terrible development situations using invalid certificates:
# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

DEFAULT_SCOPES = 'launch launch/patient online_access openid profile user/*.* patient/*.*'

# SET TO FALSE TO KEEP DATABASE BETWEEN SERVER RESTARTS
PURGE_DATABASE = true

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

[TestingInstance, SequenceResult, TestResult, TestWarning, RequestResponse, RequestResponseTestResult].each do |model|
  if PURGE_DATABASE
    model.auto_migrate!
  else
    model.auto_upgrade!
  end
end

get '/' do
  status, headers, body = call! env.merge("PATH_INFO" => '/index')
end

get '/index' do
  erb :index
end

get '/instance/:id/?' do
  @instance = TestingInstance.get(params[:id])
  @sequences = [ ConformanceSequence, DynamicRegistrationSequence, LaunchSequence, PatientStandaloneLaunchSequence, ProviderEHRLaunchSequence, TokenIntrospectionSequence, ArgonautProfilesSequence, ArgonautSearchSequence, IntrospectionSequence  ]
  @sequence_results = @instance.latest_results

  erb :details
end

post '/instance/?' do
  url = params['fhir_server']
  url = url.chomp('/') if url.end_with?('/')
  @instance = TestingInstance.new(url: url, name: params['name'], base_url: request.base_url)
  @instance.save!
  redirect "/instance/#{@instance.id}/"
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
  client.use_dstu2
  client.default_json
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

post '/instance/:id/ConformanceSkip/?' do
  instance = TestingInstance.get(params[:id])

  conformance_sequence_result = SequenceResult.new(name: "Conformance", result: "skip")
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
  @instance.update(dynamically_registered: false, oauth_register_endpoint: params['registration_url'], scopes: params['scope'], client_name: params['client_name'])

  redirect "/instance/#{@instance.id}/DynamicRegistration/"
end

post '/instance/:id/dynamic_registration_skip/?' do
  instance = TestingInstance.get(params[:id])

  sequence_result = SequenceResult.new(name: "DynamicRegistration", result: "skip")
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
    client.use_dstu2
    client.default_json
    sequence = klass.new(instance, client, sequence_result)
    sequence_result = sequence.resume(request, headers)
    sequence_result.save!

    if sequence_result.redirect_to_url
      redirect sequence_result.redirect_to_url
    end

    redirect "/instance/#{params[:id]}/##{sequence_result.name}"

  end
end

post '/instance/:id/IntrospectionLaunch/?' do
  @instance = TestingInstance.get(params[:id])
  @instance.update(scopes: params['scopes'])
  @instance.update(launch_type: 'IntrospectionLaunch')

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
