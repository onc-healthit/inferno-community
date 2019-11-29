# frozen_string_literal: true

require_relative '../../../../test/test_helper'

# Tests for the EHRLaunchSequence
# Note: This test currently only considers dstu2
class EHRLaunchSequenceTest < MiniTest::Test
  REQUEST_HEADERS = { 'Accept' => 'application/json+fhir',
                      'Accept-Charset' => 'UTF-8',
                      'Content-Type' => 'application/json+fhir;charset=UTF-8' }.freeze

  RESPONSE_HEADERS = { 'content-type' => 'application/json' }.freeze

  def setup
    @instance = Inferno::Models::TestingInstance.create(
      url: 'http://www.example.com',
      client_name: 'Inferno',
      base_url: 'http://localhost:4567',
      client_endpoint_key: Inferno::SecureRandomBase62.generate(32),
      client_id: SecureRandom.uuid,
      selected_module: 'argonaut',
      oauth_authorize_endpoint: 'http://oauth_reg.example.com/authorize',
      oauth_token_endpoint: 'http://oauth_reg.example.com/token',
      scopes: 'launch openid patient/*.* profile'
    )
    client = FHIR::Client.new(@instance.url)
    client.use_dstu2
    client.default_json
    @sequence = Inferno::Sequence::EHRLaunchSequence.new(@instance, client, true)
    @standalone_token_exchange = load_json_fixture(:standalone_token_exchange)
  end

  def all_pass(confidential)
    WebMock.reset!

    if confidential
      # Responses Must Contain Authorization Header
      stub_request(:post, @instance.oauth_token_endpoint)
        .with(headers: { 'Content-Type' => 'application/x-www-form-urlencoded',
                         'Authorization' =>
                              "Basic #{Base64.strict_encode64(@instance.client_id +
                                                                  ':' +
                                                                  @instance.client_secret)}" })
        .to_return(status: 200,
                   body: @standalone_token_exchange.to_json,
                   headers: { content_type: 'application/json; charset=UTF-8',
                              cache_control: 'no-store',
                              pragma: 'no-cache' })

      # Responses must NOT contain client_id in the body or the client secret in any situation
      stub_request(:post, @instance.oauth_token_endpoint)
        .with(body: /client_id|client_secret/,
              headers: { 'Content-Type' => 'application/x-www-form-urlencoded',
                         'Authorization' =>
                              "Basic #{Base64.strict_encode64(@instance.client_id + ':' + @instance.client_secret)}" })
        .to_return(status: 401)
    else
      stub_request(:post, @instance.oauth_token_endpoint)
        .with(headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })
        .to_return(status: 200,
                   body: @standalone_token_exchange.to_json,
                   headers: { content_type: 'application/json; charset=UTF-8',
                              cache_control: 'no-store',
                              pragma: 'no-cache' })
    end

    # To test rejection of invalid client_id
    stub_request(:post, @instance.oauth_token_endpoint)
      .with(body: /INVALID_/,
            headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })
      .to_return(status: 400)

    sequence_result = @sequence.start

    assert sequence_result.wait?, 'The sequence should be in a wait state.'
    assert sequence_result.wait_at_endpoint == 'launch', 'The sequence should be waiting at a launch url.'

    sequence_result = @sequence.resume(nil, nil, 'iss' => @instance.url, 'launch' => Inferno::SecureRandomBase62.generate(32))

    assert sequence_result.wait?, 'The sequence should be in a wait state.'
    assert sequence_result.redirect_to_url.start_with? @instance.oauth_authorize_endpoint, 'The sequence should be redirecting to the authorize url'
    assert sequence_result.wait_at_endpoint == 'redirect', 'The sequence should be waiting at a redirect url'

    redirect_params = { 'code' => '5N01E0', 'state' => @instance.state }

    sequence_result = @sequence.resume(nil, nil, redirect_params)

    failures = sequence_result.failures
    assert failures.empty?, "All tests should pass.  First error: #{!failures.empty? && failures.first.message}"
    assert sequence_result.pass?, 'Sequence should pass'
    assert sequence_result.test_results.all? { |r| r.test_warnings.empty? }, 'There should not be any warnings.'
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
