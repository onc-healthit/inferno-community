# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore311CareteamSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore311CareteamSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.1')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_ids = 'example'
    @instance.patient_ids = @patient_ids
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'CareTeam search by patient+status test' do
    before do
      @test = @sequence_class[:search_by_patient_status]
      @sequence = @sequence_class.new(@instance, @client)
      @care_team = FHIR.from_contents(load_fixture(:us_core_careteam))
      @care_team_ary = { @sequence.patient_ids.first => @care_team }
      @sequence.instance_variable_set(:'@care_team', @care_team)
      @sequence.instance_variable_set(:'@care_team_ary', @care_team_ary)

      @query = {
        'patient': @sequence.patient_ids.first,
        'status': @sequence.get_value_for_search_param(@sequence.resolve_element_from_path(@care_team_ary[@sequence.patient_ids.first], 'status'))
      }
    end

    it 'skips if the search params are not supported' do
      capabilities = Inferno::ServerCapabilities.new
      def capabilities.supported_search_params(_)
        ['patient']
      end
      @instance.server_capabilities = capabilities

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_match(/The server doesn't support the search parameters:/, exception.message)
    end

    it 'fails if a non-success response code is received' do
      ['proposed', 'active', 'suspended', 'inactive', 'entered-in-error'].each do |value|
        query_params = {
          'patient': @sequence.patient_ids.first,
          'status': value
        }
        stub_request(:get, "#{@base_url}/CareTeam")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 401)
      end

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if a Bundle is not received' do
      ['proposed', 'active', 'suspended', 'inactive', 'entered-in-error'].each do |value|
        query_params = {
          'patient': @sequence.patient_ids.first,
          'status': value
        }
        stub_request(:get, "#{@base_url}/CareTeam")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: FHIR::CareTeam.new.to_json)
      end

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected FHIR Bundle but found: CareTeam', exception.message
    end

    it 'skips if an empty Bundle is received' do
      ['proposed', 'active', 'suspended', 'inactive', 'entered-in-error'].each do |value|
        query_params = {
          'patient': @sequence.patient_ids.first,
          'status': value
        }
        stub_request(:get, "#{@base_url}/CareTeam")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: FHIR::Bundle.new.to_json)
      end

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No CareTeam resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if the bundle contains a resource which does not conform to the base FHIR spec' do
      ['proposed', 'active', 'suspended', 'inactive', 'entered-in-error'].each do |value|
        query_params = {
          'patient': @sequence.patient_ids.first,
          'status': value
        }
        stub_request(:get, "#{@base_url}/CareTeam")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: wrap_resources_in_bundle(FHIR::CareTeam.new(id: '!@#$%')).to_json)
      end

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_match(/Invalid \w+:/, exception.message)
    end

    it 'succeeds when a bundle containing a valid resource matching the search parameters is returned' do
      ['proposed', 'active', 'suspended', 'inactive', 'entered-in-error'].each do |value|
        query_params = {
          'patient': @sequence.patient_ids.first,
          'status': value
        }
        body =
          if @sequence.resolve_element_from_path(@care_team, 'CareTeam.status') == value
            wrap_resources_in_bundle(@care_team_ary.values.flatten).to_json
          else
            FHIR::Bundle.new.to_json
          end
        stub_request(:get, "#{@base_url}/CareTeam")
          .with(query: query_params, headers: @auth_header)
          .to_return(status: 200, body: body)
        reference_with_type_params = query_params.merge('patient': 'Patient/' + query_params[:patient])
        stub_request(:get, "#{@base_url}/CareTeam")
          .with(query: reference_with_type_params, headers: @auth_header)
          .to_return(status: 200, body: body)
      end

      @sequence.run_test(@test)
    end
  end

  describe 'CareTeam read test' do
    before do
      @care_team_id = '456'
      @test = @sequence_class[:read_interaction]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:'@resources_found', true)
      @sequence.instance_variable_set(:'@care_team', FHIR::CareTeam.new(id: @care_team_id))
    end

    it 'skips if the CareTeam read interaction is not supported' do
      Inferno::ServerCapabilities.delete_all
      Inferno::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.as_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support CareTeam read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no CareTeam has been found' do
      @sequence.instance_variable_set(:'@resources_found', false)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No CareTeam resources appear to be available. Please use patients with more information.', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::ResourceReference.create(
        resource_type: 'CareTeam',
        resource_id: @care_team_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/CareTeam/#{@care_team_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::ResourceReference.create(
        resource_type: 'CareTeam',
        resource_id: @care_team_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/CareTeam/#{@care_team_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected CareTeam resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a CareTeam' do
      Inferno::ResourceReference.create(
        resource_type: 'CareTeam',
        resource_id: @care_team_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/CareTeam/#{@care_team_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type CareTeam.', exception.message
    end

    it 'fails if the resource has an incorrect id' do
      Inferno::ResourceReference.create(
        resource_type: 'CareTeam',
        resource_id: @care_team_id,
        testing_instance: @instance
      )

      care_team = FHIR::CareTeam.new(
        id: 'wrong_id'
      )

      stub_request(:get, "#{@base_url}/CareTeam/#{@care_team_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: care_team.to_json)
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_equal "Expected resource to contain id: #{@care_team_id}", exception.message
    end

    it 'succeeds when a CareTeam resource is read successfully' do
      care_team = FHIR::CareTeam.new(
        id: @care_team_id
      )
      Inferno::ResourceReference.create(
        resource_type: 'CareTeam',
        resource_id: @care_team_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/CareTeam/#{@care_team_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: care_team.to_json)

      @sequence.run_test(@test)
    end
  end
end
