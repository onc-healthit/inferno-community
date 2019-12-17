# frozen_string_literal: true

require_relative '../../utils/measure_operations'
require_relative '../../utils/bundle'

module Inferno
  module Sequence
    class SubmitDataSequence < SequenceBase
      include MeasureOperations
      include BundleParserUtil
      title 'Submit Data'

      test_id_prefix 'submit_data'

      description 'Ensure that resources relevant to a measure can be submitted via the $submit-data operation'

      test 'Submit Data valid submission' do
        metadata do
          id '01'
          link 'https://www.hl7.org/fhir/measure-operation-submit-data.html'
          desc 'Submit resources relevant to a measure, and then verify they persist on the server.'
        end

        # Get the patient data to submit. For now this just always uses CMS130 data.
        patient_file = File.expand_path('../../../../resources/quality_reporting/CMS130/Bundle/cms130-patient-bundle.json', __dir__)
        patient_bundle = FHIR::STU3::Json.from_json(File.read(patient_file))
        resources = patient_bundle.entry.map(&:resource)
        patient = resources.first { |r| r.resourceType == 'Patient' }

        # Submit the data
        submit_data_response = submit_data(@instance.measure_to_test, patient.id, '2019', '2019', resources)
        assert_response_ok(submit_data_response)

        # GET and assert presence of all submitted resources
        resources.each do |r|
          relative_url = "#{r.resourceType}/#{r.id}"
          get_response = @client.get(relative_url)
          assert_response_ok(get_response, "Submitted resource unavailable on the server: #{relative_url}")
        end
      end
    end
  end
end
