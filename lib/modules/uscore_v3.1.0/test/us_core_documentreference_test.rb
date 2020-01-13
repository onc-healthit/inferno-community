# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310DocumentreferenceSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310DocumentreferenceSequence
    @base_url = 'http://www.example.com/fhir'
    @client = FHIR::Client.new(@base_url)
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(token: @token, selected_module: 'uscore_v3.1.0')
    @patient_id = 'example'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'DocumentReference')
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

    it 'skips if the DocumentReference search interaction is not supported' do
      @instance.server_capabilities.destroy
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.to_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support DocumentReference search operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'fails when the token refresh response has a success status' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 401, but found 200', exception.message
    end

    it 'succeeds when the token refresh response has an error status' do
      stub_request(:get, "#{@base_url}/DocumentReference")
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

  describe 'DocumentReference search by patient test' do
    before do
      @test = @sequence_class[:search_by_patient]
      @sequence = @sequence_class.new(@instance, @client)
      @document_reference = FHIR.from_contents(load_fixture(:us_core_documentreference))
      @document_reference_ary = [@document_reference]
      @sequence.instance_variable_set(:'@document_reference', @document_reference)
      @sequence.instance_variable_set(:'@document_reference_ary', @document_reference_ary)

      @query = {
        'patient': @instance.patient_id
      }
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::DocumentReference.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: DocumentReference', exception.message
    end

    it 'skips if an empty Bundle is received' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Bundle.new.to_json)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No DocumentReference resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::DocumentReference.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@document_reference_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'DocumentReference search by _id test' do
    before do
      @test = @sequence_class[:search_by__id]
      @sequence = @sequence_class.new(@instance, @client)
      @document_reference = FHIR.from_contents(load_fixture(:us_core_documentreference))
      @document_reference_ary = [@document_reference]
      @sequence.instance_variable_set(:'@document_reference', @document_reference)
      @sequence.instance_variable_set(:'@document_reference_ary', @document_reference_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        '_id': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@document_reference_ary, 'id'))
      }
    end

    it 'skips if no DocumentReference resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No DocumentReference resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@document_reference_ary', [FHIR::DocumentReference.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::DocumentReference.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: DocumentReference', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::DocumentReference.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@document_reference_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'DocumentReference search by patient+type test' do
    before do
      @test = @sequence_class[:search_by_patient_type]
      @sequence = @sequence_class.new(@instance, @client)
      @document_reference = FHIR.from_contents(load_fixture(:us_core_documentreference))
      @document_reference_ary = [@document_reference]
      @sequence.instance_variable_set(:'@document_reference', @document_reference)
      @sequence.instance_variable_set(:'@document_reference_ary', @document_reference_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @instance.patient_id,
        'type': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@document_reference_ary, 'type'))
      }
    end

    it 'skips if no DocumentReference resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No DocumentReference resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@document_reference_ary', [FHIR::DocumentReference.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::DocumentReference.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: DocumentReference', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::DocumentReference.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@document_reference_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'DocumentReference search by patient+category+date test' do
    before do
      @test = @sequence_class[:search_by_patient_category_date]
      @sequence = @sequence_class.new(@instance, @client)
      @document_reference = FHIR.from_contents(load_fixture(:us_core_documentreference))
      @document_reference_ary = [@document_reference]
      @sequence.instance_variable_set(:'@document_reference', @document_reference)
      @sequence.instance_variable_set(:'@document_reference_ary', @document_reference_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @instance.patient_id,
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@document_reference_ary, 'category')),
        'date': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@document_reference_ary, 'date'))
      }
    end

    it 'skips if no DocumentReference resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No DocumentReference resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@document_reference_ary', [FHIR::DocumentReference.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::DocumentReference.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: DocumentReference', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::DocumentReference.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@document_reference_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'DocumentReference search by patient+category test' do
    before do
      @test = @sequence_class[:search_by_patient_category]
      @sequence = @sequence_class.new(@instance, @client)
      @document_reference = FHIR.from_contents(load_fixture(:us_core_documentreference))
      @document_reference_ary = [@document_reference]
      @sequence.instance_variable_set(:'@document_reference', @document_reference)
      @sequence.instance_variable_set(:'@document_reference_ary', @document_reference_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @instance.patient_id,
        'category': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@document_reference_ary, 'category'))
      }
    end

    it 'skips if no DocumentReference resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No DocumentReference resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@document_reference_ary', [FHIR::DocumentReference.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::DocumentReference.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: DocumentReference', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::DocumentReference.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@document_reference_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'DocumentReference search by patient+type+period test' do
    before do
      @test = @sequence_class[:search_by_patient_type_period]
      @sequence = @sequence_class.new(@instance, @client)
      @document_reference = FHIR.from_contents(load_fixture(:us_core_documentreference))
      @document_reference_ary = [@document_reference]
      @sequence.instance_variable_set(:'@document_reference', @document_reference)
      @sequence.instance_variable_set(:'@document_reference_ary', @document_reference_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @instance.patient_id,
        'type': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@document_reference_ary, 'type')),
        'period': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@document_reference_ary, 'context.period'))
      }
    end

    it 'skips if no DocumentReference resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No DocumentReference resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@document_reference_ary', [FHIR::DocumentReference.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::DocumentReference.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: DocumentReference', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::DocumentReference.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end
  end

  describe 'DocumentReference search by patient+status test' do
    before do
      @test = @sequence_class[:search_by_patient_status]
      @sequence = @sequence_class.new(@instance, @client)
      @document_reference = FHIR.from_contents(load_fixture(:us_core_documentreference))
      @document_reference_ary = [@document_reference]
      @sequence.instance_variable_set(:'@document_reference', @document_reference)
      @sequence.instance_variable_set(:'@document_reference_ary', @document_reference_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'patient': @instance.patient_id,
        'status': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@document_reference_ary, 'status'))
      }
    end

    it 'skips if no DocumentReference resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No DocumentReference resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@document_reference_ary', [FHIR::DocumentReference.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::DocumentReference.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: DocumentReference', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::DocumentReference.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/DocumentReference")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@document_reference_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'DocumentReference read test' do
    before do
      @document_reference_id = '456'
      @test = @sequence_class[:read_interaction]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)
      @sequence.instance_variable_set(:'@document_reference', FHIR::DocumentReference.new(id: @document_reference_id))
    end

    it 'skips if the DocumentReference read interaction is not supported' do
      @instance.server_capabilities.destroy
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.to_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support DocumentReference read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no DocumentReference has been found' do
      @sequence.instance_variable_set(:'@resources_found', false)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No DocumentReference resources could be found for this patient. Please use patients with more information.', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'DocumentReference',
        resource_id: @document_reference_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/DocumentReference/#{@document_reference_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'DocumentReference',
        resource_id: @document_reference_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/DocumentReference/#{@document_reference_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected DocumentReference resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a DocumentReference' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'DocumentReference',
        resource_id: @document_reference_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/DocumentReference/#{@document_reference_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type DocumentReference.', exception.message
    end

    it 'succeeds when a DocumentReference resource is read successfully' do
      document_reference = FHIR::DocumentReference.new(
        id: @document_reference_id
      )
      Inferno::Models::ResourceReference.create(
        resource_type: 'DocumentReference',
        resource_id: @document_reference_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/DocumentReference/#{@document_reference_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: document_reference.to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'resource validation test' do
    before do
      @document_reference = FHIR::DocumentReference.new(load_json_fixture(:us_core_documentreference))
      @test = @sequence_class[:validate_resources]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)

      Inferno::Models::ResourceReference.create(
        resource_type: 'DocumentReference',
        resource_id: @document_reference.id,
        testing_instance: @instance
      )
    end

    it 'fails if a resource does not contain a code for a CodeableConcept with a required binding' do
      ['type'].each do |path|
        @sequence.resolve_path(@document_reference, path).each do |concept|
          concept&.coding&.each do |coding|
            coding&.code = nil
            coding&.system = nil
          end
          concept&.text = 'abc'
        end
      end

      stub_request(:get, "#{@base_url}/DocumentReference/#{@document_reference.id}")
        .with(headers: @auth_header)
        .to_return(status: 200, body: @document_reference.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      ['type'].each do |path|
        assert_match(%r{DocumentReference/#{@document_reference.id}: The CodeableConcept at '#{path}' is bound to a required ValueSet but does not contain any codes\.}, exception.message)
      end
    end
  end
end
