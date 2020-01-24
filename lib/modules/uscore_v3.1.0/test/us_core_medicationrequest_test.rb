# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310MedicationrequestSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310MedicationrequestSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.0')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_id = 'example'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'MedicationRequest')
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'MedicationRequest read test' do
    before do
      @medication_request_id = '456'
      @test = @sequence_class[:read_interaction]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)
      @sequence.instance_variable_set(:'@medication_request', FHIR::MedicationRequest.new(id: @medication_request_id))
    end

    it 'skips if the MedicationRequest read interaction is not supported' do
      @instance.server_capabilities.destroy
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.to_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support MedicationRequest read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no MedicationRequest has been found' do
      @sequence.instance_variable_set(:'@resources_found', false)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No MedicationRequest resources could be found for this patient. Please use patients with more information.', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'MedicationRequest',
        resource_id: @medication_request_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/MedicationRequest/#{@medication_request_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'MedicationRequest',
        resource_id: @medication_request_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/MedicationRequest/#{@medication_request_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected MedicationRequest resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a MedicationRequest' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'MedicationRequest',
        resource_id: @medication_request_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/MedicationRequest/#{@medication_request_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type MedicationRequest.', exception.message
    end

    it 'succeeds when a MedicationRequest resource is read successfully' do
      medication_request = FHIR::MedicationRequest.new(
        id: @medication_request_id
      )
      Inferno::Models::ResourceReference.create(
        resource_type: 'MedicationRequest',
        resource_id: @medication_request_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/MedicationRequest/#{@medication_request_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: medication_request.to_json)

      @sequence.run_test(@test)
    end
  end

  describe '#test_medication_inclusion' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @request_with_code = FHIR::MedicationRequest.new(medicationCodeableConcept: { coding: [{ code: 'abc' }] })
      @request_with_internal_reference = FHIR::MedicationRequest.new(medicationReference: { reference: '#456' })
      @request_with_external_reference = FHIR::MedicationRequest.new(medicationReference: { reference: 'Medication/789' })
      @search_params = {
        patient: @instance.patient_id,
        intent: 'order'
      }
      @search_params_with_medication = @search_params.merge(_include: 'MedicationRequest:medication')
    end

    it 'succeeds if no external Medication references are used' do
      @sequence.test_medication_inclusion([@request_with_code, @request_with_internal_reference], @search_params)
    end

    it 'fails if the search including Medications returns a non-success response' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @search_params_with_medication)
        .to_return(status: 400)

      exception = assert_raises(Inferno::AssertionException) do
        @sequence.test_medication_inclusion([@request_with_external_reference], @search_params)
      end

      assert_equal 'Bad response code: expected 200, 201, but found 400. ', exception.message
    end

    it 'fails if the search including Medications does not return a Bundle' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @search_params_with_medication)
        .to_return(status: 200, body: FHIR::MedicationRequest.new.to_json)

      exception = assert_raises(Inferno::AssertionException) do
        @sequence.test_medication_inclusion([@request_with_external_reference], @search_params)
      end

      assert_equal 'Expected FHIR Bundle but found: MedicationRequest', exception.message
    end

    it 'fails if no Medications are present in the search results' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @search_params_with_medication)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::MedicationRequest.new).to_json)

      exception = assert_raises(Inferno::AssertionException) do
        @sequence.test_medication_inclusion([@request_with_external_reference], @search_params)
      end

      assert_equal 'No Medications were included in the search results', exception.message
    end

    it 'succeeds if Medications are present in the search results' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @search_params_with_medication)
        .to_return(status: 200, body: wrap_resources_in_bundle([@request_with_external_reference, FHIR::Medication.new]).to_json)

      @sequence.test_medication_inclusion([@request_with_external_reference], @search_params)
    end
  end
end
