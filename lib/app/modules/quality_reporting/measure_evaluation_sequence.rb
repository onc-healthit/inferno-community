# frozen_string_literal: true

require_relative '../../utils/measure_operations'
require_relative '../../utils/bundle'

module Inferno
  module Sequence
    class MeasureEvaluationSequence < SequenceBase
      include MeasureOperations
      include BundleParserUtil

      title 'Measure Evaluation'

      test_id_prefix 'evaluate_measure'

      description 'Ensure that measure report returned by the $evaluate-measure operation for selected measure is correct'

      # Parameters appended to the url for $evaluate-measure call
      PARAMS = {
        'periodStart': '2019-01-01',
        'periodEnd': '2019-12-31'
      }.freeze
      test 'Evaluate Measure' do
        metadata do
          id '01'
          link 'https://hl7.org/fhir/STU3/measure-operations.html#evaluate-measure'
          desc 'Run the $evaluate-measure operation for a measure, results should match those reported by CQF-Ruler'
        end

        measure_id = @instance.measure_to_test
        assert !measure_id.nil?, 'Expected Measure To Test to be defined. The Measure Availability Sequence must be performed before this sequence.'

        # Get measure report from cqf-ruler and build expected results
        expected_results_report = get_measure_evaluation(measure_id, PARAMS.compact)
        expected_results = {}
        expected_results_report.group.each do |group|
          group.population.each do |population|
            name = population.code.coding[0].code
            count = population.count
            expected_results[name] = count
          end
        end

        evaluate_measure_response = evaluate_measure(measure_id, PARAMS.compact)
        assert_response_ok evaluate_measure_response

        # Load response body into a FHIR MeasureReport class
        measure_report = FHIR::STU3.from_contents(evaluate_measure_response.body)
        group = measure_report&.group
        assert(!group.nil?)

        # Check matching values for each population in the group
        group&.first&.population&.each do |p|
          coding = p.code&.coding
          assert(!coding.nil?)
          code = coding.first.code
          assert(!code.nil?)
          assert_equal(expected_results[code], p.count, "Expected #{code} count and actual #{code} count are not equal") if expected_results.key?(code)
        end
      end
    end
  end
end
