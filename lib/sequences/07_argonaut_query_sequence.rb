class ArgonautDataQuerySequence < SequenceBase

  title 'Argonaut Data Query'

  description 'The FHIR server properly follows the Argonaut Data Query Implementation Guide Server.'

  preconditions 'Client must be authorized.' do
    !@instance.token.nil?
  end

  def get_resource_by_params(klass, params = {})
    assert !params.empty?, "No params for search"
    options = {
      :search => {
        :flag => false,
        :compartment => nil,
        :parameters => params
      }
    }
    @client.search(klass, options)
  end

  def validate_search_reply(klass, reply)
    assert_response_ok(reply)
    assert_bundle_response(reply)

    entries = reply.resource.entry.select{ |entry| entry.resource.class == klass }

    assert entries.length > 0, 'No resources of this type were returned'

    if klass == FHIR::DSTU2::Patient
      assert !reply.resource.get_by_id(@instance.patient_id).nil?, 'Server returned nil patient'
      assert reply.resource.get_by_id(@instance.patient_id).equals?(@patient, ['_id', "text", "meta", "lastUpdated"]), 'Server returned wrong patient'
    elsif [FHIR::DSTU2::CarePlan, FHIR::DSTU2::Goal, FHIR::DSTU2::DiagnosticReport, FHIR::DSTU2::Observation, FHIR::DSTU2::Procedure].include?(klass)
      entries.each do |entry|
        assert (entry.resource.subject && entry.resource.subject.reference.include?(@instance.patient_id)), "Subject on resource does not match patient requested"
      end
    else
      entries.each do |entry|
        assert (entry.resource.patient && entry.resource.patient.reference.include?(@instance.patient_id)), "Patient on resource does not match patient requested"
      end
    end
  end

  def validate_read_reply(resource, klass)
    assert !resource.nil?, "Expected valid #{klass} resource to be present"
    id = resource.try(:id)
    assert !id.nil?, "#{klass} id not returned"
    read_response = @client.read(klass, id)
    assert_response_ok read_response
    assert !read_response.resource.nil?, "Expected valid #{klass} resource to be present"
    assert read_response.resource.is_a?(klass), "Expected resource to be valid #{klass}"
  end

  # --------------------------------------------------
  # Patient Search
  # --------------------------------------------------

  test 'Patient read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    patient_read_response = @client.read(FHIR::DSTU2::Patient, @instance.patient_id)
    assert_response_ok patient_read_response
    @patient = patient_read_response.resource
    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert @patient.is_a?(FHIR::DSTU2::Patient), 'Expected resource to be valid DSTU2 Patient'

  end

  test 'Patient history and vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support. ' do

    todo

  end

  test 'Patient search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Patient search does not work without proper authorization' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    identifier = @patient.try(:identifier).try(:first).try(:value)
    assert !identifier.nil?, "Patient identifier not returned"
    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Patient, {identifier: identifier})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'Patient search by identifier',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters: identifier' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    identifier = @patient.try(:identifier).try(:first).try(:value)
    assert !identifier.nil?, "Patient identifier not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Patient, {identifier: identifier})
    validate_search_reply(FHIR::DSTU2::Patient, reply)

  end

  test 'Patient search by name + gender',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    family = @patient.try(:name).try(:first).try(:family).try(:first)
    assert !family.nil?, "Patient family name not returned"
    given = @patient.try(:name).try(:first).try(:given).try(:first)
    assert !given.nil?, "Patient given name not returned"
    gender = @patient.try(:gender)
    assert !gender.nil?, "Patient gender not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Patient, {family: family, given: given, gender: gender})
    validate_search_reply(FHIR::DSTU2::Patient, reply)

  end

  test 'Patient search by name + birthdate',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    family = @patient.try(:name).try(:first).try(:family).try(:first)
    assert !family.nil?, "Patient family name not returned"
    given = @patient.try(:name).try(:first).try(:given).try(:first)
    assert !given.nil?, "Patient given name not returned"
    birthdate = @patient.try(:birthDate)
    assert !birthdate.nil?, "Patient birthDate not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Patient, {family: family, given: given, birthdate: birthdate})
    validate_search_reply(FHIR::DSTU2::Patient, reply)

  end

  test 'Patient search by gender + birthdate',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    gender = @patient.try(:gender)
    assert !gender.nil?, "Patient gender not returned"
    birthdate = @patient.try(:birthDate)
    assert !birthdate.nil?, "Patient birthDate not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Patient, {gender: gender, birthdate: birthdate})
    validate_search_reply(FHIR::DSTU2::Patient, reply)

  end

  # --------------------------------------------------
  # AllergyIntolerance Search
  # --------------------------------------------------

  test 'AllergyIntolerance search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'An AllergyIntolerance search does not work without proper authorization' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::AllergyIntolerance, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'AllergyIntolerance search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning a patient’s allergies using GET /AllergyIntolerance?patient=[id]' do

    reply = get_resource_by_params(FHIR::DSTU2::AllergyIntolerance, {patient: @instance.patient_id})
    @allergyintolerance = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::AllergyIntolerance, reply)

  end

  test 'AllergyIntolerance read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    validate_read_reply(@allergyintolerance, FHIR::DSTU2::AllergyIntolerance)

  end

  test 'AllergyIntolerance history and vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support. ' do

    todo

  end


  # --------------------------------------------------
  # CarePlan Search
  # --------------------------------------------------

  test 'CarePlan search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A CarePlan search does not work without proper authorization' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'CarePlan search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all of a patient’s Assessment and Plan of Treatment information using GET /CarePlan?patient=[id]&category=assess-plan' do

    reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan"})
    @careplan = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::CarePlan, reply)

  end

  test 'CarePlan search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable of returning a patient’s Assessment and Plan of Treatment information over a specified time period using GET /CarePlan?patient=[id]&category=assess-plan&date=[date]' do

    warning {
      assert !@careplan.nil?, 'Expected valid DSTU2 CarePlan resource to be present'
      date = @careplan.try(:period).try(:end)
      assert !date.nil?, "CarePlan period end not returned"
      reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan", date: date})
      validate_search_reply(FHIR::DSTU2::CarePlan, reply)
    }

  end

  test 'CarePlan search by patient + category + status',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patient’s active Assessment and Plan of Treatment information using GET /CarePlan?patient=[id]&category=assess-plan&status=active' do

    warning {
      reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan", status: "active"})
      validate_search_reply(FHIR::DSTU2::CarePlan, reply)
    }

  end

  test 'CarePlan search by patient + category + status + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning a patients active Assessment and Plan of Treatment information over a specified time period using GET /CarePlan?patient=[id]&category=assess-plan&status=active&date=[date]' do

    warning {
      assert !@careplan.nil?, 'Expected valid DSTU2 CarePlan resource to be present'
      date = @careplan.try(:period).try(:end)
      assert !date.nil?, "CarePlan period end not returned"
      reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan", status: "active", date: date})
      validate_search_reply(FHIR::DSTU2::CarePlan, reply)
    }

  end

  test 'CarePlan read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    validate_read_reply(@careplan, FHIR::DSTU2::CarePlan)

  end

  test 'CarePlan history and vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support. ' do

    todo

  end


  # --------------------------------------------------
  # Condition Search
  # --------------------------------------------------

  test 'Condition search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Condition search does not work without proper authorization' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'Condition search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning a patients conditions list using GET/Condition?patient=[id]' do

    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id})
    @condition = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Condition, reply)

  end

  test 'Condition search by patient + clinicalstatus',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patients active problems and health concerns using ‘GET /Condition?patient=[id]&clinicalstatus=active,recurrance,remission' do

    warning {
      reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, clinicalstatus: "active,recurrance,remission"})
      validate_search_reply(FHIR::DSTU2::Condition, reply)
    }

  end

  test 'Condition search by patient + problem category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patients problems or all of patients health concerns using ‘GET /Condition?patient=[id]&category=[problem|health-concern]' do

    warning {
      reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, category: "problem"})
      validate_search_reply(FHIR::DSTU2::Condition, reply)
    }

  end

  test 'Condition search by patient + health-concern category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patients problems or all of patients health concerns using ‘GET /Condition?patient=[id]&category=[problem|health-concern]' do

    warning {
      reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, category: "health-concern"})
      validate_search_reply(FHIR::DSTU2::Condition, reply)
    }

  end

  test 'Condition read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    validate_read_reply(@condition, FHIR::DSTU2::Condition)

  end

  test 'Condition history and vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support. ' do

    todo

  end


  # --------------------------------------------------
  # Device Search
  # --------------------------------------------------

  test 'Device search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Device search does not work without proper authorization' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Device, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'Device search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all Unique device identifier(s)(UDI) for a patient’s implanted device(s) using GET /Device?patient=[id]' do

    reply = get_resource_by_params(FHIR::DSTU2::Device, {patient: @instance.patient_id})
    @device = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Device, reply)

  end

  test 'Device read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    validate_read_reply(@device, FHIR::DSTU2::Device)

  end

  test 'Device history and vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support. ' do

    todo

  end


  # --------------------------------------------------
  # Goal Search
  # --------------------------------------------------

  test 'Goal search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Goal search does not work without proper authorization' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Goal, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'Goal search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all of a patient’s goals using GET [base]/Goal?patient=[id]' do

    reply = get_resource_by_params(FHIR::DSTU2::Goal, {patient: @instance.patient_id})
    @goal = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Goal, reply)

  end

  test 'Goal search by patient + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all of all of a patient’s goals over a specified time period using GET [base]/Goal?patient=[id]&date=[date]{&date=[date]}' do

    assert !@goal.nil?, 'Expected valid DSTU2 Goal resource to be present'
    date = @goal.try(:statusDate)
    assert !date.nil?, "Goal statusDate not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Goal, {patient: @instance.patient_id, date: date})
    validate_search_reply(FHIR::DSTU2::Goal, reply)

  end

  test 'Goal read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    validate_read_reply(@goal, FHIR::DSTU2::Goal)

  end

  test 'Goal history and vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support. ' do

    todo

  end


  # --------------------------------------------------
  # Immunization Search
  # --------------------------------------------------

  test 'Immunization search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'An Immunization search does not work without proper authorization' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Immunization, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'Immunization search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A client has connected to a server and fetched all immunizations for a patient using GET /Immunization?patient=[id]' do

    reply = get_resource_by_params(FHIR::DSTU2::Immunization, {patient: @instance.patient_id})
    @immunization = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Immunization, reply)

  end

  test 'Immunization read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    validate_read_reply(@immunization, FHIR::DSTU2::Immunization)

  end

  test 'Immunization history and vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support. ' do

    todo

  end


  # --------------------------------------------------
  # DiagnosticReport Search
  # --------------------------------------------------

  test 'DiagnosticReport search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A DiagnosticReport search does not work without proper authorization' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'DiagnosticReport search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all of a patient’s laboratory diagnostic reports queried by category using GET [base]/DiagnosticReport?patient=[id]&category=LAB' do

    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB"})
    @diagnosticreport = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)

  end

  test 'DiagnosticReport search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all of a patient’s laboratory diagnostic reports queried by category code and date range using GET [base]/DiagnosticReport?patient=[id]&category=LAB&date=[date]{&date=[date]}' do

    assert !@diagnosticreport.nil?, 'Expected valid DSTU2 DiagnosticReport resource to be present'
    date = @diagnosticreport.try(:effectiveDateTime)
    assert !date.nil?, "DiagnosticReport effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB", date: date})
    validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)

  end

  test 'DiagnosticReport search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all of a patient’s laboratory diagnostic reports queried by category and code using GET [base]/DiagnosticReport?patient=[id]&category=LAB&code=[LOINC]' do

    assert !@diagnosticreport.nil?, 'Expected valid DSTU2 DiagnosticReport resource to be present'
    code = @diagnosticreport.try(:code).try(:text)
    assert !code.nil?, "DiagnosticReport code not returned"
    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB", code: code})
    validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)

  end

  test 'DiagnosticReport search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable of returning all of a patient’s laboratory diagnostic reports queried by category and one or more codes and date range using GET [base]/DiagnosticReport?patient=[id]&category=LAB&code=[LOINC1{,LOINC2,LOINC3,…}]&date=[date]{&date=[date]}' do

    warning {
      assert !@diagnosticreport.nil?, 'Expected valid DSTU2 DiagnosticReport resource to be present'
      code = @diagnosticreport.try(:code).try(:text)
      assert !code.nil?, "DiagnosticReport code not returned"
      date = @diagnosticreport.try(:effectiveDateTime)
      assert !date.nil?, "DiagnosticReport effectiveDateTime not returned"
      reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB", code: code, date: date})
      validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)
    }

  end

  test 'DiagnosticReport read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    validate_read_reply(@diagnosticreport, FHIR::DSTU2::DiagnosticReport)

  end

  test 'DiagnosticReport history and vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support. ' do

    todo

  end

  # --------------------------------------------------
  # MedicationStatement Search
  # --------------------------------------------------

  test 'MedicationStatement search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'An MedicationStatement search does not work without proper authorization' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::MedicationStatement, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'MedicationStatement search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning a patient’s medications using one of or both 1. GET /MedicationStatement?patient=[id] 2. GET /MedicationStatement?patient=[id]&_include=MedicationStatement:medication' do

    reply = get_resource_by_params(FHIR::DSTU2::MedicationStatement, {patient: @instance.patient_id})
    @medicationstatement = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::MedicationStatement, reply)

  end

  test 'MedicationStatement read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    validate_read_reply(@medicationstatement, FHIR::DSTU2::MedicationStatement)

  end

  test 'MedicationStatement history and vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support. ' do

    todo

  end


  # --------------------------------------------------
  # MedicationOrder Search
  # --------------------------------------------------

  test 'MedicationOrder search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'An MedicationOrder search does not work without proper authorization' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::MedicationOrder, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'MedicationOrder search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning a patient’s medications using one of or both 1. GET /MedicationOrder?patient=[id] 2. GET /MedicationOrder?patient=[id]&_include=MedicationOrder:medication' do

    reply = get_resource_by_params(FHIR::DSTU2::MedicationOrder, {patient: @instance.patient_id})
    @medicationorder = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::MedicationOrder, reply)

  end

  test 'MedicationOrder read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    validate_read_reply(@medicationorder, FHIR::DSTU2::MedicationOrder)

  end

  test 'MedicationOrder history and vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support. ' do

    todo

  end


  # --------------------------------------------------
  # Observation Search
  # --------------------------------------------------

  test 'Observation Results search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'An Observation Results search does not work without proper authorization' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'Observation Results search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory results queried by category using GET [base]/Observation?patient=[id]&category=laboratory" do

    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory"})
    @observationresults = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test 'Observation Results search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory results queried by category code and date range usingGET [base]/Observation?patient=[id]&category=laboratory&date=[date]{&date=[date]}" do

    assert !@observationresults.nil?, 'Expected valid DSTU2 Observation resource to be present'
    date = @observationresults.try(:effectiveDateTime)
    assert !date.nil?, "Observation effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory", date: date})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test 'Observation Results search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory results queried by category and code using GET [base]/Observation?patient=[id]&category=laboratory&code=[LOINC]" do

    assert !@observationresults.nil?, 'Expected valid DSTU2 Observation resource to be present'
    code = @observationresults.try(:code).try(:coding).try(:first).try(:code)
    assert !code.nil?, "Observation code not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory", code: code})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test 'Observation Results search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable of returning all of a patient's laboratory results queried by category and one or more codes and date range using GET [base]/Observation?patient=[id]&category=laboratory&code=[LOINC1{,LOINC2,LOINC3,...}]&date=[date]{&date=[date]}" do

    warning {
      assert !@observationresults.nil?, 'Expected valid DSTU2 Observation resource to be present'
      code = @observationresults.try(:code).try(:coding).try(:first).try(:code)
      assert !code.nil?, "Observation code not returned"
      date = @observationresults.try(:effectiveDateTime)
      assert !date.nil?, "Observation effectiveDateTime not returned"
      reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory", code: code, date: date})
      validate_search_reply(FHIR::DSTU2::Observation, reply)
    }

  end

  test 'Smoking Status search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Smoking Status search does not work without proper authorization' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, code: "72166-2"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'Smoking Status search by patient + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning a a patient’s smoking status using GET [base]/Observation?patient=[id]&code=72166-2" do

    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, code: "72166-2"})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test 'Vital Signs search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Vital Signs search does not work without proper authorization' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'Vital Signs search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient’s vital signs that it supports using GET [base]/Observation?patient=[id]&category=vital-signs" do

    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs"})
    @vitalsigns = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test 'Vital Signs search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient’s vital signs queried by date range using GET [base]/Observation?patient=[id]&category=vital-signs&date=[date]{&date=[date]}" do

    assert !@vitalsigns.nil?, 'Expected valid DSTU2 Observation resource to be present'
    date = @vitalsigns.try(:effectiveDateTime)
    assert !date.nil?, "Observation effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs", date: date})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test 'Vital Signs search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning any of a patient’s vital signs queried by one or more of the codes listed below using GET [base]/Observation?patient=[id]&code[vital sign LOINC{,LOINC2,LOINC3,…}]" do

    assert !@vitalsigns.nil?, 'Expected valid DSTU2 Observation resource to be present'
    code = @vitalsigns.try(:code).try(:coding).try(:first).try(:code)
    assert !code.nil?, "Observation code not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs", code: code})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test 'Vital Signs search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable of returning any of a patient’s vital signs queried by one or more of the codes listed below and date range using GET [base]/Observation?patient=[id]&code=[LOINC{,LOINC2…}]vital-signs&date=[date]{&date=[date]}" do

    warning {
      assert !@vitalsigns.nil?, 'Expected valid DSTU2 Observation resource to be present'
      code = @vitalsigns.try(:code).try(:coding).try(:first).try(:code)
      assert !code.nil?, "Observation code not returned"
      date = @vitalsigns.try(:effectiveDateTime)
      assert !date.nil?, "Observation effectiveDateTime not returned"
      reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs", code: code, date: date})
      validate_search_reply(FHIR::DSTU2::Observation, reply)
    }

  end

  test 'Observation read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    validate_read_reply(@observationresults, FHIR::DSTU2::Observation)

  end

  test 'Observation history and vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support. ' do

    todo

  end

  # --------------------------------------------------
  # Procedure Search
  # --------------------------------------------------

  test 'Procedure search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Procedure search does not work without proper authorization' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Procedure, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'Procedure search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning a patient’s procedures using GET/Procedure?patient=[id]' do

    reply = get_resource_by_params(FHIR::DSTU2::Procedure, {patient: @instance.patient_id})
    @procedure = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Procedure, reply)

  end

  test 'Procedure search by patient + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all of all of a patient’s procedures over a specified time period using GET /Procedure?patient=[id]&date=[date]{&date=[date]}' do

    assert !@procedure.nil?, 'Expected valid DSTU2 Procedure resource to be present'
    date = @procedure.try(:performedDateTime)
    assert !date.nil?, "Procedure performedDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Procedure, {patient: @instance.patient_id, date: date})
    validate_search_reply(FHIR::DSTU2::Procedure, reply)

  end

  test 'Procedure read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    validate_read_reply(@procedure, FHIR::DSTU2::Procedure)

  end

  test 'Procedure history and vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support. ' do

    todo

  end

end
