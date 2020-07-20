# frozen_string_literal: true

module Inferno
  module Sequence
    class MCODERequirementsMcodeSecondaryCancerConditionSequence < SequenceBase
      title 'Secondary Cancer Condition Tests'

      description 'Verify support for the server capabilities required by the Secondary Cancer Condition.'

      details %(
      )

      test_id_prefix 'SCC'
      requires :mcode_secondary_cancer_condition_id
      conformance_supports :Condition

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Condition resource from the Condition read interaction'
          link 'http://hl7.org/fhir/us/mcode/index.html'
          description %(
            Tests whether the Condition with the provided id can be resolved and read.
          )
          versions :r4
        end

        resource_id = @instance.mcode_secondary_cancer_condition_id
        read_response = validate_read_reply(FHIR::Condition.new(id: resource_id), FHIR::Condition)
        @resource_found = read_response.resource
        @raw_resource_found = read_response.response[:body]
      end

      test :validate_resources do
        metadata do
          id '02'
          name 'The Condition resource returned from the first Read test is valid according to the profile http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-secondary-cancer-condition.'
          link ''
          description %(

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?

        test_resource_against_profile('Condition', @raw_resource_found, 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-secondary-cancer-condition')
      end
    end
  end
end
