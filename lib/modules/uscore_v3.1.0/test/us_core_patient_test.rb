# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310PatientSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310PatientSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.0')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_id = 'example'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'Patient')
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
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
        '_id': 'patient'
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

  describe 'Patient search by birthdate+family test' do
    before do
      @test = @sequence_class[:search_by_birthdate_family]
      @sequence = @sequence_class.new(@instance, @client)
      @patient = FHIR.from_contents(load_fixture(:us_core_patient))
      @patient_ary = [@patient]
      @sequence.instance_variable_set(:'@patient', @patient)
      @sequence.instance_variable_set(:'@patient_ary', @patient_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'birthdate': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@patient_ary, 'birthDate')),
        'family': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@patient_ary, 'name.family'))
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

  describe 'Patient search by family+gender test' do
    before do
      @test = @sequence_class[:search_by_family_gender]
      @sequence = @sequence_class.new(@instance, @client)
      @patient = FHIR.from_contents(load_fixture(:us_core_patient))
      @patient_ary = [@patient]
      @sequence.instance_variable_set(:'@patient', @patient)
      @sequence.instance_variable_set(:'@patient_ary', @patient_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'family': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@patient_ary, 'name.family')),
        'gender': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@patient_ary, 'gender'))
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
end
