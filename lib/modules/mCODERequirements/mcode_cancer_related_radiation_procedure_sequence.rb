# frozen_string_literal: true

module Inferno
  module Sequence
    class MCODERequirementsMcodeCancerRelatedRadiationProcedureSequence < SequenceBase
      title 'Cancer-Related Radiation Procedure Tests'

      description 'Verify support for the server capabilities required by the Cancer-Related Radiation Procedure.'

      details %(
      )

      test_id_prefix 'C-RRP'
      requires :mcode_cancer_related_radiation_procedure_id
      conformance_supports :Procedure

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Procedure resource from the Procedure read interaction'
          link 'http://hl7.org/fhir/us/mcode/index.html'
          description %(
            Tests whether the Procedure with the provided id can be resolved and read.
          )
          versions :r4
        end

        resource_id = @instance.mcode_cancer_related_radiation_procedure_id
        read_response = validate_read_reply(FHIR::Procedure.new(id: resource_id), FHIR::Procedure)
        @resource_found = read_response.resource
        @raw_resource_found = read_response.response[:body]
      end

      test :validate_resources do
        metadata do
          id '02'
          name 'The Procedure resource returned from the first Read test is valid according to the profile http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-related-radiation-procedure.'
          link ''
          description %(

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?

        test_resource_against_profile('Procedure', @raw_resource_found, 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-cancer-related-radiation-procedure')
      end
    end
  end
end
