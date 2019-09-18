# frozen_string_literal: true

require_relative '../../utils/measure_operations'
require_relative '../../utils/measure_bundle_parser'

module Inferno
  module Sequence
    class ValueSetSequence < SequenceBase
      include MeasureOperations
      include MeasureBundleParserUtil
      title 'ValueSet Availability'

      test_id_prefix 'valueset'

      description 'Ensure that all required value sets for a target measure are available'

      test 'Check ValueSet Availability' do
        metadata do
          id '01'
          link 'https://hl7.org/fhir/STU3/valueset-operations.html#expand'
          desc 'Expand each Value Set in a measure to ensure they are available'
        end

        root = "#{__dir__}/../../../.."
        path = File.expand_path('resources/quality_reporting/Bundle/measure-col-bundle.json', root)
        measurebundle = JSON.parse(File.read(path))
        main_library_id = 'MitreTestScript-measure-col'
        library = get_library_by_id(measurebundle, main_library_id)
        valueset_urls = get_all_dependent_valuesets(library, measurebundle)

        valueset_urls.each do |vs_url|
          res = @client.get "ValueSet/#{vs_url}", @client.fhir_headers(format: FHIR::Formats::ResourceFormat::RESOURCE_JSON)
          assert_response_ok res
        end
      end
    end
  end
end
