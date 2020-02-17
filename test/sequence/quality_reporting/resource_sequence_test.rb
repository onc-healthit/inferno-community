# frozen_string_literal: true

require File.expand_path '../../test_helper.rb', __dir__

# Tests for the MeasureSequence
class ResourceSequenceTest < MiniTest::Test
  REQUEST_HEADERS = { 'Accept' => 'application/fhir+json',
                      'Accept-Charset' => 'utf-8',
                      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                      'Host' => 'www.example.com',
                      'User-Agent' => 'Ruby FHIR Client' }.freeze

  def setup
    @instance = Inferno::Models::TestingInstance.new(url: 'http://www.example.com', selected_module: 'quality_reporting')
    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    client = FHIR::Client.new(@instance.url)
    client.use_r4
    client.default_json
    @sequence = Inferno::Sequence::ResourceSequence.new(@instance, client, true)
  end

  def test_all_pass
    WebMock.reset!

    observation = FHIR::Observation.new id: 'abc'
    entry = FHIR::Bundle::Entry.new
    entry.resource = observation
    bundle_with_one_resource = FHIR::Bundle.new total: 1
    bundle_with_one_resource.entry = [entry]

    stub_request(:get, /Observation/)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: bundle_with_one_resource.to_json, headers: {})

    stub_request(:post, /Observation/)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 201, body: '', headers: {})

    sequence_result = @sequence.start
    assert sequence_result.pass?, 'The sequence should be marked as pass.'
    assert sequence_result.test_results.all? { |r| r.pass? || r.skip? }, 'All tests should pass'
  end

  def test_post_fail
    WebMock.reset!
    bundle_with_one_resource = FHIR::Bundle.new
    bundle_with_one_resource.total = 1

    stub_request(:get, /Observation/)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: bundle_with_one_resource.to_s, headers: {})

    stub_request(:post, /Observation/)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 403, body: '', headers: {})

    sequence_result = @sequence.start
    assert sequence_result.fail?, 'The sequence should be marked as fail.'
  end

  def test_get_fail
    WebMock.reset!

    stub_request(:get, /Observation/)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 404, body: '', headers: {})

    stub_request(:post, /Observation/)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 201, body: '', headers: {})

    sequence_result = @sequence.start
    assert sequence_result.fail?, 'The sequence should be marked as fail.'
  end
end
