# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::ONCAccessVerifyRestrictedSequence do
  before do
    @sequence_class = Inferno::Sequence::ONCAccessVerifyRestrictedSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(url: @base_url, onc_sl_url: @base_url, token: @token, selected_module: 'uscore_v3.1.0')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_ids = 'example'
    @instance.patient_id = @instance.patient_ids = @patient_ids
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe '#scope_granting_access' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
    end

    [
      ['returns nil when no resource match', 'Condition', 'patient/Observation.read patient/Patient.read', nil],
      ['returns nil when not read or * access', 'Condition', 'patient/Patient.read patient/Condition.write', nil],
      ['returns nil when not patient-level scope', 'Condition', 'patient/Patient.read user/Condition.read', nil],
      ['returns nil when not exact resource match', 'Condition', 'patient/Patient.read patient/Condition.something.read', nil],
      ['returns nil when case wrong', 'Condition', 'patient/Patient.read patient/condition.read', nil],
      ['returns nil when Patient case wrong', 'Condition', 'patient/Patient.read Patient/Condition.read', nil],
      ['returns scope when read', 'Condition', 'patient/Patient.read patient/Condition.read', 'patient/Condition.read'],
      ['returns scope when operation wildcard', 'Condition', 'patient/Patient.read patient/Condition.*', 'patient/Condition.*'],
      ['returns scope when resource wildcard', 'Condition', 'another_scope patient/*.read yet_another_scope', 'patient/*.read'],
      ['returns scope when resource and operation wildcard', 'Condition', 'another_scope patient/*.* yet_another_scope', 'patient/*.*'],
      ['returns scope when only scope', 'Condition', 'patient/Condition.read', 'patient/Condition.read']
    ].each do |testing_case|
      description, resource, scope, expected_value = testing_case

      it description do
        assert @sequence.scope_granting_access(resource, scope) == expected_value
      end
    end
  end

  describe 'Validate correct scopes granted test' do
    before do
      @test = @sequence_class[:validate_right_scopes]
      @sequence = @sequence_class.new(@instance, @client)
      @instance.onc_sl_expected_resources = 'Observation, Condition, Patient'
    end

    it 'passes if only limited scopes received' do
      @instance.received_scopes = 'launch/patient openid fhirUser patient/Observation.read patient/Condition.read patient/Patient.read'
      assert_raises(Inferno::PassException) { @sequence.run_test(@test) }
    end

    it 'fails if wildcard resource scopes returned' do
      @instance.received_scopes = 'launch/patient openid fhirUser patient/*.read'
      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end

    it 'passes if wildcard access scopes used' do
      @instance.received_scopes = 'launch/patient openid fhirUser patient/Observation.* patient/Condition.* patient/Patient.*'
      assert_raises(Inferno::PassException) { @sequence.run_test(@test) }
    end

    it 'passes if unknown scope provided' do
      @instance.received_scopes = 'proprietary_scope launch/patient openid fhirUser patient/Observation.* patient/Condition.* patient/Patient.*'
      assert_raises(Inferno::PassException) { @sequence.run_test(@test) }
    end

    it 'passes if Practitioner, Organization, Encounter, PractitionerRole, Location, RelatedPerson scope provided' do
      @instance.received_scopes = 'patient/PractitionerRole.read patient/Location.read patient/RelatedPerson.read launch/patient openid fhirUser patient/Observation.read '\
                                  'patient/Condition.read patient/Patient.read patient/Encounter.read patient/Practitioner.read patient/Organization.read'
      assert_raises(Inferno::PassException) { @sequence.run_test(@test) }
    end

    it 'fails if additional resource scope provided' do
      @instance.received_scopes = 'launch/patient openid fhirUser patient/AllergyIntolerance.read patient/Observation.read patient/Condition.read patient/Patient.read'
      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end

    it 'fails if scope chosen to be included is omitted' do
      @instance.received_scopes = 'launch/patient openid fhirUser patient/Condition.read patient/Patient.read'
      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end

    it 'fails if offline_acess received' do
      @instance.received_scopes = 'launch/patient offline_access openid fhirUser patient/Observation.read patient/Condition.read patient/Patient.read'
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
      @instance.onc_sl_expected_resources = 'Observation, Condition, Patient'
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
  describe 'Validate AllergyIntolerance authorization when not selected' do
    before do
      @test = @sequence_class[:validate_allergyintolerance_authorization]
      @sequence = @sequence_class.new(@instance, @client)
      @instance.received_scopes = 'launch/patient openid fhirUser offline_access patient/Observation.read patient/Condition.read '\
                                  'patient/Patient.read'
      @instance.onc_sl_expected_resources = 'Observation, Condition, Patient'
    end

    it 'fails if success response received' do
      stub_request(:get, "#{@base_url}/AllergyIntolerance?patient=#{@patient_ids}")
        .with(headers: @auth_header)
        .to_return(status: 200)

      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end

    it 'passes if 401 response received' do
      stub_request(:get, "#{@base_url}/AllergyIntolerance?patient=#{@patient_ids}")
        .with(headers: @auth_header)
        .to_return(status: 401)

      @sequence.run_test(@test)
    end

    it 'passes if 403 response received' do
      stub_request(:get, "#{@base_url}/AllergyIntolerance?patient=#{@patient_ids}")
        .with(headers: @auth_header)
        .to_return(status: 403)

      @sequence.run_test(@test)
    end
  end
  describe 'Validate AllergyIntolerance authorization when selected by tester' do
    before do
      @test = @sequence_class[:validate_allergyintolerance_authorization]
      @sequence = @sequence_class.new(@instance, @client)
      @instance.received_scopes = 'launch/patient openid fhirUser offline_access patient/AllergyIntolerance.read patient/Observation.read patient/Condition.read '\
                                  'patient/Patient.read'
      @instance.onc_sl_expected_resources = 'AllergyIntolerance,Observation, Condition, Patient'
    end

    it 'passes if success response received' do
      stub_request(:get, "#{@base_url}/AllergyIntolerance?patient=#{@patient_ids}")
        .with(headers: @auth_header)
        .to_return(status: 200)

      assert_raises(Inferno::PassException) { @sequence.run_test(@test) }
    end

    it 'passes if 400 received followed by success' do
      stub_request(:get, "#{@base_url}/AllergyIntolerance?patient=#{@patient_ids}")
        .with(headers: @auth_header)
        .to_return(status: 400, body: { resourceType: 'OperationOutcome' }.to_json)
      stub_request(:get, "#{@base_url}/AllergyIntolerance?patient=#{@patient_ids}&clinical-status=active")
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
