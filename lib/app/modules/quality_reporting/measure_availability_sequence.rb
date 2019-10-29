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
      requires :measure_to_test

      description 'Ensure that a specific measure exists on test server'

      test 'Check Measure Availability' do
        metadata do
          id '01'
          link 'https://www.hl7.org/fhir/measure.html'
          desc 'Check to make sure specified measure is available on test server'
        end
        measure_id = @instance.measure_to_test
        query_response = @client.search(FHIR::Measure, search: { parameters: { _id: measure_id } })
        assert_equal query_response.resource.total, 1, "Expected to find measure with id #{measure_id}"
      end
    end
  end
end
