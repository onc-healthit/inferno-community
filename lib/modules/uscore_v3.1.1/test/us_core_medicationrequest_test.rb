# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore311MedicationrequestSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore311MedicationrequestSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.1')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_ids = 'example'
    @instance.patient_ids = @patient_ids
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'MedicationRequest search by patient+intent test' do
    before do
      @test = @sequence_class[:search_by_patient_intent]
      @sequence = @sequence_class.new(@instance, @client)
      @medication_request = FHIR.from_contents(load_fixture(:us_core_medicationrequest))
      @medication_request_ary = { @sequence.patient_ids.first => @medication_request }
      @sequence.instance_variable_set(:'@medication_request', @medication_request)
      @sequence.instance_variable_set(:'@medication_request_ary', @medication_request_ary)

      @query = {
        'patient': @sequence.patient_ids.first,
        'intent': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@medication_request_ary[@sequence.patient_ids.first], 'intent'))
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        ['patient']
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
        query_params = {
          'patient': @sequence.patient_ids.first,
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
          'patient': @sequence.patient_ids.first,
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
          'patient': @sequence.patient_ids.first,
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
          'patient': @sequence.patient_ids.first,
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
          'patient': @sequence.patient_ids.first,
          'intent': value
        }
        body =
          if @sequence.resolve_element_from_path(@medication_request, 'intent') == value
            wrap_resources_in_bundle(@medication_request_ary.values.flatten).to_json
          else
            FHIR::Bundle.new.to_json
          end
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: body)
        reference_with_type_params = query_params.merge('patient': 'Patient/' + query_params[:patient])
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: reference_with_type_params, headers: @auth_header)
          .to_return(status: 200, body: body)
      end

      @sequence.run_test(@test)
    end

    it 'stores contained Medication resources for validation in a later test' do
      medication_request = FHIR.from_contents(load_fixture(:med_request_contained))
      medication = medication_request.contained.first
      ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
        query_params = @query.merge('intent': value)
        body =
          if @sequence.resolve_element_from_path(medication_request, 'intent') == value
            wrap_resources_in_bundle([medication_request]).to_json
          else
            FHIR::Bundle.new.to_json
          end
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: body)
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: query_params.merge('patient': 'Patient/' + query_params[:patient]), headers: @auth_header)
          .to_return(status: 200, body: body)
      end

      @sequence.run_test(@test)
      contained_medications = @sequence.instance_variable_get(:@contained_medications)

      assert_equal 1, contained_medications.length
      assert_equal medication.id, contained_medications.first.id
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
          query_params = {
            'patient': @sequence.patient_ids.first,
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
            'patient': @sequence.patient_ids.first,
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
            'patient': @sequence.patient_ids.first,
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
            'patient': @sequence.patient_ids.first,
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
            'patient': @sequence.patient_ids.first,
            'intent': value
          }
          body =
            if @sequence.resolve_element_from_path(@medication_request, 'intent') == value
              wrap_resources_in_bundle([@medication_request]).to_json
            else
              FHIR::Bundle.new.to_json
            end
          stub_request(:get, "#{@base_url}/MedicationRequest")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
          stub_request(:get, "#{@base_url}/MedicationRequest")
            .with(query: query_params.merge('status': ['active,on-hold,cancelled,completed,entered-in-error,stopped,draft,unknown'].first), headers: @auth_header)
            .to_return(status: 200, body: body)
          stub_request(:get, "#{@base_url}/MedicationRequest")
            .with(query: query_params.merge('patient': 'Patient/' + query_params[:patient], 'status': ['active,on-hold,cancelled,completed,entered-in-error,stopped,draft,unknown'].first), headers: @auth_header)
            .to_return(status: 200, body: body)
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
      @medication_request_ary = { @sequence.patient_ids.first => @medication_request }
      @sequence.instance_variable_set(:'@medication_request', @medication_request)
      @sequence.instance_variable_set(:'@medication_request_ary', @medication_request_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @sequence.patient_ids.first,
        'intent': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@medication_request_ary[@sequence.patient_ids.first], 'intent')),
        'status': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@medication_request_ary[@sequence.patient_ids.first], 'status'))
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        ['patient', 'intent']
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'skips if no MedicationRequest resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No MedicationRequest resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@medication_request_ary', @sequence.patient_ids.first => FHIR::MedicationRequest.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
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
        .to_return(status: 200, body: wrap_resources_in_bundle(@medication_request_ary.values.flatten).to_json)

      @sequence.run_test(@test)
    end

    it 'stores contained Medication resources for validation in a later test' do
      medication_request = FHIR.from_contents(load_fixture(:med_request_contained))
      medication = medication_request.contained.first
      ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
        query_params = @query.merge('intent': value)
        body =
          if @sequence.resolve_element_from_path(medication_request, 'intent') == value
            wrap_resources_in_bundle([medication_request]).to_json
          else
            FHIR::Bundle.new.to_json
          end
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: body)
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: query_params.merge('patient': 'Patient/' + query_params[:patient]), headers: @auth_header)
          .to_return(status: 200, body: body)
      end

      @sequence.run_test(@test)
      contained_medications = @sequence.instance_variable_get(:@contained_medications)

      assert_equal 1, contained_medications.length
      assert_equal medication.id, contained_medications.first.id
    end
  end

  describe 'MedicationRequest search by patient+intent+encounter test' do
    before do
      @test = @sequence_class[:search_by_patient_intent_encounter]
      @sequence = @sequence_class.new(@instance, @client)
      @medication_request = FHIR.from_contents(load_fixture(:us_core_medicationrequest))
      @medication_request_ary = { @sequence.patient_ids.first => @medication_request }
      @sequence.instance_variable_set(:'@medication_request', @medication_request)
      @sequence.instance_variable_set(:'@medication_request_ary', @medication_request_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @sequence.patient_ids.first,
        'intent': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@medication_request_ary[@sequence.patient_ids.first], 'intent')),
        'encounter': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@medication_request_ary[@sequence.patient_ids.first], 'encounter'))
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        ['patient', 'intent']
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'skips if no MedicationRequest resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No MedicationRequest resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@medication_request_ary', @sequence.patient_ids.first => FHIR::MedicationRequest.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
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
        .to_return(status: 200, body: wrap_resources_in_bundle(@medication_request_ary.values.flatten).to_json)

      @sequence.run_test(@test)
    end

    it 'stores contained Medication resources for validation in a later test' do
      medication_request = FHIR.from_contents(load_fixture(:med_request_contained))
      medication = medication_request.contained.first
      ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
        query_params = @query.merge('intent': value)
        body =
          if @sequence.resolve_element_from_path(medication_request, 'intent') == value
            wrap_resources_in_bundle([medication_request]).to_json
          else
            FHIR::Bundle.new.to_json
          end
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: body)
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: query_params.merge('patient': 'Patient/' + query_params[:patient]), headers: @auth_header)
          .to_return(status: 200, body: body)
      end

      @sequence.run_test(@test)
      contained_medications = @sequence.instance_variable_get(:@contained_medications)

      assert_equal 1, contained_medications.length
      assert_equal medication.id, contained_medications.first.id
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
      @medication_request_ary = { @sequence.patient_ids.first => @medication_request }
      @sequence.instance_variable_set(:'@medication_request', @medication_request)
      @sequence.instance_variable_set(:'@medication_request_ary', @medication_request_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @sequence.patient_ids.first,
        'intent': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@medication_request_ary[@sequence.patient_ids.first], 'intent')),
        'authoredon': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@medication_request_ary[@sequence.patient_ids.first], 'authoredOn'))
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        ['patient', 'intent']
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'skips if no MedicationRequest resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No MedicationRequest resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@medication_request_ary', @sequence.patient_ids.first => FHIR::MedicationRequest.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
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
        .to_return(status: 200, body: wrap_resources_in_bundle(@medication_request_ary.values.flatten).to_json)

      @sequence.run_test(@test)
    end

    it 'stores contained Medication resources for validation in a later test' do
      medication_request = FHIR.from_contents(load_fixture(:med_request_contained))
      medication = medication_request.contained.first
      ['proposal', 'plan', 'order', 'original-order', 'reflex-order', 'filler-order', 'instance-order', 'option'].each do |value|
        query_params = @query.merge('intent': value)
        body =
          if @sequence.resolve_element_from_path(medication_request, 'intent') == value
            wrap_resources_in_bundle([medication_request]).to_json
          else
            FHIR::Bundle.new.to_json
          end
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: body)
        stub_request(:get, "#{@base_url}/MedicationRequest")
          .with(query: query_params.merge('patient': 'Patient/' + query_params[:patient]), headers: @auth_header)
          .to_return(status: 200, body: body)
      end

      @sequence.run_test(@test)
      contained_medications = @sequence.instance_variable_get(:@contained_medications)

      assert_equal 1, contained_medications.length
      assert_equal medication.id, contained_medications.first.id
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

  describe 'MedicationRequest read test' do
    before do
      @medication_request_id = '456'
      @test = @sequence_class[:read_interaction]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)
      @sequence.instance_variable_set(:'@medication_request', FHIR::MedicationRequest.new(id: @medication_request_id))
    end

    it 'skips if the MedicationRequest read interaction is not supported' do
      Inferno::ServerCapabilities.delete_all
      Inferno::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.as_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support MedicationRequest read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no MedicationRequest has been found' do
      @sequence.instance_variable_set(:'@resources_found', false)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No MedicationRequest resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::ResourceReference.create(
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
      Inferno::ResourceReference.create(
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
      Inferno::ResourceReference.create(
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

    it 'fails if the resource has an incorrect id' do
      Inferno::ResourceReference.create(
        resource_type: 'MedicationRequest',
        resource_id: @medication_request_id,
        testing_instance: @instance
      )

      medication_request = FHIR::MedicationRequest.new(
        id: 'wrong_id'
      )

      stub_request(:get, "#{@base_url}/MedicationRequest/#{@medication_request_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: medication_request.to_json)
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_equal "Expected resource to contain id: #{@medication_request_id}", exception.message
    end

    it 'succeeds when a MedicationRequest resource is read successfully' do
      medication_request = FHIR::MedicationRequest.new(
        id: @medication_request_id
      )
      Inferno::ResourceReference.create(
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
