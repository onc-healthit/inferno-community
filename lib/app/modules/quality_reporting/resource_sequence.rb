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

        get_bundle = lambda { |resource|
          reply = @client.search FHIR::Observation, search: { parameters: { identifier: resource.identifier[0].value } }
          assert_equal '200', reply.response[:code].to_s
          reply.resource
        }

        # A resource that doesnt exist returns an empty bundle
        bundle = get_bundle.call(observation)
        assert_equal 0, bundle.total

        reply = @client.create observation
        assert_equal '201', reply.response[:code].to_s

        bundle = get_bundle.call(observation)
        assert_equal 1, bundle.total

        # get the id from the bundle (id is set by the server)
        observation_id = bundle.entry.first.resource.id

        reply = @client.destroy FHIR::Observation, observation_id
        assert_equal '200', reply.response[:code].to_s

        bundle = get_bundle.call(observation)
        assert_equal 0, bundle.total
      end
    end
  end
end
