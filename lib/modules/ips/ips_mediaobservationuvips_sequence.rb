# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsMediaobservationuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Media observation (Results: laboratory, media) Tests'
      description 'Verify support for the server capabilities required by the Media observation (Results: laboratory, media) profile.'
      details %(
      )
      test_id_prefix 'MOUI'
      requires :media_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Media resource from the Media read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Media-observation-uv-ips'
          description %(
            This test will verify that Media resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.media_id
        @resource_found = validate_read_reply(FHIR::Media.new(id: resource_id), FHIR::Media)
        save_resource_references(versioned_resource_class('Media'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Media-observation-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Media resource that matches the Media observation (Results: laboratory, media) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Media-observation-uv-ips'
          description %(
            This test will validate that the Media resource returned from the server matches the Media observation (Results: laboratory, media) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Media', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Media-observation-uv-ips')
      end
    end
  end
end
