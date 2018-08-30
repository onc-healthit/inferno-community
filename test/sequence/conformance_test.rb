require File.expand_path '../../test_helper.rb', __FILE__

class ConformanceSequenceTest < MiniTest::Unit::TestCase

  REQUEST_HEADERS = { 'Accept'=>'application/json+fhir',
                      'Accept-Charset'=>'UTF-8',
                      'Content-Type'=>'application/json+fhir;charset=UTF-8'
                     }

  RESPONSE_HEADERS = {'content-type'=>'application/json+fhir;charset=UTF-8'}

  def setup
    instance = TestingInstance.new(url: 'http://www.example.com')
    instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    client = FHIR::Client.new(instance.url)
    client.use_dstu2
    client.default_json
    @sequence = ConformanceSequence.new(instance, client, true)
    @conformance = load_json_fixture(:conformance_statement)
  end

  def test_all_pass
    WebMock.reset!
    stub_request(:get, "http://www.example.com/metadata").
      with(headers: REQUEST_HEADERS).
      to_return(status: 200, body: @conformance.to_json, headers: RESPONSE_HEADERS)

    sequence_result = @sequence.start
    assert sequence_result.result == 'pass', 'The sequence should be marked as pass.'
    assert sequence_result.test_results.all?{|r| r.result == 'pass' || r.result == 'skip'}, 'All tests should pass'
    # assert sequence_result.test_results.all?{|r| r.test_warnings.empty? }, 'There should not be any warnings.'
  end

  def test_no_metadata_endpoint
    WebMock.reset!
    stub_request(:get, "http://www.example.com/metadata").
      to_return(status: 404)

    sequence_result = @sequence.start
    assert sequence_result.result == 'fail'
    assert sequence_result.test_results.select{|r| !r.required}.length == 2 #TLS and SMART capabilities
    assert sequence_result.test_results.all?{|r| r.result == 'fail' || r.result == 'skip' || !r.required}
  end

end
