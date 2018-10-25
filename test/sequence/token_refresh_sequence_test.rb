require_relative '../test_helper'

# Test for the Token Refresh Sequence
# See : https://tools.ietf.org/html/rfc6749#section-6
class TokenRefreshSequenceTest < MiniTest::Test
  def setup

    refresh_token = JSON::JWT.new(iss: 'foo_refresh')
    @instance = Inferno::Models::TestingInstance.new(url: 'http://www.example.com',
                                                     client_name: 'Inferno',
                                                     base_url: 'http://localhost:4567',
                                                     client_endpoint_key: Inferno::SecureRandomBase62.generate(32),
                                                     client_id: SecureRandom.uuid,
                                                     oauth_authorize_endpoint: 'http://oauth_reg.example.com/authorize',
                                                     oauth_token_endpoint: 'http://oauth_reg.example.com/token',
                                                     initiate_login_uri: 'http://localhost:4567/launch',
                                                     redirect_uris: 'http://localhost:4567/redirect',
                                                     scopes: 'launch openid patient/*.* profile',
                                                     refresh_token: refresh_token
                                                     )

    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    client = FHIR::Client.new(@instance.url)
    client.use_dstu2
    client.default_json
    @sequence = Inferno::Sequence::TokenRefreshSequence.new(@instance, client, true)
    @standalone_token_exchange = load_json_fixture(:standalone_token_exchange)
  end

  def all_pass(confidential)
    WebMock.reset!
    if confidential
      # Responses Must Contain Authorization Header
      stub_request(:post, @instance.oauth_token_endpoint)
          .with(headers: {'Content-Type' => 'application/x-www-form-urlencoded',
                          'Authorization' =>
                              "Basic #{Base64.strict_encode64(@instance.client_id +
                                                                  ':' +
                                                                  @instance.client_secret)}"},
                body: {'grant_type' => 'refresh_token',
                       'refresh_token' => @instance.refresh_token})
          .to_return(status: 200,
                     body: @standalone_token_exchange.to_json,
                     headers: {content_type: 'application/json; charset=UTF-8',
                               cache_control: 'no-store',
                               pragma:'no-cache'})

      # Responses must NOT contain client_id in the body or the client secret in any situation
      stub_request(:post, @instance.oauth_token_endpoint)
          .with(body: /client_id|client_secret/)
          .to_return(status: 401)
    else
      stub_request(:post, @instance.oauth_token_endpoint)
          .with(headers: {'Content-Type' => 'application/x-www-form-urlencoded'},
                body: {'client_id'=>@instance.client_id,
                       'grant_type'=>'refresh_token',
                       'refresh_token'=>@instance.refresh_token},)
          .to_return(status: 200,
                     body: @standalone_token_exchange.to_json,
                     headers: {content_type: 'application/json; charset=UTF-8',
                               cache_control: 'no-store',
                               pragma:'no-cache'})
    end

    # To test rejection of invalid client_id
    stub_request(:post, @instance.oauth_token_endpoint)
        .with(body: /INVALID/,
              headers: {'Content-Type'=>'application/x-www-form-urlencoded'})
        .to_return(status: 401)

    sequence_result = @sequence.start

    assert sequence_result.result == 'pass', 'The sequence should be marked as pass.'
  end

  def test_all_pass_confidential_client
    @instance.client_secret = SecureRandom.uuid
    @instance.confidential_client = true
    all_pass(true)
  end

  def test_all_pass_public_client
    @instance.client_secret = nil
    @instance.confidential_client = nil
    all_pass(false)
  end
end