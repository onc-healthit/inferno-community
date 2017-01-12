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
    puts 'Examining Patient for US-Core Extensions'
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
      check = :not_found
      if patient_details['extension']
        detail = patient_details['extension'].find{|e| e['url']==url }
        check = !detail.nil? if required_extensions.include?(name)
      elsif required_extensions.include?(name)
        check = false
      end
      response.assert("Patient #{name}", check, detail)
    end
    response.assert('Patient Preferred Language',(patient_details['communication'] && patient_details['communication'].find{|c|c['language'] && c['preferred']}),patient_details['communication'])

    # Get the patient's smoking status
    # {"coding":[{"system":"http://loinc.org","code":"72166-2"}]}
    puts 'Getting Smoking Status'
    search_reply = client.search(FHIR::Observation, search: { parameters: { 'patient' => patient_id, 'code' => 'http://loinc.org|72166-2'}})
    detail = search_reply.resource.entry.first.to_fhir_json rescue nil
    response.assert('Smoking Status',((search_reply.resource.entry.length >= 1) rescue false),detail)

    # Get the patient's conditions
    puts 'Getting Conditions'
    search_reply = client.search(FHIR::Condition, search: { parameters: { 'patient' => patient_id, 'clinicalstatus' => 'active' } })
    response.assert_search_results('Conditions',search_reply)

    # Get the patient's medications
    puts 'Getting MedicationOrders'
    search_reply = client.search(FHIR::MedicationOrder, search: { parameters: { 'patient' => patient_id, 'status' => 'active,completed' } })
    response.assert_search_results('MedicationOrders',search_reply)

    puts 'Getting MedicationStatements'
    search_reply = client.search(FHIR::MedicationStatement, search: { parameters: { 'patient' => patient_id, 'status' => 'active,completed' } })
    response.assert_search_results('MedicationStatements',search_reply)

    puts 'Getting MedicationDispense'
    search_reply = client.search(FHIR::MedicationDispense, search: { parameters: { 'patient' => patient_id } })
    response.assert_search_results('MedicationDispenses',search_reply)

    puts 'Getting MedicationAdministration'
    search_reply = client.search(FHIR::MedicationAdministration, search: { parameters: { 'patient' => patient_id } })
    response.assert_search_results('MedicationAdministrations',search_reply)

    puts 'Getting Immunizations'
    search_reply = client.search(FHIR::Immunization, search: { parameters: { 'patient' => patient_id } })
    response.assert_search_results('Immunizations',search_reply)

    # Get the patient's allergies
    # There should be at least one. No known allergies should have a negated entry.
    # Include these codes as defined in http://snomed.info/sct
    #   Code	     Display
    #   160244002	No Known Allergies
    #   429625007	No Known Food Allergies
    #   409137002	No Known Drug Allergies
    #   428607008	No Known Environmental Allergy
    puts 'Getting AllergyIntolerances'
    search_reply = client.search(FHIR::AllergyIntolerance, search: { parameters: { 'patient' => patient_id } })
    response.assert_search_results('AllergyIntolerances',search_reply)
    begin
      if search_reply.resource.entry.length==0
        response.assert('No Known Allergies',false)
      else
        response.assert('No Known Allergies',:skip,'Skipped because AllergyIntolerances were found.')
      end
    rescue
      response.assert('No Known Allergies',false)
    end

    puts 'Getting Procedures'
    search_reply = client.search(FHIR::Procedure, search: { parameters: { 'patient' => patient_id } })
    response.assert_search_results('Procedures',search_reply)

    puts 'Getting Encounters'
    search_reply = client.search(FHIR::Encounter, search: { parameters: { 'patient' => patient_id } })
    response.assert_search_results('Encounters',search_reply)

    puts 'Getting FamilyMemberHistory'
    search_reply = client.search(FHIR::FamilyMemberHistory, search: { parameters: { 'patient' => patient_id } })
    response.assert_search_results('FamilyMemberHistory',search_reply)

    # Vital Signs Searching
    # Vital Signs includes these codes as defined in http://loinc.org
    vital_signs = {
      '9279-1' => 'Respiratory rate',
      '8867-4' => 'Heart rate',
      '2710-2' => 'Oxygen saturation in Capillary blood by Oximetry',
      '55284-4' => 'Blood pressure systolic and diastolic',
      '8480-6' => 'Systolic blood pressure',
      '8462-4' => 'Diastolic blood pressure',
      '8310-5' => 'Body temperature',
      '8302-2' => 'Body height',
      '8306-3' => 'Body height --lying',
      '8287-5' => 'Head Occipital-frontal circumference by Tape measure',
      '3141-9' => 'Body weight Measured',
      '39156-5' => 'Body mass index (BMI) [Ratio]',
      '3140-1' => 'Body surface area Derived from formula',
      '59408-5' => 'Oxygen saturation in Arterial blood by Pulse oximetry',
      '8478-0' => 'Mean blood pressure'
    }
    puts 'Getting Vital Signs / Observations'
    vital_signs.each do |code,display|
      search_reply = client.search(FHIR::Observation, search: { parameters: { 'patient' => patient_id, 'code' => "http://loinc.org|#{code}" } })
      response.assert_search_results("Vital Sign: #{display}",search_reply)
    end

    # DAF -----------------------------
#    # AllergyIntolerance
    # DiagnosticOrder
    # DiagnosticReport
#    # Encounter
#    # FamilyMemberHistory
#    # Immunization
    # Results (Observation)
    # Medication
#    # MedicationStatement
#    # MedicationAdministration
#    # MedicationDispense
#    # MedicationOrder
#    # Patient
#    # Condition
#    # Procedure
#    # SmokingStatus (Observation)
#    # VitalSigns (Observation)
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
#    # (8)	Problems	                 Condition
#    # (9)	Medications	                Medication, MedicationStatement, MedicationOrder
#    # (10)	Medication allergies	    AllergyIntolerance
    # (11)	Laboratory test(s)	      Observation, DiagnosticReport
    # (12)	Laboratory value(s)/result(s)	Observation, DiagnosticReport
#    # (13)	Vital signs	             Observation
    # (14)	(no longer required)	-
#    # (15)	Procedures	              Procedure
    # (16)	Care team member(s)	     CarePlan
#    # (17)	Immunizations	           Immunization
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
    # search_reply.resource.entry.each do |entry|
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
