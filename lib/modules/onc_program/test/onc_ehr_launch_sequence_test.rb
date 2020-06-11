# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::OncEHRLaunchSequence do
  before do
    @sequence_class = Inferno::Sequence::OncEHRLaunchSequence
    @client = FHIR::Client.new('http://www.example.com/fhir')
    @instance = Inferno::Models::TestingInstance.new
    @sequence = @sequence_class.new(@instance, @client)
    @sequence.instance_variable_set(:@params, 'abc' => 'def')
  end

  describe 'ONC scopes test' do
    before do
      @test = @sequence_class[:onc_scopes]
    end

    let(:good_scopes) { @sequence.required_scopes.join(' ') + ' user/*.*' }

    it 'skips when the launch failed' do
      @sequence.instance_variable_set(:@params, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal @sequence.oauth_redirect_failed_message, exception.message
    end

    it 'fails when a required scope was not requested' do
      @sequence.required_scopes.each do |scope|
        scopes = @sequence.required_scopes - [scope]
        @instance.instance_variable_set(:@scopes, scopes.join(' '))
        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal "Required scopes were not requested: #{scope}", exception.message
      end
    end

    it 'fails when a required scope was not received' do
      @instance.instance_variable_set(:@scopes, good_scopes)
      @sequence.required_scopes.each do |scope|
        scopes = @sequence.required_scopes - [scope]
        @instance.instance_variable_set(:@received_scopes, scopes.join(' '))
        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal "Required scopes were not received: #{scope}", exception.message
      end
    end

    it 'fails when no user-level scope was requested' do
      @instance.instance_variable_set(:@scopes, @sequence.required_scopes.join(' '))
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'User-level scope in the format: user/[ resource | * ].[ read | *] was not requested.', exception.message
    end

    it 'fails when no user-level scope was received' do
      @instance.instance_variable_set(:@scopes, good_scopes)
      @instance.instance_variable_set(:@received_scopes, @sequence.required_scopes.join(' '))
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'User-level scope in the format: user/[ resource | * ].[ read | *] was not received.', exception.message
    end

    it 'fails when a badly formatted scope was requested' do
      bad_scopes = ['user/*/*', 'patient/*.read', 'user/*.*.*', 'user/*.write']
      bad_scopes.each do |scope|
        @instance.instance_variable_set(:@scopes, (@sequence.required_scopes + [scope]).join(' '))
        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal "Requested scope '#{scope}' does not follow the format: user/[ resource | * ].[ read | * ]", exception.message
      end

      bad_resource_type = 'ValueSet'
      @instance.instance_variable_set(:@received_scopes, good_scopes)
      @instance.instance_variable_set(:@scopes, @sequence.required_scopes.join(' ') + " user/#{bad_resource_type}.*")
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal "'#{bad_resource_type}' must be either a valid resource type or '*'", exception.message
    end

    it 'fails when a badly formatted scope was received' do
      bad_scopes = ['user/*/*', 'patient/*.read', 'user/*.*.*', 'user/*.write']
      @instance.instance_variable_set(:@scopes, good_scopes)

      bad_scopes.each do |scope|
        @instance.instance_variable_set(:@received_scopes, (@sequence.required_scopes + [scope]).join(' '))
        exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

        assert_equal "Received scope '#{scope}' does not follow the format: user/[ resource | * ].[ read | * ]", exception.message
      end

      bad_resource_type = 'ValueSet'
      @instance.instance_variable_set(:@received_scopes, @sequence.required_scopes.join(' ') + " user/#{bad_resource_type}.*")
      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal "'#{bad_resource_type}' must be either a valid resource type or '*'", exception.message
    end

    it 'succeeds when the required scopes and a user-level scope are present' do
      @instance.instance_variable_set(:@scopes, good_scopes)
      @instance.instance_variable_set(:@received_scopes, good_scopes)

      @sequence.run_test(@test)
    end
  end

  describe 'smart style url test' do
    before do
      @test = @sequence_class[:smart_style_url]
      @url = 'http://www.example.com/style'
      @sequence.instance_variable_set(:@token_response_body, 'smart_style_url' => @url)
    end

    it 'skips when the launch failed' do
      @sequence.instance_variable_set(:@params, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal @sequence.oauth_redirect_failed_message, exception.message
    end

    it 'skips when the token response body is blank' do
      @sequence.instance_variable_set(:@token_response_body, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No valid token response received', exception.message
    end

    it 'fails if the token response does not contain a smart style url' do
      @sequence.instance_variable_set(:@token_response_body, 'need_patient_banner' => true)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Token response did not contain smart_style_url', exception.message
    end

    it 'fails if the smart styles can not be retrieved' do
      stub_request(:get, @url)
        .to_return(status: 404)

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Bad response code: expected 200, 201, but found 404. ', exception.message
    end

    it 'fails if the smart styles are not valid json' do
      stub_request(:get, @url)
        .to_return(status: 200, body: '{')

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Invalid JSON. ', exception.message
    end

    it 'succeeds if the smart styles are valid json' do
      stub_request(:get, @url)
        .to_return(status: 200, body: '{}')

      @sequence.run_test(@test)
    end
  end

  describe 'need patient banner test' do
    before do
      @test = @sequence_class[:need_patient_banner]
      @sequence.instance_variable_set(:@token_response_body, 'need_patient_banner' => false)
    end

    it 'skips when the launch failed' do
      @sequence.instance_variable_set(:@params, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal @sequence.oauth_redirect_failed_message, exception.message
    end

    it 'skips when the token response body is blank' do
      @sequence.instance_variable_set(:@token_response_body, nil)

      exception = assert_raises(Inferno::SkipException) { @sequence.run_test(@test) }

      assert_equal 'No valid token response received', exception.message
    end

    it 'fails if the token response does not contain need_patient_banner' do
      @sequence.instance_variable_set(:@token_response_body, 'smart_style_url': 'abc')

      exception = assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }

      assert_equal 'Token response did not contain need_patient_banner', exception.message
    end

    it 'succeeds if the token response contains need_patient_banner' do
      @sequence.run_test(@test)
    end
  end
end
