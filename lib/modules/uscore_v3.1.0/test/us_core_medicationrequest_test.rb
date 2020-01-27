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

  describe 'MedicationRequest search by patient+intent test' do
    before do
      @test = @sequence_class[:search_by_patient_intent]
      @sequence = @sequence_class.new(@instance, @client)
      @medication_request = FHIR.from_contents(load_fixture(:us_core_medicationrequest))
      @medication_request_ary = [@medication_request]
      @sequence.instance_variable_set(:'@medication_request', @medication_request)
      @sequence.instance_variable_set(:'@medication_request_ary', @medication_request_ary)

      @query = {
        'patient': 'patient',
        'intent': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@medication_request_ary, 'intent'))
      }
    end

    it 'fails if a non-success response code is received' do
      ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'intent': value
        }
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 401)
      end

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'intent': value
        }
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: FHIR::MedicationRequest.new.to_json)
      end

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: MedicationRequest', exception.message
    end

    it 'skips if an empty Bundle is received' do
      ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'intent': value
        }
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: FHIR::Bundle.new.to_json)
      end

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No MedicationRequest resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'intent': value
        }
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::MedicationRequest.new(id: '!@#$%')).to_json)
      end

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'intent': value
        }
        body =
          if @sequence.resolve_element_from_path(@medication_request, 'intent') == value
            wrap_resources_in_bundle(@medication_request_ary).to_json
          else
            FHIR::Bundle.new.to_json
          end
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: body)
      end

      @sequence.run_test(@test)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
          query_params = {
            'patient': @instance.patient_id,
            'intent': value
          }
          stub_request(:get, "#{@base_url}/MedicationRequest")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400)
        end

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
          query_params = {
            'patient': @instance.patient_id,
            'intent': value
          }
          stub_request(:get, "#{@base_url}/MedicationRequest")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        end

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
          query_params = {
            'patient': @instance.patient_id,
            'intent': value
          }
          stub_request(:get, "#{@base_url}/MedicationRequest")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
          stub_request(:get, "#{@base_url}/MedicationRequest")
            .with(query: query_params.merge('status': ['active,on-hold,cancelled,completed,entered-in-error,stopped,draft,unknown'].first), headers: @auth_header)
            .to_return(status: 500)
        end

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
          query_params = {
            'patient': @instance.patient_id,
            'intent': value
          }
          stub_request(:get, "#{@base_url}/MedicationRequest")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
          stub_request(:get, "#{@base_url}/MedicationRequest")
            .with(query: query_params.merge('status': ['active,on-hold,cancelled,completed,entered-in-error,stopped,draft,unknown'].first), headers: @auth_header)
            .to_return(status: 200, body: FHIR::MedicationRequest.new.to_json)
        end

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: MedicationRequest', exception.message
      end

      it 'succeeds if searching with status returns valid resources' do
        ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
          query_params = {
            'patient': @instance.patient_id,
            'intent': value
          }
          stub_request(:get, "#{@base_url}/MedicationRequest")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
          stub_request(:get, "#{@base_url}/MedicationRequest")
            .with(query: query_params.merge('status': ['active,on-hold,cancelled,completed,entered-in-error,stopped,draft,unknown'].first), headers: @auth_header)
            .to_return(status: 200, body: wrap_resources_in_bundle([@medication_request]).to_json)
        end

        @sequence.run_test(@test)
      end
    end
  end

  describe 'MedicationRequest search by patient+intent+status test' do
    before do
      @test = @sequence_class[:search_by_patient_intent_status]
      @sequence = @sequence_class.new(@instance, @client)
      @medication_request = FHIR.from_contents(load_fixture(:us_core_medicationrequest))
      @medication_request_ary = [@medication_request]
      @sequence.instance_variable_set(:'@medication_request', @medication_request)
      @sequence.instance_variable_set(:'@medication_request_ary', @medication_request_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': 'patient',
        'intent': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@medication_request_ary, 'intent')),
        'status': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@medication_request_ary, 'status'))
      }
    end

    it 'skips if no MedicationRequest resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No MedicationRequest resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@medication_request_ary', [FHIR::MedicationRequest.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::MedicationRequest.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: MedicationRequest', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::MedicationRequest.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@medication_request_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'MedicationRequest search by patient+intent+encounter test' do
    before do
      @test = @sequence_class[:search_by_patient_intent_encounter]
      @sequence = @sequence_class.new(@instance, @client)
      @medication_request = FHIR.from_contents(load_fixture(:us_core_medicationrequest))
      @medication_request_ary = [@medication_request]
      @sequence.instance_variable_set(:'@medication_request', @medication_request)
      @sequence.instance_variable_set(:'@medication_request_ary', @medication_request_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': 'patient',
        'intent': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@medication_request_ary, 'intent')),
        'encounter': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@medication_request_ary, 'encounter'))
      }
    end

    it 'skips if no MedicationRequest resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No MedicationRequest resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@medication_request_ary', [FHIR::MedicationRequest.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::MedicationRequest.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: MedicationRequest', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::MedicationRequest.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@medication_request_ary).to_json)

      @sequence.run_test(@test)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query.merge('status': ['active,on-hold,cancelled,completed,entered-in-error,stopped,draft,unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query.merge('status': ['active,on-hold,cancelled,completed,entered-in-error,stopped,draft,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::MedicationRequest.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: MedicationRequest', exception.message
      end

      it 'succeeds if searching with status returns valid resources' do
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query.merge('status': ['active,on-hold,cancelled,completed,entered-in-error,stopped,draft,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@medication_request]).to_json)

        @sequence.run_test(@test)
      end
    end
  end

  describe 'MedicationRequest search by patient+intent+authoredon test' do
    before do
      @test = @sequence_class[:search_by_patient_intent_authoredon]
      @sequence = @sequence_class.new(@instance, @client)
      @medication_request = FHIR.from_contents(load_fixture(:us_core_medicationrequest))
      @medication_request_ary = [@medication_request]
      @sequence.instance_variable_set(:'@medication_request', @medication_request)
      @sequence.instance_variable_set(:'@medication_request_ary', @medication_request_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': 'patient',
        'intent': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@medication_request_ary, 'intent')),
        'authoredon': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@medication_request_ary, 'authoredOn'))
      }
    end

    it 'skips if no MedicationRequest resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No MedicationRequest resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@medication_request_ary', [FHIR::MedicationRequest.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::MedicationRequest.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: MedicationRequest', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::MedicationRequest.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/MedicationRequest")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@medication_request_ary).to_json)

      @sequence.run_test(@test)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query.merge('status': ['active,on-hold,cancelled,completed,entered-in-error,stopped,draft,unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query.merge('status': ['active,on-hold,cancelled,completed,entered-in-error,stopped,draft,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::MedicationRequest.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: MedicationRequest', exception.message
      end

      it 'succeeds if searching with status returns valid resources' do
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: @query.merge('status': ['active,on-hold,cancelled,completed,entered-in-error,stopped,draft,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@medication_request]).to_json)

        @sequence.run_test(@test)
      end
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
