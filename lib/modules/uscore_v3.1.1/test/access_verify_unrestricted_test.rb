# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::ONCAccessVerifyUnrestrictedSequence do
  before do
    @sequence_class = Inferno::Sequence::ONCAccessVerifyUnrestrictedSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(url: @base_url, onc_sl_url: @base_url, token: @token, selected_module: 'uscore_v3.1.0')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_ids = 'example'
    @instance.patient_id = @instance.patient_ids = @patient_ids
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'Validate correct scopes granted test' do
    before do
      @test = @sequence_class[:validate_right_scopes]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'passes if all scopes are received without any wildcards' do
      @instance.received_scopes = 'launch/patient openid fhirUser offline_access patient/Medication.read patient/AllergyIntolerance.read patient/CarePlan.read '\
                                  'patient/CareTeam.read patient/Condition.read patient/Device.read patient/DiagnosticReport.read patient/DocumentReference.read '\
                                  'patient/Encounter.read patient/Goal.read patient/Immunization.read patient/Location.read patient/MedicationRequest.read '\
                                  'patient/Observation.read patient/Organization.read patient/Patient.read patient/Practitioner.read patient/PractitionerRole.read '\
                                  'patient/Procedure.read patient/Provenance.read patient/RelatedPerson.read'
      assert_raises(Inferno::PassException) { @sequence.run_test(@test) }
    end

    it 'passes if wildcard resource scopes used' do
      @instance.received_scopes = 'launch/patient openid fhirUser offline_access patient/*.read'
      assert_raises(Inferno::PassException) { @sequence.run_test(@test) }
    end

    it 'passes if wildcard resource and access scopes used' do
      @instance.received_scopes = 'launch/patient openid fhirUser offline_access patient/*.*'
      assert_raises(Inferno::PassException) { @sequence.run_test(@test) }
    end

    it 'passes if wildcard access scopes used' do
      @instance.received_scopes = 'launch/patient openid fhirUser offline_access patient/Medication.* patient/AllergyIntolerance.* patient/CarePlan.* '\
                                  'patient/CareTeam.* patient/Condition.* patient/Device.* patient/DiagnosticReport.* patient/DocumentReference.* '\
                                  'patient/Encounter.* patient/Goal.* patient/Immunization.* patient/Location.* patient/MedicationRequest.* '\
                                  'patient/Observation.* patient/Organization.* patient/Patient.* patient/Practitioner.* patient/PractitionerRole.* '\
                                  'patient/Procedure.* patient/Provenance.* patient/RelatedPerson.*'
      assert_raises(Inferno::PassException) { @sequence.run_test(@test) }
    end

    it 'passes if Medication, PractitionerRole, Location and RelatedPerson are omitted' do
      @instance.received_scopes = 'launch/patient openid fhirUser offline_access patient/AllergyIntolerance.read patient/CarePlan.read '\
                                  'patient/CareTeam.read patient/Condition.read patient/Device.read patient/DiagnosticReport.read patient/DocumentReference.read '\
                                  'patient/Encounter.read patient/Goal.read patient/Immunization.read patient/MedicationRequest.read '\
                                  'patient/Observation.read patient/Organization.read patient/Patient.read patient/Practitioner.read '\
                                  'patient/Procedure.read patient/Provenance.read'
      assert_raises(Inferno::PassException) { @sequence.run_test(@test) }
    end

    it 'passes if unknown scope provided' do
      @instance.received_scopes = 'launch/patient openid fhirUser offline_access patient/Medication.read patient/AllergyIntolerance.read patient/CarePlan.read '\
                                  'patient/CareTeam.read patient/Condition.read patient/Device.read patient/DiagnosticReport.read patient/DocumentReference.read '\
                                  'patient/Encounter.read patient/Goal.read patient/Immunization.read patient/Location.read patient/MedicationRequest.read '\
                                  'patient/Observation.read patient/Organization.read patient/Patient.read patient/Practitioner.read patient/PractitionerRole.read '\
                                  'patient/Procedure.read patient/Provenance.read patient/RelatedPerson.read proprietary_scope'
      assert_raises(Inferno::PassException) { @sequence.run_test(@test) }
    end

    it 'fails if Patient scope is omitted' do
      @instance.received_scopes = 'launch/patient openid fhirUser offline_access patient/Medication.read patient/AllergyIntolerance.read patient/CarePlan.read '\
                                  'patient/CareTeam.read patient/Condition.read patient/Device.read patient/DiagnosticReport.read patient/DocumentReference.read '\
                                  'patient/Encounter.read patient/Goal.read patient/Immunization.read patient/Location.read patient/MedicationRequest.read '\
                                  'patient/Observation.read patient/Organization.read patient/Practitioner.read patient/PractitionerRole.read '\
                                  'patient/Procedure.read patient/Provenance.read patient/RelatedPerson.read'
      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end

    it 'fails if AllergyIntolerance scope is omitted' do
      @instance.received_scopes = 'launch/patient openid fhirUser offline_access patient/Medication.read patient/CarePlan.read '\
                                  'patient/CareTeam.read patient/Condition.read patient/Device.read patient/DiagnosticReport.read patient/DocumentReference.read '\
                                  'patient/Encounter.read patient/Goal.read patient/Immunization.read patient/Location.read patient/MedicationRequest.read '\
                                  'patient/Observation.read patient/Organization.read patient/Patient.read patient/Practitioner.read patient/PractitionerRole.read '\
                                  'patient/Procedure.read patient/Provenance.read patient/RelatedPerson.read'
      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end

    it 'fails if Practitioner scope is omitted' do
      @instance.received_scopes = 'launch/patient openid fhirUser offline_access patient/Medication.read patient/AllergyIntolerance.read patient/CarePlan.read '\
                                  'patient/CareTeam.read patient/Condition.read patient/Device.read patient/DiagnosticReport.read patient/DocumentReference.read '\
                                  'patient/Encounter.read patient/Goal.read patient/Immunization.read patient/Location.read patient/MedicationRequest.read '\
                                  'patient/Observation.read patient/Organization.read patient/Patient.read patient/PractitionerRole.read '\
                                  'patient/Procedure.read patient/Provenance.read patient/RelatedPerson.read'
      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end
  end

  describe 'Validate Patient Authorization' do
    before do
      @test = @sequence_class[:validate_patient_authorization]
      @sequence = @sequence_class.new(@instance, @client)
      @instance.received_scopes = 'launch/patient openid fhirUser offline_access patient/Medication.read patient/AllergyIntolerance.read patient/CarePlan.read '\
                                  'patient/CareTeam.read patient/Condition.read patient/Device.read patient/DiagnosticReport.read patient/DocumentReference.read '\
                                  'patient/Encounter.read patient/Goal.read patient/Immunization.read patient/Location.read patient/MedicationRequest.read '\
                                  'patient/Observation.read patient/Organization.read patient/Patient.read patient/Practitioner.read patient/PractitionerRole.read '\
                                  'patient/Procedure.read patient/Provenance.read patient/RelatedPerson.read'
    end

    it 'passes if success response received' do
      stub_request(:get, "#{@base_url}/Patient/#{@patient_ids}")
        .with(headers: @auth_header)
        .to_return(status: 200)

      assert_raises(Inferno::PassException) { @sequence.run_test(@test) }
    end

    it 'fails if 401 response received' do
      stub_request(:get, "#{@base_url}/Patient/#{@patient_ids}")
        .with(headers: @auth_header)
        .to_return(status: 401)

      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end

    it 'fails if 403 response received' do
      stub_request(:get, "#{@base_url}/Patient/#{@patient_ids}")
        .with(headers: @auth_header)
        .to_return(status: 403)

      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end
  end
  describe 'Validate AllergyIntolerance Authorization' do
    before do
      @test = @sequence_class[:validate_allergyintolerance_authorization]
      @sequence = @sequence_class.new(@instance, @client)
      @instance.received_scopes = 'launch/patient openid fhirUser offline_access patient/Medication.read patient/AllergyIntolerance.read patient/CarePlan.read '\
                                  'patient/CareTeam.read patient/Condition.read patient/Device.read patient/DiagnosticReport.read patient/DocumentReference.read '\
                                  'patient/Encounter.read patient/Goal.read patient/Immunization.read patient/Location.read patient/MedicationRequest.read '\
                                  'patient/Observation.read patient/Organization.read patient/Patient.read patient/Practitioner.read patient/PractitionerRole.read '\
                                  'patient/Procedure.read patient/Provenance.read patient/RelatedPerson.read'
    end

    it 'passes if success response received' do
      stub_request(:get, "#{@base_url}/AllergyIntolerance?patient=#{@patient_ids}")
        .with(headers: @auth_header)
        .to_return(status: 200)

      assert_raises(Inferno::PassException) { @sequence.run_test(@test) }
    end

    it 'fails if 401 response received' do
      stub_request(:get, "#{@base_url}/AllergyIntolerance?patient=#{@patient_ids}")
        .with(headers: @auth_header)
        .to_return(status: 401)

      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end

    it 'fails if 403 response received' do
      stub_request(:get, "#{@base_url}/AllergyIntolerance?patient=#{@patient_ids}")
        .with(headers: @auth_header)
        .to_return(status: 403)

      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end
  end
end
