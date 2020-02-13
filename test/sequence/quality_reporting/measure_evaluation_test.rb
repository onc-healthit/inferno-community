# frozen_string_literal: true

require File.expand_path '../../test_helper.rb', __dir__

class MeasureEvaluationSequenceTest < MiniTest::Test
  def setup
    @instance = Inferno::Models::TestingInstance.new(url: 'http://www.example.com', selected_module: 'quality_reporting')
    @instance.save! # this is for convenience.  we could rewrite to ensure nothing gets saved within tests.
    @instance.measure_to_test = 'TestMeasure'
    client = FHIR::Client.new(@instance.url)
    client.use_r4
    client.default_json
    @sequence = Inferno::Sequence::MeasureEvaluationSequence.new(@instance, client, true)
  end

  MEASURES_TO_TEST = [
    {   measure_id: 'measurereport-numer-EXM130-FHIR4-7.2.000-expectedresults',
        measure_report: 'measurereport-numer-EXM130_FHIR4-7.2.000-expectedresults' }
  ].freeze

  def test_all_pass
    WebMock.reset!

    MEASURES_TO_TEST.each do |measure_info|
      measure_report = load_json_fixture(measure_info[:measure_report])

      # Mock a request for $evaluate-measure
      stub_request(:get, /\$evaluate-measure/)
        .to_return(status: 200, body: measure_report.to_json, headers: {})

      sequence_result = @sequence.start
      assert sequence_result.pass?, 'The sequence should be marked as pass.'
      assert sequence_result.test_results.all? { |r| r.pass? || r.skip? }, 'All tests should pass'
    end
  end

  def test_evaluate_measure_fail_mismatched_population_counts
    WebMock.reset!

    @instance.measure_to_test = 'MitreTestScript-measure-col'
    # These reports do not have matching population counts which should cause the sequence to fail
    mismatched_measure_report = load_json_fixture(:col_measure_report)
    all_zeros_report = load_json_fixture(:col_measure_report_all_zero)

    # Stub out the response from the SUT
    stub_request(:get, %r{www.example.com/Measure})
      .to_return(status: 200, body: mismatched_measure_report.to_json, headers: {})
    # Stub out the response from CQF-Ruler which the sequence uses to retrieve "known-good" results
    stub_request(:get, %r{cqf-ruler-r4/fhir})
      .to_return(status: 200, body: all_zeros_report.to_json, headers: {})

    sequence_result = @sequence.start
    assert(sequence_result.fail?, 'The sequence should be marked as fail.')
  end

  def test_evaluate_measure_unsupported_measure_fail
    WebMock.reset!

    @instance.measure_to_test = 'measure-not-supported'
    stub_request(:get, /\$evaluate-measure/)
      .to_return(status: 200)

    sequence_result = @sequence.start
    assert(sequence_result.fail?, 'The sequence should be marked as fail.')
  end
end
