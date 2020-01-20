# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310ImmunizationSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310ImmunizationSequence
    @base_url = 'http://www.example.com/fhir'
    @client = FHIR::Client.new(@base_url)
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.0')
    @patient_id = 'example'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'Immunization')
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'unauthorized search test' do
    before do
      @test = @sequence_class[:unauthorized_search]
      @sequence = @sequence_class.new(@instance, @client)

      @query = {
        'patient': @instance.patient_id
      }
    end

    it 'skips if the Immunization search interaction is not supported' do
      @instance.server_capabilities.destroy
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.to_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Immunization search operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'fails when the token refresh response has a success status' do
      stub_request(:get, "#{@base_url}/Immunization")
        .with(query: @query)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 401, but found 200', exception.message
    end

    it 'succeeds when the token refresh response has an error status' do
      stub_request(:get, "#{@base_url}/Immunization")
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

  describe 'Immunization search by patient test' do
    before do
      @test = @sequence_class[:search_by_patient]
      @sequence = @sequence_class.new(@instance, @client)
      @immunization = FHIR.from_contents(load_fixture(:us_core_immunization))
      @immunization_ary = [@immunization]
      @sequence.instance_variable_set(:'@immunization', @immunization)
      @sequence.instance_variable_set(:'@immunization_ary', @immunization_ary)

      @query = {
        'patient': @instance.patient_id
      }
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Immunization")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Immunization")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Immunization.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Immunization', exception.message
    end

    it 'skips if an empty Bundle is received' do
      stub_request(:get, "#{@base_url}/Immunization")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Bundle.new.to_json)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Immunization resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Immunization")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Immunization.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Immunization")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@immunization_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Immunization search by patient+date test' do
    before do
      @test = @sequence_class[:search_by_patient_date]
      @sequence = @sequence_class.new(@instance, @client)
      @immunization = FHIR.from_contents(load_fixture(:us_core_immunization))
      @immunization_ary = [@immunization]
      @sequence.instance_variable_set(:'@immunization', @immunization)
      @sequence.instance_variable_set(:'@immunization_ary', @immunization_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @instance.patient_id,
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@immunization_ary, 'occurrence'))
      }
    end

    it 'skips if no Immunization resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Immunization resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@immunization_ary', [FHIR::Immunization.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Immunization")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Immunization")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Immunization.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Immunization', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Immunization")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Immunization.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end
  end

  describe 'Immunization search by patient+status test' do
    before do
      @test = @sequence_class[:search_by_patient_status]
      @sequence = @sequence_class.new(@instance, @client)
      @immunization = FHIR.from_contents(load_fixture(:us_core_immunization))
      @immunization_ary = [@immunization]
      @sequence.instance_variable_set(:'@immunization', @immunization)
      @sequence.instance_variable_set(:'@immunization_ary', @immunization_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @instance.patient_id,
        'status': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@immunization_ary, 'status'))
      }
    end

    it 'skips if no Immunization resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Immunization resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@immunization_ary', [FHIR::Immunization.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Immunization")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Immunization")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Immunization.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Immunization', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Immunization")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Immunization.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Immunization")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@immunization_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Immunization read test' do
    before do
      @immunization_id = '456'
      @test = @sequence_class[:read_interaction]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)
      @sequence.instance_variable_set(:'@immunization', FHIR::Immunization.new(id: @immunization_id))
    end

    it 'skips if the Immunization read interaction is not supported' do
      @instance.server_capabilities.destroy
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.to_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Immunization read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no Immunization has been found' do
      @sequence.instance_variable_set(:'@resources_found', false)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Immunization resources could be found for this patient. Please use patients with more information.', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Immunization',
        resource_id: @immunization_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Immunization/#{@immunization_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Immunization',
        resource_id: @immunization_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Immunization/#{@immunization_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected Immunization resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a Immunization' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Immunization',
        resource_id: @immunization_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Immunization/#{@immunization_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type Immunization.', exception.message
    end

    it 'succeeds when a Immunization resource is read successfully' do
      immunization = FHIR::Immunization.new(
        id: @immunization_id
      )
      Inferno::Models::ResourceReference.create(
        resource_type: 'Immunization',
        resource_id: @immunization_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Immunization/#{@immunization_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: immunization.to_json)

      @sequence.run_test(@test)
    end
  end
end
