# frozen_string_literal: true

require File.expand_path '../../test_helper.rb', __dir__

# Tests for the MeasureSequence
class MeasureSequenceTest < MiniTest::Test
  REQUEST_HEADERS = { 'Accept' => 'application/fhir+json',
                      'Accept-Charset' => 'utf-8',
                      'Accept-Encoding' => 'gzip, deflate',
                      'Format' => 'application/fhir+json',
                      'Host' => 'www.example.com',
                      'User-Agent' => 'Ruby FHIR Client' }.freeze

  MEASURES_TO_TEST = [
    {
      measure_id: 'MitreTestScript-measure-col',
      params: {
        'patient': 'MitreTestScript-test-Patient-410',
        'periodStart': '2017',
        'periodEnd': '2017'
      },
      example_measurereport: :col_measure_report
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
      # Set the required instance variables
      @instance.measure_id = req[:measure_id]
      @instance.patient_id = req[:params][:patient]
      @instance.period_start = req[:params][:periodStart]
      @instance.period_end = req[:params][:periodEnd]

      # Set other variables needed
      params_string = !req[:params].empty? ? "?#{req[:params].to_query}" : ''
      measure_report = load_json_fixture(req[:example_measurereport])

      # Mock a request for $evaluate-measure
      stub_request(:get, "http://www.example.com/Measure/#{req[:measure_id]}/$evaluate-measure#{params_string}")
        .with(headers: REQUEST_HEADERS)
        .to_return(status: 200, body: measure_report.to_json, headers: {})

      sequence_result = @sequence.start
      assert sequence_result.pass?, 'The sequence should be marked as pass.'
      assert sequence_result.test_results.all? { |r| r.pass? || r.skip? }, 'All tests should pass'
    end
  end
end
