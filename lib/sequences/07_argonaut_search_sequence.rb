class ArgonautSearchSequence < SequenceBase

  title 'Argonaut Search'

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

  def validate_reply(klass, reply)
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

  # --------------------------------------------------
  # Patient Search
  # --------------------------------------------------

  test 'Has Patient resource',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning a patient using GET [base]/Patient/[id]' do

    patient_read_response = @client.read(FHIR::DSTU2::Patient, @instance.patient_id)
    assert_response_ok patient_read_response
    @patient = patient_read_response.resource
    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    @patient_hash = @patient.to_hash
    assert @patient.is_a?(FHIR::DSTU2::Patient), 'Expected resource to be valid DSTU2 Patient'

  end

  test 'Patient search by identifier',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters: identifier' do

    assert !(@patient_hash.nil? || @patient_hash.empty?), 'No Patient resource available'
    identifier = @patient_hash['identifier'][0]['value'] rescue nil
    assert identifier, "Patient identifier not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Patient, {identifier: identifier})
    validate_reply(FHIR::DSTU2::Patient, reply)

  end

  test 'Patient search by name + gender',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate' do

    assert !(@patient_hash.nil? || @patient_hash.empty?), 'No Patient resource available'
    family = @patient_hash['name'][0]['family'][0] rescue nil
    assert family, "Patient family name not returned"
    given = @patient_hash['name'][0]['given'][0] rescue nil
    assert given, "Patient given name not returned"
    gender = @patient_hash['gender'] rescue nil
    assert gender, "Patient gender not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Patient, {family: family, given: given, gender: gender})
    validate_reply(FHIR::DSTU2::Patient, reply)

  end

  test 'Patient search by name + birthdate',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate' do

    assert !(@patient_hash.nil? || @patient_hash.empty?), 'No Patient resource available'
    family = @patient_hash['name'][0]['family'][0] rescue nil
    assert family, "Patient family name not returned"
    given = @patient_hash['name'][0]['given'][0] rescue nil
    assert given, "Patient given name not returned"
    birthdate = @patient_hash['birthDate'] rescue nil
    assert birthdate, "Patient birthDate not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Patient, {family: family, given: given, birthdate: birthdate})
    validate_reply(FHIR::DSTU2::Patient, reply)

  end

  test 'Patient search by gender + birthdate',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate' do

    assert !(@patient_hash.nil? || @patient_hash.empty?), 'No Patient resource available'
    gender = @patient_hash['gender'] rescue nil
    assert gender, "Patient gender not returned"
    birthdate = @patient_hash['birthDate'] rescue nil
    assert birthdate, "Patient birthDate not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Patient, {gender: gender, birthdate: birthdate})
    validate_reply(FHIR::DSTU2::Patient, reply)

  end

  # --------------------------------------------------
  # AllergyIntolerance Search
  # --------------------------------------------------

  test 'AllergyIntolerance search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning a patient’s allergies using GET /AllergyIntolerance?patient=[id]' do

    reply = get_resource_by_params(FHIR::DSTU2::AllergyIntolerance, {patient: @instance.patient_id})
    @allergyintolerance_hash = reply.resource.entry[0].to_hash rescue []
    validate_reply(FHIR::DSTU2::AllergyIntolerance, reply)

  end

  # --------------------------------------------------
  # CarePlan Search
  # --------------------------------------------------

  test 'CarePlan search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all of a patient’s Assessment and Plan of Treatment information using GET /CarePlan?patient=[id]&category=assess-plan' do

    reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan"})
    @careplan_hash = reply.resource.entry[0].resource.to_hash rescue []
    validate_reply(FHIR::DSTU2::CarePlan, reply)

  end

  test 'CarePlan search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable of returning a patient’s Assessment and Plan of Treatment information over a specified time period using GET /CarePlan?patient=[id]&category=assess-plan&date=[date]' do

    warning {
      assert !(@careplan_hash.nil? || @careplan_hash.empty?), 'No CarePlan resource available'
      date = @careplan_hash['period']['end'] rescue nil
      assert date, "CarePlan period end not returned"
      reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan", date: date})
      validate_reply(FHIR::DSTU2::CarePlan, reply)
    }

  end

  test 'CarePlan search by patient + category + status',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patient’s active Assessment and Plan of Treatment information using GET /CarePlan?patient=[id]&category=assess-plan&status=active' do

    warning {
      assert !(@careplan_hash.nil? || @careplan_hash.empty?), 'No CarePlan resource available'
      reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan", status: "active"})
      validate_reply(FHIR::DSTU2::CarePlan, reply)
    }

  end

  test 'CarePlan search by patient + category + status + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning a patient’s active Assessment and Plan of Treatment information over a specified time period using GET /CarePlan?patient=[id]&category=assess-plan&status=active&date=[date]' do

    warning {
      assert !(@careplan_hash.nil? || @careplan_hash.empty?), 'No CarePlan resource available'
      date = @careplan_hash['period']['end'] rescue nil
      assert date, "CarePlan period end not returned"
      reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan", status: "active", date: date})
      validate_reply(FHIR::DSTU2::CarePlan, reply)
    }

  end

  # --------------------------------------------------
  # Condition Search
  # --------------------------------------------------

  test 'Condition search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning a patient’s conditions list using GET/Condition?patient=[id]' do

    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id})
    @condition_hash = reply.resource.entry[0].resource.to_hash rescue []
    validate_reply(FHIR::DSTU2::Condition, reply)

  end

  test 'Condition search by patient + clinicalstatus',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patient’s active problems and health concerns using ‘GET /Condition?patient=[id]&clinicalstatus=active,recurrance,remission' do

    warning {
      assert !(@condition_hash.nil? || @condition_hash.empty?), 'No Condition resource available'
      reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, clinicalstatus: "active,recurrance,remission"})
      validate_reply(FHIR::DSTU2::Condition, reply)
    }

  end

  test 'Condition search by patient + problem category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patient’s problems or all of patient’s health concerns using ‘GET /Condition?patient=[id]&category=[problem|health-concern]' do

    warning {
      assert !(@condition_hash.nil? || @condition_hash.empty?), 'No Condition resource available'
      reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, category: "problem"})
      validate_reply(FHIR::DSTU2::Condition, reply)
    }

  end

  test 'Condition search by patient + health-concern category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patient’s problems or all of patient’s health concerns using ‘GET /Condition?patient=[id]&category=[problem|health-concern]' do

    warning {
      assert !(@condition_hash.nil? || @condition_hash.empty?), 'No Condition resource available'
      reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, category: "health-concern"})
      validate_reply(FHIR::DSTU2::Condition, reply)
    }

  end

  # --------------------------------------------------
  # Device Search
  # --------------------------------------------------

  test 'Device search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all Unique device identifier(s)(UDI) for a patient’s implanted device(s) using GET /Device?patient=[id]' do

    reply = get_resource_by_params(FHIR::DSTU2::Device, {patient: @instance.patient_id})
    @device_hash = reply.resource.entry[0].resource.to_hash rescue []
    validate_reply(FHIR::DSTU2::Device, reply)

  end

  # --------------------------------------------------
  # Goal Search
  # --------------------------------------------------

  test 'Goal search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all of a patient’s goals using GET [base]/Goal?patient=[id]' do

    reply = get_resource_by_params(FHIR::DSTU2::Goal, {patient: @instance.patient_id})
    @goal_hash = reply.resource.entry[0].resource.to_hash rescue []
    validate_reply(FHIR::DSTU2::Goal, reply)

  end

  test 'Goal search by patient + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all of all of a patient’s goals over a specified time period using GET [base]/Goal?patient=[id]&date=[date]{&date=[date]}' do

    assert !(@goal_hash.nil? || @goal_hash.empty?), 'No Goal resource available'
    date = @goal_hash['statusDate'] rescue nil
    assert date, "Goal statusDate not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Goal, {patient: @instance.patient_id, date: date})
    validate_reply(FHIR::DSTU2::Goal, reply)

  end

  # --------------------------------------------------
  # Immunization Search
  # --------------------------------------------------

  test 'Immunization search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A client has connected to a server and fetched all immunizations for a patient using GET /Immunization?patient=[id]' do

    reply = get_resource_by_params(FHIR::DSTU2::Immunization, {patient: @instance.patient_id})
    @immunization_hash = reply.resource.entry[0].resource.to_hash rescue []
    validate_reply(FHIR::DSTU2::Immunization, reply)

  end

  # --------------------------------------------------
  # DiagnosticReport Search
  # --------------------------------------------------

  test 'DiagnosticReport search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all of a patient’s laboratory diagnostic reports queried by category using GET [base]/DiagnosticReport?patient=[id]&category=LAB' do

    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB"})
    @diagnosticreport_hash = reply.resource.entry[0].resource.to_hash rescue []
    validate_reply(FHIR::DSTU2::DiagnosticReport, reply)

  end

  test 'DiagnosticReport search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all of a patient’s laboratory diagnostic reports queried by category code and date range using GET [base]/DiagnosticReport?patient=[id]&category=LAB&date=[date]{&date=[date]}' do

    assert !(@diagnosticreport_hash.nil? || @diagnosticreport_hash.empty?), 'No DiagnosticReport resource available'
    date = @diagnosticreport_hash['effectiveDateTime'] rescue nil
    assert date, "DiagnosticReport effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB", date: date})
    validate_reply(FHIR::DSTU2::DiagnosticReport, reply)

  end

  test 'DiagnosticReport search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all of a patient’s laboratory diagnostic reports queried by category and code using GET [base]/DiagnosticReport?patient=[id]&category=LAB&code=[LOINC]' do

    assert !(@diagnosticreport_hash.nil? || @diagnosticreport_hash.empty?), 'No DiagnosticReport resource available'
    code = @diagnosticreport_hash['code']['text'] rescue nil
    assert code, "DiagnosticReport code not returned"
    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB", code: code})
    validate_reply(FHIR::DSTU2::DiagnosticReport, reply)

  end

  test 'DiagnosticReport search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable of returning all of a patient’s laboratory diagnostic reports queried by category and one or more codes and date range using GET [base]/DiagnosticReport?patient=[id]&category=LAB&code=[LOINC1{,LOINC2,LOINC3,…}]&date=[date]{&date=[date]}' do

    warning {
      assert !(@diagnosticreport_hash.nil? || @diagnosticreport_hash.empty?), 'No DiagnosticReport resource available'
      code = @diagnosticreport_hash['code']['text'] rescue nil
      assert code, "DiagnosticReport code not returned"
      date = @diagnosticreport_hash['effectiveDateTime']
      assert date, "DiagnosticReport effectiveDateTime not returned"
      reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB", code: code, date: date})
      validate_reply(FHIR::DSTU2::DiagnosticReport, reply)
    }

  end

  # --------------------------------------------------
  # MedicationStatement Search
  # --------------------------------------------------

  test 'MedicationStatement search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning a patient’s medications using one of or both 1. GET /MedicationStatement?patient=[id] 2. GET /MedicationStatement?patient=[id]&_include=MedicationStatement:medication' do

    reply = get_resource_by_params(FHIR::DSTU2::MedicationStatement, {patient: @instance.patient_id})
    @medicationstatement_hash = reply.resource.entry[0].resource.to_hash rescue []
    validate_reply(FHIR::DSTU2::MedicationStatement, reply)

  end

  # --------------------------------------------------
  # MedicationOrder Search
  # --------------------------------------------------

  test 'MedicationOrder search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning a patient’s medications using one of or both 1. GET /MedicationOrder?patient=[id] 2. GET /MedicationOrder?patient=[id]&_include=MedicationOrder:medication' do

    reply = get_resource_by_params(FHIR::DSTU2::MedicationOrder, {patient: @instance.patient_id})
    @medicationorder_hash = reply.resource.entry[0].resource.to_hash rescue []
    validate_reply(FHIR::DSTU2::MedicationOrder, reply)

  end

  # --------------------------------------------------
  # Observation Search
  # --------------------------------------------------

  test 'Observation Results search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory results queried by category using GET [base]/Observation?patient=[id]&category=laboratory" do

    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory"})
    @observationresults_hash = reply.resource.entry[0].resource.to_hash rescue []
    validate_reply(FHIR::DSTU2::Observation, reply)

  end

  test 'Observation Results search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory results queried by category code and date range usingGET [base]/Observation?patient=[id]&category=laboratory&date=[date]{&date=[date]}" do

    assert !(@observationresults_hash.nil? || @observationresults_hash.empty?), 'No Observation resource available'
    date = @observationresults_hash['effectiveDateTime'] rescue nil
    assert date, "Observation effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory", date: date})
    validate_reply(FHIR::DSTU2::Observation, reply)

  end

  test 'Observation Results search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory results queried by category and code using GET [base]/Observation?patient=[id]&category=laboratory&code=[LOINC]" do

    assert !(@observationresults_hash.nil? || @observationresults_hash.empty?), 'No Observation resource available'
    code = @observationresults_hash['code']['coding'][0]['code'] rescue nil
    assert code, "Observation code not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory", code: code})
    validate_reply(FHIR::DSTU2::Observation, reply)

  end

  test 'Observation Results search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable of returning all of a patient's laboratory results queried by category and one or more codes and date range using GET [base]/Observation?patient=[id]&category=laboratory&code=[LOINC1{,LOINC2,LOINC3,...}]&date=[date]{&date=[date]}" do

    warning {
      assert !(@observationresults_hash.nil? || @observationresults_hash.empty?), 'No Observation resource available'
      code = @observationresults_hash['code']['coding'][0]['code'] rescue nil
      assert code, "Observation code not returned"
      date = @observationresults_hash['effectiveDateTime'] rescue nil
      assert date, "Observation effectiveDateTime not returned"
      reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory", code: code, date: date})
      validate_reply(FHIR::DSTU2::Observation, reply)
    }

  end

  test 'Smoking Status search by patient + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning a a patient’s smoking status using GET [base]/Observation?patient=[id]&code=72166-2" do

    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, code: "72166-2"})
    @smokingstatus_hash = reply.resource.entry[0].resource.to_hash rescue []
    validate_reply(FHIR::DSTU2::Observation, reply)

  end

  test 'Vital Signs search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient’s vital signs that it supports using GET [base]/Observation?patient=[id]&category=vital-signs" do

    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs"})
    @vitalsigns_hash = reply.resource.entry[0].resource.to_hash rescue []
    validate_reply(FHIR::DSTU2::Observation, reply)

  end

  test 'Vital Signs search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient’s vital signs queried by date range using GET [base]/Observation?patient=[id]&category=vital-signs&date=[date]{&date=[date]}" do

    assert !(@vitalsigns_hash.nil? || @vitalsigns_hash.empty?), 'No Observation resource available'
    date = @vitalsigns_hash['effectiveDateTime'] rescue nil
    assert date, "Observation effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs", date: date})
    validate_reply(FHIR::DSTU2::Observation, reply)

  end

  test 'Vital Signs search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning any of a patient’s vital signs queried by one or more of the codes listed below using GET [base]/Observation?patient=[id]&code[vital sign LOINC{,LOINC2,LOINC3,…}]" do

    assert !(@vitalsigns_hash.nil? || @vitalsigns_hash.empty?), 'No Observation resource available'
    code = @vitalsigns_hash['code']['coding'][0]['code'] rescue nil
    assert code, "Observation code not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs", code: code})
    validate_reply(FHIR::DSTU2::Observation, reply)

  end

  test 'Vital Signs search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable of returning any of a patient’s vital signs queried by one or more of the codes listed below and date range using GET [base]/Observation?patient=[id]&code=[LOINC{,LOINC2…}]vital-signs&date=[date]{&date=[date]}" do

    warning {
      assert !(@vitalsigns_hash.nil? || @vitalsigns_hash.empty?), 'No Observation resource available'
      code = @vitalsigns_hash['code']['coding'][0]['code'] rescue nil
      assert code, "Observation code not returned"
      date = @vitalsigns_hash['effectiveDateTime']
      assert date, "Observation effectiveDateTime not returned"
      reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs", code: code, date: date})
      validate_reply(FHIR::DSTU2::Observation, reply)
    }

  end

  # --------------------------------------------------
  # Procedure Search
  # --------------------------------------------------

  test 'Procedure search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning a patient’s procedures using GET/Procedure?patient=[id]' do

    reply = get_resource_by_params(FHIR::DSTU2::Procedure, {patient: @instance.patient_id})
    @procedure_hash = reply.resource.entry[0].resource.to_hash rescue []
    validate_reply(FHIR::DSTU2::Procedure, reply)

  end

  test 'Procedure search by patient + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning all of all of a patient’s procedures over a specified time period using GET /Procedure?patient=[id]&date=[date]{&date=[date]}' do

    assert !(@procedure_hash.nil? || @procedure_hash.empty?), 'No Procedure resource available'
    date = @procedure_hash['performedDateTime'] rescue nil
    assert date, "Procedure performedDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Procedure, {patient: @instance.patient_id, date: date})
    validate_reply(FHIR::DSTU2::Procedure, reply)
  end

end
