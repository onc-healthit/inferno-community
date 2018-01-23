class ArgonautSearchSequence < SequenceBase

  title 'Argonaut Search'

  description 'The FHIR server properly follows the Argonaut Data Query Implementation Guide Server.'

  preconditions 'Client must be authorized.' do
    !@instance.token.nil?
  end

  def get_patient_by_param(params = {}, flag = true)
    assert !params.empty?, "No params for patient"
    options = {
      :search => {
        :flag => flag,
        :compartment => nil,
        :parameters => params
      }
    }
    reply = @client.search(FHIR::DSTU2::Patient, options)
    assert_response_ok(reply)
    assert_bundle_response(reply)
    assert !reply.resource.get_by_id(@instance.patient_id).nil?, 'Server returned nil patient.'
    assert reply.resource.get_by_id(@instance.patient_id).equals?(@patient, ['_id', "text", "meta", "lastUpdated"]), 'Server returned wrong patient.'
  end

  # --------------------------------------------------
  # Patient Search
  # --------------------------------------------------

  test 'Has Patient resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html' do

    patient_read_response = @client.read(FHIR::DSTU2::Patient, @instance.patient_id)
    assert_response_ok patient_read_response
    @patient = patient_read_response.resource
    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    @patient_details = @patient.to_hash
    assert @patient.is_a?(FHIR::DSTU2::Patient), 'Expected resource to be valid DSTU2 Patient'
  end

  test 'Patient search by name',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: name' do

    family = @patient_details['name'][0]['family'][0]
    assert family, "Patient family name not returned"
    given = @patient_details['name'][0]['given'][0]
    assert given, "Patient given name not returned"
    get_patient_by_param(family: family, given: given)

  end

  test 'Patient search by family',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: family' do

    family = @patient_details['name'][0]['family'][0]
    assert family, "Patient family name not returned"
    get_patient_by_param(family: family)

  end

  test 'Patient search by given',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: given' do

    given = @patient_details['name'][0]['given'][0]
    assert given, "Patient given name not returned"
    get_patient_by_param(given: given)

  end

  test 'Patient search by identifier',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: identifier' do

    identifier = @patient_details['identifier'][0]['value']
    assert identifier, "Patient identifier not returned"
    get_patient_by_param(identifier: identifier)

  end

  test 'Patient search by gender',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: gender' do

    gender = @patient_details['gender']
    assert gender, "Patient gender not returned"
    get_patient_by_param(gender: gender)

  end

  test 'Patient search by birthdate',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: birthdate' do

    birthdate = @patient_details['birthDate']
    assert birthdate, "Patient birthdate not returned"
    get_patient_by_param(birthdate: birthdate)

  end

  test 'Patient search by name + gender',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: name + gender' do

    family = @patient_details['name'][0]['family'][0]
    assert family, "Patient family name not returned"
    given = @patient_details['name'][0]['given'][0]
    assert given, "Patient given name not returned"
    gender = @patient_details['gender']
    assert gender, "Patient gender not returned"
    get_patient_by_param(family: family, given: given, gender: gender)

  end

  test 'Patient search by name + birthdate',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: name + birthdate' do

    family = @patient_details['name'][0]['family'][0]
    assert family, "Patient family name not returned"
    given = @patient_details['name'][0]['given'][0]
    assert given, "Patient given name not returned"
    birthdate = @patient_details['birthDate']
    assert birthdate, "Patient birthDate not returned"
    get_patient_by_param(family: family, given: given, birthdate: birthdate)

  end

  test 'Patient search by family + gender',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: family + gender' do

    family = @patient_details['name'][0]['family'][0]
    assert family, "Patient family name not returned"
    gender = @patient_details['gender']
    assert gender, "Patient gender not returned"
    get_patient_by_param(family: family, gender: gender)

  end

  test 'Patient search by given + gender',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: given + gender' do

    given = @patient_details['name'][0]['given'][0]
    assert given, "Patient given name not returned"
    gender = @patient_details['gender']
    assert gender, "Patient gender not returned"
    get_patient_by_param(given: given, gender: gender)

  end

  # --------------------------------------------------
  # AllergyIntolerance Search
  # --------------------------------------------------

  test 'AllergyIntolerance search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    todo
  end

  # --------------------------------------------------
  # CarePlan Search
  # --------------------------------------------------

  test 'CarePlan search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    todo
  end

  test 'CarePlan search by category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: category' do

    todo
  end

  test 'CarePlan search by status',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: status' do

    todo
  end

  test 'CarePlan search by date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: date' do

    todo
  end

  test 'CarePlan search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category' do

    todo
  end

  test 'CarePlan search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + date' do

    todo
  end

  test 'CarePlan search by patient + category + status',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + status' do

    todo
  end

  test 'CarePlan search by patient + category + status + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + status + date' do

    todo
  end

  # --------------------------------------------------
  # Condition Search
  # --------------------------------------------------

  test 'Condition search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    todo
  end

  test 'Condition search by category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: category' do

    todo
  end

  test 'Condition search by clinicalstatus',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: clinicalstatus' do

    todo
  end

  test 'Condition search by patient + clinicalstatus',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + clinicalstatus' do

    todo
  end

  test 'Condition search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category' do

    todo
  end

  # --------------------------------------------------
  # Device Search
  # --------------------------------------------------

  test 'Device search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    todo
  end

  # --------------------------------------------------
  # Goal Search
  # --------------------------------------------------

  test 'Goal search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    todo
  end

  test 'Goal search by date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: date' do

    todo
  end

  test 'Goal search by patient + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + date' do

    todo
  end

  # --------------------------------------------------
  # Immunization Search
  # --------------------------------------------------

  test 'Immunization search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    todo
  end

  # --------------------------------------------------
  # DiagnosticReport Search
  # --------------------------------------------------

  test 'DiagnosticReport search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    todo
  end

  test 'DiagnosticReport search by category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: category' do

    todo
  end

  test 'DiagnosticReport search by code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: code' do

    todo
  end

  test 'DiagnosticReport search by date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: date' do

    todo
  end

  test 'DiagnosticReport search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category' do

    todo
  end

  test 'DiagnosticReport search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + date' do

    todo
  end

  test 'DiagnosticReport search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + code' do

    todo
  end

  test 'DiagnosticReport search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + code + date' do

    todo
  end

  # --------------------------------------------------
  # Medication Search
  # --------------------------------------------------

  # --------------------------------------------------
  # MedicationStatement Search
  # --------------------------------------------------

  test 'MedicationStatement search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    todo
  end

  # --------------------------------------------------
  # MedicationOrder Search
  # --------------------------------------------------

  test 'MedicationOrder search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    todo
  end

  # --------------------------------------------------
  # Observation Search
  # --------------------------------------------------

  test 'Observation search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    todo
  end

  test 'Observation search by category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: category' do

    todo
  end

  test 'Observation search by code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: code' do

    todo
  end

  test 'Observation search by date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: date' do

    todo
  end

  test 'Observation search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category' do

    todo
  end

  test 'Observation search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + date' do

    todo
  end

  test 'Observation search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + code' do

    todo
  end

  test 'Observation search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + code + date' do

    todo
  end

  # --------------------------------------------------
  # Procedure Search
  # --------------------------------------------------

  test 'Procedure search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    todo
  end

  test 'Procedure search by date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: date' do

    todo
  end

  test 'Procedure search by patient + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + date' do

    todo
  end

end
