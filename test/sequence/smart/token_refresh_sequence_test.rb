# frozen_string_literal: true

require_relative '../../test_helper'

describe Inferno::Sequence::TokenRefreshSequence do
  SEQUENCE = Inferno::Sequence::TokenRefreshSequence

  let(:full_body) do
    {
      'access_token' => 'abc',
      'expires_in' => 'def',
      'token_type' => 'Bearer',
      'scope' => 'jkl'
    }
  end

  before do
    @token_endpoint = 'http://www.example.com/token'
    @client = FHIR::Client.new('http://www.example.com/fhir')
    @instance = Inferno::Models::TestingInstance.new(oauth_token_endpoint: @token_endpoint, scopes: 'jkl')
  end

  describe 'invalid refresh token test' do
    before do
      @test = SEQUENCE[:invalid_refresh_token]
      @sequence = SEQUENCE.new(@instance, @client)
    end

    it 'fails when the token refresh response has a success status' do
      stub_request(:post, @token_endpoint)
        .with(body: hash_including(refresh_token: SEQUENCE::INVALID_REFRESH_TOKEN))
        .to_return(status: 200)

      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end

    it 'succeeds when the token refresh response has an error status' do
      stub_request(:post, @token_endpoint)
        .with(body: hash_including(refresh_token: SEQUENCE::INVALID_REFRESH_TOKEN))
        .to_return(status: 400)

      @sequence.run_test(@test)
    end
  end

  describe 'invalid client id test' do
    before do
      @test = SEQUENCE[:invalid_client_id]
      @sequence = SEQUENCE.new(@instance, @client)
    end

    it 'fails when the token refresh response has a success status' do
      stub_request(:post, @token_endpoint)
        .with(body: hash_including(client_id: SEQUENCE::INVALID_CLIENT_ID))
        .to_return(status: 200)

      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end

    it 'succeeds when the token refresh has an error status' do
      stub_request(:post, @token_endpoint)
        .with(body: hash_including(client_id: SEQUENCE::INVALID_CLIENT_ID))
        .to_return(status: 400)

      @sequence.run_test(@test)
    end
  end

  describe 'refresh with scope parameter test' do
    before do
      @test = SEQUENCE[:refresh_with_scope]
      @sequence = SEQUENCE.new(@instance, @client)
    end

    it 'succeeds when the token refresh succeeds' do
      stub_request(:post, @token_endpoint)
        .with(body: hash_including(scope: 'jkl'))
        .to_return(status: 200, body: full_body.to_json, headers: {})

      @sequence.run_test(@test)
    end

    it 'fails when the token refresh fails' do
      stub_request(:post, @token_endpoint)
        .with(body: hash_including(scope: 'jkl'))
        .to_return(status: 400)

      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end
  end

  describe 'refresh without scope parameter test' do
    before do
      @test = SEQUENCE[:refresh_without_scope]
      @sequence = SEQUENCE.new(@instance, @client)
    end

    it 'succeeds when the token refresh succeeds' do
      stub_request(:post, @token_endpoint)
        .with { |request| !request.body.include? 'scope' }
        .to_return(status: 200, body: full_body.to_json, headers: {})

      @sequence.run_test(@test)
    end

    it 'fails when the token refresh fails' do
      stub_request(:post, @token_endpoint)
        .with { |request| !request.body.include? 'scope' }
        .to_return(status: 400)

      assert_raises(Inferno::AssertionException) { @sequence.run_test(@test) }
    end
  end

  describe '#validate_and_save_refresh_response' do
    let(:successful_response) do
      OpenStruct.new(
        code: 200,
        body: full_body.to_json,
        headers: {}
      )
    end

    before do
      @sequence = SEQUENCE.new(@instance, @client)
    end

    it 'fails when the token response has an error status' do
      response = OpenStruct.new(code: 400)
      exception = assert_raises(Inferno::AssertionException) { @sequence.validate_and_save_refresh_response(response) }
      assert_equal('Bad response code: expected 200, 201, but found 400. ', exception.message)
    end

    it 'fails when the token response body is invalid json' do
      response = OpenStruct.new(code: 200, body: '{')
      exception = assert_raises(Inferno::AssertionException) { @sequence.validate_and_save_refresh_response(response) }
      assert_equal('Invalid JSON', exception.message)
    end

    it 'fails when the token response does not contain an access token' do
      response = OpenStruct.new(code: 200, body: '{"not_access_token":"abc"}')
      exception = assert_raises(Inferno::AssertionException) { @sequence.validate_and_save_refresh_response(response) }
      assert_equal('Token response did not contain access_token as required', exception.message)
    end

    it 'fails when the token response does not contain a required field' do
      required_fields = ['expires_in', 'token_type', 'scope']
      required_fields.each do |field|
        body = full_body.reject { |key, _| key == field }.to_json
        response = OpenStruct.new(code: 200, body: body)
        exception = assert_raises(Inferno::AssertionException) { @sequence.validate_and_save_refresh_response(response) }
        assert_equal("Token response did not contain #{field} as required", exception.message)
      end
    end

    it 'fails when the token_type is not "Bearer"' do
      full_body['token_type'] = 'ghi'
      response = OpenStruct.new(code: 200, body: full_body.to_json)
      exception = assert_raises(Inferno::AssertionException) { @sequence.validate_and_save_refresh_response(response) }
      assert_equal('Token type must be Bearer.', exception.message)
    end

    it 'creates a warning when scopes are missing' do
      @instance.scopes = 'jkl mno'
      @sequence.validate_and_save_refresh_response(successful_response)

      warnings = @sequence.instance_variable_get(:'@test_warnings')
      assert_includes(warnings, 'Token exchange response did not include expected scopes: ["mno"]')
    end

    it 'creates a warning when the body has no patient field' do
      @sequence.validate_and_save_refresh_response(successful_response)

      warnings = @sequence.instance_variable_get(:'@test_warnings')
      assert_includes(warnings, 'No patient id provided in token exchange.')
    end

    it 'creates a warning when the cache_control header is missing' do
      @sequence.validate_and_save_refresh_response(successful_response)

      warnings = @sequence.instance_variable_get(:'@test_warnings')
      assert_includes(warnings, 'Token response headers did not contain cache_control as is recommended for token exchanges.')
    end

    it 'creates a warning when the pragma header is missing' do
      successful_response.headers = { cache_control: 'abc' }
      @sequence.validate_and_save_refresh_response(successful_response)

      warnings = @sequence.instance_variable_get(:'@test_warnings')
      assert_includes(warnings, 'Token response headers did not contain pragma as is recommended for token exchanges.')
    end

    it 'creates a warning when the cache_control header is not set to "no-store"' do
      successful_response.headers = { cache_control: 'abc', pragma: 'def' }
      @sequence.validate_and_save_refresh_response(successful_response)

      warnings = @sequence.instance_variable_get(:'@test_warnings')
      assert_includes(warnings, 'Token response header should have cache_control containing no-store.')
    end

    it 'creates a warning when the pragma header is not set to "no-cache"' do
      successful_response.headers = { cache_control: 'no-store', pragma: 'def' }
      @sequence.validate_and_save_refresh_response(successful_response)

      warnings = @sequence.instance_variable_get(:'@test_warnings')
      assert_includes(warnings, 'Token response header should have pragma containing no-cache.')
    end
  end
end
