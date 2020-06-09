# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310EncounterSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310EncounterSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.0')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_ids = 'example'
    @instance.patient_ids = @patient_ids
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'Encounter search by patient test' do
    before do
      @test = @sequence_class[:search_by_patient]
      @sequence = @sequence_class.new(@instance, @client)
      @encounter = FHIR.from_contents(load_fixture(:us_core_encounter))
      @encounter_ary = { @sequence.patient_ids.first => @encounter }
      @sequence.instance_variable_set(:'@encounter', @encounter)
      @sequence.instance_variable_set(:'@encounter_ary', @encounter_ary)

      @query = {
        'patient': @sequence.patient_ids.first
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::Models::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        []
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Encounter.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Encounter', exception.message
    end

    it 'skips if an empty Bundle is received' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Bundle.new.to_json)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Encounter resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Encounter.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@encounter_ary.values.flatten).to_json)

      reference_with_type_params = @query.merge('patient': 'Patient/' + @query[:patient])
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: reference_with_type_params, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@encounter_ary.values.flatten).to_json)

      @sequence.run_test(@test)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::Encounter.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: Encounter', exception.message
      end

      it 'succeeds if searching with status returns valid resources' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@encounter]).to_json)

        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('patient': 'Patient/' + @query[:patient], 'status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@encounter]).to_json)

        @sequence.run_test(@test)
      end
    end
  end

  describe 'Encounter search by _id test' do
    before do
      @test = @sequence_class[:search_by__id]
      @sequence = @sequence_class.new(@instance, @client)
      @encounter = FHIR.from_contents(load_fixture(:us_core_encounter))
      @encounter_ary = { @sequence.patient_ids.first => @encounter }
      @sequence.instance_variable_set(:'@encounter', @encounter)
      @sequence.instance_variable_set(:'@encounter_ary', @encounter_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        '_id': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@encounter_ary[@sequence.patient_ids.first], 'id'))
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::Models::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        []
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'skips if no Encounter resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Encounter resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@encounter_ary', @sequence.patient_ids.first => FHIR::Encounter.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Encounter.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Encounter', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Encounter.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@encounter_ary.values.flatten).to_json)

      @sequence.run_test(@test)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::Encounter.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: Encounter', exception.message
      end

      it 'succeeds if searching with status returns valid resources' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@encounter]).to_json)

        @sequence.run_test(@test)
      end
    end
  end

  describe 'Encounter search by date+patient test' do
    before do
      @test = @sequence_class[:search_by_date_patient]
      @sequence = @sequence_class.new(@instance, @client)
      @encounter = FHIR.from_contents(load_fixture(:us_core_encounter))
      @encounter_ary = { @sequence.patient_ids.first => @encounter }
      @sequence.instance_variable_set(:'@encounter', @encounter)
      @sequence.instance_variable_set(:'@encounter_ary', @encounter_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@encounter_ary[@sequence.patient_ids.first], 'period')),
        'patient': @sequence.patient_ids.first
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::Models::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        ['date']
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'skips if no Encounter resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Encounter resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@encounter_ary', @sequence.patient_ids.first => FHIR::Encounter.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Encounter.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Encounter', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Encounter.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::Encounter.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: Encounter', exception.message
      end
    end
  end

  describe 'Encounter search by identifier test' do
    before do
      @test = @sequence_class[:search_by_identifier]
      @sequence = @sequence_class.new(@instance, @client)
      @encounter = FHIR.from_contents(load_fixture(:us_core_encounter))
      @encounter_ary = { @sequence.patient_ids.first => @encounter }
      @sequence.instance_variable_set(:'@encounter', @encounter)
      @sequence.instance_variable_set(:'@encounter_ary', @encounter_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'identifier': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@encounter_ary[@sequence.patient_ids.first], 'identifier'))
      }

      @query_with_system = {
        'identifier': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@encounter_ary[@sequence.patient_ids.first], 'identifier'), true)
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::Models::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        []
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'skips if no Encounter resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Encounter resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@encounter_ary', @sequence.patient_ids.first => FHIR::Encounter.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Encounter.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Encounter', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Encounter.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@encounter_ary.values.flatten).to_json)

      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query_with_system, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@encounter_ary.values.flatten).to_json)

      @sequence.run_test(@test)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::Encounter.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: Encounter', exception.message
      end

      it 'succeeds if searching with status returns valid resources' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@encounter]).to_json)

        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query_with_system.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@encounter]).to_json)

        @sequence.run_test(@test)
      end
    end
  end

  describe 'Encounter search by patient+status test' do
    before do
      @test = @sequence_class[:search_by_patient_status]
      @sequence = @sequence_class.new(@instance, @client)
      @encounter = FHIR.from_contents(load_fixture(:us_core_encounter))
      @encounter_ary = { @sequence.patient_ids.first => @encounter }
      @sequence.instance_variable_set(:'@encounter', @encounter)
      @sequence.instance_variable_set(:'@encounter_ary', @encounter_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @sequence.patient_ids.first,
        'status': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@encounter_ary[@sequence.patient_ids.first], 'status'))
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::Models::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        ['patient']
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'skips if no Encounter resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Encounter resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@encounter_ary', @sequence.patient_ids.first => FHIR::Encounter.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Encounter.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Encounter', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Encounter.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@encounter_ary.values.flatten).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Encounter search by class+patient test' do
    before do
      @test = @sequence_class[:search_by_class_patient]
      @sequence = @sequence_class.new(@instance, @client)
      @encounter = FHIR.from_contents(load_fixture(:us_core_encounter))
      @encounter_ary = { @sequence.patient_ids.first => @encounter }
      @sequence.instance_variable_set(:'@encounter', @encounter)
      @sequence.instance_variable_set(:'@encounter_ary', @encounter_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'class': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@encounter_ary[@sequence.patient_ids.first], 'local_class')),
        'patient': @sequence.patient_ids.first
      }

      @query_with_system = {
        'class': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@encounter_ary[@sequence.patient_ids.first], 'local_class'), true),
        'patient': @sequence.patient_ids.first
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::Models::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        ['class']
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'skips if no Encounter resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Encounter resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@encounter_ary', @sequence.patient_ids.first => FHIR::Encounter.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Encounter.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Encounter', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Encounter.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@encounter_ary.values.flatten).to_json)

      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query_with_system, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@encounter_ary.values.flatten).to_json)

      @sequence.run_test(@test)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::Encounter.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: Encounter', exception.message
      end

      it 'succeeds if searching with status returns valid resources' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@encounter]).to_json)

        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query_with_system.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@encounter]).to_json)

        @sequence.run_test(@test)
      end
    end
  end

  describe 'Encounter search by patient+type test' do
    before do
      @test = @sequence_class[:search_by_patient_type]
      @sequence = @sequence_class.new(@instance, @client)
      @encounter = FHIR.from_contents(load_fixture(:us_core_encounter))
      @encounter_ary = { @sequence.patient_ids.first => @encounter }
      @sequence.instance_variable_set(:'@encounter', @encounter)
      @sequence.instance_variable_set(:'@encounter_ary', @encounter_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @sequence.patient_ids.first,
        'type': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@encounter_ary[@sequence.patient_ids.first], 'type'))
      }

      @query_with_system = {
        'patient': @sequence.patient_ids.first,
        'type': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@encounter_ary[@sequence.patient_ids.first], 'type'), true)
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::Models::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        ['patient']
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'skips if no Encounter resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Encounter resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@encounter_ary', @sequence.patient_ids.first => FHIR::Encounter.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Encounter.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Encounter', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Encounter.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@encounter_ary.values.flatten).to_json)

      stub_request(:get, "#{@base_url}/Encounter")
        .with(query: @query_with_system, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@encounter_ary.values.flatten).to_json)

      @sequence.run_test(@test)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::Encounter.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: Encounter', exception.message
      end

      it 'succeeds if searching with status returns valid resources' do
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@encounter]).to_json)

        stub_request(:get, "#{@base_url}/Encounter")
          .with(query: @query_with_system.merge('status': ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@encounter]).to_json)

        @sequence.run_test(@test)
      end
    end
  end

  describe 'Encounter read test' do
    before do
      @encounter_id = '456'
      @test = @sequence_class[:read_interaction]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)
      @sequence.instance_variable_set(:'@encounter', FHIR::Encounter.new(id: @encounter_id))
    end

    it 'skips if the Encounter read interaction is not supported' do
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.to_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Encounter read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no Encounter has been found' do
      @sequence.instance_variable_set(:'@resources_found', false)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Encounter resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::Models::ResourceReference.create(
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
      Inferno::Models::ResourceReference.create(
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
      Inferno::Models::ResourceReference.create(
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
      Inferno::Models::ResourceReference.create(
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
      Inferno::Models::ResourceReference.create(
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
