# You should never deactivate SSL Peer Verification
# except in terrible development situations using invalid certificates:
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

require 'yaml'
require 'sinatra'
require 'fhir_client'
require 'rest-client'

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
  bullets = {
    '/index' => 'this page',
    '/app' => 'the app (also the redirect_uri after authz)',
    '/launch' => 'the launch url',
    '/config' => 'configure client ID and scopes'
  }
  response = Crucible::App::Html.new
  body response.open.echo_hash('End Points',bullets).close
end

# This is the primary endpoint of the app and the OAuth2 redirect URL
get '/app' do
  response = Crucible::App::Html.new
  if params['error']
    if params['error_uri']
      redirect params['error_uri']
    else
      body response.open.echo_hash('Invalid Launch!',params).close
    end
  elsif params['state'] && params['state'] != session[:state]
    body response.open.echo_hash('Invalid Launch State!',params).close
  else
    # Get the OAuth2 token
    puts "App Params: #{params}"

    oauth2_params = {
      'grant_type' => 'authorization_code',
      'code' => params['code'],
      'redirect_uri' => "#{request.base_url}/app",
      'client_id' => session[:client_id]
    }
    puts "Token Params: #{oauth2_params}"
    token_response = RestClient.post(session[:token_url], oauth2_params)
    token_response = JSON.parse(token_response.body)
    puts "Token Response: #{token_response}"
    token = token_response['access_token']
    patient_id = token_response['patient']
    scopes = token_response['scope']

    # Begin outputting the response body
    response.open
    response.echo_hash('oauth2 redirect parameters',params)
    response.echo_hash('token response',token_response)
    response.start_table('Crucible Test Results',['Status','Description','Detail'])

    # Configure the FHIR Client
    client = FHIR::Client.new(session[:fhir_url])
    client.set_bearer_token(token)
    client.default_format = 'application/json+fhir'
    client.default_format_bundle = 'application/json+fhir'

    # Get the patient demographics
    patient = client.read(FHIR::Patient, patient_id).resource
    response.assert('Patient successfully retrieved.',patient.is_a?(FHIR::Patient),patient.xmlId)

    patient_details = patient.massageHash(patient,true)
    puts "Patient: #{patient_details['id']} #{patient_details['name']}"

    # DAF/US-Core CCDS
    response.assert('Patient Name',patient_details['name'],patient_details['name'])
    response.assert('Patient Gender',FHIR::Patient::VALID_CODES[:gender].include?(patient_details['gender']),patient_details['gender'])
    response.assert('Patient Date of Birth',patient_details['birthDate'],patient_details['birthDate'])
    # US Extensions
    extensions = {
      'Race' => 'http://hl7.org/fhir/StructureDefinition/us-core-race',
      'Ethnicity' => 'http://hl7.org/fhir/StructureDefinition/us-core-ethnicity',
      'Religion' => 'http://hl7.org/fhir/StructureDefinition/us-core-religion',
      'Mother\'s Maiden Name' => 'http://hl7.org/fhir/StructureDefinition/patient-mothersMaidenName',
      'Birth Place' => 'http://hl7.org/fhir/StructureDefinition/birthPlace'
    }
    required_extensions = ['Race','Ethnicity']
    extensions.each do |name,url|
      detail = nil
      check = false
      if patient_details['extension']
        detail = patient_details['extension'].find{|e| e['url']==url }
        if required_extensions.include?(name)
          check = !detail.nil?
        else
          check = :not_found
        end
      end
      response.assert("Patient #{name}", check, detail)
    end
    response.assert('Patient Preferred Language',(patient_details['communication'] && patient_details['communication'].find{|c|c['language'] && c['preferred']}),patient_details['communication'])

    # Get the patient's smoking status
    # {"coding":[{"system":"http://loinc.org","code":"72166-2"}]}
    smoking_reply = client.search(FHIR::Observation, search: { parameters: { 'patient' => patient_id, 'code' => 'http://loinc.org|72166-2'}})
    detail = smoking_reply.resource.entry.first.to_fhir_json rescue nil
    response.assert('Smoking Status',((smoking_reply.resource.entry.length >= 1) rescue false),detail)

    # Get the patient's conditions
    condition_reply = client.search(FHIR::Condition, search: { parameters: { 'patient' => patient_id, 'clinicalstatus' => 'active' } })
    puts "Conditions: #{condition_reply.resource.entry.length}"

    # Get the patient's medications
    medication_reply = client.search(FHIR::MedicationOrder, search: { parameters: { 'patient' => patient_id, 'status' => 'active' } })
    puts "Medications: #{medication_reply.resource.entry.length}"

    # Get the patient's allergies
    # There should be at least one. No known allergies should have a negated entry.
    # Include these codes as defined in http://snomed.info/sct
    #   Code	     Display
    #   160244002	No Known Allergies
    #   429625007	No Known Food Allergies
    #   409137002	No Known Drug Allergies
    #   428607008	No Known Environmental Allergy
    allergy_reply = client.search(FHIR::AllergyIntolerance, search: { parameters: { 'patient' => patient_id } })
    puts "AllergyIntolerances: #{allergy_reply.resource.entry.length}"

    # DAF -----------------------------
#~    # AllergyIntolerance
    # DiagnosticOrder
    # DiagnosticReport
    # Encounter
    # FamilyMemberHistory
    # Immunization
    # Results (Observation)
    # Medication
    # MedicationStatement
    # MedicationAdministration
    # MedicationDispense
#    # MedicationOrder
#    # Patient
#    # Condition
    # Procedure
#    # SmokingStatus (Observation)
    # VitalSigns (Observation)
    # List
    # Supporting Resources: Organization, Location, Practitioner, Substance, RelatedPerson, Specimen

    # ARGONAUTS ----------------------
    # 	CCDS Data Element	         FHIR Resource
#    # (1)	Patient Name	             Patient
#    # (2)	Sex	                        Patient
#    # (3)	Date of birth	              Patient
#    # (4)	Race	                       Patient
#    # (5)	Ethnicity	                  Patient
#    # (6)	Preferred language	       Patient
#    # (7)	Smoking status	           Observation
    # (8)	Problems	                 Condition
    # (9)	Medications	                Medication, MedicationStatement, MedicationOrder
    # (10)	Medication allergies	    AllergyIntolerance
    # (11)	Laboratory test(s)	      Observation, DiagnosticReport
    # (12)	Laboratory value(s)/result(s)	Observation, DiagnosticReport
    # (13)	Vital signs	             Observation
    # (14)	(no longer required)	-
    # (15)	Procedures	              Procedure
    # (16)	Care team member(s)	     CarePlan
    # (17)	Immunizations	           Immunization
    # (18)	Unique device identifier(s) for a patient’s implantable device(s)	Device
    # (19)	Assessment and plan of treatment	CarePlan
    # (20)	Goals	                   Goal
    # (21)	Health concerns	         Condition
    # --------------------------------
    # Date range search requirements are included in the Quick Start section for the following resources -
    # Vital Signs, Laboratory Results, Goals, Procedures, and Assessment and Plan of Treatment.

    # Assemble the patient record
    # record = FHIR::Bundle.new
    # record.entry << bundle_entry(patient)
    # condition_reply.resource.entry.each do |entry|
    #   record.entry << bundle_entry(entry.resource)
    # end
    # medication_reply.resource.entry.each do |entry|
    #   record.entry << bundle_entry(entry.resource)
    # end
    # puts "Built the bundle..."

    response.end_table
    body response.close
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
  client_id = Crucible::App::Config.get_client_id(params['iss'])
  auth_info = Crucible::App::Config.get_auth_info(params['iss'])
  session[:client_id] = client_id
  session[:fhir_url] = params['iss']
  session[:authorize_url] = auth_info[:authorize_url]
  session[:token_url] = auth_info[:token_url]
  puts "Launch Client ID: #{client_id}\nLaunch Auth Info: #{auth_info}\nLaunch Redirect: #{request.base_url}/app"
  session[:state] = SecureRandom.uuid
  oauth2_params = {
    'response_type' => 'code',
    'client_id' => client_id,
    'redirect_uri' => "#{request.base_url}/app",
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
  response = Crucible::App::Html.new
  content = response.open.echo_hash('params',params).echo_hash('OAuth2 Metadata',auth_info).close
  redirect oauth2_auth_query[0..-2], content
end

get '/config' do
  response = Crucible::App::Html.new
  response.open
  response.start_table('Configuration',['Server','Client ID','Scopes',''])
  Crucible::App::Config.get_config.each do |row|
    delete_button = "<form method=\"POST\" action=\"/config\"><input type=\"hidden\" name=\"delete\" value=\"#{row.first}\"><input type=\"submit\" value=\"Delete\"></form>"
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
  redirect '/config'
end
