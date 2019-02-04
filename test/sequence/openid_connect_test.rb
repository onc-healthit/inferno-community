# frozen_string_literal: true

require_relative '../test_helper'

# Tests for the OpenIDConnectSequence
# Note: This test currently only considers dstu2
class OpenIDConnectSequenceTest < MiniTest::Test
  RESPONSE_HEADERS = { 'content-type' => 'application/json' }.freeze

  def setup
    @key_pair = OpenSSL::PKey::RSA.new(2048)
    bad_key_pair = OpenSSL::PKey::RSA.new(2048)
    @public_key = @key_pair.public_key
    @openid_configuration = load_json_fixture(:openid_configuration)

    client_id = SecureRandom.uuid

    @id_token = JSON::JWT.new(
      iss: @openid_configuration['issuer'],
      exp: 1.hour.from_now,
      nbf: Time.now,
      iat: Time.now,
      aud: client_id,
      sub: SecureRandom.uuid,
      profile: 'https://www.example.com/profile_url/'
    )

    jwk = @key_pair.to_jwk(kid: 'internal_testing', alg: 'RS256')
    @id_token.header[:kid] = jwk[:kid]

    @invalid_id_token = SecureRandom.hex(32)
    @unsigned_id_token = @id_token.clone
    @bad_signature_id_token = @id_token.sign(bad_key_pair, jwk['alg'])
    @expired_id_token = @id_token.clone
    @expired_id_token['exp'] = 1.year.ago.to_i
    @id_token = @id_token.sign(@key_pair, jwk['alg'])
    @expired_id_token = @expired_id_token.sign(@key_pair, jwk['alg'])

    @instance = Inferno::Models::TestingInstance.new(url: 'https://www.example.com/testing',
                                                     client_name: 'Inferno',
                                                     base_url: 'http://localhost:4567',
                                                     client_endpoint_key: Inferno::SecureRandomBase62.generate(32),
                                                     client_id: client_id,
                                                     selected_module: 'argonaut',
                                                     oauth_authorize_endpoint: @openid_configuration['authorization_endpoint'],
                                                     oauth_token_endpoint: @openid_configuration['token_endpoint'],
                                                     scopes: @openid_configuration['scopes_supported'].join(' '))

    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    client = FHIR::Client.new(@instance.url)
    client.use_dstu2
    client.default_json
    @sequence = Inferno::Sequence::OpenIDConnectSequence.new(@instance, client, true)
  end

  def test_all_pass
    WebMock.reset!

    @instance.save!
    @instance.update(id_token: @id_token.to_s)

    openid_configuration_url = @openid_configuration['issuer'].chomp('/') + '/.well-known/openid-configuration'
    stub_openid_register = stub_request(:get, openid_configuration_url)
                           .to_return(status: 200, body: @openid_configuration.to_json, headers: RESPONSE_HEADERS)

    stub_jwks_register = stub_request(:get, @openid_configuration['jwks_uri'])
                         .to_return(status: 200, body: @public_key.to_jwk(kid: 'internal_testing', alg: 'RS256').to_json, headers: RESPONSE_HEADERS)

    sequence_result = @sequence.start

    assert_requested(stub_openid_register)
    assert_requested(stub_jwks_register)

    failures = sequence_result.test_results.reject { |r| r.result == 'pass' }

    assert failures.empty?, "All tests should pass.  First error: #{!failures.empty? && failures.first.message}"
    assert sequence_result.result == 'pass', 'Sequence should pass'
    assert sequence_result.test_results.all? { |r| r.test_warnings.empty? }, 'There should not be any warnings.'
  end

  def test_invalid_token
    WebMock.reset!

    @instance.save!
    @instance.update(id_token: @invalid_id_token.to_s)

    openid_configuration_url = @openid_configuration['issuer'].chomp('/') + '/.well-known/openid-configuration'
    stub_openid_register = stub_request(:get, openid_configuration_url)
                           .to_return(status: 200, body: @openid_configuration.to_json, headers: RESPONSE_HEADERS)

    stub_jwks_register = stub_request(:get, @openid_configuration['jwks_uri'])
                         .to_return(status: 200, body: @public_key.to_jwk(kid: 'internal_testing', alg: 'RS256').to_json, headers: RESPONSE_HEADERS)

    sequence_result = @sequence.start

    assert sequence_result.result == 'fail'
    # all tests depend on valid token
    assert sequence_result.test_results.all? { |r| r.result == 'fail' }
  end

  def test_bad_signature_token
    WebMock.reset!

    @instance.save!
    @instance.update(id_token: @bad_signature_id_token.to_s)

    openid_configuration_url = @openid_configuration['issuer'].chomp('/') + '/.well-known/openid-configuration'
    stub_openid_register = stub_request(:get, openid_configuration_url)
                           .to_return(status: 200, body: @openid_configuration.to_json, headers: RESPONSE_HEADERS)

    stub_jwks_register = stub_request(:get, @openid_configuration['jwks_uri'])
                         .to_return(status: 200, body: @public_key.to_jwk(kid: 'internal_testing', alg: 'RS256').to_json, headers: RESPONSE_HEADERS)

    sequence_result = @sequence.start

    assert_requested(stub_openid_register)
    assert_requested(stub_jwks_register)

    assert sequence_result.result == 'fail'
    # 2 test depends on proper signature
    assert sequence_result.test_results.select { |r| r.result == 'fail' }.length == 2
  end

  def test_unsigned_token
    WebMock.reset!

    @instance.save!
    @instance.update(id_token: @unsigned_id_token.to_s)

    openid_configuration_url = @openid_configuration['issuer'].chomp('/') + '/.well-known/openid-configuration'
    stub_openid_register = stub_request(:get, openid_configuration_url)
                           .to_return(status: 200, body: @openid_configuration.to_json, headers: RESPONSE_HEADERS)

    stub_jwks_register = stub_request(:get, @openid_configuration['jwks_uri'])
                         .to_return(status: 200, body: @public_key.to_jwk(kid: 'internal_testing', alg: 'RS256').to_json, headers: RESPONSE_HEADERS)

    sequence_result = @sequence.start

    assert_requested(stub_openid_register)
    assert_requested(stub_jwks_register)

    assert sequence_result.result == 'fail'
    # 2 test depends on present signature
    assert sequence_result.test_results.select { |r| r.result == 'fail' }.length == 2
  end

  def test_expired_token
    WebMock.reset!

    @instance.save!
    @instance.update(id_token: @expired_id_token.to_s)

    openid_configuration_url = @openid_configuration['issuer'].chomp('/') + '/.well-known/openid-configuration'
    stub_openid_register = stub_request(:get, openid_configuration_url)
                           .to_return(status: 200, body: @openid_configuration.to_json, headers: RESPONSE_HEADERS)

    stub_jwks_register = stub_request(:get, @openid_configuration['jwks_uri'])
                         .to_return(status: 200, body: @public_key.to_jwk(kid: 'internal_testing', alg: 'RS256').to_json, headers: RESPONSE_HEADERS)

    sequence_result = @sequence.start

    assert_requested(stub_openid_register)
    assert_requested(stub_jwks_register)

    assert sequence_result.result == 'fail'
    # 1 test depends on claims
    assert sequence_result.test_results.select { |r| r.result == 'fail' }.length == 1
  end

  def test_no_openid_configuration_url
    WebMock.reset!

    @instance.save!
    @instance.update(id_token: @id_token.to_s)

    openid_configuration_url = @openid_configuration['issuer'].chomp('/') + '/.well-known/openid-configuration'
    stub_openid_register = stub_request(:get, openid_configuration_url)
                           .to_return(status: 404)

    sequence_result = @sequence.start
    assert sequence_result.result == 'fail'
    # 4 tests depend on openid-configuration information
    assert sequence_result.test_results.select { |r| r.result == 'fail' }.length == 4
  end

  def test_no_jwks_uri
    WebMock.reset!

    @instance.save!
    @instance.update(id_token: @id_token.to_s)

    openid_configuration_url = @openid_configuration['issuer'].chomp('/') + '/.well-known/openid-configuration'
    stub_openid_register = stub_request(:get, openid_configuration_url)
                           .to_return(status: 200, body: @openid_configuration.to_json, headers: RESPONSE_HEADERS)

    stub_jwks_register = stub_request(:get, @openid_configuration['jwks_uri'])
                         .to_return(status: 404)

    sequence_result = @sequence.start
    assert sequence_result.result == 'fail'
    # 3 tests depend on jwks information
    assert sequence_result.test_results.select { |r| r.result == 'fail' }.length == 3
  end
end
