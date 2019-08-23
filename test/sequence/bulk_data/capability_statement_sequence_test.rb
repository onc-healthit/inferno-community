# frozen_string_literal: true

require_relative '../../test_helper'

class BulkDataCapabilityStatementSequenceTest < MiniTest::Test
  REQUEST_HEADERS = { 'Accept' => 'application/fhir+json',
                      'Accept-Charset' => 'utf-8',
                      'Accept-Encoding' => 'gzip, deflate',
                      'Host' => 'www.example.com',
                      'User-Agent' => 'Ruby FHIR Client' }.freeze

  RESPONSE_HEADERS = { 'content-type' => 'application/json+fhir;charset=UTF-8' }.freeze

  def setup
    instance = Inferno::Models::TestingInstance.new(
      url: 'http://www.example.com',
      selected_module: 'bulk_data'
    )
    instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.

    client = FHIR::Client.new(instance.url)
    client.use_stu3
    client.default_json

    @sequence = Inferno::Sequence::BulkDataCapabilityStatementSequence.new(instance, client, true)
    @conformance = load_json_fixture(:bulk_data_conformance)
  end

  def test_all_pass
    WebMock.reset!
    stub_request(:get, 'http://www.example.com/metadata')
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: @conformance.to_json, headers: RESPONSE_HEADERS)

    sequence_result = @sequence.start
    assert sequence_result.pass?, 'The sequence should be marked as pass.'
    assert sequence_result.test_results.all? { |r| r.pass? || r.skip? || r.omit? }, 'All tests should pass'
  end
end
