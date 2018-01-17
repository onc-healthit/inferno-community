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

    todo
  end

  test 'Patient search by family',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: family' do

    todo
  end

  test 'Patient search by given',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: given' do

    todo
  end

  test 'Patient search by identifier',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: identifier' do

    todo
  end

  test 'Patient search by gender',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: gender' do

    todo
  end

  test 'Patient search by birthdate',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: birthdate' do

    todo
  end

  test 'Patient search by name + gender',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: name + gender' do

    todo
  end

  test 'Patient search by name + birthdate',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: name + birthdate' do

    todo
  end

  test 'Patient search by family + gender',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: family + gender' do

    todo
  end

  test 'Patient search by given + gender',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'Supported Searches: given + gender' do

    todo
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
