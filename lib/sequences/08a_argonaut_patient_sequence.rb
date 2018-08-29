class ArgonautPatientSequence < SequenceBase

  group 'Argonaut Profile Conformance'

  title 'Patient'

  description 'Verify that Patient resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

  test_id_prefix 'ADQ-PA'

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

  test '03', '', 'Patient validates against Argonaut Profile',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server returns valid FHIR Patient resources according to the Data Access Framework (DAF) Patient Profile (http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html).' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert @patient.is_a?(FHIR::DSTU2::Patient), 'Expected resource to be valid DSTU2 Patient'
    profile = ValidationUtil.guess_profile(@patient)
    errors = profile.validate_resource(@patient)
    assert errors.empty?, "Patient did not validate against profile: #{errors.join(", ")}"
  end

  test '04', '', 'Patient has address',
          '',
          'Additional Patient resource requirement.' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert @patient.is_a?(FHIR::DSTU2::Patient), 'Expected resource to be valid DSTU2 Patient'
    address = @patient.try(:address).try(:first)
    assert !address.nil?, 'Patient address not returned'
  end

  test '05', '', 'Patient has telecom',
          '',
          'Additional Patient resource requirement.' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert @patient.is_a?(FHIR::DSTU2::Patient), 'Expected resource to be valid DSTU2 Patient'
    telecom = @patient.try(:telecom).try(:first)
    assert !telecom.nil?, 'Patient telecom not returned'
  end


  # test 'Patient supports $everything operation', '', 'DISCUSSION REQUIRED', :optional do
  #   everything_response = @client.fetch_patient_record(@instance.patient_id)
  #   skip_unless [200, 201].include?(everything_response.code)
  #   @everything = everything_response.resource
  #   assert !@everything.nil?, 'Expected valid DSTU2 Bundle resource on $everything request'
  #   assert @everything.is_a?(FHIR::DSTU2::Bundle), 'Expected resource to be valid DSTU2 Bundle'
  # end
          #
  test '06', '', 'Server rejects Patient search without proper authorization',
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

  test '07', '', 'Server returns expected results from Patient search by identifier',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server has exposed a FHIR Patient search endpoint supporting at a minimum the following search parameters: identifier.' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    identifier = @patient.try(:identifier).try(:first).try(:value)
    assert !identifier.nil?, "Patient identifier not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Patient, {identifier: identifier})
    validate_search_reply(FHIR::DSTU2::Patient, reply)

  end

  test '08', '', 'Server returns expected results from Patient search by name + gender',
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

  test '09', '', 'Server returns expected results from Patient search by name + birthdate',
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

  test '10', '', 'Server returns expected results from Patient search by gender + birthdate',
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

  test '11', '', 'Server returns expected results from Patient history resource',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Patient, [:history])

    validate_history_reply(@patient, FHIR::DSTU2::Patient)

  end

  test '12', '', 'Server returns expected results from Patient vread resource',
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


end
