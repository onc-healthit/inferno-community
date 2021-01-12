# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsImagingstudyuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Imaging Study (IPS) Tests'
      description 'Verify support for the server capabilities required by the Imaging Study (IPS) profile.'
      details %(
      )
      test_id_prefix 'ISUI'
      requires :imaging_study_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct ImagingStudy resource from the ImagingStudy read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/ImagingStudy-uv-ips'
          description %(
            This test will verify that ImagingStudy resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.imaging_study_id
        @resource_found = validate_read_reply(FHIR::ImagingStudy.new(id: resource_id), FHIR::ImagingStudy)
        save_resource_references(versioned_resource_class('ImagingStudy'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/ImagingStudy-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns ImagingStudy resource that matches the Imaging Study (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/ImagingStudy-uv-ips'
          description %(
            This test will validate that the ImagingStudy resource returned from the server matches the Imaging Study (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('ImagingStudy', 'http://hl7.org/fhir/uv/ips/StructureDefinition/ImagingStudy-uv-ips')
      end
    end
  end
end
