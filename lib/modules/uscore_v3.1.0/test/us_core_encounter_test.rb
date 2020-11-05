# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310EncounterSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310EncounterSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.0')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_ids = 'example'
    @instance.patient_ids = @patient_ids
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'Encounter read test' do
    before do
      @encounter_id = '456'
      @test = @sequence_class[:resource_read]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'skips if the Encounter read interaction is not supported' do
      Inferno::ServerCapabilities.delete_all
      Inferno::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.as_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Encounter read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no Encounter has been found' do
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Encounter references found from the prior searches', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::ResourceReference.create(
        resource_type: 'Encounter',
        resource_id: @encounter_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Encounter/#{@encounter_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::ResourceReference.create(
        resource_type: 'Encounter',
        resource_id: @encounter_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Encounter/#{@encounter_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected Encounter resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a Encounter' do
      Inferno::ResourceReference.create(
        resource_type: 'Encounter',
        resource_id: @encounter_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Encounter/#{@encounter_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type Encounter.', exception.message
    end

    it 'fails if the resource has an incorrect id' do
      Inferno::ResourceReference.create(
        resource_type: 'Encounter',
        resource_id: @encounter_id,
        testing_instance: @instance
      )

      encounter = FHIR::Encounter.new(
        id: 'wrong_id'
      )

      stub_request(:get, "#{@base_url}/Encounter/#{@encounter_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: encounter.to_json)
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_equal "Expected resource to contain id: #{@encounter_id}", exception.message
    end

    it 'succeeds when a Encounter resource is read successfully' do
      encounter = FHIR::Encounter.new(
        id: @encounter_id
      )
      Inferno::ResourceReference.create(
        resource_type: 'Encounter',
        resource_id: @encounter_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Encounter/#{@encounter_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: encounter.to_json)

      @sequence.run_test(@test)
    end
  end
end
