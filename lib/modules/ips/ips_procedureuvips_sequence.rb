# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsProcedureuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Procedure (IPS) Tests'
      description 'Verify support for the server capabilities required by the Procedure (IPS) profile.'
      details %(
      )
      test_id_prefix 'PUI'
      requires :procedure_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Procedure resource from the Procedure read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Procedure-uv-ips'
          description %(
            This test will verify that Procedure resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.procedure_id
        @resource_found = validate_read_reply(FHIR::Procedure.new(id: resource_id), FHIR::Procedure)
        save_resource_references(versioned_resource_class('Procedure'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Procedure-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Procedure resource that matches the Procedure (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Procedure-uv-ips'
          description %(
            This test will validate that the Procedure resource returned from the server matches the Procedure (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Procedure', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Procedure-uv-ips')
      end
    end
  end
end
