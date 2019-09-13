# frozen_string_literal: true

require_relative '../../utils/measure_operations'

module Inferno
  module Sequence
    class CMS165ReportingSequence < SequenceBase
      include MeasureOperations

      title 'CMS165 Quality Reporting'

      test_id_prefix 'CMS165'

      description 'Tests measure operations for CMS165 (Controlling High Blood Pressure). <br/><br/>'\
                  'Prior to running tests, you must: <br/>'\
                  '1) POST '\
                  '<a href="/inferno/resources/quality_reporting/Bundle/cms165vs-bundle.json">the CMS165 ValueSet Bundle</a> '\
                  'to your FHIR server, and observe the status codes in the response to ensure all resources '\
                  'saved sucessfully. <br/>'\
                  '2) POST the '\
                  '<a href="/inferno/resources/quality_reporting/Bundle/cms165-bundle.json">measure Bundle</a> '\
                  'to your FHIR server, and observe the status codes in the response to ensure all resources '\
                  'saved sucessfully. <br/>'\
                  '3) POST the '\
                  '<a href="/inferno/resources/quality_reporting/Bundle/cms165-patient-bundle.json">patient Bundle</a> '\
                  'to your FHIR server, and observe the status codes in the response to ensure all resources '\
                  'saved sucessfully. <br/>'

      # These values are based on the content of the CMS165 bundle used for this module.
      measure_id = 'MitreTestScript-measure-exm165-FHIR3'
      patient_id = 'bc4159a4-6ff2-4a5b-be3a-d9c4778642c2-1'
      period_start = '2019'
      period_end = '2019'

      test 'Evaluate Measure' do
        metadata do
          id '01'
          link 'https://hl7.org/fhir/STU3/measure-operations.html#evaluate-measure'
          desc 'Run the $evaluate-measure operation for an individual that should be in the IPP and Denominator'
        end

        # Parameters appended to the url for $evaluate-measure call
        PARAMS = {
          'patient': patient_id,
          'periodStart': period_start,
          'periodEnd': period_end
        }.freeze

        # TODO: The way we handle expected results are going to change in the future
        # Eventually, we will have test bundles that will be calculated as the "gold standard" for calc results
        # For now, we are going to keep if with these individual canned expected results
        EXPECTED_RESULTS = {
          'initial-population': 1,
          'numerator': 1,
          'denominator': 1
        }.freeze

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
          assert_equal(EXPECTED_RESULTS[code.to_sym], p.count, "Expected #{code} count and actual #{code} count are not equal") if EXPECTED_RESULTS.key?(code.to_sym)
        end
      end
    end
  end
end
