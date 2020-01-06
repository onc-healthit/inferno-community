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
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.to_json
      )
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

      @practitioner_role_ary = FHIR.from_contents(load_fixture(:us_core_practitionerrole))
      @sequence.instance_variable_set(:'@practitioner_role_ary', @practitioner_role_ary)

      @query = {
        'specialty': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@practitioner_role_ary, 'specialty'))
      }
    end

    it 'skips if the PractitionerRole search interaction is not supported' do
      @instance.server_capabilities.destroy
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.to_json
      )
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
        'specialty': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@practitioner_role_ary, 'specialty'))
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

      assert_equal 'No PractitionerRole resources appear to be available.', exception.message
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
        'practitioner': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@practitioner_role_ary, 'practitioner'))
      }
    end

    it 'skips if no PractitionerRole resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No PractitionerRole resources appear to be available.', exception.message
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

  describe 'PractitionerRole chained search by practitioner test' do
    before do
      @test = @sequence_class[:chained_search_by_practitioner]
      @sequence = @sequence_class.new(@instance, @client)
      @practitioner = FHIR::Practitioner.new(name: [{ family: 'FAMILY_NAME' }])
      identifier_system = 'http://www.example.com/system'
      identifier_value = 'IDENTIFIER'
      @practitioner_with_identifier = FHIR::Practitioner.new(
        identifier: [{ system: identifier_system, value: identifier_value }],
        name: [{ family: 'FAMILY_NAME' }]
      )
      @identifier_string = "#{identifier_system}|#{identifier_value}"
      @practitioner_role = FHIR::PractitionerRole.new(
        id: '123',
        practitioner: { reference: 'Practitioner/practitioner1' }
      )

      @sequence.instance_variable_set(:'@practitioner_role_ary', [@practitioner_role])
      @sequence.instance_variable_set(:'@resources_found', true)
    end

    it 'skips if no PractitionerRole resources have been found' do
      @sequence.instance_variable_set(:'@resources_found', false)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No PractitionerRole resources appear to be available.', exception.message
    end

    it 'skips if no PractitionerRoles contain a Practitioner reference' do
      @sequence.instance_variable_set(:'@practitioner_role_ary', [FHIR::PractitionerRole.new])

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No PractitionerRoles containing a Practitioner reference were found', exception.message
    end

    it 'fails if the Practitioner can not be fetched' do
      stub_request(:get, "#{@base_url}/#{@practitioner_role.practitioner.reference}")
        .with(headers: @auth_header)
        .to_return(status: 400)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Unable to resolve Practitioner reference:/, exception.message)
    end

    it 'fails if a Practitioner resource in not received' do
      stub_request(:get, "#{@base_url}/#{@practitioner_role.practitioner.reference}")
        .with(headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Practitioner but found: Patient', exception.message
    end

    it 'skips if the Practitioner has no family name' do
      stub_request(:get, "#{@base_url}/#{@practitioner_role.practitioner.reference}")
        .with(headers: @auth_header)
        .to_return(status: 200, body: FHIR::Practitioner.new.to_json)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'Practitioner has no family name', exception.message
    end

    it 'fails if searching by practitioner.name returns a non-success response' do
      stub_request(:get, "#{@base_url}/#{@practitioner_role.practitioner.reference}")
        .with(headers: @auth_header)
        .to_return(status: 200, body: @practitioner.to_json)
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(headers: @auth_header, query: { 'practitioner.name': @practitioner.name.first.family })
        .to_return(status: 400)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 400. ', exception.message
    end

    it 'fails if searching by practitioner.name does not return a Bundle' do
      stub_request(:get, "#{@base_url}/#{@practitioner_role.practitioner.reference}")
        .with(headers: @auth_header)
        .to_return(status: 200, body: @practitioner.to_json)
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(headers: @auth_header, query: { 'practitioner.name': @practitioner.name.first.family })
        .to_return(status: 200, body: @practitioner_role.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: PractitionerRole', exception.message
    end

    it 'fails if searching by practitioner.name does not return the expected PractitionerRole' do
      stub_request(:get, "#{@base_url}/#{@practitioner_role.practitioner.reference}")
        .with(headers: @auth_header)
        .to_return(status: 200, body: @practitioner.to_json)
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(headers: @auth_header, query: { 'practitioner.name': @practitioner.name.first.family })
        .to_return(status: 200, body: wrap_resources_in_bundle([FHIR::PractitionerRole.new]).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'PractitionerRole with id 123 not found in search results for practitioner.name = FAMILY_NAME', exception.message
    end

    it 'skips if the Practitioner has no identifier' do
      stub_request(:get, "#{@base_url}/#{@practitioner_role.practitioner.reference}")
        .with(headers: @auth_header)
        .to_return(status: 200, body: @practitioner.to_json)
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(headers: @auth_header, query: { 'practitioner.name': @practitioner.name.first.family })
        .to_return(status: 200, body: wrap_resources_in_bundle([@practitioner_role]).to_json)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'Practitioner has no identifier', exception.message
    end

    it 'fails if searching by practitioner.identifier returns a non-success response' do
      stub_request(:get, "#{@base_url}/#{@practitioner_role.practitioner.reference}")
        .with(headers: @auth_header)
        .to_return(status: 200, body: @practitioner_with_identifier.to_json)
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(headers: @auth_header, query: { 'practitioner.name': @practitioner.name.first.family })
        .to_return(status: 200, body: wrap_resources_in_bundle([@practitioner_role]).to_json)
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(headers: @auth_header, query: { 'practitioner.identifier': @identifier_string })
        .to_return(status: 400)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 400. ', exception.message
    end

    it 'fails if searching by practitioner.identifier does not return a Bundle' do
      stub_request(:get, "#{@base_url}/#{@practitioner_role.practitioner.reference}")
        .with(headers: @auth_header)
        .to_return(status: 200, body: @practitioner_with_identifier.to_json)
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(headers: @auth_header, query: { 'practitioner.name': @practitioner.name.first.family })
        .to_return(status: 200, body: wrap_resources_in_bundle([@practitioner_role]).to_json)
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(headers: @auth_header, query: { 'practitioner.identifier': @identifier_string })
        .to_return(status: 200, body: FHIR::PractitionerRole.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: PractitionerRole', exception.message
    end

    it 'fails if searching by practitioner.identifier does not return the expected PractitionerRole' do
      stub_request(:get, "#{@base_url}/#{@practitioner_role.practitioner.reference}")
        .with(headers: @auth_header)
        .to_return(status: 200, body: @practitioner_with_identifier.to_json)
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(headers: @auth_header, query: { 'practitioner.name': @practitioner.name.first.family })
        .to_return(status: 200, body: wrap_resources_in_bundle([@practitioner_role]).to_json)
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(headers: @auth_header, query: { 'practitioner.identifier': @identifier_string })
        .to_return(status: 200, body: wrap_resources_in_bundle([FHIR::PractitionerRole.new]).to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal "PractitionerRole with id 123 not found in search results for practitioner.identifier = #{@identifier_string}", exception.message
    end

    it 'succeeds if the PractitionerRole is found in both chained searches' do
      bundle = wrap_resources_in_bundle([@practitioner_role])
      stub_request(:get, "#{@base_url}/#{@practitioner_role.practitioner.reference}")
        .with(headers: @auth_header)
        .to_return(status: 200, body: @practitioner_with_identifier.to_json)
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(headers: @auth_header, query: { 'practitioner.name': @practitioner.name.first.family })
        .to_return(status: 200, body: bundle.to_json)
      stub_request(:get, "#{@base_url}/PractitionerRole")
        .with(headers: @auth_header, query: { 'practitioner.identifier': @identifier_string })
        .to_return(status: 200, body: bundle.to_json)

      @sequence.run_test(@test)
    end
  end
end
