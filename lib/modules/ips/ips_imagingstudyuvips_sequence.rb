# frozen_string_literal: true

require_relative './profile_definitions/ips_imagingstudyuvips_sequence_definitions'

module Inferno
  module Sequence
    class IpsImagingstudyuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities
      include Inferno::IpsProfileDefinitions

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

      test :must_support do
        metadata do
          id '03'
          name 'All must support elements are provided in the ImagingStudy resources returned.'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/ImagingStudy-uv-ips'
          optional
          description %(

            This will look through the ImagingStudy resource for the following must support elements:

            * ImagingStudy
            * identifier
            * procedureCode
            * reasonCode
            * series
            * series.instance
            * series.instance.sopClass
            * series.instance.uid
            * series.modality
            * series.uid
            * started
            * subject
            * subject.reference

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        must_supports = IpsImagingstudyuvipsSequenceDefinition::MUST_SUPPORTS

        missing_must_support_elements = must_supports[:elements].reject do |element|
          value_found = resolve_element_from_path(@resource_found, element[:path]) do |value|
            value_without_extensions = value.respond_to?(:to_hash) ? value.to_hash.reject { |key, _| key == 'extension' } : value
            (value_without_extensions.present? || value_without_extensions == false) && (element[:fixed_value].blank? || value == element[:fixed_value])
          end

          # Note that false.present? => false, which is why we need to add this extra check
          value_found.present? || value_found == false
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the provided resource"
        @instance.save!
      end
    end
  end
end
