# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCore311OrganizationSequence do
  before do
    @sequence_class = Inferno::Sequence::USCore311OrganizationSequence
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @instance = Inferno::Models::TestingInstance.create(url: @base_url, token: @token, selected_module: 'uscore_v3.1.1')
    @client = FHIR::Client.for_testing_instance(@instance)
    @patient_ids = 'example'
    @instance.patient_ids = @patient_ids
    @auth_header = { 'Authorization' => "Bearer #{@token}" }
  end

  describe 'Organization read test' do
    before do
      @organization_id = '456'
      @test = @sequence_class[:resource_read]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'skips if the Organization read interaction is not supported' do
      Inferno::Models::ServerCapabilities.create(
        testing_instance_id: @instance.id,
        capabilities: FHIR::CapabilityStatement.new.to_json
      )
      @instance.reload
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      skip_message = 'This server does not support Organization read operation(s) according to conformance statement.'
      assert_equal skip_message, exception.message
    end

    it 'skips if no Organization has been found' do
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No Organization references found from the prior searches', exception.message
    end

    it 'fails if a non-success response code is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Organization',
        resource_id: @organization_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Organization/#{@organization_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 401)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 401. ', exception.message
    end

    it 'fails if no resource is received' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Organization',
        resource_id: @organization_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Organization/#{@organization_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected Organization resource to be present.', exception.message
    end

    it 'fails if the resource returned is not a Organization' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Organization',
        resource_id: @organization_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Organization/#{@organization_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected resource to be of type Organization.', exception.message
    end

    it 'fails if the resource has an incorrect id' do
      Inferno::Models::ResourceReference.create(
        resource_type: 'Organization',
        resource_id: @organization_id,
        testing_instance: @instance
      )

      organization = FHIR::Organization.new(
        id: 'wrong_id'
      )

      stub_request(:get, "#{@base_url}/Organization/#{@organization_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: organization.to_json)
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
      assert_equal "Expected resource to contain id: #{@organization_id}", exception.message
    end

    it 'succeeds when a Organization resource is read successfully' do
      organization = FHIR::Organization.new(
        id: @organization_id
      )
      Inferno::Models::ResourceReference.create(
        resource_type: 'Organization',
        resource_id: @organization_id,
        testing_instance: @instance
      )

      stub_request(:get, "#{@base_url}/Organization/#{@organization_id}")
        .with(query: @query, headers: @auth_header)
        .to_return(status: 200, body: organization.to_json)

      @sequence.run_test(@test)
    end
  end
end
