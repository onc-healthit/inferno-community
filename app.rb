require 'yaml'
require 'sinatra'
require 'sinatra/config_file'
require 'fhir_client'
require 'rest-client'
require 'time_difference'
require 'pry'
require 'dm-core'
require 'dm-migrations'
require 'jwt'
require 'json/jwt'

config_file './config.yml'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE if settings.disable_verify_peer

DEFAULT_SCOPES = 'launch launch/patient online_access openid profile user/*.* patient/*.*'

DataMapper::Logger.new($stdout, :debug) if settings.environment == :development
DataMapper::Model.raise_on_save_failure = true

DataMapper.setup(:default, "sqlite3:data/#{settings.environment.to_s}_data.db")

require './lib/sequence_base'
['lib', 'models'].each do |dir|
  Dir.glob(File.join(File.dirname(File.absolute_path(__FILE__)),dir, '**','*.rb')).each do |file|
    require file
  end
end

require './lib/version'

#TODO clean up database stuff

DataMapper.finalize

[TestingInstance, SequenceResult, TestResult, TestWarning, RequestResponse, RequestResponseTestResult, SupportedResource, ResourceReference].each do |model|
  if settings.purge_database_on_reload || settings.environment == :test
    model.auto_migrate!
  else
    model.auto_upgrade!
  end
end

helpers do
  def request_headers
    env.inject({}){|acc, (k,v)| acc[$1.downcase] = v if k =~ /^http_(.*)/i; acc}
  end
  def version
    VERSION
  end
  def app_name
    settings.app_name
  end
  def valid_json?(json)
    JSON.parse(json)
    return true
  rescue JSON::ParserError => e
    return false
  end
end

get '/' do
  status, headers, body = call! env.merge("PATH_INFO" => '/smart/')
end

get '/smart/?' do
  erb :index
end

get '/smart/static/*' do
  status, headers, body = call! env.merge("PATH_INFO" => '/' + params['splat'].first)
end

get '/smart/:id/?' do
  instance = TestingInstance.get(params[:id])
  halt 404 if instance.nil?
  sequence_results = instance.latest_results
  erb :details, {}, {instance: instance, sequences: SequenceBase.ordered_sequences, sequence_results: sequence_results, error_code: params[:error]}
end

post '/smart/?' do
  url = params['fhir_server']
  url = url.chomp('/') if url.end_with?('/')
  @instance = TestingInstance.new(url: url, name: params['name'], base_url: request.base_url)
  @instance.save!
  redirect "/smart/#{@instance.id}/"
end

get '/smart/:id/test_result/:test_result_id/?' do
  @test_result = TestResult.get(params[:test_result_id])
  halt 404 if @test_result.sequence_result.testing_instance.id != params[:id]
  erb :test_result_details, layout: false
end

get '/smart/:id/sequence_result/:sequence_result_id/cancel' do

  @sequence_result = SequenceResult.get(params[:sequence_result_id])
  halt 404 if @sequence_result.testing_instance.id != params[:id]

  @sequence_result.result = 'cancel'
  cancel_message = 'Test cancelled by user.'

  if @sequence_result.test_results.length > 0
    last_result = @sequence_result.test_results.last
    last_result.result = 'cancel'
    last_result.message = cancel_message
  end

  sequence = SequenceBase.subclasses.find{|x| x.to_s.start_with?(@sequence_result.name)}

  current_test_count = @sequence_result.test_results.length

  sequence.tests.each_with_index do |test, index|
    next if index < current_test_count
    @sequence_result.test_results << TestResult.new(name: test[:name], result: 'cancel', url: test[:url], description: test[:description], test_index: test[:test_index], message: cancel_message)
  end

  @sequence_result.save!

  redirect "/smart/#{params[:id]}/##{@sequence_result.name}"

end


get '/smart/:id/:sequence/?' do
  instance = TestingInstance.get(params[:id])
  client = FHIR::Client.new(instance.url)
  client.use_dstu2
  client.default_json
  klass = SequenceBase.subclasses.find{|x| x.to_s.start_with?(params[:sequence])}
  if klass
    sequence = klass.new(instance, client, settings.disable_tls_tests)
    stream do |out|
      out << erb(:details, {}, {instance: instance, sequences: SequenceBase.ordered_sequences, sequence_results: instance.latest_results, tests_running: true})
      out << "<script>$('#WaitModal').modal('hide')</script>"
      out << "<script>$('#testsRunningModal').modal('show')</script>"
      count = 0
      sequence_result = sequence.start do |result|
        count = count + 1
        out << "<script>$('#testsRunningModal').find('.number-complete').html('(#{count} of #{sequence.test_count} complete)');</script>"
      end
      sequence_result.save!
      if sequence_result.redirect_to_url
        out << "<script>$('#testsRunningModal').find('.modal-body').html('Redirecting to <textarea readonly class=\"form-control\" rows=\"3\">#{sequence_result.redirect_to_url}</textarea>');</script>"
        out << "<script> window.location = '#{sequence_result.redirect_to_url}'</script>"
      else
        out << "<script> window.location = '/smart/#{params[:id]}/##{params[:sequence]}'</script>"
      end
    end

  else
   redirect "/smart/#{params[:id]}/##{params[:sequence]}"
  end

end

post '/smart/:id/ConformanceSkip/?' do
  instance = TestingInstance.get(params[:id])

  conformance_sequence_result = SequenceResult.new(name: "Conformance", result: "skip")
  conformance_sequence_result.save

  instance.conformance_checked = false
  instance.oauth_authorize_endpoint = params[:conformance_authorize_endpoint]
  instance.oauth_token_endpoint = params[:conformance_token_endpoint]

  instance.sequence_results.push(conformance_sequence_result)
  instance.save!

  redirect "/smart/#{params[:id]}/"
end

post '/smart/:id/DynamicRegistration' do
  @instance = TestingInstance.get(params[:id])
  @instance.update(dynamically_registered: false, oauth_register_endpoint: params['registration_url'], scopes: params['scope'], client_name: params['client_name'])

  redirect "/smart/#{@instance.id}/DynamicRegistration/"
end

post '/smart/:id/ArgonautDataQuery' do
  instance = TestingInstance.get(params[:id])
  halt 404 if instance.nil?

  instance.resource_references.select{|ref| ref.resource_type == 'Patient'}.each(&:destroy)
  params['patient_id'].split(",").map(&:strip).each do |patient_id|
    instance.resource_references << ResourceReference.new({resource_type: 'Patient', resource_id: patient_id})
  end

  instance.save

  redirect "/smart/#{instance.id}/ArgonautDataQuery/"
end

post '/smart/:id/ArgonautProfiles' do

  instance = TestingInstance.get(params[:id])
  halt 404 if instance.nil?

  redirect "/smart/#{instance.id}/ArgonautProfiles/"
end

post '/smart/:id/dynamic_registration_skip/?' do
  instance = TestingInstance.get(params[:id])

  sequence_result = SequenceResult.new(name: "DynamicRegistration", result: "skip")
  instance.sequence_results << sequence_result

  instance.client_id = params[:client_id]
  instance.scopes = params[:scope]
  instance.dynamically_registered = false
  instance.save!

  redirect "/smart/#{params[:id]}/"
end

post '/smart/:id/PatientStandaloneLaunch/?' do
  @instance = TestingInstance.get(params[:id])
  @instance.update(scopes: params['scopes'], id_token: nil)
  redirect "/smart/#{params[:id]}/PatientStandaloneLaunch/"
end

post '/smart/:id/ProviderEHRLaunch/?' do
  @instance = TestingInstance.get(params[:id])
  @instance.update(scopes: params['scopes'], id_token: nil)
  redirect "/smart/#{params[:id]}/ProviderEHRLaunch/"
end

post '/smart/:id/OpenIDConnect/?' do
  @instance = TestingInstance.get(params[:id])
  redirect "/smart/#{params[:id]}/OpenIDConnect/"
end

post '/smart/:id/TokenIntrospectionSkip/?' do
  instance = TestingInstance.get(params[:id])

  sequence_result = SequenceResult.new(name: "TokenIntrospection", result: "skip")
  instance.sequence_results << sequence_result

  instance.save!

  redirect "/smart/#{params[:id]}/"
end

get '/smart/:id/:key/:endpoint/?' do
  instance = TestingInstance.get(params[:id])
  halt 404 unless !instance.nil? && instance.client_endpoint_key == params[:key] && ['launch','redirect'].include?(params[:endpoint])

  sequence_result = instance.waiting_on_sequence

  if sequence_result.nil? || sequence_result.result != 'wait'
    redirect "/smart/#{params[:id]}/?error=no_#{params[:endpoint]}"
  else
    klass = SequenceBase.subclasses.find{|x| x.to_s.start_with?(sequence_result.name)}

    client = FHIR::Client.new(instance.url)
    client.use_dstu2
    client.default_json
    sequence = klass.new(instance, client, settings.disable_tls_tests, sequence_result)
    stream do |out|
      out << erb(:details, {}, {instance: instance, sequences: SequenceBase.ordered_sequences, sequence_results: instance.latest_results, tests_running: true})
      out << "<script>$('#WaitModal').modal('hide')</script>"
      out << "<script>$('#testsRunningModal').modal('show')</script>"
      count = sequence_result.test_results.length
      sequence_result = sequence.resume(request, headers, request.params) do |result|
        count = count + 1
        out << "<script>$('#testsRunningModal').find('.number-complete').html('(#{count} of #{sequence.test_count} complete)');</script>"
        instance.save!
      end
      instance.sequence_results.push(sequence_result)
      instance.save!
      if sequence_result.redirect_to_url
        out << "<script>$('#testsRunningModal').find('.modal-body').html('Redirecting to <textarea readonly class=\"form-control\" rows=\"3\">#{sequence_result.redirect_to_url}</textarea>');</script>"
        out << "<script> window.location = '#{sequence_result.redirect_to_url}'</script>"
      else
        out << "<script> window.location = '/smart/#{params[:id]}/##{params[:sequence]}'</script>"
      end
    end
  end
end

post '/smart/:id/TokenIntrospection' do
  @instance = TestingInstance.get(params[:id])
  @instance.update(oauth_introspection_endpoint: params['oauth_introspection_endpoint'])
  @instance.update(resource_id: params['resource_id'])
  @instance.update(resource_secret: params['resource_secret'])

  # copy over the access token to a different place in case it's not the same
  @instance.update(introspect_token: params['access_token'])

  redirect "/smart/#{params[:id]}/TokenIntrospection/"

end
