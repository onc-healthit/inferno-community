class ArgonautProfilesSequence < SequenceBase

  description 'The FHIR server properly follows the Argonaut Data Query Implementation Guide.'

  preconditions 'Client must be authorized.' do
    !@instance.token.nil?
  end

  # --------------------------------------------------
  # Patient Profile
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

  test 'Patient has valid communication language',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html',
          'If the data is present, Patient shall include: 2. a communication language' do

    todo
  end

  test 'Patient has valid race',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html',
          'If the data is present, Patient shall include: 3. a race' do

    todo
  end

  test 'Patient has valid ethnicity',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html',
          'If the data is present, Patient shall include: 4. an ethnicity' do

    todo
  end

  test 'Patient has valid birth sex',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html',
          'If the data is present, Patient shall include: 5. a birth sex' do

    todo
  end

  # --------------------------------------------------
  # AllergyIntolerance Profile
  # --------------------------------------------------

  test 'Has AllergyIntolerance resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-allergyintolerance.html' do

    todo
  end

  test 'AllergyIntolerance has valid status',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-allergyintolerance.html',
          'Each AllergyIntolerance must have: 1. a status of the allergy' do

    todo
  end

  test 'AllergyIntolerance has valid code for substance causing adverse reaction',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-allergyintolerance.html',
          'Each AllergyIntolerance must have: 2. a code which indicates the substance responsible for an adverse reaction' do

    todo
  end

  test 'AllergyIntolerance has valid patient',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-allergyintolerance.html',
          'Each AllergyIntolerance must have: 3. a patient' do

    todo
  end

  # --------------------------------------------------
  # CarePlan Profile
  # --------------------------------------------------

  test 'Has CarePlan resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careplan.html' do

    todo
  end

  test 'CarePlan has valid narrative summary',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careplan.html',
          'Each CarePlan must have: 1. a narrative summary of the patient assessment and plan of treatment' do

    todo
  end

  test 'CarePlan has valid patient',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careplan.html',
          'Each CarePlan must have: 2. a patient' do

    todo
  end

  test 'CarePlan has valid status',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careplan.html',
          'Each CarePlan must have: 3. a status' do

    todo
  end

  test 'CarePlan has valid category code',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careplan.html',
          'Each CarePlan must have: 4. a category-code of assess-plan' do

    todo
  end

  # --------------------------------------------------
  # CareTeam Profile
  # --------------------------------------------------

  test 'Has CareTeam resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careteam.html' do

    todo
  end

  test 'CareTeam has valid patient',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careteam.html',
          'Each CareTeam must have: 1. a patient' do

    todo
  end

  test 'CareTeam has valid status code',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careteam.html',
          'Each CareTeam must have: 2. a status code' do

    todo
  end

  test 'CareTeam has valid category code',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careteam.html',
          'Each CareTeam must have: 3. a category code of careteam' do

    todo
  end

  test 'CareTeam has valid participant roles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careteam.html',
          'Each CareTeam must have: 4. a participant role for each careteam member' do

    todo
  end

  test 'CareTeam has valid names of careteam members',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careteam.html',
          'Each CareTeam must have: 5. names of careteam members' do

    todo
  end

  # --------------------------------------------------
  # Condition Profile
  # --------------------------------------------------

  test 'Has Condition resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-condition.html' do

    todo
  end

  test 'Condition has valid patient',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-condition.html',
          'Each Condition must have: 1. a patient' do

    todo
  end

  test 'Condition has valid code that identifies the problem',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-condition.html',
          'Each Condition must have: 2. a code that identifies the problem' do

    todo
  end

  test 'Condition has valid category',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-condition.html',
          'Each Condition must have: 3. a category' do

    todo
  end

  test 'Condition has valid status of the problem',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-condition.html',
          'Each Condition must have: 4. a status of the problem' do

    todo
  end

  test 'Condition has valid verification status',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-condition.html',
          'Each Condition must have: 5. a verification status' do

    todo
  end

  # --------------------------------------------------
  # Device Profile
  # --------------------------------------------------

  test 'Has Device resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-device.html' do

    todo
  end

  test 'Device has valid code identifying the type of resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-device.html',
          'Each Condition must have: 1. a code identifying the type of resource' do

    todo
  end

  test 'Device has valid UDI string',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-device.html',
          'Each Condition must have: 2. a UDI string (udicarrier)' do

    todo
  end

  test 'Device has valid patient',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-device.html',
          'Each Condition must have: 3. a patient' do

    todo
  end

  # --------------------------------------------------
  # DiagnosticReport Profile
  # --------------------------------------------------

  test 'Has DiagnosticReport resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-diagnosticreport.html' do

    todo
  end

  test 'DiagnosticReport has valid status',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-diagnosticreport.html',
          'Each DiagnosticReport must have: 1. a status' do

    todo
  end

  test 'DiagnosticReport has valid category code',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-diagnosticreport.html',
          'Each DiagnosticReport must have: 2. a category code of LAB' do

    todo
  end

  test 'DiagnosticReport has valid code which tells you what is being measured',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-diagnosticreport.html',
          'Each DiagnosticReport must have: 3. a code (preferably a LOINC code) which tells you what is being measured' do

    todo
  end

  test 'DiagnosticReport has valid patient',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-diagnosticreport.html',
          'Each DiagnosticReport must have: 4. a patient' do

    todo
  end

  test 'DiagnosticReport has valid time indicating when the measurement was taken',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-diagnosticreport.html',
          'Each DiagnosticReport must have: 5. a time indicating when the measurement was taken' do

    todo
  end

  test 'DiagnosticReport has valid time indicating when the measurement was reported',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-diagnosticreport.html',
          'Each DiagnosticReport must have: 6. a time indicating when the measurement was reported' do

    todo
  end

  test 'DiagnosticReport has valid indication of who issues the report',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-diagnosticreport.html',
          'Each DiagnosticReport must have: 7. who issues the report' do

    todo
  end

  test 'DiagnosticReport supports valid result(s)',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-diagnosticreport.html',
          'Each DiagnosticReport Must Support: 1. at least one result (discrete observation or image or text representation of the entire result)' do

    todo
  end

  # --------------------------------------------------
  # Observation Results Profile
  # --------------------------------------------------

  test 'Has Observation resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-observationresults.html' do

    todo
  end

  test 'Observation has valid status',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-observationresults.html',
          'Each Observation must have: 1. a status' do

    todo
  end

  test 'Observation has valid category code',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-observationresults.html',
          'Each Observation must have: 2. a category code of laboratory' do

    todo
  end

  test 'Observation has valid code which tells you what is being measured',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-observationresults.html',
          'Each Observation must have: 3. a LOINC code, if available, which tells you what is being measured' do

    todo
  end

  test 'Observation has valid patient',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-observationresults.html',
          'Each Observation must have: 4. a patient' do

    todo
  end

  test 'Observation has valid result value',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-observationresults.html',
          'Each Observation must have: 5. a result value and, if the result value is a numeric quantity, a standard UCUM unit' do

    todo
  end

  test 'Observation has valid time indicating when the measurement was taken',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-observationresults.html',
          'Each Observation SHOULD have: 1. a time indicating when the measurement was taken' do

    todo
  end

  test 'Observation has valid reference range if available',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-observationresults.html',
          'Each Observation SHOULD have: 2. a reference range if available' do

    todo
  end

  # --------------------------------------------------
  # Goal Profile
  # --------------------------------------------------

  test 'Has Goal resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-goal.html' do

    todo
  end

  test 'Goal has valid patient',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-goal.html',
          'Each Goal must have: 1. a patient' do

    todo
  end

  test 'Goal has valid text description of the goal',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-goal.html',
          'Each Goal must have: 2. text description of the goal' do

    todo
  end

  test 'Goal has valid status',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-goal.html',
          'Each Goal must have: 3. a status' do

    todo
  end

  # --------------------------------------------------
  # Immunization Profile
  # --------------------------------------------------

  test 'Has Immunization resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-immunization.html' do

    todo
  end

  test 'Immunization has valid status',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-immunization.html',
          'Each Immunization must have: 1. a status' do

    todo
  end

  test 'Immunization has valid date',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-immunization.html',
          'Each Immunization must have: 2. a date the vaccine was administered' do

    todo
  end

  test 'Immunization has valid vaccine code',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-immunization.html',
          'Each Immunization must have: 3. a vaccine code that identifies the kind of vaccine administered' do

    todo
  end

  test 'Immunization has valid patient',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-immunization.html',
          'Each Immunization must have: 4. a patient' do

    todo
  end

  test 'Immunization has valid flag to indicate whether vaccine was given',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-immunization.html',
          'Each Immunization must have: 5. a flag to indicate whether vaccine was given' do

    todo
  end

  test 'Immunization has valid a flag to indicate whether the vaccine was reported by patient rather than directly administered',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-immunization.html',
          'Each Immunization must have: 6. a flag to indicate whether the vaccine was reported by patient rather than directly administered' do

    todo
  end

  # --------------------------------------------------
  # Medication Profile
  # --------------------------------------------------

  test 'Has Medication resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medication.html' do

    todo
  end

  test 'Medication has valid medication code',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medication.html',
          'Each Medication must have: 1. a medication code' do

    todo
  end

  # --------------------------------------------------
  # MedicationOrder Profile
  # --------------------------------------------------

  test 'Has MedicationOrder resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationorder.html' do

    todo
  end

  test 'MedicationOrder has valid date for when written',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationorder.html',
          'Each MedicationOrder must have: 1. a date for when written' do

    todo
  end

  test 'MedicationOrder has valid status',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationorder.html',
          'Each MedicationOrder must have: 2. a status' do

    todo
  end

  test 'MedicationOrder has valid patient',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationorder.html',
          'Each MedicationOrder must have: 3. a patient' do

    todo
  end

  test 'MedicationOrder has valid prescriber',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationorder.html',
          'Each MedicationOrder must have: 4. a prescriber' do

    todo
  end

  test 'MedicationOrder has valid medication',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationorder.html',
          'Each MedicationOrder must have: 5. a medication' do

    todo
  end

  # --------------------------------------------------
  # MedicationStatement Profile
  # --------------------------------------------------

  test 'Has MedicationStatement resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationstatement.html' do

    todo
  end

  test 'MedicationStatement has valid patient',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationstatement.html',
          'Each MedicationOrder must have: 1. a patient' do

    todo
  end

  test 'MedicationStatement has valid date',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationstatement.html',
          'Each MedicationOrder must have: 2. a date' do

    todo
  end

  test 'MedicationStatement has valid status',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationstatement.html',
          'Each MedicationOrder must have: 3. a status' do

    todo
  end

  test 'MedicationStatement has valid medication',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationstatement.html',
          'Each MedicationOrder must have: 4. a medication' do

    todo
  end

  # --------------------------------------------------
  # Procedure Profile
  # --------------------------------------------------

  test 'Has Procedure resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-procedure.html' do

    todo
  end

  test 'Procedure has valid patient',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-procedure.html',
          'Each Procedure must have: 1. a patient' do

    todo
  end

  test 'Procedure has valid status',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-procedure.html',
          'Each Procedure must have: 2. a status' do

    todo
  end

  test 'Procedure has valid procedure code',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-procedure.html',
          'Each Procedure must have: 3. a code that identifies the type of procedure performed on the patient' do

    todo
  end

  test 'Procedure has valid time indicating when the procedure was performed',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-procedure.html',
          'Each Procedure must have: 4. when the procedure was performed' do

    todo
  end

  # --------------------------------------------------
  # SmokingStatus Profile
  # --------------------------------------------------

  test 'Has Observation resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html' do

    todo
  end

  test 'Observation has valid status',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html',
          'Each Observation must have: 1. a status' do

    todo
  end

  test 'Observation has valid fixed code for smoking observation',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html',
          'Each Observation must have: 2. a fixed code for smoking observation' do

    todo
  end

  test 'Observation has valid patient',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html',
          'Each Observation must have: 3. a patient' do

    todo
  end

  test 'Observation has valid date representing when the smoking status was recorded',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html',
          'Each Observation must have: 4. a date representing when the smoking status was recorded' do

    todo
  end

  test 'Observation has valid result value code for smoking status',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html',
          'Each Observation must have: 5. a result value code for smoking status' do

    todo
  end

  # --------------------------------------------------
  # VitalSigns Profile
  # --------------------------------------------------

  test 'Has Observation resource',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-vitalsigns.html' do

    todo
  end

  test 'Observation has valid status',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-vitalsigns.html',
          'Each Observation must have: 1. a status' do

    todo
  end

  test 'Observation has valid category',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-vitalsigns.html',
          'Each Observation must have: 2. a category code of vital-signs' do

    todo
  end

  test 'Observation has valid code which tells you what is being measured',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-vitalsigns.html',
          'Each Observation must have: 3. a LOINC code which tells you what is being measured' do

    todo
  end

  test 'Observation has valid patient',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-vitalsigns.html',
          'Each Observation must have: 4. a patient' do

    todo
  end

  test 'Observation has valid a time indicating when the measurement was taken',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-vitalsigns.html',
          'Each Observation must have: 5. a time indicating when the measurement was taken' do

    todo
  end

  test 'Observation has valid numeric result value and standard UCUM unit',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-vitalsigns.html',
          'Each Observation must have: 6. a numeric result value and standard UCUM unit' do

    todo
  end

end
