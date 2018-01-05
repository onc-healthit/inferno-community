class ArgonautSequence < SequenceBase

  description 'The FHIR server properly follows the Argonaut Data Query Implementation Guide.'

  test 'Has Patient resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html',
          'Exact Language' do

    patient_read_response = @client.read(FHIR::DSTU2::Patient, @instance.patient_id)
    assert_response_ok patient_read_response
    @patient = patient_read_response.resource
    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    @patient_details = @patient.to_hash
    assert @patient.is_a?(FHIR::DSTU2::Patient), 'Expected resource to be valid DSTU2 Patient'
  end

  test 'Patient has identifier',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html',
          'Each Patient must have: 1. a patient identifier (e.g. MRN)' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert !@patient_details['id'].nil?, 'Expected Patient to have identifier'
  end

  test 'Patient has name',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html',
          'Each Patient must have: 2. a patient name' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert !@patient_details['name'].nil?, 'Expected Patient to have name'
  end

  test 'Patient has gender',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html',
          'Each Patient must have: 3. a patient gender' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert !@patient_details['gender'].nil?, 'Expected Patient to have gender'
  end
end
