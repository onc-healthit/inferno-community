# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsRatioipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Ratio (IPS) Tests'
      description 'Verify support for the server capabilities required by the Ratio (IPS) profile.'
      details %(
      )
      test_id_prefix 'RIPS'
      requires :ratio_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Ratio resource from the Ratio read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Ratio-uv-ips'
          description %(
            This test will verify that Ratio resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.ratio_id
        @resource_found = validate_read_reply(FHIR::Ratio.new(id: resource_id), FHIR::Ratio)
        save_resource_references(versioned_resource_class('Ratio'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Ratio-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Ratio resource that matches the Ratio (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Ratio-uv-ips'
          description %(
            This test will validate that the Ratio resource returned from the server matches the Ratio (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Ratio', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Ratio-uv-ips')
      end
    end
  end
end
