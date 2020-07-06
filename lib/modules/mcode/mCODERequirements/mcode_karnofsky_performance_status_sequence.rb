# frozen_string_literal: true

module Inferno
  module Sequence
    class MCODERequirementsMcodeKarnofskyPerformanceStatusSequence < SequenceBase
      title 'Karnofsky Performance Status Tests'

      description 'Verify support for the server capabilities required by the Karnofsky Performance Status.'

      details %(
      )

      test_id_prefix 'KPS'
      requires :mcode_karnofsky_performance_status_id
      conformance_supports :Observation

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Observation resource from the Observation read interaction'
          link 'http://hl7.org/fhir/us/mcode/index.html'
          description %(
            Tests whether the Observation with the provided id can be resolved and read.
          )
          versions :r4
        end

        resource_id = @instance.mcode_karnofsky_performance_status_id
        read_response = validate_read_reply(FHIR::Observation.new(id: resource_id), FHIR::Observation)
        @resource_found = read_response.resource
        @raw_resource_found = read_response.response[:body]
      end

      test :validate_resources do
        metadata do
          id '02'
          name 'The Observation resource returned from the first Read test is valid according to the profile http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-karnofsky-performance-status.'
          link ''
          description %(

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?

        test_resource_against_profile('Observation', @raw_resource_found, 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-karnofsky-performance-status')
      end
    end
  end
end
