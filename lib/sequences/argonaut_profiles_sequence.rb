class ArgonautProfilesSequence < SequenceBase

  description 'The FHIR server properly follows the Argonaut Data Query Implementation Guide.'

  # --------------------------------------------------
  # StructureDefinition-argo-patient
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

  test 'Patient has valid identifier(s)',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html',
          'Each Patient must have: 1. a patient identifier (e.g. MRN)' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert !@patient_details['identifier'].nil?, 'Expected Patient to have Patient.identifier'
    @patient_details['identifier'].each do |identifier|
      assert !(identifier['system'].nil? || identifier['system'].to_s.strip.empty?), 'Expected each Patient.identifier to have Patient.identifier.system'
      assert !(identifier['value'].nil? || identifier['value'].to_s.strip.empty?), 'Expected each Patient.identifier to have Patient.identifier.value'
    end
  end

  test 'Patient has valid name(s)',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html',
          'Each Patient must have: 2. a patient name' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert !@patient_details['name'].nil?, 'Expected Patient to have Patient.name'
    @patient_details['name'].each do |name|
      assert !(name['family'].nil? || name['family'].to_s.strip.empty?), 'Expected each Patient.name to have Patient.name.family'
      assert !(name['given'].nil? || name['given'].to_s.strip.empty?), 'Expected each Patient.name to have Patient.name.given'
    end
  end

  test 'Patient has valid gender',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html',
          'Each Patient must have: 3. a patient gender' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert !@patient_details['gender'].nil?, 'Expected Patient to have Patient.gender'
    assert ['male', 'female', 'other', 'unknown'].include?(@patient_details['gender']), 'Expected Patient gender to be bound to AdministrativeGender ValueSet'
  end

  test 'Patient has valid birth date',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html',
          'If the data is present, Patient shall include: 1. a birth date' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert !@patient_details['birthDate'].nil?, 'Expected Patient to have Patient.birthDate'
  end

  test 'foo' do

    throw "TODO"
  end

end
