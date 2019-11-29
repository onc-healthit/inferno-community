# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::USCoreR4PatientReadOnlySequence do
  before do
    @base_url = 'http://www.example.com/fhir'
    @token = 'ABC'
    @patient_id = '123'
    @sequence_class = Inferno::Sequence::USCoreR4PatientReadOnlySequence
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

  describe 'authenticated read test' do
    before do
      @test = @sequence_class[:authenticated_read]
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
        .to_return(status: 200, body: FHIR::Condition.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal exception.message, 'Expected response to be a Patient resource'
    end

    it 'succeeds when the server returns a Patient Resource' do
      stub_request(:get, "#{@base_url}/Patient/#{@patient_id}")
        .with(headers: { 'Authorization' => "Bearer #{@instance.token}" })
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      @sequence.run_test(@test)
    end
  end
end
