# frozen_string_literal: true

require_relative '../../../../test/test_helper'

describe Inferno::Sequence::BulkDataAuthorizationSequence do
  before do
    @sequence_class = Inferno::Sequence::BulkDataAuthorizationSequence
    config = load_json_fixture(:bulk_data_authorization)

    @instance = Inferno::Models::TestingInstance.create(
      url: 'http://www.example.com',
      bulk_client_id: config['client_id'],
      bulk_data_jwks: config['bulk_data_jwks'].to_json,
      bulk_token_endpoint: config['token_url'],
      bulk_scope: 'system/*.read'
    )

    @client = FHIR::Client.new(@instance.url)

    @access_token = {
      'token_type' => 'bearer',
      'expires_in' => 900,
      'access_token' => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYmVhcmVyIiwiZXhwaXJlc19pbiI6OTAwLCJpYXQiOjE1NzM5NDU1MDQsImV4cCI6MTU3Mzk0NjQwNH0.Ds-9HxQPJshkPYYBowJXltTaX2T6MSv_qYnZLjteTH8',
      'scope' => @instance.bulk_scope
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
    end
  end

  def it_tests_client_assertion(request_payload, parameter)
    uri = Addressable::URI.new
    uri.query = request_payload
    client_assertion = uri.query_values['client_assertion']
    jwk = JSON::JWK.new(@instance.bulk_selected_private_key)

    return it_tests_invalid_private_key(client_assertion, jwk) if parameter[:name] == 'bulk_private_key'

    it_tests_jwt_token_values(client_assertion, jwk, parameter)
  end

  def it_tests_invalid_private_key(client_assertion, jwk)
    JSON::JWT.decode(client_assertion, jwk.to_key)
    false
  rescue JSON::JWT::VerificationFailed
    true
  end

  def it_tests_jwt_token_values(client_assertion, jwk, parameter)
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

  describe 'endpoint TLS tests' do
    before do
      @sequence = @sequence_class.new(@instance, @client)
      @test = @sequence_class[:bulk_token_endpoint_tls]
    end

    it 'fails when the auth endpoint does not support tls' do
      @instance.bulk_token_endpoint = 'http://www.example.com/bulk'

      error = assert_raises(Inferno::AssertionException) do
        @sequence.run_test(@test)
      end

      assert_match(/^URI is not HTTPS/, error.message)
    end

    it 'succeeds when TLS 1.2 is supported' do
      @instance.bulk_token_endpoint = 'https://www.example.com/bulk'

      stub_request(:get, @instance.bulk_token_endpoint)
        .to_return(status: 200).then
        .to_raise(StandardError)

      @sequence.run_test(@test)
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

  describe 'require JWT' do
    before do
      @test = @sequence_class[:require_jwt]
      @sequence = @sequence_class.new(@instance, @client)
    end

    it_tests_required_parameter(jwt_token_parameter: { name: 'iss', value: 'not_a_iss' })
  end

  describe 'return access token tests' do
    before do
      @test = @sequence_class[:authorization_success]
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
    end
  end
end
