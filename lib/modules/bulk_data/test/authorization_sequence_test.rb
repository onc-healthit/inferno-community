# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::BulkDataAuthorizationSequence do
  before do
    @sequence_class = Inferno::Sequence::BulkDataAuthorizationSequence
    config = load_json_fixture(:bulk_data_authorization)

    @instance = Inferno::Models::TestingInstance.create(
      url: 'http://www.example.com',
      client_id: config['client_id'],
      bulk_public_key: config['public_key'].to_json,
      bulk_private_key: config['private_key'].to_json,
      oauth_token_endpoint: config['token_url']
    )

    @client = FHIR::Client.new(@instance.url)

    @access_token = {
      'token_type' => 'bearer',
      'expires_in' => 900,
      'access_token' => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYmVhcmVyIiwiZXhwaXJlc19pbiI6OTAwLCJpYXQiOjE1NzM5NDU1MDQsImV4cCI6MTU3Mzk0NjQwNH0.Ds-9HxQPJshkPYYBowJXltTaX2T6MSv_qYnZLjteTH8',
      'scope' => 'system/*.read'

    }
  end

  def self.it_test_rquired_parameter(test_id, request_headers: nil)
    before do
      @test = @sequence_class[test_id]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'pass with stastus code 400' do
      a_request = stub_request(:post, @instance.oauth_token_endpoint)
        .to_return(
          status: 400
        )

      a_request.with(headers: request_headers) if request_headers.present?

      @sequence.run_test(@test)
    end

    it 'fail with status code 200' do
      a_request = stub_request(:post, @instance.oauth_token_endpoint)
        .to_return(
          status: 200
        )

      a_request.with(headers: request_headers) if request_headers.present?

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_match(/^Bad response code/, error.message)
    end
  end

  describe 'require correct content-type' do
    it_test_rquired_parameter(:require_content_type, request_headers: { content_type: 'application/json' })
  end

  describe 'require system scope' do
    it_test_rquired_parameter(:require_system_scope)
  end

  describe 'require grant type' do
    it_test_rquired_parameter(:require_grant_type)
  end

  describe 'require client assertion type' do
    it_test_rquired_parameter(:require_client_assertion_type)
  end

  describe 'require JWT iss' do
    it_test_rquired_parameter(:require_jwt_iss)
  end

  describe 'require JWT sub' do
    it_test_rquired_parameter(:require_jwt_sub)
  end

  describe 'require JWT aud' do
    it_test_rquired_parameter(:require_jwt_aud)
  end

  describe 'require JWT exp' do
    it_test_rquired_parameter(:require_jwt_exp)
  end

  describe 'require JWT jti' do
    it_test_rquired_parameter(:require_jwt_jti)
  end

  describe 'sign with private key' do
    it_test_rquired_parameter(:correct_signature)
  end

  describe 'return access token tests' do
    before do
      @test = @sequence_class[:return_access_token]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'pass when server returns access token' do
      stub_request(:post, @instance.oauth_token_endpoint)
        .to_return(
          status: 200,
          headers: { content_type: 'application/json' },
          body: @access_token.to_json
        )

      @sequence.run_test(@test)
    end

    it 'fail when server returns status other than 200' do
      stub_request(:post, @instance.oauth_token_endpoint)
        .to_return(
          status: 400
        )

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_match(/^Bad response code/, error.message)
    end

    it 'fail when server returns empty access_token' do
      invalid_access_token = @access_token.clone
      invalid_access_token.delete('access_token')

      stub_request(:post, @instance.oauth_token_endpoint)
        .to_return(
          status: 200,
          body: invalid_access_token.to_json
        )

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_match(/access_token is empty/, error.message)
    end

    it 'fail when server returns empty token_type' do
      invalid_access_token = @access_token.clone
      invalid_access_token.delete('token_type')

      stub_request(:post, @instance.oauth_token_endpoint)
        .to_return(
          status: 200,
          body: invalid_access_token.to_json
        )

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_match(/^token_type expected to be/, error.message)
    end
  end
end
