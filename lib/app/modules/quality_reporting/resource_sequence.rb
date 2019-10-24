# frozen_string_literal: true

require 'securerandom'
require_relative '../../utils/measure_operations'
require_relative '../../utils/bundle'

module Inferno
  module Sequence
    class ResourceSequence < SequenceBase
      include MeasureOperations
      include BundleParserUtil
      title 'Resource Addition and Availability'

      test_id_prefix 'resource'

      description 'Ensure that a resource can be added via POST request and is afterwards available'

      test 'Check Resource Addition and Availability' do
        metadata do
          id '01'
          link 'https://www.hl7.org/fhir/http.html#ops'
          desc 'Add a resource using a POST request, then verify it is available'
        end

        id_string = SecureRandom.uuid
        observation = FHIR::Observation.new
        identifier = FHIR::Identifier.new value: id_string
        observation.identifier = [identifier]

        reply = @client.create observation
        assert_response_created reply

        reply = @client.search(FHIR::Observation, search: { parameters: { identifier: id_string } })
        assert_response_ok reply
        assert_equal 1, reply.resource.total
      end
    end
  end
end
