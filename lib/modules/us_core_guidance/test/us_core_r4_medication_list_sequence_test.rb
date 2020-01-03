# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCoreR4MedicationListSequence do
  before do
    @sequence_class = Inferno::Sequence::USCoreR4MedicationListSequence
    @url = 'http://www.example.com/fhir'
    @client = FHIR::Client.new(@url)
    @instance = Inferno::Models::TestingInstance.create
    @patient_id = '123'
    @instance.patient_id = @patient_id
    # @instance.instance_variable_set(:'@module', OpenStruct.new(fhir_version: 'r4'))
  end

  let(:request_with_code) do
    FHIR::MedicationRequest.new(
      medicationCodeableConcept: {
        coding: [
          {
            code: 'abc'
          }
        ]
      }
    )
  end

  let(:request_with_internal_reference) do
    FHIR::MedicationRequest.new(
      medicationReference: {
        reference: '#456'
      }
    )
  end

  let(:request_with_external_reference) do
    FHIR::MedicationRequest.new(
      medicationReference: {
        reference: 'Medication/789'
      }
    )
  end

  let(:requests_without_external_references) do
    [request_with_code, request_with_internal_reference]
  end

  let(:requests_with_external_references) do
    requests_without_external_references + [request_with_external_reference]
  end

  let(:requests_with_medication) do
    requests_with_external_references + [FHIR::Medication.new]
  end

  describe '_include Medications test' do
    before do
      @test = @sequence_class[:include_medications]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'fails if the MedicationRequest search is not successful' do
      stub_request(:get, "#{@url}/MedicationRequest")
        .with(query: { patient: @patient_id, intent: 'order' })
        .to_return(status: 404)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 404. ', exception.message
    end

    it 'fails if the MedicationRequest search does not return a Bundle' do
      stub_request(:get, "#{@url}/MedicationRequest")
        .with(query: { patient: @patient_id, intent: 'order' })
        .to_return(status: 200, body: FHIR::MedicationRequest.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: MedicationRequest', exception.message
    end

    it 'skips if no resources are found' do
      stub_request(:get, "#{@url}/MedicationRequest")
        .with(query: { patient: @patient_id, intent: 'order' })
        .to_return(status: 200, body: FHIR::Bundle.new.to_json)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No MedicationRequests were found', exception.message
    end

    it 'omits if no MedicationRequests with external references are found' do
      stub_request(:get, "#{@url}/MedicationRequest")
        .with(query: { patient: @patient_id, intent: 'order' })
        .to_return(status: 200, body: wrap_resources_in_bundle(requests_without_external_references).to_json)

      exception = assert_raises(Inferno::OmitException) { @sequence.run_test(@test) }

      assert_equal 'No MedicationRequests use external Medication references', exception.message
    end

    it 'fails if the search including Medications is not successful' do
      stub_request(:get, "#{@url}/MedicationRequest")
        .with(query: { patient: @patient_id, intent: 'order' })
        .to_return(status: 200, body: wrap_resources_in_bundle(requests_with_external_references).to_json)
      stub_request(:get, "#{@url}/MedicationRequest")
        .with(query: { patient: @patient_id, intent: 'order', _include: 'MedicationRequest:medication' })
        .to_return(status: 400)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 400. ', exception.message
    end

    it 'fails if the search including Medications does not return a Bundle' do
      stub_request(:get, "#{@url}/MedicationRequest")
        .with(query: { patient: @patient_id, intent: 'order' })
        .to_return(status: 200, body: wrap_resources_in_bundle(requests_with_external_references).to_json)
      stub_request(:get, "#{@url}/MedicationRequest")
        .with(query: { patient: @patient_id, intent: 'order', _include: 'MedicationRequest:medication' })
        .to_return(status: 200, body: FHIR::Medication.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Medication', exception.message
    end

    it 'fails if the Bundle does not contain any Medications' do
      stub_request(:get, "#{@url}/MedicationRequest")
        .with(query: { patient: @patient_id, intent: 'order' })
        .to_return(status: 200, body: wrap_resources_in_bundle(requests_with_external_references).to_json)
      stub_request(:get, "#{@url}/MedicationRequest")
        .with(query: { patient: @patient_id, intent: 'order', _include: 'MedicationRequest:medication' })
        .to_return(status: 200, body: wrap_resources_in_bundle(requests_with_external_references).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'No Medications were included in the search results', exception.message
    end

    it 'succeeds if the Bundle contains Medications' do
      stub_request(:get, "#{@url}/MedicationRequest")
        .with(query: { patient: @patient_id, intent: 'order' })
        .to_return(status: 200, body: wrap_resources_in_bundle(requests_with_external_references).to_json)
      stub_request(:get, "#{@url}/MedicationRequest")
        .with(query: { patient: @patient_id, intent: 'order', _include: 'MedicationRequest:medication' })
        .to_return(status: 200, body: wrap_resources_in_bundle(requests_with_medication).to_json)

      @sequence.run_test(@test)
    end
  end
end
