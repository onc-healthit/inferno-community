require File.expand_path '../../test_helper.rb', __FILE__

class DynamicRegistrationSequenceTest < MiniTest::Unit::TestCase

  REQUEST_HEADERS = { 'Accept'=>'application/json+fhir',
                      'Accept-Charset'=>'UTF-8',
                      'Content-Type'=>'application/json+fhir;charset=UTF-8'
                     }

  RESPONSE_HEADERS = {"content-type"=>"application/json"}

  def setup
    @instance = Inferno::Models::TestingInstance.new(url: 'http://www.example.com',
                                   client_name: 'Inferno',
                                   base_url: 'http://localhost:4567',
                                   client_endpoint_key: Inferno::SecureRandomBase62.generate(32),
                                   oauth_register_endpoint: 'https://oauth_reg.example.com/register',
                                   scopes: 'launch openid patient/*.* profile'
                                   )
    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    client = FHIR::Client.new(@instance.url)
    client.use_dstu2
    client.default_json
    @sequence = Inferno::Sequence::DynamicRegistrationSequence.new(@instance, client, true)
    @dynamic_registration = load_json_fixture(:dynamic_registration)
  end

  def validate_register_payload(req)
    body = JSON.parse(req.body)

    required_fields = ['client_name', 'initiate_login_uri', 'redirect_uris', 'token_endpoint_auth_method', 'grant_types', 'scope'].all? {|k| body.has_key?(k)}
    all_uris = [body['initiate_login_uri'], body['redirect_uris']].flatten.all?{|uri| valid_uri?(uri)}

    required_fields && all_uris
  end

  def test_all_pass
    WebMock.reset!
    headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }

    stub_register = stub_request(:post, @instance.oauth_register_endpoint).
      with(headers: headers){|req| validate_register_payload(req)}.
      to_return(status: 201, body: @dynamic_registration.to_json, headers: RESPONSE_HEADERS)

    sequence_result = @sequence.start

    assert_requested(stub_register)

    failures = sequence_result.test_results.select{|r| r.result != 'pass' && r.result != 'skip'}

    assert failures.length == 0, "All tests should pass.  First error: #{!failures.empty? && failures.first.message}"
    assert sequence_result.result == 'pass', 'Sequence should pass'
    assert sequence_result.test_results.all?{|r| r.test_warnings.empty? }, 'There should not be any warnings.'
  end

end
