# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsObservationtobaccouseuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Observation (SH: tobacco use) Tests'
      description 'Verify support for the server capabilities required by the Observation (SH: tobacco use) profile.'
      details %(
      )
      test_id_prefix 'OTUUI'
      requires :observation_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Observation resource from the Observation read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-tobaccouse-uv-ips'
          description %(
            This test will verify that Observation resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.observation_id
        @resource_found = validate_read_reply(FHIR::Observation.new(id: resource_id), FHIR::Observation)
        save_resource_references(versioned_resource_class('Observation'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-tobaccouse-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Observation resource that matches the Observation (SH: tobacco use) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-tobaccouse-uv-ips'
          description %(
            This test will validate that the Observation resource returned from the server matches the Observation (SH: tobacco use) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Observation', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-tobaccouse-uv-ips')
      end
    end
  end
end
