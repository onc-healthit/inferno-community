# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310PatientSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310PatientSequence
    @base_url = 'http://www.example.com/fhir'
    @client = FHIR::Client.new(@base_url)
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(token: @token, selected_module: 'uscore_v3.1.0')
    @patient_id = 'example'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'Patient')
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'unauthorized search test' do
    before do
      @test = @sequence_class[:unauthorized_search]
      @sequence = @sequence_class.new(@instance, @client)

      @query = {
        '_id': @instance.patient_id
      }
    end

    it 'skips if the Patient search interaction is not supported' do
      @instance.server_capabilities.destroy
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Patient search operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'fails when the token refresh response has a success status' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 401, but found 200', exception.message
    end

    it 'succeeds when the token refresh response has an error status' do
      stub_request(:get, "#{@base_url}/Patient")
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

  describe 'Patient search by _id test' do
    before do
      @test = @sequence_class[:search_by__id]
      @sequence = @sequence_class.new(@instance, @client)
      @patient = FHIR.from_contents(load_fixture(:us_core_patient))
      @patient_ary = [@patient]
      @sequence.instance_variable_set(:'@patient', @patient)
      @sequence.instance_variable_set(:'@patient_ary', @patient_ary)

      @query = {
        '_id': @instance.patient_id
      }
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Patient', exception.message
    end

    it 'skips if an empty Bundle is received' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Bundle.new.to_json)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Patient resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Patient.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@patient_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Patient search by identifier test' do
    before do
      @test = @sequence_class[:search_by_identifier]
      @sequence = @sequence_class.new(@instance, @client)
      @patient = FHIR.from_contents(load_fixture(:us_core_patient))
      @patient_ary = [@patient]
      @sequence.instance_variable_set(:'@patient', @patient)
      @sequence.instance_variable_set(:'@patient_ary', @patient_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'identifier': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@patient_ary, 'identifier'))
      }
    end

    it 'skips if no Patient resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Patient resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@patient_ary', [FHIR::Patient.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Patient', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Patient.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@patient_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Patient search by name test' do
    before do
      @test = @sequence_class[:search_by_name]
      @sequence = @sequence_class.new(@instance, @client)
      @patient = FHIR.from_contents(load_fixture(:us_core_patient))
      @patient_ary = [@patient]
      @sequence.instance_variable_set(:'@patient', @patient)
      @sequence.instance_variable_set(:'@patient_ary', @patient_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'name': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@patient_ary, 'name'))
      }
    end

    it 'skips if no Patient resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Patient resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@patient_ary', [FHIR::Patient.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Patient', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Patient.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@patient_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Patient search by gender+name test' do
    before do
      @test = @sequence_class[:search_by_gender_name]
      @sequence = @sequence_class.new(@instance, @client)
      @patient = FHIR.from_contents(load_fixture(:us_core_patient))
      @patient_ary = [@patient]
      @sequence.instance_variable_set(:'@patient', @patient)
      @sequence.instance_variable_set(:'@patient_ary', @patient_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'gender': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@patient_ary, 'gender')),
        'name': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@patient_ary, 'name'))
      }
    end

    it 'skips if no Patient resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Patient resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@patient_ary', [FHIR::Patient.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Patient', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Patient.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@patient_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Patient search by birthdate+name test' do
    before do
      @test = @sequence_class[:search_by_birthdate_name]
      @sequence = @sequence_class.new(@instance, @client)
      @patient = FHIR.from_contents(load_fixture(:us_core_patient))
      @patient_ary = [@patient]
      @sequence.instance_variable_set(:'@patient', @patient)
      @sequence.instance_variable_set(:'@patient_ary', @patient_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'birthdate': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@patient_ary, 'birthDate')),
        'name': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@patient_ary, 'name'))
      }
    end

    it 'skips if no Patient resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Patient resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@patient_ary', [FHIR::Patient.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Patient', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Patient.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Patient")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@patient_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Patient read test' do
    before do
      @patient_id = '456'
      @test = @sequence_class[:read_interaction]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)
      @sequence.instance_variable_set(:'@patient', FHIR::Patient.new(id: @patient_id))
    end

    it 'skips if the Patient read interaction is not supported' do
      @instance.server_capabilities.destroy
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Patient read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no Patient has been found' do
      @sequence.instance_variable_set(:'@resources_found', false)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Patient resources could be found for this patient. Please use patients with more information.', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Patient',
        resource_id: @patient_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Patient/#{@patient_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Patient',
        resource_id: @patient_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Patient/#{@patient_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected Patient resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a Patient' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Patient',
        resource_id: @patient_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Patient/#{@patient_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Observation.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type Patient.', exception.message
    end

    it 'succeeds when a Patient resource is read successfully' do
      patient = FHIR::Patient.new(
        id: @patient_id
      )
      Inferno::Models::ResourceReference.create(
        resource_type: 'Patient',
        resource_id: @patient_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Patient/#{@patient_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: patient.to_json)

      @sequence.run_test(@test)
    end
  end
end
