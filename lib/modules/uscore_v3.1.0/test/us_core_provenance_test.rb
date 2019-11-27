# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310ProvenanceSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310ProvenanceSequence
    @base_url = 'http://www.example.com/fhir'
    @client = FHIR::Client.new(@base_url)
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(token: @token, selected_module: 'uscore_v3.1.0')
    @patient_id = 'example'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'Provenance')
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'Provenance read test' do
    before do
      @provenance_id = '456'
      @test = @sequence_class[:resource_read]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'skips if the Provenance read interaction is not supported' do
      @instance.server_capabilities.destroy
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Provenance read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no Provenance has been found' do
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Provenance references found from the prior searches', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Provenance',
        resource_id: @provenance_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Provenance/#{@provenance_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Provenance',
        resource_id: @provenance_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Provenance/#{@provenance_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected Provenance resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a Provenance' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Provenance',
        resource_id: @provenance_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Provenance/#{@provenance_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type Provenance.', exception.message
    end

    it 'succeeds when a Provenance resource is read successfully' do
      provenance = FHIR::Provenance.new(
        id: @provenance_id
      )
      Inferno::Models::ResourceReference.create(
        resource_type: 'Provenance',
        resource_id: @provenance_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Provenance/#{@provenance_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: provenance.to_json)

      @sequence.run_test(@test)
    end
  end
end
