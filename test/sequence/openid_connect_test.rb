require File.expand_path '../../test_helper.rb', __FILE__

class OpenIDConnectSequenceTest < MiniTest::Unit::TestCase

  REQUEST_HEADERS = { 'Accept'=>'application/json',
                      'Accept-Charset'=>'UTF-8',
                      'Content-Type'=>'application/json;charset=UTF-8'
                     }

  RESPONSE_HEADERS = {"content-type"=>"application/json"}

  def setup
    @key_pair = load_json_fixture(:key_pair)
    @public_key = load_json_fixture(:public_key)
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

    id_token.sign(JSON::JWK.new(@key_pair).to_key, @key_pair['alg'])

    @instance = TestingInstance.new(url: 'https://www.example.com/testing',
                                   client_name: 'Crucible Smart App',
                                   base_url: 'http://localhost:4567',
                                   client_endpoint_key: SecureRandomBase62.generate(32),
                                   client_id: client_id,
                                   oauth_authorize_endpoint: @openid_configuration['authorization_endpoint'],
                                   oauth_token_endpoint: @openid_configuration['token_endpoint'],
                                   scopes: @openid_configuration['scopes'].join(" "),
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
      with(headers: REQUEST_HEADERS).
      to_return(status: 200, body: @openid_configuration, headers: RESPONSE_HEADERS)

    stub_jwks_register = stub_request(:get, @openid_configuration['jwks_uri']).
      with(headers: REQUEST_HEADERS).
      to_return(status: 200, body: @public_key, headers: RESPONSE_HEADERS)

    sequence_result = @sequence.start

    assert_requested(stub_openid_register)
    assert_requested(stub_jwks_register)

    failures = sequence_result.test_results.select{|r| r.result != 'pass'}

    assert failures.length == 0, "All tests should pass.  First error: #{!failures.empty? && failures.first.message}"
    assert sequence_result.result == 'pass', 'Sequence should pass'
    assert sequence_result.test_results.all?{|r| r.test_warnings.empty? }, 'There should not be any warnings.'
  end

end
