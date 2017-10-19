# You should never deactivate SSL Peer Verification
# except in terrible development situations using invalid certificates:
# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

require 'yaml'
require 'sinatra'
require 'fhir_client'
require 'rest-client'
require 'time_difference'
require 'pry'

Dir.glob(File.join(File.dirname(File.absolute_path(__FILE__)),'lib','**','*.rb')).each do |file|
  require file
end

enable :sessions
set :session_secret, SecureRandom.uuid

# Root: redirect to /index
get '/' do
  status, headers, body = call! env.merge("PATH_INFO" => '/index')
end

# The index displays the available endpoints
get '/index' do
  response = Crucible::App::Html.new
  bullets = {
    "#{response.base_url}/index" => 'this page',
    "#{response.base_url}/app" => 'the app (also the redirect_uri after authz)',
    "#{response.base_url}/launch" => 'the launch url',
    "#{response.base_url}/config" => 'configure client ID and scopes'
  }
  response.open.echo_hash('End Points',bullets)

  body response.instructions.close
end

# This is the primary endpoint of the app and the OAuth2 redirect URL
get '/app' do
stream :keep_open do |out|
  response = Crucible::App::Html.new(out)
  if params['error']
    if params['error_uri']
      redirect params['error_uri']
    else
      response.open.echo_hash('Invalid Launch!',params).close
    end
  elsif params['state'] != session[:state]
    response.open
    response.echo_hash('OAuth2 Redirect Parameters',params)
    response.echo_hash('Session State',session)
    response.start_table('Errors',['Status','Description','Detail'])
    message = 'The <span>state</span> parameter did not match the session <span>state</span> set at launch.
              <br/>&nbsp;<br/>
              Please read the <a href="http://docs.smarthealthit.org/authorization/">SMART "launch sequence"</a> for more information.'
    response.assert('Invalid Launch State',false,message).end_table
    response.instructions.close
  elsif params['state'].nil? || params['code'].nil? || session[:client_id].nil? || session[:token_url].nil? || session[:fhir_url].nil?
    response.open
    response.echo_hash('OAuth2 Redirect Parameters',params)
    response.echo_hash('Session State',session)
    response.start_table('Errors',['Status','Description','Detail'])
    message = 'The <span>/app</span> endpoint requires <span>code</span> and <span>state</span> parameters.
              <br/>&nbsp;<br/>
              The session state should also have been set at <span>/launch</span> with <span>client_id</span>, <span>token_url</span>, and <span>fhir_url</span> information.
              <br/>&nbsp;<br/>
               Please read the <a href="http://docs.smarthealthit.org/authorization/">SMART "launch sequence"</a> for more information.'
    response.assert('OAuth2 Launch Parameters',false,message).end_table
    response.instructions.close
  else
    start_time = Time.now
    # Get the OAuth2 token
    puts "App Params: #{params}"

    oauth2_params = {
      'grant_type' => 'authorization_code',
      'code' => params['code'],
      'redirect_uri' => Crucible::App::Config::CONFIGURATION['redirect_url'],
      'client_id' => session[:client_id]
    }
    puts "Token Params: #{oauth2_params}"
    token_response = RestClient.post(session[:token_url], oauth2_params)
    token_response = JSON.parse(token_response.body)
    puts "Token Response: #{token_response}"

    # Begin outputting the response body
    response.open
    response.echo_hash('OAuth2 Redirect Parameters',params)
    response.echo_hash('Token Response',token_response)

    # Run all tests
    testing = Crucible::App::Test.new(session[:fhir_url], token_response, response)
    testing.run_patient
    testing.run_smoking_status
    testing.run_allergyintolerance
    testing.run_vital_signs
    testing.run_supporting_resources
    testing.score

    # Output the time spent
    end_time = Time.now
    response.output "</div><div><br/><p>Tests completed in #{TimeDifference.between(start_time,end_time).humanize}.</p><br/>"
    response.close
  end
  out.close
end
end

# Helper method to wrap a resource in a Bundle.entry
def bundle_entry(resource)
  entry = FHIR::Bundle::BundleEntryComponent.new
  entry.resource = resource
  entry
end

# This is the launch URI that redirects to an Authorization server
get '/launch' do
  if params && params['iss'] && params['launch']
    client_id = Crucible::App::Config.get_client_id(params['iss'])
    auth_info = Crucible::App::Config.get_auth_info(params['iss'])
    session[:client_id] = client_id
    session[:fhir_url] = params['iss']
    session[:authorize_url] = auth_info[:authorize_url]
    session[:token_url] = auth_info[:token_url]
    puts "Launch Client ID: #{client_id}\nLaunch Auth Info: #{auth_info}\nLaunch Redirect: #{Crucible::App::Config::CONFIGURATION['redirect_url']}"
    session[:state] = SecureRandom.uuid
    oauth2_params = {
      'response_type' => 'code',
      'client_id' => client_id,
      'redirect_uri' => Crucible::App::Config::CONFIGURATION['redirect_url'],
      'scope' => Crucible::App::Config.get_scopes(params['iss']),
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
    response = Crucible::App::Html.new
    response.open.echo_hash('params',params)
    response.start_table('Errors',['Status','Description','Detail'])
    message = 'The <span>/launch</span> endpoint requires <span>iss</span> and <span>launch</span> parameters.
              <br/>&nbsp;<br/>
               Please read the <a href="http://docs.smarthealthit.org/authorization/">SMART "launch sequence"</a> for more information.'
    response.assert('OAuth2 Launch Parameters',false,message).end_table
    body response.instructions.close
  end
end

get '/config' do
  response = Crucible::App::Html.new
  response.open
  response.start_table('Configuration',['Server','Client ID','Scopes',''])
  Crucible::App::Config.get_config.each do |row|
    delete_button = "<form method=\"POST\" action=\"#{response.base_url}/config\"><input type=\"hidden\" name=\"delete\" value=\"#{row.first}\"><input type=\"submit\" value=\"Delete\"></form>"
    response.add_table_row(row << delete_button)
  end
  response.end_table
  fields = { 'Server' => '', 'Client ID' => '', 'Scopes' => 'launch openid profile patient/*.read'}
  response.add_form('Add New Configuration','/config',fields)
  body response.close
end

post '/config' do
  if params['delete']
    puts "Deleting configuration: #{params['delete']}"
    Crucible::App::Config.delete_client(params['delete'])
  else
    puts "Saving configuration: #{params}"
    Crucible::App::Config.add_client(params['Server'],params['Client ID'],params['Scopes'])
  end
  puts "Configuration saved."
  redirect "#{Crucible::App::Html.new.base_url}/config"
end
