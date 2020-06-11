# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::SharedONCLaunchTests do
  class SharedONCLaunchTestSequence < Inferno::Sequence::SequenceBase
    include Inferno::Sequence::SharedONCLaunchTests

    patient_context_test(index: '01')
    encounter_context_test(index: '02')
  end

  before do
    @base_url = 'http://www.example.com/fhir'
    @sequence_class = SharedONCLaunchTestSequence
    @client = FHIR::Client.new(@base_url)
    @instance = Inferno::Models::TestingInstance.create(token: 'ACCESS_TOKEN')
    @instance.patient_id = '123'
    @instance.encounter_id = '456'
    @instance.instance_variable_set(:@module, OpenStruct.new(resources_to_test: Set['Patient', 'Encounter']))
  end

  describe 'patient_context_test' do
    before do
      @test = @sequence_class[:patient_context]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:@params, 'abc' => 'def')
    end

    it 'skips when authorization failed' do
      @sequence.instance_variable_set(:@params, nil)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal @sequence.oauth_redirect_failed_message, exception.message
    end

    it 'skips when no access token was received' do
      @instance.token = nil
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No access token was received during the SMART launch', exception.message
    end

    it 'skips when no patient id was received' do
      @instance.patient_id = nil
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'Token response did not contain `patient` field', exception.message
    end

    it 'fails when a non-200 response is received' do
      stub_request(:get, "#{@base_url}/Patient/#{@instance.patient_id}")
        .to_return(status: 400)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 400. ', exception.message
    end

    it 'fails when a Patient resource is not received' do
      stub_request(:get, "#{@base_url}/Patient/#{@instance.patient_id}")
        .to_return(status: 200, body: FHIR::Bundle.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected response to be a Patient resource', exception.message
    end

    it 'succeeds when a Patient resource is received' do
      stub_request(:get, "#{@base_url}/Patient/#{@instance.patient_id}")
        .to_return(status: 200, body: FHIR::Patient.new.to_json)

      @sequence.run_test(@test)
    end
  end

  describe 'encounter_context_test' do
    before do
      @test = @sequence_class[:encounter_context]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.instance_variable_set(:@params, 'abc' => 'def')
    end

    it 'skips when authorization failed' do
      @sequence.instance_variable_set(:@params, nil)
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal @sequence.oauth_redirect_failed_message, exception.message
    end

    it 'skips when no access token was received' do
      @instance.token = nil
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No access token was received during the SMART launch', exception.message
    end

    it 'skips when no encounter id was received' do
      @instance.encounter_id = nil
      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'Token response did not contain `encounter` field', exception.message
    end

    it 'fails when a non-200 response is received' do
      stub_request(:get, "#{@base_url}/Encounter/#{@instance.encounter_id}")
        .to_return(status: 400)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 400. ', exception.message
    end

    it 'fails when a Encounter resource is not received' do
      stub_request(:get, "#{@base_url}/Encounter/#{@instance.encounter_id}")
        .to_return(status: 200, body: FHIR::Bundle.new.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Expected response to be an Encounter resource', exception.message
    end

    it 'fails when the Encounter does not refer to the patient' do
      encounter = FHIR::Encounter.new(subject: { reference: "Patient/#{@instance.patient_id + 'x'}" })
      stub_request(:get, "#{@base_url}/Encounter/#{@instance.encounter_id}")
        .to_return(status: 200, body: encounter.to_json)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Encounter subject (Patient/123x) does not match patient id (123)', exception.message
    end

    it 'succeeds when an Encounter resource referring to the patient is received' do
      encounter = FHIR::Encounter.new(subject: { reference: "Patient/#{@instance.patient_id}" })
      stub_request(:get, "#{@base_url}/Encounter/#{@instance.encounter_id}")
        .to_return(status: 200, body: encounter.to_json)

      @sequence.run_test(@test)
    end
  end

  class SharedONCLaunchTestRefreshSequence < Inferno::Sequence::SequenceBase
    include Inferno::Sequence::SharedLaunchTests
    include Inferno::Sequence::SharedONCLaunchTests

    patient_context_test(index: '01', refresh: true)
    encounter_context_test(index: '02', refresh: true)

    def skip_if_no_refresh_token
      skip_if @instance.refresh_token.blank?, 'no refresh token'
    end
  end

  describe 'tests in refresh sequence' do
    before do
      @base_url = 'http://www.example.com/fhir'
      @sequence_class = SharedONCLaunchTestRefreshSequence
      @client = FHIR::Client.new(@base_url)
      @instance = Inferno::Models::TestingInstance.create
      @sequence = @sequence_class.new(@instance, @client)
    end

    describe 'patient context test' do
      before do
        @test = @sequence_class[:patient_context]
        @instance.refresh_token = 'ABC'
      end

      it 'skips if no refresh token was received' do
        @instance.refresh_token = nil
        exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

        assert_equal 'no refresh token', exception.message
      end

      it 'skips if a refresh has not occurred' do
        exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

        assert_equal 'Token was not successfully refreshed', exception.message
      end

      it 'continues if a refresh has occurred' do
        @sequence.instance_variable_set(:@refresh_successful, true)

        exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

        assert_equal 'No access token was received during the SMART launch', exception.message
      end
    end

    describe 'encounter context test' do
      before do
        @test = @sequence_class[:encounter_context]
        @instance.refresh_token = 'ABC'
      end

      it 'skips if no refresh token was received' do
        @instance.refresh_token = nil
        exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

        assert_equal 'no refresh token', exception.message
      end

      it 'skips if a refresh has not occurred' do
        exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

        assert_equal 'Token was not successfully refreshed', exception.message
      end

      it 'continues if a refresh has occurred' do
        @sequence.instance_variable_set(:@refresh_successful, true)

        exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

        assert_equal 'No access token was received during the SMART launch', exception.message
      end
    end
  end
end
