# frozen_string_literal: true

require_relative '../../utils/measure_operations'
require_relative '../../utils/bundle'

module Inferno
  module Sequence
    class MeasureAvailability < SequenceBase
      include MeasureOperations
      include BundleParserUtil
      title 'Measure Availability'

      test_id_prefix 'measure_availability'
      requires :measure_to_test, :api_key, :auth_header

      description 'Ensure that a specific measure exists on test server'

      test 'Check Measure Availability' do
        metadata do
          id '01'
          link 'https://www.hl7.org/fhir/measure.html'
          desc 'Check to make sure specified measure is available on test server'
        end

        # Look for matching measure from cqf-ruler datastore by resource id
        measure_id = @instance.measure_to_test
        measure_resource = @instance.module.measures.find { |m| m.resource.id == measure_id }

        @client.additional_headers = { 'x-api-key': @instance.api_key, 'Authorization': @instance.auth_header } if @instance.api_key && @instance.auth_header

        # Search system for measure by identifier and version
        measure_identifier = measure_resource.resource.identifier.find { |id| id.system == 'http://hl7.org/fhir/cqi/ecqm/Measure/Identifier/cms' }
        measure_version = measure_resource.resource.version
        query_response = @client.search(FHIR::Measure, search: { parameters: { identifier: measure_identifier.value, version: measure_version } })
        assert_equal query_response.resource.total, 1, "Expected to find measure with id #{measure_id}"

        # Update instance variable to be the ID we get back from the SUT
        @instance.measure_to_test = query_response.resource.entry.first.resource.id
      end
    end
  end
end
