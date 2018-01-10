class ArgonautSearchSequence < SequenceBase

  description 'The FHIR server properly follows the Argonaut Data Query Implementation Guide Server.'

  preconditions 'Client must be authorized.' do 
    !@instance.token.nil?
  end

  # --------------------------------------------------
  # Patient Search
  # --------------------------------------------------

  test 'Patient search by name',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: name' do

    TODO
  end

  test 'Patient search by family',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: family' do

    TODO
  end

  test 'Patient search by given',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: given' do

    TODO
  end

  test 'Patient search by identifier',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: identifier' do

    TODO
  end

  test 'Patient search by gender',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: gender' do

    TODO
  end

  test 'Patient search by birthdate',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: birthdate' do

    TODO
  end

  test 'Patient search by name + gender',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: name + gender' do

    TODO
  end

  test 'Patient search by name + birthdate',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: name + birthdate' do

    TODO
  end

  test 'Patient search by family + gender',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: family + gender' do

    TODO
  end

  test 'Patient search by given + gender',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: given + gender' do

    TODO
  end

  # --------------------------------------------------
  # AllergyIntolerance Search
  # --------------------------------------------------

  test 'AllergyIntolerance search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    TODO
  end

  # --------------------------------------------------
  # CarePlan Search
  # --------------------------------------------------

  test 'CarePlan search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    TODO
  end

  test 'CarePlan search by category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: category' do

    TODO
  end

  test 'CarePlan search by status',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: status' do

    TODO
  end

  test 'CarePlan search by date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: date' do

    TODO
  end

  test 'CarePlan search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category' do

    TODO
  end

  test 'CarePlan search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + date' do

    TODO
  end

  test 'CarePlan search by patient + category + status',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + status' do

    TODO
  end

  test 'CarePlan search by patient + category + status + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + status + date' do

    TODO
  end

  # --------------------------------------------------
  # Condition Search
  # --------------------------------------------------

  test 'Condition search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    TODO
  end

  test 'Condition search by category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: category' do

    TODO
  end

  test 'Condition search by clinicalstatus',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: clinicalstatus' do

    TODO
  end

  test 'Condition search by patient + clinicalstatus',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + clinicalstatus' do

    TODO
  end

  test 'Condition search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category' do

    TODO
  end

  # --------------------------------------------------
  # Device Search
  # --------------------------------------------------

  test 'Device search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    TODO
  end

  # --------------------------------------------------
  # Goal Search
  # --------------------------------------------------

  test 'Goal search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    TODO
  end

  test 'Goal search by date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: date' do

    TODO
  end

  test 'Goal search by patient + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + date' do

    TODO
  end

  # --------------------------------------------------
  # Immunization Search
  # --------------------------------------------------

  test 'Immunization search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    TODO
  end

  # --------------------------------------------------
  # DiagnosticReport Search
  # --------------------------------------------------

  test 'DiagnosticReport search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    TODO
  end

  test 'DiagnosticReport search by category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: category' do

    TODO
  end

  test 'DiagnosticReport search by code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: code' do

    TODO
  end

  test 'DiagnosticReport search by date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: date' do

    TODO
  end

  test 'DiagnosticReport search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category' do

    TODO
  end

  test 'DiagnosticReport search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + date' do

    TODO
  end

  test 'DiagnosticReport search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + code' do

    TODO
  end

  test 'DiagnosticReport search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + code + date' do

    TODO
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

    TODO
  end

  # --------------------------------------------------
  # MedicationOrder Search
  # --------------------------------------------------

  test 'MedicationOrder search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    TODO
  end

  # --------------------------------------------------
  # Observation Search
  # --------------------------------------------------

  test 'Observation search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    TODO
  end

  test 'Observation search by category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: category' do

    TODO
  end

  test 'Observation search by code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: code' do

    TODO
  end

  test 'Observation search by date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: date' do

    TODO
  end

  test 'Observation search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category' do

    TODO
  end

  test 'Observation search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + date' do

    TODO
  end

  test 'Observation search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + code' do

    TODO
  end

  test 'Observation search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + category + code + date' do

    TODO
  end

  # --------------------------------------------------
  # Procedure Search
  # --------------------------------------------------

  test 'Procedure search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient' do

    TODO
  end

  test 'Procedure search by date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: date' do

    TODO
  end

  test 'Procedure search by patient + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: patient + date' do

    TODO
  end

end
