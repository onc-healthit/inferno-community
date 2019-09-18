# frozen_string_literal: true

require File.expand_path '../../test_helper.rb', __dir__

# Tests for the MeasureSequence
class MeasureSequenceTest < MiniTest::Test
  REQUEST_HEADERS = { 'Accept' => 'application/fhir+json',
                      'Accept-Charset' => 'utf-8',
                      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                      'Format' => 'application/fhir+json',
                      'Host' => 'www.example.com',
                      'User-Agent' => 'Ruby FHIR Client' }.freeze

  MEASURES_TO_TEST = [
    {
      measure_id: 'MitreTestScript-measure-col',
      example_measurereport: :col_measure_report,
      mock_collect_data_response: :col_collect_data_response,
      mock_get_measure_response: :col_get_measure_resource
      # Add new Measures/params here...
    }
  ].freeze

  def setup
    @instance = Inferno::Models::TestingInstance.new(url: 'http://www.example.com', selected_module: 'quality_reporting')
    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    client = FHIR::Client.new(@instance.url)
    client.use_stu3
    client.default_json
    @sequence = Inferno::Sequence::MeasureSequence.new(@instance, client, true)
  end

  def test_all_pass
    WebMock.reset!

    MEASURES_TO_TEST.each do |req|
      # Set other variables needed
      measure_report = load_json_fixture(req[:example_measurereport])
      collect_data_response = load_json_fixture(req[:mock_collect_data_response])
      measure_resource = load_json_fixture(req[:mock_get_measure_response])

      # Mock a request for $evaluate-measure
      stub_request(:get, /\$evaluate-measure/)
        .with(headers: REQUEST_HEADERS)
        .to_return(status: 200, body: measure_report.to_json, headers: {})

      # Mock a request for $collect-data
      stub_request(:get, /\$collect-data/)
        .with(headers: REQUEST_HEADERS)
        .to_return(status: 200, body: collect_data_response.to_json, headers: {})

      # Mock a request for measure resource with name EXM130
      stub_request(:get, /Measure\/name\=EXM130$/)
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 200, body: measure_resource.to_json, headers: {})

      sequence_result = @sequence.start
      assert sequence_result.pass?, 'The sequence should be marked as pass.'
      assert sequence_result.test_results.all? { |r| r.pass? || r.skip? }, 'All tests should pass'
    end
  end

  def test_non_existant_measure_fails
    WebMock.reset!
    # This is the webmock response that will cause the test to fail, it reports 0 measure resources found
    measure_resource = load_json_fixture(:col_get_non_existant_measure)

    # Mock a request for measure resource with name EXM130, response will not be included
    stub_request(:get, /Measure\/name\=EXM130$/)
    .with(headers: REQUEST_HEADERS)
    .to_return(status: 200, body: measure_resource.to_json, headers: {})

    sequence_result = @sequence.start
    assert !sequence_result.pass?, 'The sequence should not be marked as pass. Non-existant measure should not be found'
  end

end
