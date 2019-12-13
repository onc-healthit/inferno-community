# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310ConditionSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310ConditionSequence
    @base_url = 'http://www.example.com/fhir'
    @client = FHIR::Client.new(@base_url)
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(token: @token, selected_module: 'uscore_v3.1.0')
    @patient_id = 'example'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'Condition')
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

    it 'skips if the Condition search interaction is not supported' do
      @instance.server_capabilities.destroy
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Condition search operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'fails when the token refresh response has a success status' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 401, but found 200', exception.message
    end

    it 'succeeds when the token refresh response has an error status' do
      stub_request(:get, "#{@base_url}/Condition")
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

  describe 'Condition search by patient test' do
    before do
      @test = @sequence_class[:search_by_patient]
      @sequence = @sequence_class.new(@instance, @client)
      @resources_found = [FHIR.from_contents(load_fixture(:us_core_condition))]

      @query = {
        'patient': @instance.patient_id
      }
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Condition.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Condition', exception.message
    end

    it 'skips if an empty Bundle is received' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Bundle.new.to_json)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Condition resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Condition.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@resources_found).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Condition search by patient+category test' do
    before do
      @test = @sequence_class[:search_by_patient_category]
      @sequence = @sequence_class.new(@instance, @client)
      @resources_found = [FHIR.from_contents(load_fixture(:us_core_condition))]

      @sequence.instance_variable_set(:'@resources_found', @resources_found)

      @query = {
        'patient': @instance.patient_id,
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@resources_found, 'category'))
      }
    end

    it 'skips if no Condition resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', [])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Condition resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@resources_found', [FHIR::Condition.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Condition.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Condition', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Condition.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@resources_found).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Condition search by patient+onset-date test' do
    before do
      @test = @sequence_class[:search_by_patient_onset_date]
      @sequence = @sequence_class.new(@instance, @client)
      @resources_found = [FHIR.from_contents(load_fixture(:us_core_condition))]

      @sequence.instance_variable_set(:'@resources_found', @resources_found)

      @query = {
        'patient': @instance.patient_id,
        'onset-date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@resources_found, 'onsetDateTime'))
      }
    end

    it 'skips if no Condition resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', [])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Condition resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@resources_found', [FHIR::Condition.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Condition.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Condition', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Condition.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end
  end

  describe 'Condition search by patient+clinical-status test' do
    before do
      @test = @sequence_class[:search_by_patient_clinical_status]
      @sequence = @sequence_class.new(@instance, @client)
      @resources_found = [FHIR.from_contents(load_fixture(:us_core_condition))]

      @sequence.instance_variable_set(:'@resources_found', @resources_found)

      @query = {
        'patient': @instance.patient_id,
        'clinical-status': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@resources_found, 'clinicalStatus'))
      }
    end

    it 'skips if no Condition resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', [])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Condition resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@resources_found', [FHIR::Condition.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Condition.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Condition', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Condition.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@resources_found).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Condition search by patient+code test' do
    before do
      @test = @sequence_class[:search_by_patient_code]
      @sequence = @sequence_class.new(@instance, @client)
      @resources_found = [FHIR.from_contents(load_fixture(:us_core_condition))]

      @sequence.instance_variable_set(:'@resources_found', @resources_found)

      @query = {
        'patient': @instance.patient_id,
        'code': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@resources_found, 'code'))
      }
    end

    it 'skips if no Condition resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', [])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Condition resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@resources_found', [FHIR::Condition.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Condition.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: Condition', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::Condition.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/Condition")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@resources_found).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'Condition read test' do
    before do
      @condition_id = '456'
      @test = @sequence_class[:read_interaction]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)
      @sequence.instance_variable_set(:'@resources_found', Array.wrap(FHIR::Condition.new(id: @condition_id)))
    end

    it 'skips if the Condition read interaction is not supported' do
      @instance.server_capabilities.destroy
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Condition read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no Condition has been found' do
      @sequence.instance_variable_set(:'@resources_found', false)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Condition resources could be found for this patient. Please use patients with more information.', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Condition',
        resource_id: @condition_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Condition/#{@condition_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Condition',
        resource_id: @condition_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Condition/#{@condition_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected Condition resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a Condition' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Condition',
        resource_id: @condition_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Condition/#{@condition_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type Condition.', exception.message
    end

    it 'succeeds when a Condition resource is read successfully' do
      condition = FHIR::Condition.new(
        id: @condition_id
      )
      Inferno::Models::ResourceReference.create(
        resource_type: 'Condition',
        resource_id: @condition_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Condition/#{@condition_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: condition.to_json)

      @sequence.run_test(@test)
    end
  end
end
