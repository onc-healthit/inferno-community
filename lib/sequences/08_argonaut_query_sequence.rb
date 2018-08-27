class ArgonautDataQuerySequence < SequenceBase

  group 'Argonaut Query and Data'

  title 'Argonaut Data Query'

  modal_before_run

  description 'Verify that the FHIR server follows the Argonaut Data Query Implementation Guide Server.'

  test_id_prefix 'ADQ'

  requires :token, :patient_id

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  # --------------------------------------------------
  # Patient Search
  # --------------------------------------------------
  #
  test '01', '', 'Server rejects patient read without proper authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A patient read does not work without authorization.' do

    @client.set_no_auth
    reply = @client.read(FHIR::DSTU2::Patient, @instance.patient_id)
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '02', '', 'Server returns expected results from Patient read resource',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    patient_read_response = @client.read(FHIR::DSTU2::Patient, @instance.patient_id)
    assert_response_ok patient_read_response
    @patient = patient_read_response.resource
    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert @patient.is_a?(FHIR::DSTU2::Patient), 'Expected resource to be valid DSTU2 Patient'

  end

  test '03', '', 'Server rejects Patient search without proper authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Patient search does not work without proper authorization.' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    identifier = @patient.try(:identifier).try(:first).try(:value)
    assert !identifier.nil?, "Patient identifier not returned"
    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Patient, {identifier: identifier})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '04', '', 'Server returns expected results from Patient search by identifier',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters: identifier.' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    identifier = @patient.try(:identifier).try(:first).try(:value)
    assert !identifier.nil?, "Patient identifier not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Patient, {identifier: identifier})
    validate_search_reply(FHIR::DSTU2::Patient, reply)

  end

  test '05', '', 'Server returns expected results from Patient search by name + gender',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate.' do

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

  test '06', '', 'Server returns expected results from Patient search by name + birthdate',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate.' do

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

  test '07', '', 'Server returns expected results from Patient search by gender + birthdate',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters when at least 2 (example name and gender) are present: name, gender, birthdate.' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    gender = @patient.try(:gender)
    assert !gender.nil?, "Patient gender not returned"
    birthdate = @patient.try(:birthDate)
    assert !birthdate.nil?, "Patient birthDate not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Patient, {gender: gender, birthdate: birthdate})
    validate_search_reply(FHIR::DSTU2::Patient, reply)

  end

  test '08', '', 'Server returns expected results from Patient history resource',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Patient, [:history])

    validate_history_reply(@patient, FHIR::DSTU2::Patient)

  end

  test '09', '', 'Server returns expected results from Patient vread resource',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do


    skip_if_not_supported(:Patient, [:vread])

    validate_vread_reply(@patient, FHIR::DSTU2::Patient)

  end

  # test 'Patient supports $everything operation', '', 'DISCUSSION REQUIRED', :optional do
  #   everything_response = @client.fetch_patient_record(@instance.patient_id)
  #   skip_unless [200, 201].include?(everything_response.code)
  #   @everything = everything_response.resource
  #   assert !@everything.nil?, 'Expected valid DSTU2 Bundle resource on $everything request'
  #   assert @everything.is_a?(FHIR::DSTU2::Bundle), 'Expected resource to be valid DSTU2 Bundle'
  # end


  # --------------------------------------------------
  # AllergyIntolerance Search
  # --------------------------------------------------

  test '10', '', 'Server rejects AllergyIntolerance search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'An AllergyIntolerance search does not work without proper authorization.' do

    skip_if_not_supported(:AllergyIntolerance, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::AllergyIntolerance, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '11', '', 'Server returns expected results from AllergyIntolerance search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning a patient's allergies." do

    skip_if_not_supported(:AllergyIntolerance, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::AllergyIntolerance, {patient: @instance.patient_id})
    @allergyintolerance = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::AllergyIntolerance, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::AllergyIntolerance, reply)

  end

  test '12', '', 'Server returns expected results from AllergyIntolerance read resource',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:AllergyIntolerance, [:search, :read])
    validate_read_reply(@allergyintolerance, FHIR::DSTU2::AllergyIntolerance)

  end

  test '13', '', 'AllergyIntolerance history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:AllergyIntolerance, [:history])
    validate_history_reply(@allergyintolerance, FHIR::DSTU2::AllergyIntolerance)

  end

  test '14', '', 'AllergyIntolerance vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:AllergyIntolerance, [:vread])

    validate_vread_reply(@allergyintolerance, FHIR::DSTU2::AllergyIntolerance)

  end


  # --------------------------------------------------
  # CarePlan Search
  # --------------------------------------------------

  test '15', '', 'Server rejects CarePlan search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A CarePlan search does not work without proper authorization.' do

    skip_if_not_supported(:CarePlan, [:search, :read])
    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '16', '', 'Server returns expected results from CarePlan search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's Assessment and Plan of Treatment information." do

    skip_if_not_supported(:CarePlan, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan"})
    @careplan = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::CarePlan, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::CarePlan, reply)

  end

  test '17', '', 'Server returns expected results from CarePlan search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable of returning a patient's Assessment and Plan of Treatment information over a specified time period.",
          :optional do

    skip_if_not_supported(:CarePlan, [:search, :read])

    assert !@careplan.nil?, 'Expected valid DSTU2 CarePlan resource to be present'

    date = @careplan.try(:period).try(:start)
    assert !date.nil?, "CarePlan period not returned"
    reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan", date: date})
    validate_search_reply(FHIR::DSTU2::CarePlan, reply)

  end

  test '18', '', 'Server returns expected results from CarePlan search by patient + category + status',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable returning all of a patient's active Assessment and Plan of Treatment information.",
          :optional do

    skip_if_not_supported(:CarePlan, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan", status: "active"})
    validate_search_reply(FHIR::DSTU2::CarePlan, reply)

  end

  test '19', '', 'Server returns expected results from CarePlan search by patient + category + status + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable returning a patient's active Assessment and Plan of Treatment information over a specified time period.",
          :optional do

    skip_if_not_supported(:CarePlan, [:search, :read])

    assert !@careplan.nil?, 'Expected valid DSTU2 CarePlan resource to be present'
    date = @careplan.try(:period).try(:start)
    assert !date.nil?, "CarePlan period not returned"
    reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan", status: "active", date: date})
    validate_search_reply(FHIR::DSTU2::CarePlan, reply)

  end

  test '20', '', 'CarePlan read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:CarePlan, [:search, :read])

    validate_read_reply(@careplan, FHIR::DSTU2::CarePlan)

  end

  test '21', '', 'CarePlan history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:CarePlan, [:history])

    validate_history_reply(@careplan, FHIR::DSTU2::CarePlan)

  end

  test '22', '', 'CarePlan vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:CarePlan, [:vread])

    validate_vread_reply(@careplan, FHIR::DSTU2::CarePlan)

  end


  # --------------------------------------------------
  # Condition Search
  # --------------------------------------------------

  test '23', '', 'Server rejects Condition search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Condition search does not work without proper authorization.' do

    skip_if_not_supported(:Condition, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '24', '', 'Server returns expected results from Condition search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning a patients conditions list.' do

    skip_if_not_supported(:Condition, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id})
    @condition = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Condition, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::Condition, reply)

  end

  test '25', '', 'Server returns expected results from Condition search by patient + clinicalstatus',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patients active problems and health concerns.',
          :optional do

    skip_if_not_supported(:Condition, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, clinicalstatus: "active,recurrance,remission"})
    validate_search_reply(FHIR::DSTU2::Condition, reply)

  end

  test '26', '', 'Server returns expected results from Condition search by patient + problem category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patients problems or all of patients health concerns.',
          :optional do

    skip_if_not_supported(:Condition, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, category: "problem"})
    validate_search_reply(FHIR::DSTU2::Condition, reply)

  end

  test '27', '', 'Server returns expected results from Condition search by patient + health-concern category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patients problems or all of patients health concerns.',
          :optional do

    skip_if_not_supported(:Condition, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, category: "health-concern"})
    validate_search_reply(FHIR::DSTU2::Condition, reply)

  end

  test '28', '', 'Condition read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:Condition, [:search, :read])

    validate_read_reply(@condition, FHIR::DSTU2::Condition)

  end

  test '29', '', 'Condition history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Condition, [:history])

    validate_history_reply(@condition, FHIR::DSTU2::Condition)

  end

  test '30', '', 'Condition vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Condition, [:vread])

    validate_vread_reply(@condition, FHIR::DSTU2::Condition)

  end


  # --------------------------------------------------
  # Device Search
  # --------------------------------------------------

  test '31', '', 'Server rejects Device search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Device search does not work without proper authorization.' do

    skip_if_not_supported(:Device, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Device, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '32', '', 'Server returns expected results from Device search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all Unique device identifier(s)(UDI) for a patient's implanted device(s)." do

    skip_if_not_supported(:Device, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Device, {patient: @instance.patient_id})
    @device = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Device, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::Device, reply)

  end

  test '33', '', 'Device read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:Device, [:search, :read])

    validate_read_reply(@device, FHIR::DSTU2::Device)

  end

  test '34', '', 'Device history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Device, [:history])

    validate_history_reply(@device, FHIR::DSTU2::Device)

  end

  test '35', '', 'Device vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Device, [:vread])

    validate_vread_reply(@device, FHIR::DSTU2::Device)

  end


  # --------------------------------------------------
  # DocumentReference Search
  # --------------------------------------------------

  test '36', '', 'Server rejects DocumentReference search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A DocumentReference search does not work without proper authorization.' do

    skip_if_not_supported(:DocumentReference, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::DocumentReference, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '37', '', 'Server returns expected results from DocumentReference search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'If supporting a direct query, a server SHALL be capable of returning at least the most recent CCD document references and MAY provide most recent references to other document types for a patient.]' do

    skip_if_not_supported(:DocumentReference, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::DocumentReference, {patient: @instance.patient_id})
    @documentreference = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::DocumentReference, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::DocumentReference, reply)

  end

  test '38', '', 'Server returns expected results from DocumentReference search by patient + type',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'If supporting a direct query, A server SHOULD be capable of returning references to CCD documents and MAY provide references to other document types for a patient searched by type and/or date.',
          :optional do

    skip_if_not_supported(:DocumentReference, [:search, :read])

    assert !@documentreference.nil?, 'Expected valid DSTU2 DocumentReference resource to be present'
    type = @documentreference.try(:type).try(:coding).try(:first).try(:code)
    assert !type.nil?, "DocumentReference type not returned"
    reply = get_resource_by_params(FHIR::DSTU2::DocumentReference, {patient: @instance.patient_id, type: type})
    validate_search_reply(FHIR::DSTU2::DocumentReference, reply)

  end

  test '39', '', 'Server returns expected results from DocumentReference search by patient + period',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'If supporting a direct query, A server SHOULD be capable of returning references to CCD documents and MAY provide references to other document types for a patient searched by type and/or date.',
          :optional do

    skip_if_not_supported(:DocumentReference, [:search, :read])

    assert !@documentreference.nil?, 'Expected valid DSTU2 DocumentReference resource to be present'
    period = @documentreference.try(:context).try(:period).try(:start)
    assert !period.nil?, "DocumentReference period not returned"
    reply = get_resource_by_params(FHIR::DSTU2::DocumentReference, {patient: @instance.patient_id, period: period})
    validate_search_reply(FHIR::DSTU2::DocumentReference, reply)

  end

  test '40', '', 'Server returns expected results from DocumentReference search by patient + type + period',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'If supporting a direct query, A server SHOULD be capable of returning references to CCD documents and MAY provide references to other document types for a patient searched by type and/or date.',
          :optional do

    skip_if_not_supported(:DocumentReference, [:search, :read])

    assert !@documentreference.nil?, 'Expected valid DSTU2 DocumentReference resource to be present'
    type = @documentreference.try(:type).try(:coding).try(:first).try(:code)
    assert !type.nil?, "DocumentReference type not returned"
    period = @documentreference.try(:context).try(:period).try(:start)
    assert !period.nil?, "DocumentReference period not returned"
    reply = get_resource_by_params(FHIR::DSTU2::DocumentReference, {patient: @instance.patient_id, type: type, period: period})
    validate_search_reply(FHIR::DSTU2::DocumentReference, reply)

  end

  test '41', '', 'DocumentReference read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:DocumentReference, [:search, :read])

    validate_read_reply(@documentreference, FHIR::DSTU2::DocumentReference)

  end

  test '42', '', 'DocumentReference history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:DocumentReference, [:history])

    validate_history_reply(@documentreference, FHIR::DSTU2::DocumentReference)

  end

  test '43', '', 'DocumentReference vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:DocumentReference, [:vread])

    validate_vread_reply(@documentreference, FHIR::DSTU2::DocumentReference)

  end


  # --------------------------------------------------
  # Goal Search
  # --------------------------------------------------

  test '44', '', 'Server rejects Goal search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Goal search does not work without proper authorization.' do

    skip_if_not_supported(:Goal, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Goal, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '45', '', 'Server returns expected results from Goal search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's goals." do

    skip_if_not_supported(:Goal, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Goal, {patient: @instance.patient_id})
    @goal = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Goal, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::Goal, reply)

  end

  test '46', '', 'Server returns expected results from Goal search by patient + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of all of a patient's goals over a specified time period." do

    skip_if_not_supported(:Goal, [:search, :read])

    assert !@goal.nil?, 'Expected valid DSTU2 Goal resource to be present'
    date = @goal.try(:statusDate) || @goal.try(:targetDate) || @goal.try(:startDate)
    assert !date.nil?, "Goal statusDate, targetDate, nor startDate returned"
    reply = get_resource_by_params(FHIR::DSTU2::Goal, {patient: @instance.patient_id, date: date})
    validate_search_reply(FHIR::DSTU2::Goal, reply)

  end

  test '47', '', 'Goal read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:Goal, [:search, :read])

    validate_read_reply(@goal, FHIR::DSTU2::Goal)

  end

  test '48', '', 'Goal history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Goal, [:history])

    validate_history_reply(@goal, FHIR::DSTU2::Goal)

  end

  test '49', '', 'Goal vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Goal, [:vread])

    validate_vread_reply(@goal, FHIR::DSTU2::Goal)

  end


  # --------------------------------------------------
  # Immunization Search
  # --------------------------------------------------

  test '50', '', 'Server rejects Immunization search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'An Immunization search does not work without proper authorization.' do

    skip_if_not_supported(:Immunization, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Immunization, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '51', '', 'Server supports Immunization search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A client has connected to a server and fetched all immunizations for a patient.' do

    skip_if_not_supported(:Immunization, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Immunization, {patient: @instance.patient_id})
    @immunization = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Immunization, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::Immunization, reply)

  end

  test '52', '', 'Immunization read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:Immunization, [:search, :read])

    validate_read_reply(@immunization, FHIR::DSTU2::Immunization)

  end

  test '53', '', 'Immunization history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Immunization, [:history])

    validate_history_reply(@immunization, FHIR::DSTU2::Immunization)

  end

  test '54', '', 'Immunization vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Immunization, [:vread])

    validate_vread_reply(@immunization, FHIR::DSTU2::Immunization)

  end


  # --------------------------------------------------
  # DiagnosticReport Search
  # --------------------------------------------------

  test '55', '', 'Server rejects DiagnosticReport search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A DiagnosticReport search does not work without proper authorization.' do

    skip_if_not_supported(:DiagnosticReport, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '56', '', 'Server returns expected results from DiagnosticReport search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory diagnostic reports queried by category." do

    skip_if_not_supported(:DiagnosticReport, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB"})
    @diagnosticreport = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)

  end

  test '57', '', 'Server returns expected results from DiagnosticReport search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory diagnostic reports queried by category code and date range." do

    skip_if_not_supported(:DiagnosticReport, [:search, :read])

    assert !@diagnosticreport.nil?, 'Expected valid DSTU2 DiagnosticReport resource to be present'
    date = @diagnosticreport.try(:effectiveDateTime)
    assert !date.nil?, "DiagnosticReport effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB", date: date})
    validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)

  end

  test '58', '', 'Server returns expected results from DiagnosticReport search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory diagnostic reports queried by category and code." do

    skip_if_not_supported(:DiagnosticReport, [:search, :read])

    assert !@diagnosticreport.nil?, 'Expected valid DSTU2 DiagnosticReport resource to be present'
    code = @diagnosticreport.try(:code).try(:coding).try(:first).try(:code)
    assert !code.nil?, "DiagnosticReport code not returned"
    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB", code: code})
    validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)

  end

  test '59', '', 'Server returns expected results from DiagnosticReport search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable of returning all of a patient's laboratory diagnostic reports queried by category and one or more codes and date range.",
          :optional do

    skip_if_not_supported(:DiagnosticReport, [:search, :read])

    assert !@diagnosticreport.nil?, 'Expected valid DSTU2 DiagnosticReport resource to be present'
    code = @diagnosticreport.try(:code).try(:coding).try(:first).try(:code)
    assert !code.nil?, "DiagnosticReport code not returned"
    date = @diagnosticreport.try(:effectiveDateTime)
    assert !date.nil?, "DiagnosticReport effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB", code: code, date: date})
    validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)

  end

  test '60', '', 'DiagnosticReport read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:DiagnosticReport, [:search, :read])

    validate_read_reply(@diagnosticreport, FHIR::DSTU2::DiagnosticReport)

  end

  test '61', '', 'DiagnosticReport history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:DiagnosticReport, [:history])

    validate_history_reply(@diagnosticreport, FHIR::DSTU2::DiagnosticReport)

  end

  test '62', '', 'DiagnosticReport vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:DiagnosticReport, [:vread])

    validate_vread_reply(@diagnosticreport, FHIR::DSTU2::DiagnosticReport)

  end

  # --------------------------------------------------
  # MedicationStatement Search
  # --------------------------------------------------

  test '63', '', 'Server rejects MedicationStatement search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'An MedicationStatement search does not work without proper authorization.' do

    skip_if_not_supported(:MedicationStatement, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::MedicationStatement, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '64', '', 'Server returns expected results from MedicationStatement search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning a patient's medications." do

    skip_if_not_supported(:MedicationStatement, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::MedicationStatement, {patient: @instance.patient_id})
    @medicationstatement = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::MedicationStatement, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::MedicationStatement, reply)

  end

  test '65', '', 'MedicationStatement read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:MedicationStatement, [:search, :read])

    validate_read_reply(@medicationstatement, FHIR::DSTU2::MedicationStatement)

  end

  test '66', '', 'MedicationStatement history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:MedicationStatement, [:history])

    validate_history_reply(@medicationstatement, FHIR::DSTU2::MedicationStatement)

  end

  test '67', '', 'MedicationStatement vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:MedicationStatement, [:vread])

    validate_vread_reply(@medicationstatement, FHIR::DSTU2::MedicationStatement)

  end


  # --------------------------------------------------
  # MedicationOrder Search
  # --------------------------------------------------

  test '68', '', 'Server rejects MedicationOrder search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'An MedicationOrder search does not work without proper authorization.' do

    skip_if_not_supported(:MedicationOrder, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::MedicationOrder, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '69', '', 'Server returns expected results from MedicationOrder search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning a patient's medications." do

    skip_if_not_supported(:MedicationOrder, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::MedicationOrder, {patient: @instance.patient_id})
    @medicationorder = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::MedicationOrder, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::MedicationOrder, reply)

  end

  test '70', '', 'MedicationOrder read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:MedicationOrder, [:search, :read])

    validate_read_reply(@medicationorder, FHIR::DSTU2::MedicationOrder)

  end

  test '71', '', 'MedicationOrder history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:MedicationOrder, [:history])

    validate_history_reply(@medicationorder, FHIR::DSTU2::MedicationOrder)

  end

  test '72', '', 'MedicationOrder vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:MedicationOrder, [:vread])

    validate_vread_reply(@medicationorder, FHIR::DSTU2::MedicationOrder)

  end


  # --------------------------------------------------
  # Observation Search
  # --------------------------------------------------

  test '73', '', 'Observation Results search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'An Observation Results search does not work without proper authorization.' do

    skip_if_not_supported(:Observation, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '74', '', 'Server returns expected results from Observation Results search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory results queried by category." do

    skip_if_not_supported(:Observation, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory"})
    @observationresults = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Observation, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::Observation, reply)

  end

  test '75', '', 'Server returns expected results from Observation Results search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory results queried by category code and date range." do

    skip_if_not_supported(:Observation, [:search, :read])

    assert !@observationresults.nil?, 'Expected valid DSTU2 Observation resource to be present'
    date = @observationresults.try(:effectiveDateTime)
    assert !date.nil?, "Observation effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory", date: date})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test '76', '', 'Server returns expected results from Observation Results search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory results queried by category and code." do

    skip_if_not_supported(:Observation, [:search, :read])

    assert !@observationresults.nil?, 'Expected valid DSTU2 Observation resource to be present'
    code = @observationresults.try(:code).try(:coding).try(:first).try(:code)
    assert !code.nil?, "Observation code not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory", code: code})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test '77', '', 'Server returns expected results from Observation Results search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable of returning all of a patient's laboratory results queried by category and one or more codes and date range.",
          :optional do

    skip_if_not_supported(:Observation, [:search, :read])

    assert !@observationresults.nil?, 'Expected valid DSTU2 Observation resource to be present'
    code = @observationresults.try(:code).try(:coding).try(:first).try(:code)
    assert !code.nil?, "Observation code not returned"
    date = @observationresults.try(:effectiveDateTime)
    assert !date.nil?, "Observation effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory", code: code, date: date})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test '78', '', 'Server rejects Smoking Status search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Smoking Status search does not work without proper authorization.' do

    skip_if_not_supported(:Observation, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, code: "72166-2"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '79', '', 'Server returns expected results from Smoking Status search by patient + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning a patient's smoking status." do

    skip_if_not_supported(:Observation, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, code: "72166-2"})
    validate_search_reply(FHIR::DSTU2::Observation, reply)
    # TODO check for 72166-2
    save_resource_ids_in_bundle(FHIR::DSTU2::Observation, reply)

  end

  test '80', '', 'Server rejects Vital Signs search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Vital Signs search does not work without proper authorization.' do

    skip_if_not_supported(:Observation, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '81', '', 'Server returns expected results from Vital Signs search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's vital signs that it supports." do

    skip_if_not_supported(:Observation, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs"})
    @vitalsigns = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Observation, reply)
    # TODO check for `vital-signs` category
    save_resource_ids_in_bundle(FHIR::DSTU2::Observation, reply)

  end

  test '82', '', 'Server returns expected results from Vital Signs search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's vital signs queried by date range." do

    skip_if_not_supported(:Observation, [:search, :read])

    assert !@vitalsigns.nil?, 'Expected valid DSTU2 Observation resource to be present'
    date = @vitalsigns.try(:effectiveDateTime)
    assert !date.nil?, "Observation effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs", date: date})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test '83', '', 'Server returns expected results from Vital Signs search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning any of a patient's vital signs queried by one or more of the specified codes." do

    skip_if_not_supported(:Observation, [:search, :read])

    assert !@vitalsigns.nil?, 'Expected valid DSTU2 Observation resource to be present'
    code = @vitalsigns.try(:code).try(:coding).try(:first).try(:code)
    assert !code.nil?, "Observation code not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs", code: code})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test '84', '', 'Server returns expected results from Vital Signs search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable of returning any of a patient's vital signs queried by one or more of the codes listed below and date range.",
          :optional do

    skip_if_not_supported(:Observation, [:search, :read])

    assert !@vitalsigns.nil?, 'Expected valid DSTU2 Observation resource to be present'
    code = @vitalsigns.try(:code).try(:coding).try(:first).try(:code)
    assert !code.nil?, "Observation code not returned"
    date = @vitalsigns.try(:effectiveDateTime)
    assert !date.nil?, "Observation effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs", code: code, date: date})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test '85', '', 'Observation read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:Observation, [:search, :read])

    validate_read_reply(@observationresults, FHIR::DSTU2::Observation)

  end

  test '86', '', 'Observation history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Observation, [:history])

    validate_history_reply(@observationresults, FHIR::DSTU2::Observation)

  end

  test '87', '', 'Observation vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Observation, [:vread])

    validate_vread_reply(@observationresults, FHIR::DSTU2::Observation)

  end


  # --------------------------------------------------
  # Procedure Search
  # --------------------------------------------------

  test '88', '', 'Server rejects Procedure search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Procedure search does not work without proper authorization.' do


    skip_if_not_supported(:Procedure, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Procedure, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply
    save_resource_ids_in_bundle(FHIR::DSTU2::Procedure, reply)

  end

  test '89', '', 'Server returns expected results from Procedure search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning a patient's procedures." do

    skip_if_not_supported(:Procedure, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Procedure, {patient: @instance.patient_id})
    @procedure = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Procedure, reply)

  end

  test '90', '', 'Server returns expected results from Procedure search by patient + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of all of a patient's procedures over a specified time period." do

    skip_if_not_supported(:Procedure, [:search, :read])

    assert !@procedure.nil?, 'Expected valid DSTU2 Procedure resource to be present'
    date = @procedure.try(:performedDateTime) || @procedure.try(:performedPeriod).try(:start)
    assert !date.nil?, "Procedure performedDateTime or performedPeriod not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Procedure, {patient: @instance.patient_id, date: date})
    validate_search_reply(FHIR::DSTU2::Procedure, reply)

  end

  test '91', '', 'Procedure read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:Procedure, [:search, :read])

    validate_read_reply(@procedure, FHIR::DSTU2::Procedure)

  end

  test '92', '', 'Procedure history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Procedure, [:history])

    validate_history_reply(@procedure, FHIR::DSTU2::Procedure)

  end

  test '93', '', 'Procedure vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Procedure, [:vread])

    validate_vread_reply(@procedure, FHIR::DSTU2::Procedure)

  end

  def skip_if_not_supported(resource, methods)

    skip "This server does not support #{resource.to_s} #{methods.join(',').to_s} operation(s) according to conformance statement." unless @instance.conformance_supported?(resource, methods)

  end

end
