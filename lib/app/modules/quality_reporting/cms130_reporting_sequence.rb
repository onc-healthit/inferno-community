# frozen_string_literal: true

require_relative '../../utils/measure_operations'

module Inferno
  module Sequence
    class CMS130ReportingSequence < SequenceBase
      include MeasureOperations

      title 'CMS130 Quality Reporting'

      test_id_prefix 'CMS130'

      description 'Tests measure operations for CMS130 (Colorectal Cancer Screening). <br/><br/>'\
                  'Prior to running tests, you must: <br/>'\
                  '1) Verify all needed VSAC ValueSets are on your FHIR server using the ValueSetSequence above. '\
                  'If any are missing, they can be downloaded from the '\
                  '<a href="https://cts.nlm.nih.gov/fhir/">NIH VSAC FHIR server</a>.<br/>'\
                  '2) POST '\
                  '<a href="/inferno/resources/quality_reporting/CMS130/Bundle/cms130-bundle.json">this Bundle</a> '\
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
          link 'https://www.hl7.org/fhir/operation-measure-evaluate-measure.html'
          desc 'Run the $evaluate-measure operation for an individual that should be in the IPP and Denominator'
        end

        # Check that measure exists
        measure_resource_response = get_measure_resources_by_name(measure_name)
        assert_response_ok measure_resource_response
        bundle = FHIR::Bundle.new(JSON.parse(measure_resource_response.body))
        assert(bundle&.total&.positive?, "#{measure_name} not found")

        measure_id = bundle.entry[0].resource.id
        evaluate_measure_response = evaluate_measure(measure_id, PARAMS.compact)
        assert_response_ok evaluate_measure_response

        # Load response body into a FHIR MeasureReport class
        measure_report = FHIR.from_contents(evaluate_measure_response.body)
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
        bundle = FHIR::Bundle.new(JSON.parse(measure_resource_response.body))
        assert(bundle&.total&.positive?, "#{measure_name} not found")

        measure_id = bundle.entry[0].resource.id
        collect_data_response = collect_data(measure_id, PARAMS.compact)
        assert_response_ok collect_data_response

        # Load response body into a FHIR Parameters class
        parameters = FHIR.from_contents(collect_data_response.body)
        assert !parameters.nil?, 'Response must be a Parameters object.'

        # Assert that the Parameters response contains a MeasureReport
        measure_report_param = parameters.parameter.find { |p| p.resource.is_a?(FHIR::MeasureReport) }
        assert !measure_report_param.nil?, 'Response Parameters must contain a MeasureReport.'
        assert measure_report_param.name == 'measurereport', 'Expected MeasureReport Parameter to have name "measurereport".'

        # Assert that the Parameters response contains the Patient
        patient_param = parameters.parameter.find do |p|
          p.resource.is_a?(FHIR::Patient) &&
            p.resource.id == patient_id
        end
        assert !patient_param.nil?, "Response Parameters must contain Patient: #{patient_id}."
        assert patient_param.name == 'resource', 'Expected Patient Parameter to have name "resource".'

        # Assert that the Parameters response contains the Observation
        observation_param = parameters.parameter.find do |p|
          p.resource.is_a?(FHIR::Observation) &&
            p.resource.id == observation_id
        end
        assert !observation_param.nil?, "Response Parameters must contain the Observation relevant to the measure: #{observation_id}."
        assert observation_param.name == 'resource', 'Expected Observation Parameter to have name "resource".'
      end
    end
  end
end
