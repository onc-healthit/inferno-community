# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore310PractitionerroleSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore310PractitionerroleSequence
    @base_url = 'http://www.example.com/fhir'
    @client = FHIR::Client.new(@base_url)
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(token: @token, selected_module: 'uscore_v3.1.0')
    @patient_id = 'example'
    @instance.patient_id = @patient_id
    set_resource_support(@instance, 'PractitionerRole')
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'PractitionerRole read test' do
    before do
      @practitioner_role_id = '456'
      @test = @sequence_class[:resource_read]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'skips if the PractitionerRole read interaction is not supported' do
      @instance.server_capabilities.destroy
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support PractitionerRole read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no PractitionerRole has been found' do
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No PractitionerRole references found from the prior searches', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'PractitionerRole',
        resource_id: @practitioner_role_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/PractitionerRole/#{@practitioner_role_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'PractitionerRole',
        resource_id: @practitioner_role_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/PractitionerRole/#{@practitioner_role_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected PractitionerRole resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a PractitionerRole' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'PractitionerRole',
        resource_id: @practitioner_role_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/PractitionerRole/#{@practitioner_role_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type PractitionerRole.', exception.message
    end

    it 'succeeds when a PractitionerRole resource is read successfully' do
      practitioner_role = FHIR::PractitionerRole.new(
        id: @practitioner_role_id
      )
      Inferno::Models::ResourceReference.create(
        resource_type: 'PractitionerRole',
        resource_id: @practitioner_role_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/PractitionerRole/#{@practitioner_role_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: practitioner_role.to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'unauthorized search test' do
    before do
      @test = @sequence_class[:unauthorized_search]
      @sequence = @sequence_class.new(@instance, @client)

      @practitionerrole_ary = FHIR.from_contents(load_fixture(:us_core_practitionerrole))
      @sequence.instance_variable_set(:'@practitionerrole_ary', @practitionerrole_ary)

      @query = {
        'specialty': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@practitionerrole_ary, 'specialty'))
      }
    end

    it 'skips if the PractitionerRole search interaction is not supported' do
      @instance.server_capabilities.destroy
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support PractitionerRole search operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'fails when the token refresh response has a success status' do
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(query: @query)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 401, but found 200', exception.message
    end

    it 'succeeds when the token refresh response has an error status' do
      stub_request(:get, "#{@base_url}/PractitionerRole")
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

  describe 'PractitionerRole search by specialty test' do
    before do
      @test = @sequence_class[:search_by_specialty]
      @sequence = @sequence_class.new(@instance, @client)
      @practitioner_role = FHIR.from_contents(load_fixture(:us_core_practitionerrole))
      @practitioner_role_ary = [@practitioner_role]
      @sequence.instance_variable_set(:'@practitioner_role', @practitioner_role)
      @sequence.instance_variable_set(:'@practitioner_role_ary', @practitioner_role_ary)

      @query = {
        'specialty': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@practitionerrole_ary, 'specialty'))
      }
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::PractitionerRole.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: PractitionerRole', exception.message
    end

    it 'skips if an empty Bundle is received' do
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Bundle.new.to_json)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No resources appear to be available for this patient. Please use patients with more information.', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::PractitionerRole.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@practitioner_role_ary).to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'PractitionerRole search by practitioner test' do
    before do
      @test = @sequence_class[:search_by_practitioner]
      @sequence = @sequence_class.new(@instance, @client)
      @practitioner_role = FHIR.from_contents(load_fixture(:us_core_practitionerrole))
      @practitioner_role_ary = [@practitioner_role]
      @sequence.instance_variable_set(:'@practitioner_role', @practitioner_role)
      @sequence.instance_variable_set(:'@practitioner_role_ary', @practitioner_role_ary)

      @sequence.instance_variable_set(:'@resources_found', true)

      @query = {
        'practitioner': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@practitionerrole_ary, 'practitioner'))
      }
    end

    it 'skips if no PractitionerRole resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No resources appear to be available for this patient. Please use patients with more information.', exception.message
    end

    it 'skips if a value for one of the search parameters cannot be found' do
      @sequence.instance_variable_set(:'@practitioner_role_ary', [FHIR::PractitionerRole.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/Could not resolve [\w-]+ in given resource/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::PractitionerRole.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: PractitionerRole', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::PractitionerRole.new(id: '!@#$%')).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: wrap_resources_in_bundle(@practitioner_role_ary).to_json)

      @sequence.run_test(@test)
    end
  end
end
