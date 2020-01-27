# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310BodytempSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310BodytempSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.0')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_id = 'example'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'Observation')
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'Observation search by patient+code test' do
    before do
      @test = @sequence_class[:search_by_patient_code]
      @sequence = @sequence_class.new(@instance, @client)
      @observation = FHIR.from_contents(load_fixture(:bodytemp))
      @observation_ary = [@observation]
      @sequence.instance_variable_set(:'@observation', @observation)
      @sequence.instance_variable_set(:'@observation_ary', @observation_ary)

      @query = {
        'patient': 'patient',
        'code': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary, 'code'))
      }
    end

    it 'fails if a non-success response code is received' do
      ['8310-5'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
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
      ['8310-5'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
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
      ['8310-5'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
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
      ['8310-5'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
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
      ['8310-5'].each do |value|
        query_params = {
          'patient': @instance.patient_id,
          'code': value
        }
        body =
          if @sequence.resolve_element_from_path(@observation, 'code.coding.code') == value
            wrap_resources_in_bundle(@observation_ary).to_json
          else
            FHIR::Bundle.new.to_json
          end
        stub_request(:get, "#{@base_url}/Observation")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: body)
      end

      @sequence.run_test(@test)
    end

    describe 'with servers that require status' do
      it 'fails if a 400 is received without an OperationOutcome' do
        ['8310-5'].each do |value|
          query_params = {
            'patient': @instance.patient_id,
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
        ['8310-5'].each do |value|
          query_params = {
            'patient': @instance.patient_id,
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
        ['8310-5'].each do |value|
          query_params = {
            'patient': @instance.patient_id,
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
        ['8310-5'].each do |value|
          query_params = {
            'patient': @instance.patient_id,
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
        ['8310-5'].each do |value|
          query_params = {
            'patient': @instance.patient_id,
            'code': value
          }
          stub_request(:get, "#{@base_url}/Observation")
            .with(query: query_params, headers: @auth_header)
            .to_return(status: 400, body: FHIR::OperationOutcome.new.to_json)
          stub_request(:get, "#{@base_url}/Observation")
            .with(query: query_params.merge('status': ['registered,preliminary,final,amended,corrected,cancelled,entered-in-error,unknown'].first), headers: @auth_header)
            .to_return(status: 200, body: wrap_resources_in_bundle([@observation]).to_json)
        end

        @sequence.run_test(@test)
      end
    end
  end

  describe 'Observation search by patient+category+date test' do
    before do
      @test = @sequence_class[:search_by_patient_category_date]
      @sequence = @sequence_class.new(@instance, @client)
      @observation = FHIR.from_contents(load_fixture(:bodytemp))
      @observation_ary = [@observation]
      @sequence.instance_variable_set(:'@observation', @observation)
      @sequence.instance_variable_set(:'@observation_ary', @observation_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': 'patient',
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary, 'category')),
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary, 'effective'))
      }
    end

    it 'skips if no Observation resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Observation resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@observation_ary', [FHIR::Observation.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
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
      @observation = FHIR.from_contents(load_fixture(:bodytemp))
      @observation_ary = [@observation]
      @sequence.instance_variable_set(:'@observation', @observation)
      @sequence.instance_variable_set(:'@observation_ary', @observation_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': 'patient',
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary, 'category'))
      }
    end

    it 'skips if no Observation resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Observation resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@observation_ary', [FHIR::Observation.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
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
        .to_return(status: 200, body: wrap_resources_in_bundle(@observation_ary).to_json)

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

        @sequence.run_test(@test)
      end
    end
  end

  describe 'Observation search by patient+code+date test' do
    before do
      @test = @sequence_class[:search_by_patient_code_date]
      @sequence = @sequence_class.new(@instance, @client)
      @observation = FHIR.from_contents(load_fixture(:bodytemp))
      @observation_ary = [@observation]
      @sequence.instance_variable_set(:'@observation', @observation)
      @sequence.instance_variable_set(:'@observation_ary', @observation_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': 'patient',
        'code': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary, 'code')),
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary, 'effective'))
      }
    end

    it 'skips if no Observation resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Observation resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@observation_ary', [FHIR::Observation.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
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
      @observation = FHIR.from_contents(load_fixture(:bodytemp))
      @observation_ary = [@observation]
      @sequence.instance_variable_set(:'@observation', @observation)
      @sequence.instance_variable_set(:'@observation_ary', @observation_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': 'patient',
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary, 'category')),
        'status': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary, 'status'))
      }
    end

    it 'skips if no Observation resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Observation resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@observation_ary', [FHIR::Observation.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
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
        .to_return(status: 200, body: wrap_resources_in_bundle(@observation_ary).to_json)

      @sequence.run_test(@test)
    end
  end
end
