# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310BodyweightSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310BodyweightSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.0')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_id = 'example'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'Observation')
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'unauthorized search test' do
    before do
      @test = @sequence_class[:unauthorized_search]
      @sequence = @sequence_class.new(@instance, @client)

      @query = {
        'patient': 'patient',
        'code': '29463-7'
      }
    end

    it 'skips if the Observation search interaction is not supported' do
      @instance.server_capabilities.destroy
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.to_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Observation search operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'fails when the token refresh response has a success status' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 401, but found 200', exception.message
    end

    it 'succeeds when the token refresh response has an error status' do
      stub_request(:get, "#{@base_url}/Observation")
        .with(query: @query)
        .to_return(status: 401)

      @sequence.run_test(@test)
    end

    it 'is omitted when no token is set' do
      @instance.token = ''

      exception = assert_raises(Inferno::OmitException) { @sequence.run_test(@test) }

      assert_equal 'Do not test if no bearer token set', exception.message
    end
  end

  describe 'Observation search by patient+code test' do
    before do
      @test = @sequence_class[:search_by_patient_code]
      @sequence = @sequence_class.new(@instance, @client)
      @observation = FHIR.from_contents(load_fixture(:bodyweight))
      @observation_ary = [@observation]
      @sequence.instance_variable_set(:'@observation', @observation)
      @sequence.instance_variable_set(:'@observation_ary', @observation_ary)

      @query = {
        'patient': 'patient',
        'code': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@observation_ary, 'code'))
      }
    end

    it 'fails if a non-success response code is received' do
      ['29463-7'].each do |value|
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
      ['29463-7'].each do |value|
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
      ['29463-7'].each do |value|
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
      ['29463-7'].each do |value|
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
      ['29463-7'].each do |value|
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
  end

  describe 'Observation search by patient+category+date test' do
    before do
      @test = @sequence_class[:search_by_patient_category_date]
      @sequence = @sequence_class.new(@instance, @client)
      @observation = FHIR.from_contents(load_fixture(:bodyweight))
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
  end

  describe 'Observation search by patient+category test' do
    before do
      @test = @sequence_class[:search_by_patient_category]
      @sequence = @sequence_class.new(@instance, @client)
      @observation = FHIR.from_contents(load_fixture(:bodyweight))
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
  end

  describe 'Observation search by patient+code+date test' do
    before do
      @test = @sequence_class[:search_by_patient_code_date]
      @sequence = @sequence_class.new(@instance, @client)
      @observation = FHIR.from_contents(load_fixture(:bodyweight))
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
  end

  describe 'Observation search by patient+category+status test' do
    before do
      @test = @sequence_class[:search_by_patient_category_status]
      @sequence = @sequence_class.new(@instance, @client)
      @observation = FHIR.from_contents(load_fixture(:bodyweight))
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

  describe 'Observation read test' do
    before do
      @observation_id = '456'
      @test = @sequence_class[:read_interaction]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)
      @sequence.instance_variable_set(:'@observation', FHIR::Observation.new(id: @observation_id))
    end

    it 'skips if the Observation read interaction is not supported' do
      @instance.server_capabilities.destroy
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.to_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Observation read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no Observation has been found' do
      @sequence.instance_variable_set(:'@resources_found', false)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Observation resources could be found for this patient. Please use patients with more information.', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::Models::ResourceReference.create(
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
      Inferno::Models::ResourceReference.create(
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
      Inferno::Models::ResourceReference.create(
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

    it 'succeeds when a Observation resource is read successfully' do
      observation = FHIR::Observation.new(
        id: @observation_id
      )
      Inferno::Models::ResourceReference.create(
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
