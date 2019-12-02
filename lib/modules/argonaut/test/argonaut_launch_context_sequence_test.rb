# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::ArgonautLaunchContextSequence do
  before do
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @patient_id = '123'
    @encounter_id = '456'
    @sequence_class = Inferno::Sequence::ArgonautLaunchContextSequence
    @client = FHIR::Client.new(@base_url)
    @client.set_bearer_token(@token)
    @instance = Inferno::Models::TestingInstance.create
    @instance.patient_id = @patient_id
  end

  describe 'unauthenticated read test' do
    before do
      @test = @sequence_class[:unauthenticated_read]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'skips if no token is set' do
      assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }
    end

    it 'fails when the server does not return a 401' do
      @instance.token = 'ABC'
      stub_request(:get, "#{@base_url}/Patient/#{@patient_id}")
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal exception.message, 'Bad response code: expected 401, but found 200'
    end

    it 'succeeds when the server returns a 401' do
      @instance.token = @token
      stub_request(:get, "#{@base_url}/Patient/#{@patient_id}")
        .to_return(status: 401)

      @sequence.run_test(@test)
    end
  end

  describe 'patient read test' do
    before do
      @test = @sequence_class[:patient_read]
      @sequence = @sequence_class.new(@instance, @client)
      @instance.token = @token
    end

    it 'fails when the server does not return a 200' do
      stub_request(:get, "#{@base_url}/Patient/#{@patient_id}")
        .with(headers: { 'Authorization' => "Bearer #{@instance.token}" })
        .to_return(status: 202)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal exception.message, 'Bad response code: expected 200, 201, but found 202. '
    end

    it 'fails when the server does not return a FHIR resource' do
      stub_request(:get, "#{@base_url}/Patient/#{@patient_id}")
        .with(headers: { 'Authorization' => "Bearer #{@instance.token}" })
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal exception.message, 'Expected response to be a Patient resource'
    end

    it 'fails when the server does not return a Patient Resource' do
      stub_request(:get, "#{@base_url}/Patient/#{@patient_id}")
        .with(headers: { 'Authorization' => "Bearer #{@instance.token}" })
        .to_return(status: 200, body: FHIR::DSTU2::Condition.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal exception.message, 'Expected response to be a Patient resource'
    end

    it 'succeeds when the server returns a Patient Resource' do
      stub_request(:get, "#{@base_url}/Patient/#{@patient_id}")
        .with(headers: { 'Authorization' => "Bearer #{@instance.token}" })
        .to_return(status: 200, body: FHIR::DSTU2::Patient.new.to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'encounter read test' do
    before do
      @test = @sequence_class[:encounter_read]
      @sequence = @sequence_class.new(@instance, @client)
      @instance.token = @token
      @instance.encounter_id = @encounter_id
    end

    it 'skips if no encounter id is known' do
      @instance.encounter_id = nil
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal exception.message, 'No Encounter ID found in launch context'
    end

    it 'fails when the server does not return a 200' do
      stub_request(:get, "#{@base_url}/Encounter/#{@encounter_id}")
        .with(headers: { 'Authorization' => "Bearer #{@instance.token}" })
        .to_return(status: 202)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal exception.message, 'Bad response code: expected 200, 201, but found 202. '
    end

    it 'fails when the server does not return a FHIR resource' do
      stub_request(:get, "#{@base_url}/Encounter/#{@encounter_id}")
        .with(headers: { 'Authorization' => "Bearer #{@instance.token}" })
        .to_return(status: 200)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal exception.message, 'Expected response to be a Encounter resource'
    end

    it 'fails when the server does not return a Encounter Resource' do
      stub_request(:get, "#{@base_url}/Encounter/#{@encounter_id}")
        .with(headers: { 'Authorization' => "Bearer #{@instance.token}" })
        .to_return(status: 200, body: FHIR::DSTU2::Condition.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal exception.message, 'Expected response to be a Encounter resource'
    end

    it 'succeeds when the server returns a Encounter Resource' do
      stub_request(:get, "#{@base_url}/Encounter/#{@encounter_id}")
        .with(headers: { 'Authorization' => "Bearer #{@instance.token}" })
        .to_return(status: 200, body: FHIR::DSTU2::Encounter.new.to_json)

      @sequence.run_test(@test)
    end
  end
end

class ArgonautLaunchContextSequenceTest < MiniTest::Test
  def setup
    @instance = get_test_instance
    client = get_client(@instance)

    @fixture = 'patient' # put fixture file name here
    @sequence = Inferno::Sequence::ArgonautLaunchContextSequence.new(@instance, client) # put sequence here
    @resource_type = 'Patient'

    @resource = FHIR::DSTU2.from_contents(load_fixture(@fixture.to_sym))
    assert_empty @resource.validate, "Setup failure: Resource fixture #{@fixture}.json not a valid #{@resource_type}."

    @resource_bundle = wrap_resources_in_bundle(@resource)
    @resource_bundle.entry.each do |entry|
      entry.resource.meta = FHIR::DSTU2::Meta.new unless entry.resource.meta
      entry.resource.meta.versionId = '1'
    end

    @patient_id = @resource.id
    @patient_id = @patient_id.split('/')[-1] if @patient_id.include?('/')

    @patient_resource = FHIR::DSTU2::Patient.new(id: @patient_id)
    @practitioner_resource = FHIR::DSTU2::Practitioner.new(id: 432)

    @encounter = FHIR::DSTU2.from_contents(load_fixture(:encounter))
    @instance.encounter_id = @encounter.id

    # Assume we already have a patient
    @instance.resource_references << Inferno::Models::ResourceReference.new(
      resource_type: 'Patient',
      resource_id: @patient_id
    )

    set_resource_support(@instance, @resource_type)

    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.

    @request_headers = { 'Accept' => 'application/json+fhir',
                         'Accept-Charset' => 'utf-8',
                         'User-Agent' => 'Ruby FHIR Client',
                         'Authorization' => "Bearer #{@instance.token}" }

    @response_headers = { 'content-type' => 'application/json+fhir' }
  end

  def full_sequence_stubs
    # Return 401 if no Authorization Header
    uri_template = Addressable::Template.new "http://www.example.com/#{@resource_type}{?patient,target,start,end,userid,agent}"
    stub_request(:get, uri_template).to_return(status: 401)
    stub_request(:get, "http://www.example.com/#{@resource_type}/#{@resource.id}").to_return(status: 401)

    # Search Resources
    stub_request(:get, uri_template)
      .with(headers: @request_headers)
      .to_return(
        status: 200, body: @resource_bundle.to_json, headers: @response_headers
      )

    # Read Resources
    stub_request(:get, "http://www.example.com/#{@resource_type}/#{@resource.id}")
      .with(headers: @request_headers)
      .to_return(status: 200,
                 body: @resource.to_json,
                 headers: { content_type: 'application/json+fhir; charset=UTF-8' })

    # Stub Patient for Reference Resolution Tests
    stub_request(:get, %r{example.com/Patient/})
      .with(headers: {
              'Authorization' => "Bearer #{@instance.token}"
            })
      .to_return(status: 200,
                 body: @resource.to_json,
                 headers: { content_type: 'application/json+fhir; charset=UTF-8' })

    stub_request(:get, %r{example.com/Encounter/})
      .with(headers: {
              'Authorization' => "Bearer #{@instance.token}"
            })
      .to_return(status: 200,
                 body: @encounter.to_json,
                 headers: { content_type: 'application/json+fhir; charset=UTF-8' })
  end

  def test_all_pass
    full_sequence_stubs

    sequence_result = @sequence.start

    failures = sequence_result.failures
    assert failures.empty?, "All tests should pass.  First error: #{!failures.empty? && failures.first.message}"
    assert sequence_result.pass?, "The sequence should be marked as pass. #{sequence_result.result}"
    assert sequence_result.test_results.all? { |r| r.test_warnings.empty? }, 'There should not be any warnings.'
  end
end
