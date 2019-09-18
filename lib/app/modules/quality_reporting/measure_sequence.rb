# frozen_string_literal: true

require_relative '../../utils/measure_operations'

module Inferno
  module Sequence
    class MeasureSequence < SequenceBase
      include MeasureOperations

      title 'FHIR Quality Reporting'

      test_id_prefix 'eCQM'

      description 'Tests measure operations for a given FHIR Measure. <br/><br/>'\
                  'Prior to running tests, you must: <br/>'\
                  '1) Have all the VSAC ValueSets on your FHIR server. If you need them, they can be downloaded from the '\
                  '<a href="https://cts.nlm.nih.gov/fhir/">NIH VSAC FHIR server</a>.<br/>'\
                  '2) POST '\
                  '<a href="/inferno/resources/quality_reporting/Bundle/measure-col-bundle.json">this Bundle</a> '\
                  'to your FHIR server, and observe the status codes in the response to ensure all resources '\
                  'saved sucessfully.'

      # These values are based on the content of the measure-col bundle used for this module.
      measure_name = 'EXM130'
      patient_id = 'MitreTestScript-test-Patient-410'
      observation_id = 'MitreTestScript-test-Observation-32794'
      period_start = '2017'
      period_end = '2017'

      # Parameters appended to the url for $evaluate-measure and $collect-data calls
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

      test 'Evaluate Measure' do
        metadata do
          id '01'
          link 'https://hl7.org/fhir/STU3/measure-operations.html#evaluate-measure'
          desc 'Run the $evaluate-measure operation for an individual that should be in the IPP and Denominator'
        end

        # Check that measure exists
        measure_resource_response = get_measure_resources_by_name(measure_name)
        assert_response_ok measure_resource_response
        assert(JSON.parse(measure_resource_response.body)['total'] > 0, "#{measure_name} not found")

        evaluate_measure_response = evaluate_measure(measure_name, PARAMS.compact)
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

      test 'Collect Data' do
        metadata do
          id '02'
          link 'https://hl7.org/fhir/measure-operation-collect-data.html'
          desc 'Run the $collect-data operation for a measure that should contain an individual in the IPP, Denominator, and Numerator'
        end

        # Check that measure exists
        measure_resource_response = get_measure_resources_by_name(measure_name)
        assert_response_ok measure_resource_response
        assert(JSON.parse(measure_resource_response.body)['total'] > 0, "#{measure_name} not found")

        collect_data_response = collect_data(measure_name, PARAMS.compact)
        assert_response_ok collect_data_response

        # Load response body into a FHIR Parameters class
        parameters = FHIR::STU3.from_contents(collect_data_response.body)
        assert !parameters.nil?, 'Response must be a Parameters object.'

        # Assert that the Parameters response contains a MeasureReport
        measure_report_param = parameters.parameter.find { |p| p.resource.is_a?(FHIR::STU3::MeasureReport) }
        assert !measure_report_param.nil?, 'Response Parameters must contain a MeasureReport.'
        assert measure_report_param.name == 'measurereport', 'Expected MeasureReport Parameter to have name "measurereport".'

        # Assert that the Parameters response contains the Patient
        patient_param = parameters.parameter.find do |p|
          p.resource.is_a?(FHIR::STU3::Patient) &&
            p.resource.id == patient_id
        end
        assert !patient_param.nil?, "Response Parameters must contain Patient: #{patient_id}."
        assert patient_param.name == 'resource', 'Expected Patient Parameter to have name "resource".'

        # Assert that the Parameters response contains the Observation
        observation_param = parameters.parameter.find do |p|
          p.resource.is_a?(FHIR::STU3::Observation) &&
            p.resource.id == observation_id
        end
        assert !observation_param.nil?, "Response Parameters must contain the Observation relevant to the measure: #{observation_id}."
        assert observation_param.name == 'resource', 'Expected Observation Parameter to have name "resource".'
      end
    end
  end
end
