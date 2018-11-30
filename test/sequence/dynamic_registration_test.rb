# frozen_string_literal: true

require_relative '../test_helper'

# Tests for the DynamicRegistrationSequence
# Note: This test currently only considers dstu2
class DynamicRegistrationSequenceTest < MiniTest::Test
  REQUEST_HEADERS = { 'Accept' => 'application/json+fhir',
                      'Accept-Charset' => 'UTF-8',
                      'Content-Type' => 'application/json+fhir;charset=UTF-8' }.freeze

  RESPONSE_HEADERS = { 'content-type' => 'application/json' }.freeze

  DYNAMIC_REGISTRATION_TOKEN = 'AAAAAAAAAAAAAAAAAAAAAAAAAA'

  def setup
    @instance = Inferno::Models::TestingInstance.new(url: 'http://www.example.com',
                                                     client_name: 'Inferno',
                                                     base_url: 'http://localhost:4567',
                                                     client_endpoint_key: Inferno::SecureRandomBase62.generate(32),
                                                     initiate_login_uri: 'http://localhost:4567/launch',
                                                     redirect_uris: 'http://localhost:4567/redirect',
                                                     oauth_register_endpoint: 'https://oauth_reg.example.com/register',
                                                     scopes: 'launch openid patient/*.* profile',
                                                     selected_module: 'argonaut')
    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    client = FHIR::Client.new(@instance.url)
    client.use_dstu2
    client.default_json
    @sequence = @instance.module.sequence_by_name('DynamicRegistrationSequence').new(@instance, client, true)
    @dynamic_registration = load_json_fixture(:dynamic_registration)
  end

  def validate_register_payload(req, confidential)
    body = JSON.parse(req.body)

    required_fields = %w[client_name initiate_login_uri redirect_uris token_endpoint_auth_method grant_types scope].all? { |k| body.key?(k) }
    all_uris = [body['initiate_login_uri'], body['redirect_uris']].flatten.all? { |uri| valid_uri?(uri) }

    confidential_correct = (!confidential && body['token_endpoint_auth_method'] == 'none') || (confidential && body['token_endpoint_auth_method'] == 'client_secret_basic')

    required_fields && all_uris && confidential_correct
  end

  def all_pass(bearer_present, confidential)
    WebMock.reset!
    headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
    headers['Authorization'] = "Bearer #{DYNAMIC_REGISTRATION_TOKEN}" if bearer_present

    stub_register = stub_request(:post, @instance.oauth_register_endpoint)
                    .with(headers: headers) { |req| validate_register_payload(req, confidential) }
                    .to_return(status: 201, body: @dynamic_registration.to_json, headers: RESPONSE_HEADERS)

    @instance.dynamic_registration_token = (DYNAMIC_REGISTRATION_TOKEN if bearer_present)

    @instance.confidential_client = confidential
    sequence_result = @sequence.start

    assert_requested(stub_register)

    failures = sequence_result.test_results.select { |r| r.result != 'pass' && r.result != 'skip' }

    assert failures.empty?, "All tests should pass.  First error: #{!failures.empty? && failures.first.message}"
    assert sequence_result.result == 'pass', 'Sequence should pass'
    assert sequence_result.test_results.all? { |r| r.test_warnings.empty? }, 'There should not be any warnings.'
  end

  def test_all_pass_bearer_confidential
    all_pass(true, true)
  end

  def test_all_pass_no_bearer_confidential
    all_pass(false, true)
  end

  def test_all_pass_no_bearer_not_confidential
    all_pass(false, false)
  end

  def test_all_pass_bearer_not_confidential
    all_pass(true, false)
  end
end
