require File.expand_path '../../test_helper.rb', __FILE__

class OpenIDConnectSequenceTest < MiniTest::Unit::TestCase

  RESPONSE_HEADERS = {"content-type"=>"application/json"}

  def setup
    @key_pair = OpenSSL::PKey::RSA.new(2048)
    @public_key = @key_pair.public_key
    @openid_configuration = load_json_fixture(:openid_configuration)

    #binding.pry

    client_id = SecureRandom.uuid

    id_token = JSON::JWT.new(
      iss: @openid_configuration['issuer'],
      exp: 1.hour.from_now,
      nbf: Time.now,
      iat: Time.now,
      aud: client_id,
      sub: SecureRandom.uuid
    )

    jwk = @key_pair.to_jwk({kid: 'internal_testing', alg: 'RS256'})
    id_token.header[:kid] = jwk[:kid]
    id_token.sign(@key_pair, jwk['alg'])

    @instance = TestingInstance.new(url: 'https://www.example.com/testing',
                                   client_name: 'Crucible Smart App',
                                   base_url: 'http://localhost:4567',
                                   client_endpoint_key: SecureRandomBase62.generate(32),
                                   client_id: client_id,
                                   oauth_authorize_endpoint: @openid_configuration['authorization_endpoint'],
                                   oauth_token_endpoint: @openid_configuration['token_endpoint'],
                                   scopes: @openid_configuration['scopes_supported'].join(" "),
                                   id_token: id_token.to_s
                                   )

    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    client = FHIR::Client.new(@instance.url)
    client.use_dstu2
    client.default_json
    @sequence = OpenIDConnectSequence.new(@instance, client)
  end

  def test_all_pass
    WebMock.reset!

    openid_configuration_url = @openid_configuration['issuer'].chomp('/') + '/.well-known/openid-configuration'
    stub_openid_register = stub_request(:get, openid_configuration_url).
      to_return(status: 200, body: @openid_configuration.to_json, headers: RESPONSE_HEADERS)

    stub_jwks_register = stub_request(:get, @openid_configuration['jwks_uri']).
      to_return(status: 200, body: @public_key.to_jwk.to_json, headers: RESPONSE_HEADERS)

    sequence_result = @sequence.start

    assert_requested(stub_openid_register)
    assert_requested(stub_jwks_register)

    failures = sequence_result.test_results.select{|r| r.result != 'pass'}

    assert failures.length == 0, "All tests should pass.  First error: #{!failures.empty? && failures.first.message}"
    assert sequence_result.result == 'pass', 'Sequence should pass'
    assert sequence_result.test_results.all?{|r| r.test_warnings.empty? }, 'There should not be any warnings.'
  end

end
