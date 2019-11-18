# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310LocationSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310LocationSequence
    @base_url = 'http://www.example.com/fhir'
    @client = FHIR::Client.new(@base_url)
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(token: @token, selected_module: 'uscore_v3.1.0')
    @patient_id = '123'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'Location')
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'Location read test' do
    before do
      @location_id = '456'
      @test = @sequence_class[:resource_read]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'skips if the Location read interaction is not supported' do
      @instance.server_capabilities.destroy
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

      @location_ary = load_json_fixture(:us_core_location_location_ary)
        .map { |resource| FHIR.from_contents(resource.to_json) }
      @sequence.instance_variable_set(:'@location_ary', @location_ary)

      @query = {
        'name': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@location_ary, 'name'))
      }
    end

    it 'skips if the Location search interaction is not supported' do
      @instance.server_capabilities.destroy
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
end
