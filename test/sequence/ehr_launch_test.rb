require File.expand_path '../../test_helper.rb', __FILE__

class EHRLaunchSequenceTest < MiniTest::Unit::TestCase

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
                                   client_id: SecureRandom.uuid,
                                   oauth_authorize_endpoint: 'http://oauth_reg.example.com/authorize',
                                   oauth_token_endpoint: 'http://oauth_reg.example.com/token',
                                   scopes: 'launch openid patient/*.* profile'
                                   )
    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    client = FHIR::Client.new(@instance.url)
    client.use_dstu2
    client.default_json
    @sequence = ProviderEHRLaunchSequence.new(@instance, client, true)
    @standalone_token_exchange = load_json_fixture(:standalone_token_exchange)
  end

  def test_all_pass
    WebMock.reset!

    stub_request(:post, @instance.oauth_token_endpoint).
      with(headers: {'Content-Type'=>'application/x-www-form-urlencoded'}).
      to_return(status: 200, body: @standalone_token_exchange.to_json, headers: {content_type: 'application/json; charset=UTF-8', cache_control: 'no-store', pragma:'no-cache'})

    stub_request(:post, @instance.oauth_token_endpoint).
      with(body: /INVALID_/,headers: {'Content-Type'=>'application/x-www-form-urlencoded'}).
      to_return(status: 401)


    sequence_result = @sequence.start

    assert sequence_result.result == 'wait', 'The sequence should be in a wait state.'
    assert sequence_result.wait_at_endpoint == 'launch', 'The sequence should be waiting at a launch url.'

    sequence_result = @sequence.resume(nil, nil, {"iss"=>@instance.url, "launch" => SecureRandomBase62.generate(32)})

    assert sequence_result.result == 'wait', 'The sequence should be in a wait state.'
    assert sequence_result.redirect_to_url.start_with? @instance.oauth_authorize_endpoint, 'The sequence should be redirecting to the authorize url'
    assert sequence_result.wait_at_endpoint == 'redirect', 'The sequence should be waiting at a redirect url'

    redirect_params = {'code'=>'5N01E0', 'state'=>@instance.state}

    sequence_result = @sequence.resume(nil, nil, redirect_params)

    failures = sequence_result.test_results.select{|r| r.result != 'pass' && r.result != 'skip'}
    assert failures.length == 0, "All tests should pass.  First error: #{!failures.empty? && failures.first.message}"
    assert sequence_result.result == 'pass', 'Sequence should pass'
    assert sequence_result.test_results.all?{|r| r.test_warnings.empty? }, 'There should not be any warnings.'

  end

end
