require File.expand_path '../../test_helper.rb', __FILE__

class DynamicRegistrationSequenceTest < MiniTest::Unit::TestCase

  REQUEST_HEADERS = { 'Accept'=>'application/json+fhir', 
                      'Accept-Charset'=>'UTF-8', 
                      'Content-Type'=>'application/json+fhir;charset=UTF-8'
                     }

  RESPONSE_HEADERS = {"content-type"=>"application/json"}

  def setup
    @instance = TestingInstance.new(url: 'http://www.example.com',
                                   client_name: 'Crucible Smart App',
                                   base_url: 'http://localhost:4567',
                                   client_endpoint_key: SecureRandomBase62.generate(32),
                                   oauth_register_endpoint: 'https://oauth_reg.example.com/register',
                                   scopes: 'launch openid patient/*.* profile'
                                   )
    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    client = FHIR::Client.new(@instance.url)
    client.use_dstu2
    client.default_json
    @sequence = DynamicRegistrationSequence.new(@instance, client)
    @dynamic_registration = load_json_fixture(:dynamic_registration)
  end

  def test_all_pass
    WebMock.reset!
    headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }

    stub_request(:post, @instance.oauth_register_endpoint).
      with(headers: headers).
      to_return(status: 201, body: @dynamic_registration.to_json, headers: RESPONSE_HEADERS)

    sequence_result = @sequence.start

    failures = sequence_result.test_results.select{|r| r.result != 'pass'}

    assert failures.length == 0, "All tests should pass.  First error: #{!failures.empty? && failures.first.message}"
    assert sequence_result.result == 'pass', 'Sequence should pass'
    assert sequence_result.test_results.all?{|r| r.test_warnings.empty? }, 'There should not be any warnings.'
  end

end
