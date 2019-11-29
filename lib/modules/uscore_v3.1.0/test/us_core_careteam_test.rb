# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310CareteamSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310CareteamSequence
    @base_url = 'http://www.example.com/fhir'
    @client = FHIR::Client.new(@base_url)
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(token: @token, selected_module: 'uscore_v3.1.0')
    @patient_id = '123'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'CareTeam')
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'unauthorized search test' do
    before do
      @test = @sequence_class[:unauthorized_search]
      @sequence = @sequence_class.new(@instance, @client)

      @query = {
        'patient': @instance.patient_id,
        'status': 'proposed'
      }
    end

    it 'skips if the CareTeam search interaction is not supported' do
      @instance.server_capabilities.destroy
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support CareTeam search operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'fails when the token refresh response has a success status' do
      stub_request(:get, "#{@base_url}/CareTeam")
        .with(query: @query)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 401, but found 200', exception.message
    end

    it 'succeeds when the token refresh response has an error status' do
      stub_request(:get, "#{@base_url}/CareTeam")
        .with(query: @query)
        .to_return(status: 401)

      @sequence.run_test(@test)
    end

    it 'is omitted when no token is set' do
      @instance.token = ''

      exception = assert_raises(Inferno::OmitException) { @sequence.run_test(@test) }

      assert_equal 'Do not test if no bearer token set', exception.message
    end
  end

  describe 'CareTeam read test' do
    before do
      @care_team_id = '456'
      @test = @sequence_class[:read_interaction]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)
      @sequence.instance_variable_set(:'@care_team', FHIR::CareTeam.new(id: @care_team_id))
    end

    it 'skips if the CareTeam read interaction is not supported' do
      @instance.server_capabilities.destroy
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support CareTeam read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no CareTeam has been found' do
      @sequence.instance_variable_set(:'@resources_found', false)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No CareTeam resources could be found for this patient. Please use patients with more information.', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'CareTeam',
        resource_id: @care_team_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/CareTeam/#{@care_team_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'CareTeam',
        resource_id: @care_team_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/CareTeam/#{@care_team_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected CareTeam resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a CareTeam' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'CareTeam',
        resource_id: @care_team_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/CareTeam/#{@care_team_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type CareTeam.', exception.message
    end

    it 'succeeds when a CareTeam resource is read successfully' do
      care_team = FHIR::CareTeam.new(
        id: @care_team_id
      )
      Inferno::Models::ResourceReference.create(
        resource_type: 'CareTeam',
        resource_id: @care_team_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/CareTeam/#{@care_team_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: care_team.to_json)

      @sequence.run_test(@test)
    end
  end
end
