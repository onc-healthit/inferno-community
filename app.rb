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


DataMapper.setup(:default, 'sqlite3:data/data.db')


['lib', 'models'].each do |dir|
  Dir.glob(File.join(File.dirname(File.absolute_path(__FILE__)),dir, '**','*.rb')).each do |file|
    require file
  end
end

#TODO clean up database stuff

DataMapper.finalize

# automatically create the post table
TestingInstance.auto_migrate!
TestingInstance.auto_upgrade!

SequenceResult.auto_migrate!
SequenceResult.auto_upgrade!

TestResult.auto_migrate!
TestResult.auto_upgrade!

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
  erb :details
end

post '/instance/?' do
  id = SecureRandom.uuid
  url = params['fhir_server']
  url = url.chomp('/') if url.end_with?('/')
  @instance = TestingInstance.new(id: id, created_at: DateTime.now, url: url, name: params['name'])
  @instance.save
  redirect "/instance/#{id}/"
end

get '/instance/:id/conformance_sequence/?' do
  @instance = TestingInstance.get(params[:id])
  client = FHIR::Client.new(@instance.url)

  # test that conformance is present and is DSTU2
  if client.conformance_statement.nil?
    conformance_present_result = TestResult.new(id: SecureRandom.uuid, name: 'Conformance Present', result: 'fail')
    conformance_dstu2_result = TestResult.new(id: SecureRandom.uuid, name: 'Conformance DSTU2', result: 'skip')
  else
    conformance_present_result = TestResult.new(id: SecureRandom.uuid, name: 'Conformance Present', result: 'pass')
    if client.conformance_statement.is_a?(FHIR::DSTU2::Conformance)
      conformance_dstu2_result = TestResult.new(id: SecureRandom.uuid, name: 'Conformance DSTU2', result: 'pass')
    else
      conformance_dstu2_result = TestResult.new(id: SecureRandom.uuid, name: 'Conformance DSTU2', result: 'fail')
    end
  end

  # store TestResult in SequenceResult
  conformance_sequence_result = SequenceResult.new(id: SecureRandom.uuid, name: "Conformance")
  conformance_sequence_result.test_results.push(conformance_present_result)
  conformance_sequence_result.test_results.push(conformance_dstu2_result)

  # store SequenceResult in TestingInstance
  @instance.sequence_results.push(conformance_sequence_result)
end

get '/instance/:id/redirect/:key/' do


end

get '/instance/:id/launch/:key/' do


end

# This is the primary endpoint of the app and the OAuth2 redirect URL
get '/app' do
if params['error']
  if params['error_uri']
    redirect params['error_uri']
  else
    response = Crucible::App::Html.new
    response.open.echo_hash('Invalid Launch!',params).close
  end
end
stream :keep_open do |out|
  response = Crucible::App::Html.new(out)
  if params['state'] != session[:state]
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
              The session state should also have been set at <span>/launch_ehr</span> with <span>client_id</span>, <span>token_url</span>, and <span>fhir_url</span> information.
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
    token = token_response['access_token']
    patient_id = token_response['patient']
    scopes = token_response['scope']
    if scopes.nil?
      scopes = Crucible::App::Config.get_scopes(session[:fhir_url])
    end

    # Begin outputting the response body
    response.open
    response.echo_hash('OAuth2 Redirect Parameters',params)
    response.echo_hash('Token Response',token_response)
    response.start_table('Crucible Test Results',['Status','Description','Detail'])

    # Configure the FHIR Client
    client = FHIR::Client.new(session[:fhir_url])
    version = client.detect_version
    client.set_bearer_token(token)
    client.default_json

    # All supporting resources
    if version == :dstu2
      klass_header = "FHIR::DSTU2::"
      conformance_klass = FHIR::DSTU2::Conformance
      supporting_resources = [
        FHIR::DSTU2::AllergyIntolerance, FHIR::DSTU2::CarePlan, FHIR::DSTU2::Condition,
        FHIR::DSTU2::DiagnosticOrder, FHIR::DSTU2::DiagnosticReport, FHIR::DSTU2::Encounter,
        FHIR::DSTU2::FamilyMemberHistory, FHIR::DSTU2::Goal, FHIR::DSTU2::Immunization,
        FHIR::DSTU2::List, FHIR::DSTU2::Procedure, FHIR::DSTU2::MedicationAdministration,
        FHIR::DSTU2::MedicationDispense, FHIR::DSTU2::MedicationOrder,
        FHIR::DSTU2::MedicationStatement, FHIR::DSTU2::Observation, FHIR::DSTU2::RelatedPerson
      ]
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
    elsif version == :stu3
      klass_header = "FHIR::"
      conformance_klass = FHIR::CapabilityStatement
      supporting_resources = [
        FHIR::AllergyIntolerance, FHIR::CarePlan, FHIR::CareTeam, FHIR::Condition, FHIR::Device,
        FHIR::DiagnosticReport, FHIR::Goal, FHIR::Immunization, FHIR::MedicationRequest,
        FHIR::MedicationStatement, FHIR::Observation, FHIR::Procedure, FHIR::RelatedPerson, FHIR::Specimen
      ]
      # Vital Signs includes these codes as defined in http://hl7.org/fhir/STU3/observation-vitalsigns.html
      vital_signs = {
        '85353-1' => 'Vital signs, weight, height, head circumference, oxygen saturation and BMI panel',
        '9279-1' => 'Respiratory Rate',
        '8867-4' => 'Heart rate',
        '59408-5' => 'Oxygen saturation in Arterial blood by Pulse oximetry',
        '8310-5' => 'Body temperature',
        '8302-2' => 'Body height',
        '8306-3' => 'Body height --lying',
        '8287-5' => 'Head Occipital-frontal circumference by Tape measure',
        '29463-7' => 'Body weight',
        '39156-5' => 'Body mass index (BMI) [Ratio]',
        '85354-9' => 'Blood pressure systolic and diastolic',
        '8480-6' => 'Systolic blood pressure',
        '8462-4' => 'Diastolic blood pressure'
      }
    end

    # Parse accessible resources from scopes
    accessible_resource_names = scopes.scan(/patient\/(.*?)\.[read|\*]/)
    accessible_resources = []
    if accessible_resource_names.include?(["*"])
      accessible_resources = supporting_resources.dup
    else
      accessible_resources = accessible_resource_names.map {|w| Object.const_get("#{klass_header}#{w.first}")}
    end

    # Get the conformance statement
    statement = client.conformance_statement
    response.assert('Conformance Successfully Retrieved',statement.is_a?(conformance_klass),statement.fhirVersion)
    statement_details = statement.to_hash

    puts "FHIR Version: #{statement_details['fhirVersion']}"

    # Get read capabilities
    readable_resource_names = []
    readable_resource_names = statement_details['rest'][0]['resource'].select {|r|
      r['interaction'].include?({"code"=>"read"})
    }.map {|n| n['type']}

    # Get the patient demographics
    patient_read_response = client.read(Object.const_get("#{klass_header}Patient"), patient_id)
    patient = patient_read_response.resource
    is_patient = patient.is_a?(Object.const_get("#{klass_header}Patient"))
    response.assert('Patient Successfully Retrieved',is_patient,"HTTP #{patient_read_response.code} Patient/#{patient_id}")
    if is_patient
      patient_details = patient.to_hash
      puts "Patient: #{patient_details['id']} #{patient_details['name']}"

      # DAF/US-Core CCDS
      response.assert('Patient Name',patient_details['name'],patient_details['name'])
      response.assert('Patient Gender',patient_details['gender'],patient_details['gender'])
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
    else
      response.assert('Patient Name',:skip,'Unable to access patient demographics.')
      response.assert('Patient Gender',:skip,'Unable to access patient demographics.')
      response.assert('Patient Date of Birth',:skip,'Unable to access patient demographics.')
      response.assert('Patient Race',:skip,'Unable to access patient demographics.')
      response.assert('Patient Ethnicity',:skip,'Unable to access patient demographics.')
      response.assert('Patient Preferred Language',:skip,'Unable to access patient demographics.')
    end
    # Get the patient's smoking status
    # {"coding":[{"system":"http://loinc.org","code":"72166-2"}]}
    puts 'Getting Smoking Status'
    search_reply = client.search(Object.const_get("#{klass_header}Observation"), search: { parameters: { 'patient' => patient_id, 'code' => 'http://loinc.org|72166-2'}})
    search_reply_length = search_reply.try(:resource).try(:entry).try(:length)
    unless search_reply_length.nil?
      if accessible_resources.include?(Object.const_get("#{klass_header}Observation")) # If resource is in scopes
        if search_reply_length == 0
          if readable_resource_names.include?("Observation")
            response.assert("Smoking Status",:not_found)
          else
            response.assert("Smoking Status",:skip,"Read capability for resource not in conformance statement.")
          end
        elsif search_reply_length > 0
          response.assert("Smoking Status",true,(search_reply.resource.entry.first.to_fhir_json rescue nil))
        else
          if readable_resource_names.include?("Observation") # If comformance claims read capability for resource
            response.assert("Smoking Status",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
          else
            response.assert("Smoking Status",:skip,"Read capability for resource not in conformance statement.")
          end
        end
      else # If resource is not in scopes
        if search_reply_length > 0
          response.assert("Smoking Status",false,"Resource provided without required scopes.")
        else
          response.assert("Smoking Status",:skip,"Access not granted through scopes.")
        end
      end
    else
      if readable_resource_names.include?("Observation") # If comformance claims read capability for resource
        response.assert("Smoking Status",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
      else
        response.assert("Smoking Status",:skip,"Read capability for resource not in conformance statement.")
      end
    end

    # Get the patient's allergies
    # There should be at least one. No known allergies should have a negated entry.
    # Include these codes as defined in http://snomed.info/sct
    #   Code	     Display
    #   160244002	No Known Allergies
    #   429625007	No Known Food Allergies
    #   409137002	No Known Drug Allergies
    #   428607008	No Known Environmental Allergy
    puts 'Getting AllergyIntolerances'
    search_reply = client.search(Object.const_get("#{klass_header}AllergyIntolerance"), search: { parameters: { 'patient' => patient_id } })
    search_reply_length = search_reply.try(:resource).try(:entry).try(:length)
    unless search_reply_length.nil?
      if accessible_resources.include?(Object.const_get("#{klass_header}AllergyIntolerance")) # If resource is in scopes
        if search_reply_length == 0
          if readable_resource_names.include?("AllergyIntolerance")
            response.assert("AllergyIntolerances",false,"No Known Allergies.");
          else
            response.assert("AllergyIntolerances",:skip,"Read capability for resource not in conformance statement.")
          end
        elsif search_reply_length > 0
          response.assert("AllergyIntolerances",true,"Found #{search_reply_length} AllergyIntolerance.")
        else
          if readable_resource_names.include?("AllergyIntolerance") # If comformance claims read capability for resource
            response.assert("AllergyIntolerances",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
          else
            response.assert("AllergyIntolerances",:skip,"Read capability for resource not in conformance statement.")
          end
        end
      else # If resource is not in scopes
        if search_reply_length > 0
          response.assert("AllergyIntolerances",false,"Resource provided without required scopes.")
        else
          response.assert("AllergyIntolerances",:skip,"Access not granted through scopes.")
        end
      end
    else
      if readable_resource_names.include?("AllergyIntolerance") # If comformance claims read capability for resource
        response.assert("AllergyIntolerances",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
      else
        response.assert("AllergyIntolerances",:skip,"Read capability for resource not in conformance statement.")
      end
    end

    puts 'Getting Vital Signs / Observations'
    vital_signs.each do |code,display|
      search_reply = client.search(Object.const_get("#{klass_header}Observation"), search: { parameters: { 'patient' => patient_id, 'code' => "http://loinc.org|#{code}" } })
      search_reply_length = search_reply.try(:resource).try(:entry).try(:length)
      unless search_reply_length.nil?
        if accessible_resources.include?(Object.const_get("#{klass_header}Observation")) # If resource is in scopes
          if search_reply_length == 0
            if readable_resource_names.include?("Observation")
              response.assert("Vital Sign: #{display}",:not_found)
            else
              response.assert("Vital Sign: #{display}",:skip,"Read capability for resource not in conformance statement.")
            end
          elsif search_reply_length > 0
            response.assert("Vital Sign: #{display}",true,"Found #{search_reply_length} Vital Sign: #{display}.")
          else
            if readable_resource_names.include?("Observation") # If comformance claims read capability for resource
              response.assert("Vital Sign: #{display}",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
            else
              response.assert("Vital Sign: #{display}",:skip,"Read capability for resource not in conformance statement.")
            end
          end
        else # If resource is not in scopes
          if search_reply_length > 0
            response.assert("Vital Sign: #{display}",false,"Resource provided without required scopes.")
          else
            response.assert("Vital Sign: #{display}",:skip,"Access not granted through scopes.")
          end
        end
      else
        if readable_resource_names.include?("Observation") # If comformance claims read capability for resource
          response.assert("Vital Sign: #{display}",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
        else
          response.assert("Vital Sign: #{display}",:skip,"Read capability for resource not in conformance statement.")
        end
      end
    end

    puts 'Checking for Supporting Resources'
    supporting_resources.each do |klass|
      unless [Object.const_get("#{klass_header}AllergyIntolerance"), Object.const_get("#{klass_header}Observation")].include?(klass) # Do not test for AllergyIntolerance or Observation
        puts "Getting #{klass.name.demodulize}s"
        search_reply = client.search(klass, search: { parameters: { 'patient' => patient_id } })
        search_reply_length = search_reply.try(:resource).try(:entry).try(:length)
        unless search_reply_length.nil?
          if accessible_resources.include?(klass) # If resource is in scopes
            if search_reply_length == 0
              if readable_resource_names.include?(klass.name.demodulize)
                response.assert("#{klass.name.demodulize}s",:not_found)
              else
                response.assert("#{klass.name.demodulize}s",:skip,"Read capability for resource not in conformance statement.")
              end
            elsif search_reply_length > 0
              response.assert("#{klass.name.demodulize}s",true,"Found #{search_reply_length} #{klass.name.demodulize}.")
            else
              if readable_resource_names.include?(klass.name.demodulize) # If comformance claims read capability for resource
                response.assert("#{klass.name.demodulize}s",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
              else
                response.assert("#{klass.name.demodulize}s",:skip,"Read capability for resource not in conformance statement.")
              end
            end
          else # If resource is not in scopes
            if search_reply_length > 0
              response.assert("#{klass.name.demodulize}s",false,"Resource provided without required scopes.")
            else
              response.assert("#{klass.name.demodulize}s",:skip,"Access not granted through scopes.")
            end
          end
        else
          if readable_resource_names.include?(klass.name.demodulize) # If comformance claims read capability for resource
            response.assert("#{klass.name.demodulize}s",false,"HTTP Status #{search_reply.code}&nbsp;#{search_reply.body}")
          else
            response.assert("#{klass.name.demodulize}s",:skip,"Read capability for resource not in conformance statement.")
          end
        end
      end
    end

    # DAF (DSTU2)-----------------------------
#    # AllergyIntolerance
#    # DiagnosticOrder
#    # DiagnosticReport
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
#    # Additional Resources: RelatedPerson, Specimen

    # US Core (STU3)-----------------------------
    # AllergyIntolerance
    # CareTeam
    # Condition
    # Device
    # DiagnosticReport
    # Goal
    # Immunization
    # Location (can't search by patient)
    # Medication (can't search by patient)
    # MedicationRequest
    # MedicationStatement
    # Practitioner (can't search by patient)
    # Procedure
    # Results (Observation)
    # SmokingStatus (Observation
    # CarePlan
    # Organization (can't search by patient)
    # Patient
    # VitalSigns (Observation)
    # Additional Resources: RelatedPerson, Specimen

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
#    # (11)	Laboratory test(s)	      Observation, DiagnosticReport
#    # (12)	Laboratory value(s)/result(s)	Observation, DiagnosticReport
#    # (13)	Vital signs	             Observation
    # (14)	(no longer required)	-
#    # (15)	Procedures	              Procedure
#    # (16)	Care team member(s)	     CarePlan
#    # (17)	Immunizations	           Immunization
    # (18)	Unique device identifier(s) for a patient’s implantable device(s)	Device
#    # (19)	Assessment and plan of treatment	CarePlan
#    # (20)	Goals	                   Goal
#    # (21)	Health concerns	         Condition
    # --------------------------------
    # Date range search requirements are included in the Quick Start section for the following resources -
    # Vital Signs, Laboratory Results, Goals, Procedures, and Assessment and Plan of Treatment.

    # Output a summary
    total = response.pass + response.not_found + response.skip + response.fail
    response.assert("#{((response.pass.to_f / total.to_f)*100.0).round}% (#{response.pass} of #{total})",true,'Total tests passed')
    response.assert("#{((response.not_found.to_f / total.to_f)*100.0).round}% (#{response.not_found} of #{total})",:not_found,'Total tests "not found" or inconclusive')
    response.assert("#{((response.skip.to_f / total.to_f)*100.0).round}% (#{response.skip} of #{total})",:skip,'Total tests skipped')
    response.assert("#{((response.fail.to_f / total.to_f)*100.0).round}% (#{response.fail} of #{total})",false,'Total tests failed')
    response.end_table

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

# This is the EHR launch URI that redirects to an Authorization server
get '/launch_ehr' do
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
    message = 'The <span>/launch_ehr</span> endpoint requires <span>iss</span> and <span>launch</span> parameters.
              <br/>&nbsp;<br/>
               Please read the <a href="http://docs.smarthealthit.org/authorization/">SMART "launch sequence"</a> for more information.'
    response.assert('OAuth2 Launch Parameters',false,message).end_table
    body response.instructions.close
  end
end

get '/launch_sa' do
  response = Crucible::App::Html.new
  response.open
  response.instructions_standalone
  fields = { 'Endpoint URL' => '', 'Client ID' => '', 'Scopes' => 'launch/patient patient/*.read openid profile'}
  response.add_form('Standalone Launch','/launch_sa',fields)
  body response.close
end

# This is the standalone launch URI that redirects to an Authorization server
post '/launch_sa' do
  if params && params['Endpoint URL'] && params['Client ID'] && params['Scopes']
    client_id = params['Client ID']
    auth_info = Crucible::App::Config.get_auth_info(params['Endpoint URL'])
    session[:client_id] = client_id
    session[:fhir_url] = params['Endpoint URL']
    session[:authorize_url] = auth_info[:authorize_url]
    session[:token_url] = auth_info[:token_url]
    puts "Launch Client ID: #{client_id}\nLaunch Auth Info: #{auth_info}\nLaunch Redirect: #{Crucible::App::Config::CONFIGURATION['redirect_url']}"
    session[:state] = SecureRandom.uuid
    oauth2_params = {
      'response_type' => 'code',
      'client_id' => client_id,
      'redirect_uri' => Crucible::App::Config::CONFIGURATION['redirect_url'],
      'scope' => params['Scopes'],
      'state' => session[:state],
      'aud' => params['Endpoint URL']
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
    message = 'The <span>/launch_sa</span> endpoint requires <span>Endpoint URL</span>, <span>Client ID</span>, and <span>Scopes</span> parameters.
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
