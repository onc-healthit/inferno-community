# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310ResprateSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310ResprateSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.0')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_ids = 'example'
    @instance.patient_ids = @patient_ids
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'Observation search by patient+code test' do
    before do
      @test = @sequence_class[:search_by_patient_code]
      @sequence = @sequence_class.new(@instance, @client)
      @observation = FHIR.from_contents(load_fixture(:resprate))
      @observation_ary = { @sequence.patient_ids.first => @observation }
      @sequence.instance_variable_set(:'@observation', @observation)
      @sequence.instance_variable_set(:'@observation_ary', @observation_ary)

      @query = {
        'patient': @sequence.patient_ids.first,
        'code': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'code'))
      }

      @query_with_system = {
        'patient': @sequence.patient_ids.first,
        'code': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'code'), true)
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
      ['9279-1'].each do |value|
        query_params = {
          'patient': @sequence.patient_ids.first,
          'code': value
        }
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 401)
      end

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      ['9279-1'].each do |value|
        query_params = {
          'patient': @sequence.patient_ids.first,
          'code': value
        }
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: FHIR::Observation.new.to_json)
      end

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Observation', exception.message
    end

    it 'skips if an empty Bundle is received' do
      ['9279-1'].each do |value|
        query_params = {
          'patient': @sequence.patient_ids.first,
          'code': value
        }
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: FHIR::Bundle.new.to_json)
      end

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Observation resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      ['9279-1'].each do |value|
        query_params = {
          'patient': @sequence.patient_ids.first,
          'code': value
        }
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Observation.new(id: '!@#$%')).to_json)
      end

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      ['9279-1'].each do |value|
        query_params = {
          'patient': @sequence.patient_ids.first,
          'code': value
        }
        body =
          if @sequence.resolve_element_from_path(@observation, 'Observation.code.coding.code') == value
            wrap_resources_in_bundle(@observation_ary.values.flatten).to_json
          else
            FHIR::Bundle.new.to_json
          end
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: body)
        reference_with_type_params = query_params.merge('patient': 'Patient/' + query_params[:patient])
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: reference_with_type_params, headers: @auth_header)
          .to_return(status: 200, body: body)
      end

      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query_with_system, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@observation_ary.values.flatten).to_json)

      @sequence.run_test(@test)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        ['9279-1'].each do |value|
          query_params = {
            'patient': @sequence.patient_ids.first,
            'code': value
          }
          stub_request(:get, "#{@base_url}/Observation")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400)
        end

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        ['9279-1'].each do |value|
          query_params = {
            'patient': @sequence.patient_ids.first,
            'code': value
          }
          stub_request(:get, "#{@base_url}/Observation")
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
        ['9279-1'].each do |value|
          query_params = {
            'patient': @sequence.patient_ids.first,
            'code': value
          }
          stub_request(:get, "#{@base_url}/Observation")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
          stub_request(:get, "#{@base_url}/Observation")
            .with(query: query_params.merge('status': ['registered,preliminary,final,amended,corrected,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
            .to_return(status: 500)
        end

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        ['9279-1'].each do |value|
          query_params = {
            'patient': @sequence.patient_ids.first,
            'code': value
          }
          stub_request(:get, "#{@base_url}/Observation")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
          stub_request(:get, "#{@base_url}/Observation")
            .with(query: query_params.merge('status': ['registered,preliminary,final,amended,corrected,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
            .to_return(status: 200, body: FHIR::Observation.new.to_json)
        end

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: Observation', exception.message
      end

      it 'succeeds if searching with status returns valid resources' do
        ['9279-1'].each do |value|
          query_params = {
            'patient': @sequence.patient_ids.first,
            'code': value
          }
          body =
            if @sequence.resolve_element_from_path(@observation, 'Observation.code.coding.code') == value
              wrap_resources_in_bundle([@observation]).to_json
            else
              FHIR::Bundle.new.to_json
            end
          stub_request(:get, "#{@base_url}/Observation")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
          stub_request(:get, "#{@base_url}/Observation")
            .with(query: query_params.merge('status': ['registered,preliminary,final,amended,corrected,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
            .to_return(status: 200, body: body)
          stub_request(:get, "#{@base_url}/Observation")
            .with(query: query_params.merge('patient': 'Patient/' + query_params[:patient], 'status': ['registered,preliminary,final,amended,corrected,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
            .to_return(status: 200, body: body)
        end

        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query_with_system.merge('status': ['registered,preliminary,final,amended,corrected,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@observation]).to_json)

        @sequence.run_test(@test)
      end
    end
  end

  describe 'Observation search by patient+category+date test' do
    before do
      @test = @sequence_class[:search_by_patient_category_date]
      @sequence = @sequence_class.new(@instance, @client)
      @observation = FHIR.from_contents(load_fixture(:resprate))
      @observation_ary = { @sequence.patient_ids.first => @observation }
      @sequence.instance_variable_set(:'@observation', @observation)
      @sequence.instance_variable_set(:'@observation_ary', @observation_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @sequence.patient_ids.first,
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'category')),
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'effective'))
      }

      @query_with_system = {
        'patient': @sequence.patient_ids.first,
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'category'), true),
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'effective'))
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        ['patient', 'category']
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'skips if no Observation resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Observation resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@observation_ary', @sequence.patient_ids.first => FHIR::Observation.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Observation.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Observation', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Observation.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query.merge('status': ['registered,preliminary,final,amended,corrected,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query.merge('status': ['registered,preliminary,final,amended,corrected,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::Observation.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: Observation', exception.message
      end
    end
  end

  describe 'Observation search by patient+category test' do
    before do
      @test = @sequence_class[:search_by_patient_category]
      @sequence = @sequence_class.new(@instance, @client)
      @observation = FHIR.from_contents(load_fixture(:resprate))
      @observation_ary = { @sequence.patient_ids.first => @observation }
      @sequence.instance_variable_set(:'@observation', @observation)
      @sequence.instance_variable_set(:'@observation_ary', @observation_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @sequence.patient_ids.first,
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'category'))
      }

      @query_with_system = {
        'patient': @sequence.patient_ids.first,
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'category'), true)
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

    it 'skips if no Observation resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Observation resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@observation_ary', @sequence.patient_ids.first => FHIR::Observation.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Observation.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Observation', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Observation.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@observation_ary.values.flatten).to_json)

      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query_with_system, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@observation_ary.values.flatten).to_json)

      @sequence.run_test(@test)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query.merge('status': ['registered,preliminary,final,amended,corrected,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query.merge('status': ['registered,preliminary,final,amended,corrected,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::Observation.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: Observation', exception.message
      end

      it 'succeeds if searching with status returns valid resources' do
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query.merge('status': ['registered,preliminary,final,amended,corrected,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@observation]).to_json)

        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query_with_system.merge('status': ['registered,preliminary,final,amended,corrected,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle([@observation]).to_json)

        @sequence.run_test(@test)
      end
    end
  end

  describe 'Observation search by patient+code+date test' do
    before do
      @test = @sequence_class[:search_by_patient_code_date]
      @sequence = @sequence_class.new(@instance, @client)
      @observation = FHIR.from_contents(load_fixture(:resprate))
      @observation_ary = { @sequence.patient_ids.first => @observation }
      @sequence.instance_variable_set(:'@observation', @observation)
      @sequence.instance_variable_set(:'@observation_ary', @observation_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @sequence.patient_ids.first,
        'code': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'code')),
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'effective'))
      }

      @query_with_system = {
        'patient': @sequence.patient_ids.first,
        'code': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'code'), true),
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'effective'))
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        ['patient', 'code']
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'skips if no Observation resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Observation resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@observation_ary', @sequence.patient_ids.first => FHIR::Observation.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Observation.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Observation', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Observation.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Server returned a status of 400 without an OperationOutcome.', exception.message
      end

      it 'warns if the search is not documented in the CapabilityStatement' do
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)

        assert_raises(WebMock::NetConnectNotAllowedError) { @sequence.run_test(@test) }

        warnings = @sequence.instance_variable_get(:@test_warnings)

        assert warnings.present?, 'Test did not generate any warnings.'
        assert warnings.any? { |warning| warning.match(/search interaction for this resource is not documented/) },
               'Test did not generate the expected warning.'
      end

      it 'fails if searching with status is not successful' do
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query.merge('status': ['registered,preliminary,final,amended,corrected,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 500)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Bad response code: expected 200, 201, but found 500. ', exception.message
      end

      it 'fails if searching with status does not return a Bundle' do
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query, headers: @auth_header)
          .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: @query.merge('status': ['registered,preliminary,final,amended,corrected,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
          .to_return(status: 200, body: FHIR::Observation.new.to_json)

        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal 'Expected FHIR Bundle but found: Observation', exception.message
      end
    end
  end

  describe 'Observation search by patient+category+status test' do
    before do
      @test = @sequence_class[:search_by_patient_category_status]
      @sequence = @sequence_class.new(@instance, @client)
      @observation = FHIR.from_contents(load_fixture(:resprate))
      @observation_ary = { @sequence.patient_ids.first => @observation }
      @sequence.instance_variable_set(:'@observation', @observation)
      @sequence.instance_variable_set(:'@observation_ary', @observation_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @sequence.patient_ids.first,
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'category')),
        'status': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'status'))
      }

      @query_with_system = {
        'patient': @sequence.patient_ids.first,
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'category'), true),
        'status': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary[@sequence.patient_ids.first], 'status'))
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        ['patient', 'category']
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'skips if no Observation resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Observation resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@observation_ary', @sequence.patient_ids.first => FHIR::Observation.new)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Observation.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Observation', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Observation.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@observation_ary.values.flatten).to_json)

      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query_with_system, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@observation_ary.values.flatten).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Observation read test' do
    before do
      @observation_id = '456'
      @test = @sequence_class[:read_interaction]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)
      @sequence.instance_variable_set(:'@observation', FHIR::Observation.new(id: @observation_id))
    end

    it 'skips if the Observation read interaction is not supported' do
      Inferno::ServerCapabilities.delete_all
      Inferno::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.as_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Observation read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no Observation has been found' do
      @sequence.instance_variable_set(:'@resources_found', false)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Observation resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::ResourceReference.create(
        resource_type: 'Observation',
        resource_id: @observation_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Observation/#{@observation_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::ResourceReference.create(
        resource_type: 'Observation',
        resource_id: @observation_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Observation/#{@observation_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected Observation resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a Observation' do
      Inferno::ResourceReference.create(
        resource_type: 'Observation',
        resource_id: @observation_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Observation/#{@observation_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type Observation.', exception.message
    end

    it 'fails if the resource has an incorrect id' do
      Inferno::ResourceReference.create(
        resource_type: 'Observation',
        resource_id: @observation_id,
        testing_instance: @instance
      )

      observation = FHIR::Observation.new(
        id: 'wrong_id'
      )

      stub_request(:get, "#{@base_url}/Observation/#{@observation_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: observation.to_json)
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_equal "Expected resource to contain id: #{@observation_id}", exception.message
    end

    it 'succeeds when a Observation resource is read successfully' do
      observation = FHIR::Observation.new(
        id: @observation_id
      )
      Inferno::ResourceReference.create(
        resource_type: 'Observation',
        resource_id: @observation_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Observation/#{@observation_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: observation.to_json)

      @sequence.run_test(@test)
    end
  end
end
