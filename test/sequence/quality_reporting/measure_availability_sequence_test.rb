# frozen_string_literal: true

require File.expand_path '../../test_helper.rb', __dir__

class MeasureAvailabilityTest < MiniTest::Test
  REQUEST_HEADERS = {
    'Accept' => 'application/fhir+json',
    'Accept-Charset' => 'utf-8',
    'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
    'Host' => 'www.example.com',
    'User-Agent' => 'Ruby FHIR Client'
  }.freeze

  MEASURES_TO_TEST = [
    {
      measure_id: 'MitreTestScript-measure-col',
      example_measurereport: :col_measure_report,
      mock_collect_data_response: :col_collect_data_response,
      mock_get_measure_response: :exm130_get_measure_resource
      # Add new Measures/params here...
    }
  ].freeze

  def setup
    @instance = Inferno::Models::TestingInstance.new(url: 'http://www.example.com', selected_module: 'quality_reporting')
    @instance.save!
    client = FHIR::Client.new(@instance.url)
    client.use_stu3
    client.default_json
    @sequence = Inferno::Sequence::MeasureAvailability.new(@instance, client, true)
  end

  def test_all_pass
    WebMock.reset!

    MEASURES_TO_TEST.each do |req|
      # Set other variables needed
      measure_resource = load_json_fixture(req[:mock_get_measure_response])
      @instance.measure_to_test = req[:measure_id]
      # Mock a request for measure resource with specified id
      stub_request(:get, "http://www.example.com/Measure?_id=#{@instance.measure_to_test}")
        .with(headers: REQUEST_HEADERS)
        .to_return(status: 200, body: measure_resource.to_json, headers: {})

      sequence_result = @sequence.start
      assert sequence_result.pass?, 'The sequence should be marked as pass.'
      assert sequence_result.test_results.all? { |r| r.pass? || r.skip? }, 'All tests should pass'
    end
  end

  def test_measure_not_found
    WebMock.reset!
    @instance.measure_to_test = 'foobar'
    stub_request(:get, 'http://www.example.com/Measure?_id=foobar')
      .with(headers: REQUEST_HEADERS)
      .to_return(status: 404, body: '', headers: {})

    sequence_result = @sequence.start
    assert sequence_result.fail?, 'The sequence should be marked as fail.'
  end
end
