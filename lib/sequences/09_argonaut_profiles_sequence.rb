# TODO: Is this still valid, or have all of these tests been broken out by FHIR resource?

class ArgonautProfilesSequence < SequenceBase

  group 'Argonaut Query and Data'

  title 'Argonaut Data Profiles'

  modal_before_run

  description 'Verify that the FHIR server follows the Argonaut Data Query Implementation Guide.'

  test_id_prefix 'ADP'

  preconditions 'Argonaut Data Query Sequence must be completed' do
    !@instance.token.nil? && @instance.latest_results.has_key?('ArgonautDataQuery')
  end

  # --------------------------------------------------
  # Patient Profile
  # --------------------------------------------------

  test '01', '', 'Valid DSTU2 patient resource provided and is accessable via read',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning a patient using GET [base]/Patient/[id].' do

    patient_id = @instance.resource_references.select{|r| r.resource_type === 'Patient' }.first.try(:resource_id)

    assert !patient_id.nil?, 'A patient id must be available'

    patient_read_response = @client.read(FHIR::DSTU2::Patient, patient_id)
    assert_response_ok patient_read_response
    @patient = patient_read_response.resource
    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert @patient.is_a?(FHIR::DSTU2::Patient), 'Expected resource to be valid DSTU2 Patient'
  end

  test '02', '', 'Patient validates against Argonaut Profile',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server returns valid FHIR Patient resources according to the Data Access Framework (DAF) Patient Profile (http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-patient.html).' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert @patient.is_a?(FHIR::DSTU2::Patient), 'Expected resource to be valid DSTU2 Patient'
    profile = ValidationUtil.guess_profile(@patient)
    errors = profile.validate_resource(@patient)
    assert errors.empty?, "Patient did not validate against profile: #{errors.join(", ")}"
  end

  test '03', '', 'Patient has address',
          '',
          'Additional Patient resource requirement.' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert @patient.is_a?(FHIR::DSTU2::Patient), 'Expected resource to be valid DSTU2 Patient'
    address = @patient.try(:address).try(:first)
    assert !address.nil?, 'Patient address not returned'
  end

  test '04', '', 'Patient has telecom',
          '',
          'Additional Patient resource requirement.' do

    assert !@patient.nil?, 'Expected valid DSTU2 Patient resource to be present'
    assert @patient.is_a?(FHIR::DSTU2::Patient), 'Expected resource to be valid DSTU2 Patient'
    telecom = @patient.try(:telecom).try(:first)
    assert !telecom.nil?, 'Patient telecom not returned'
  end

  # test 'Resources in the Patient $everything results conform to Argonaut profiles',
  #         'http://www.fhir.org/guides/argonaut/r2/profiles.html', 'DISCUSSION REQUIRED', :optional do

  #   skip_unless !@everything.nil?, 'Expected valid DSTU2 Bundle to be present as a result of $everything request'
  #   assert @everything.is_a?(FHIR::DSTU2::Bundle), 'Expected resource to be valid DSTU2 Bundle'

  #   all_errors = []
  #   @everything.entry.each do |entry|
  #     p = ValidationUtil.guess_profile(entry.resource)
  #     if p
  #       errors = p.validate_resource(entry.resource)
  #       all_errors.concat(errors)
  #     else
  #       errors = entry.resource.validate
  #       all_errors.concat(errors.values)
  #     end
  #   end
  #   assert(all_errors.empty?, all_errors.join("<br/>\n"))
  # end

  attr_accessor :profiles_encountered
  attr_accessor :profiles_failed

  def test_resources_against_profile(resource_type, specified_profile=nil)
    @profiles_encountered = [] unless @profiles_encountered
    @profiles_failed = {} unless @profiles_failed

    all_errors = []

    resources = @instance.resource_references.select{|r| r.resource_type == resource_type}
    skip("Skip profile validation since no #{resource_type} resources found for Patient.") if resources.empty?

    @instance.resource_references.select{|r| r.resource_type == resource_type}.map(&:resource_id).each do |resource_id|

      resource_response = @client.read("FHIR::DSTU2::#{resource_type}", resource_id)
      assert_response_ok resource_response
      resource = resource_response.resource
      assert resource.is_a?("FHIR::DSTU2::#{resource_type}".constantize), "Expected resource to be of type #{resource_type}"

      p = ValidationUtil.guess_profile(resource)
      if specified_profile
        next unless p.url == specified_profile
      end
      if p
        @profiles_encountered << p.url
        @profiles_encountered.uniq!
        errors = p.validate_resource(resource)
        unless errors.empty?
          errors.map!{|e| "#{resource_type}/#{resource_id}: #{e}"}
          @profiles_failed[p.url] = [] unless @profiles_failed[p.url]
          @profiles_failed[p.url].concat(errors)
        end
        all_errors.concat(errors)
      else
        errors = entry.resource.validate
        all_errors.concat(errors.values)
      end
    end
    # TODO
    # bundle = client.next_bundle
    assert(all_errors.empty?, all_errors.join("<br/>\n"))
  end

  test '05', '', 'AllergyIntolerance resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-allergyintolerance.html',
          'AllergyIntolerance resources associated with Patient conform to Argonaut profiles.' do
    test_resources_against_profile('AllergyIntolerance')
  end

  test '06', '', 'CarePlan resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careplan.html',
         'CarePlan resources associated with Patient conform to Argonaut profiles.' do
    test_resources_against_profile('CarePlan', ValidationUtil::CARE_PLAN_URL)
    skip_unless @profiles_encountered.include?(ValidationUtil::CARE_PLAN_URL), 'No CarePlans found.'
    assert !@profiles_failed.include?(ValidationUtil::CARE_PLAN_URL), "CarePlans failed validation.<br/>#{@profiles_failed[ValidationUtil::CARE_PLAN_URL]}"
  end

  test '07', '', 'CareTeam resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careteam.html',
         'CareTeam resources associated with Patient conform to Argonaut profiles.' do
    test_resources_against_profile('CarePlan', ValidationUtil::CARE_TEAM_URL)
    skip_unless @profiles_encountered.include?(ValidationUtil::CARE_TEAM_URL), 'No CareTeams found.'
    assert !@profiles_failed.include?(ValidationUtil::CARE_TEAM_URL), "CareTeams failed validation.<br/>#{@profiles_failed[ValidationUtil::CARE_TEAM_URL]}"
  end

  test '08', '', 'Condition resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-condition.html',
         'Condition resources associated with Patient conform to Argonaut profiles..' do
    test_resources_against_profile('Condition')
  end

  test '09', '', 'Device resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-device.html',
          'Device resources associated with Patient conform to Argonaut profiles' do
    test_resources_against_profile('Device')
  end

  test '10', '', 'DiagnosticReport resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-diagnosticreport.html',
         'DiagnosticReport resources associated with Patient conform to Argonaut profiles.' do
    test_resources_against_profile('DiagnosticReport')
  end

  test '11', '', 'DocumentReference resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-documentreference.html',
          'DocumentReference resources associated with Patient conform to Argonaut profiles.' do
    test_resources_against_profile('DocumentReference')
  end

  test '12', '', 'Goal resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-goal.html',
          'Goal resources associated with Patient conform to Argonaut profiles.' do
    test_resources_against_profile('Goal')
  end

  test '13', '', 'Immunization resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-immunization.html',
          'Immunization resources associated with Patient conform to Argonaut profiles.' do
    test_resources_against_profile('Immunization')
  end

  test '14', '', 'Medication resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medication.html',
          'Medication resources associated with Patient conform to Argonaut profiles.' do
    test_resources_against_profile('Medication')
  end

  test '15', '', 'MedicationOrder resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationorder.html',
          'MedicationOrder resources associated with Patient conform to Argonaut profiles.' do
    test_resources_against_profile('MedicationOrder')
  end

  test '16', '', 'MedicationStatement resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medicationstatement.html',
          'MedicationStatement resources associated with Patient conform to Argonaut profiles.' do
    test_resources_against_profile('MedicationStatement')
  end

  test '17', '', 'Observation Result resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-observationresults.html',
          'Observation Result resources associated with Patient conform to Argonaut profiles.' do
    test_resources_against_profile('Observation', ValidationUtil::OBSERVATION_RESULTS_URL)
    skip_unless @profiles_encountered.include?(ValidationUtil::OBSERVATION_RESULTS_URL), 'No Observation Results found.'
    assert !@profiles_failed.include?(ValidationUtil::OBSERVATION_RESULTS_URL), "Observation Results failed validation.<br/>#{@profiles_failed[ValidationUtil::OBSERVATION_RESULTS_URL]}"
  end

  test '18', '', 'Procedure resources associated with Procedure conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-procedure.html',
          'Procedure resources associated with Procedure conform to Argonaut profiles.' do
    test_resources_against_profile('Procedure')
  end

  test '19', '', 'Smoking Status resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html',
          'Procedure resources associated with Procedure conform to Argonaut profiles.' do
    test_resources_against_profile('Observation', ValidationUtil::SMOKING_STATUS_URL)
    skip_unless @profiles_encountered.include?(ValidationUtil::SMOKING_STATUS_URL), 'No Smoking Status Observations found.'
    assert !@profiles_failed.include?(ValidationUtil::SMOKING_STATUS_URL), "Smoking Status Observations failed validation.<br/>#{@profiles_failed[ValidationUtil::SMOKING_STATUS_URL]}"
  end

  test '20', '', 'Vital Signs resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-vitalsigns.html',
          'Vital Signs resources associated with Patient conform to Argonaut profiles.' do
    test_resources_against_profile('Observation', ValidationUtil::VITAL_SIGNS_URL)
    skip_unless @profiles_encountered.include?(ValidationUtil::VITAL_SIGNS_URL), 'No Vital Sign Observations found.'
    assert !@profiles_failed.include?(ValidationUtil::VITAL_SIGNS_URL), "Vital Sign Observations failed validation.<br/>#{@profiles_failed[ValidationUtil::VITAL_SIGNS_URL]}"
  end
end
