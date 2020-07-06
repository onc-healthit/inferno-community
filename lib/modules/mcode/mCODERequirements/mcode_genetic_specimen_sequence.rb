# frozen_string_literal: true

module Inferno
  module Sequence
    class MCODERequirementsMcodeGeneticSpecimenSequence < SequenceBase
      title 'Genetic Specimen Tests'

      description 'Verify support for the server capabilities required by the Genetic Specimen.'

      details %(
      )

      test_id_prefix 'GS'
      requires :mcode_genetic_specimen_id
      conformance_supports :Specimen

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Specimen resource from the Specimen read interaction'
          link 'http://hl7.org/fhir/us/mcode/index.html'
          description %(
            Tests whether the Specimen with the provided id can be resolved and read.
          )
          versions :r4
        end

        resource_id = @instance.mcode_genetic_specimen_id
        read_response = validate_read_reply(FHIR::Specimen.new(id: resource_id), FHIR::Specimen)
        @resource_found = read_response.resource
        @raw_resource_found = read_response.response[:body]
      end

      test :validate_resources do
        metadata do
          id '02'
          name 'The Specimen resource returned from the first Read test is valid according to the profile http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-genetic-specimen.'
          link ''
          description %(

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?

        test_resource_against_profile('Specimen', @raw_resource_found, 'http://hl7.org/fhir/us/mcode/StructureDefinition/mcode-genetic-specimen')
      end
    end
  end
end
