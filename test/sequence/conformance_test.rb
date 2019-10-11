# frozen_string_literal: true

require File.expand_path '../test_helper.rb', __dir__

# Tests for the ArgonautConformanceSequence
# Note: This test currently only considers dstu2
class ConformanceSequenceTest < MiniTest::Test
  REQUEST_HEADERS = { 'Accept' => 'application/json+fhir',
                      'Accept-Charset' => 'utf-8',
                      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                      'Host' => 'www.example.com',
                      'User-Agent' => 'Ruby FHIR Client' }.freeze

  RESPONSE_HEADERS = { 'content-type' => 'application/json+fhir;charset=UTF-8' }.freeze

  def setup
    instance = Inferno::Models::TestingInstance.new(url: 'http://www.example.com', selected_module: 'argonaut')
    instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    client = FHIR::Client.new(instance.url)
    client.use_dstu2
    client.default_json
    @sequence = Inferno::Sequence::ArgonautConformanceSequence.new(instance, client, true)
    @conformance = load_json_fixture(:conformance_statement)
  end

  def test_all_pass
    WebMock.reset!
    stub_request(:get, 'http://www.example.com/metadata')
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: @conformance.to_json, headers: RESPONSE_HEADERS)

    sequence_result = @sequence.start
    assert sequence_result.pass?, 'The sequence should be marked as pass.'
    assert sequence_result.test_results.all? { |r| r.pass? || r.skip? || r.omit? }, 'All tests should pass'
    # assert sequence_result.test_results.all?{|r| r.test_warnings.empty? }, 'There should not be any warnings.'
  end

  def test_no_metadata_endpoint
    WebMock.reset!
    stub_request(:get, 'http://www.example.com/metadata')
      .to_return(status: 404)

    sequence_result = @sequence.start
    assert sequence_result.fail?
  end
end
