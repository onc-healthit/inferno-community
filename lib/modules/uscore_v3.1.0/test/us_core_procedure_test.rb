# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310ProcedureSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310ProcedureSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.0')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_id = 'example'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'Procedure')
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'Procedure read test' do
    before do
      @procedure_id = '456'
      @test = @sequence_class[:read_interaction]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)
      @sequence.instance_variable_set(:'@procedure', FHIR::Procedure.new(id: @procedure_id))
    end

    it 'skips if the Procedure read interaction is not supported' do
      @instance.server_capabilities.destroy
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.to_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Procedure read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no Procedure has been found' do
      @sequence.instance_variable_set(:'@resources_found', false)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Procedure resources could be found for this patient. Please use patients with more information.', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Procedure',
        resource_id: @procedure_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Procedure/#{@procedure_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Procedure',
        resource_id: @procedure_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Procedure/#{@procedure_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected Procedure resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a Procedure' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Procedure',
        resource_id: @procedure_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Procedure/#{@procedure_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type Procedure.', exception.message
    end

    it 'succeeds when a Procedure resource is read successfully' do
      procedure = FHIR::Procedure.new(
        id: @procedure_id
      )
      Inferno::Models::ResourceReference.create(
        resource_type: 'Procedure',
        resource_id: @procedure_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Procedure/#{@procedure_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: procedure.to_json)

      @sequence.run_test(@test)
    end
  end
end
