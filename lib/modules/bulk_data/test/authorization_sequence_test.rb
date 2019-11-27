# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::BulkDataAuthorizationSequence do
  before do
    @sequence_class = Inferno::Sequence::BulkDataAuthorizationSequence
    config = load_json_fixture(:bulk_data_authorization)

    @instance = Inferno::Models::TestingInstance.create(
      url: 'http://www.example.com',
      bulk_client_id: config['client_id'],
      bulk_public_key: config['public_key'].to_json,
      bulk_private_key: config['private_key'].to_json,
      bulk_token_endpoint: config['token_url']
    )

    @client = FHIR::Client.new(@instance.url)

    @access_token = {
      'token_type' => 'bearer',
      'expires_in' => 900,
      'access_token' => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYmVhcmVyIiwiZXhwaXJlc19pbiI6OTAwLCJpYXQiOjE1NzM5NDU1MDQsImV4cCI6MTU3Mzk0NjQwNH0.Ds-9HxQPJshkPYYBowJXltTaX2T6MSv_qYnZLjteTH8',
      'scope' => 'system/*.read'
    }
  end

  def build_request(status_code, request_headers, request_parameter, jwt_token_parameter)
    a_request = stub_request(:post, @instance.bulk_token_endpoint)
      .to_return(
        status: status_code
      )

    a_request.with(headers: request_headers) if request_headers.present?

    if request_parameter.present?
      a_request.with(body: hash_including(request_parameter))
    elsif jwt_token_parameter.present?
      a_request.with { |request| it_tests_client_assertion(request.body, jwt_token_parameter) }
    elsif @payload.present?
      a_request.with(body: @payload)
    end
  end

  def it_tests_invalid_private_key(client_assertion, jwk)
    JSON::JWT.decode(client_assertion, jwk.to_key)
    false
  rescue JSON::JWT::VerificationFailed
    true
  end

  def it_tests_client_assertion(request_payload, parameter)
    uri = Addressable::URI.new
    uri.query = request_payload
    client_assertion = uri.query_values['client_assertion']

    jwk = JSON::JWK.new(JSON.parse(@instance.bulk_public_key))

    return it_tests_invalid_private_key(client_assertion, jwk) if parameter[:name] == 'bulk_private_key'

    jwt_token = JSON::JWT.decode(client_assertion, jwk.to_key)

    return jwt_token.key?(parameter[:name]) == false if parameter[:value].nil?

    return jwt_token[parameter[:name]] >= parameter[:value].to_i if parameter[:name] == 'exp'

    jwt_token[parameter[:name]] == parameter[:value]
  end

  def self.it_tests_required_parameter(request_headers: nil, request_parameter: nil, jwt_token_parameter: nil)
    it 'passes with status code 400' do
      build_request(400, request_headers, request_parameter, jwt_token_parameter)

      @sequence.run_test(@test)
    end

    it 'fail with status code 200' do
      build_request(200, request_headers, request_parameter, jwt_token_parameter)

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_match(/^Bad response code/, error.message)
    end
  end

  describe 'require correct content-type' do
    before do
      @test = @sequence_class[:require_content_type]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it_tests_required_parameter(request_headers: { content_type: 'application/json' })
  end

  describe 'require system scope' do
    before do
      @test = @sequence_class[:require_system_scope]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it_tests_required_parameter(request_parameter: { scope: 'user/*.read' })
  end

  describe 'require grant type' do
    before do
      @test = @sequence_class[:require_grant_type]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it_tests_required_parameter(request_parameter: { grant_type: 'not_a_grant_type' })
  end

  describe 'require client assertion type' do
    before do
      @test = @sequence_class[:require_client_assertion_type]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it_tests_required_parameter(request_parameter: { client_assertion_type: 'not_a_assertion_type' })
  end

  describe 'require JWT iss' do
    before do
      @test = @sequence_class[:require_jwt_iss]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it_tests_required_parameter(jwt_token_parameter: { name: 'iss', value: 'not_a_iss' })
  end

  describe 'require JWT sub' do
    before do
      @test = @sequence_class[:require_jwt_sub]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it_tests_required_parameter(jwt_token_parameter: { name: 'sub', value: 'not_a_sub' })
  end

  describe 'require JWT aud' do
    before do
      @test = @sequence_class[:require_jwt_aud]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it_tests_required_parameter(jwt_token_parameter: { name: 'aud', value: 'not_a_aud' })
  end

  describe 'require JWT exp' do
    before do
      @test = @sequence_class[:require_jwt_exp]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it_tests_required_parameter(jwt_token_parameter: { name: 'exp', value: nil })
  end

  describe 'require JWT exp less than 5 minutes' do
    before do
      @test = @sequence_class[:require_jwt_exp_value]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it_tests_required_parameter(jwt_token_parameter: { name: 'exp', value: 10.minutes.from_now })
  end

  describe 'require JWT jti' do
    before do
      @test = @sequence_class[:require_jwt_jti]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it_tests_required_parameter(jwt_token_parameter: { name: 'jti', value: nil })
  end

  describe 'sign with private key' do
    before do
      @test = @sequence_class[:correct_signature]
      @sequence = @sequence_class.new(@instance, @client)
      @sequence.jti = SecureRandom.hex(32)
      @sequence.expires_in = 5.minutes.from_now
      @sequence.is_unit_test = true
      @payload = @sequence.create_post_palyload(bulk_private_key: @sequence.invalid_private_key.to_json)
    end

    it_tests_required_parameter(jwt_token_parameter: { name: 'bulk_private_key', value: nil })
  end

  describe 'return access token tests' do
    before do
      @test = @sequence_class[:return_access_token]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it 'pass when server returns access token' do
      stub_request(:post, @instance.bulk_token_endpoint)
        .to_return(
          status: 200,
          headers: { content_type: 'application/json' },
          body: @access_token.to_json
        )

      @sequence.run_test(@test)
      assert @instance.bulk_access_token == @access_token['access_token']
    end

    it 'fail when server returns status other than 200' do
      stub_request(:post, @instance.bulk_token_endpoint)
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

      stub_request(:post, @instance.bulk_token_endpoint)
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

      stub_request(:post, @instance.bulk_token_endpoint)
        .to_return(
          status: 200,
          body: invalid_access_token.to_json
        )

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_match(/^token_type expected to be/, error.message)
    end

    it 'fail when server returns empty expires_in' do
      invalid_access_token = @access_token.clone
      invalid_access_token.delete('expires_in')

      stub_request(:post, @instance.bulk_token_endpoint)
        .to_return(
          status: 200,
          body: invalid_access_token.to_json
        )

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_match(/expires_in is empty/, error.message)
    end

    it 'fail when server returns empty scope' do
      invalid_access_token = @access_token.clone
      invalid_access_token.delete('scope')

      stub_request(:post, @instance.bulk_token_endpoint)
        .to_return(
          status: 200,
          body: invalid_access_token.to_json
        )

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_match(/scope is empty/, error.message)
    end
  end
end
