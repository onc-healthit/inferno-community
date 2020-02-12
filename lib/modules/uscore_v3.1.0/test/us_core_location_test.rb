# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310LocationSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310LocationSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.0')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_ids = 'example'
    @instance.patient_ids = @patient_ids
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'Location read test' do
    before do
      @location_id = '456'
      @test = @sequence_class[:resource_read]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'skips if the Location read interaction is not supported' do
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.to_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Location read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no Location has been found' do
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Location references found from the prior searches', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Location',
        resource_id: @location_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Location/#{@location_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Location',
        resource_id: @location_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Location/#{@location_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected Location resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a Location' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Location',
        resource_id: @location_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Location/#{@location_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type Location.', exception.message
    end

    it 'fails if the resource has an incorrect id' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Location',
        resource_id: @location_id,
        testing_instance: @instance
      )

      location = FHIR::Location.new(
        id: 'wrong_id'
      )

      stub_request(:get, "#{@base_url}/Location/#{@location_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: location.to_json)
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_equal "Expected resource to contain id: #{@location_id}", exception.message
    end

    it 'succeeds when a Location resource is read successfully' do
      location = FHIR::Location.new(
        id: @location_id
      )
      Inferno::Models::ResourceReference.create(
        resource_type: 'Location',
        resource_id: @location_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Location/#{@location_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: location.to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'unauthorized search test' do
    before do
      @test = @sequence_class[:unauthorized_search]
      @sequence = @sequence_class.new(@instance, @client)

      @location_ary = FHIR.from_contents(load_fixture(:us_core_location))
      @sequence.instance_variable_set(:'@location_ary', @location_ary)

      @query = {
        'name': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@location_ary, 'name'))
      }
    end

    it 'skips if the Location search interaction is not supported' do
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.to_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Location search operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'fails when the token refresh response has a success status' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 401, but found 200', exception.message
    end

    it 'succeeds when the token refresh response has an error status' do
      stub_request(:get, "#{@base_url}/Location")
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

  describe 'Location search by name test' do
    before do
      @test = @sequence_class[:search_by_name]
      @sequence = @sequence_class.new(@instance, @client)
      @location = FHIR.from_contents(load_fixture(:us_core_location))
      @location_ary = [@location]
      @sequence.instance_variable_set(:'@location', @location)
      @sequence.instance_variable_set(:'@location_ary', @location_ary)

      @query = {
        'name': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@location_ary, 'name'))
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
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Location.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Location', exception.message
    end

    it 'skips if an empty Bundle is received' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Bundle.new.to_json)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Location resources appear to be available.', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Location.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@location_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Location search by address test' do
    before do
      @test = @sequence_class[:search_by_address]
      @sequence = @sequence_class.new(@instance, @client)
      @location = FHIR.from_contents(load_fixture(:us_core_location))
      @location_ary = [@location]
      @sequence.instance_variable_set(:'@location', @location)
      @sequence.instance_variable_set(:'@location_ary', @location_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'address': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@location_ary, 'address'))
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

    it 'skips if no Location resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Location resources appear to be available.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@location_ary', [FHIR::Location.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Location.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Location', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Location.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@location_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Location search by address-city test' do
    before do
      @test = @sequence_class[:search_by_address_city]
      @sequence = @sequence_class.new(@instance, @client)
      @location = FHIR.from_contents(load_fixture(:us_core_location))
      @location_ary = [@location]
      @sequence.instance_variable_set(:'@location', @location)
      @sequence.instance_variable_set(:'@location_ary', @location_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'address-city': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@location_ary, 'address.city'))
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

    it 'skips if no Location resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Location resources appear to be available.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@location_ary', [FHIR::Location.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Location.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Location', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Location.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@location_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Location search by address-state test' do
    before do
      @test = @sequence_class[:search_by_address_state]
      @sequence = @sequence_class.new(@instance, @client)
      @location = FHIR.from_contents(load_fixture(:us_core_location))
      @location_ary = [@location]
      @sequence.instance_variable_set(:'@location', @location)
      @sequence.instance_variable_set(:'@location_ary', @location_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'address-state': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@location_ary, 'address.state'))
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

    it 'skips if no Location resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Location resources appear to be available.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@location_ary', [FHIR::Location.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Location.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Location', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Location.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@location_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Location search by address-postalcode test' do
    before do
      @test = @sequence_class[:search_by_address_postalcode]
      @sequence = @sequence_class.new(@instance, @client)
      @location = FHIR.from_contents(load_fixture(:us_core_location))
      @location_ary = [@location]
      @sequence.instance_variable_set(:'@location', @location)
      @sequence.instance_variable_set(:'@location_ary', @location_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'address-postalcode': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@location_ary, 'address.postalCode'))
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

    it 'skips if no Location resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Location resources appear to be available.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@location_ary', [FHIR::Location.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve .* in any resource\./, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Location.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Location', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Location.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Location")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@location_ary).to_json)

      @sequence.run_test(@test)
    end
  end
end
