# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsSpecimenuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Specimen (IPS) Tests'
      description 'Verify support for the server capabilities required by the Specimen (IPS) profile.'
      details %(
      )
      test_id_prefix 'SUI'
      requires :specimen_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Specimen resource from the Specimen read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Specimen-uv-ips'
          description %(
            This test will verify that Specimen resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.specimen_id
        @resource_found = validate_read_reply(FHIR::Specimen.new(id: resource_id), FHIR::Specimen)
        save_resource_references(versioned_resource_class('Specimen'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Specimen-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Specimen resource that matches the Specimen (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Specimen-uv-ips'
          description %(
            This test will validate that the Specimen resource returned from the server matches the Specimen (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Specimen', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Specimen-uv-ips')
      end

      test :must_support do
        metadata do
          id '03'
          name 'All must support elements are provided in the Specimen resources returned.'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Specimen-uv-ips'
          optional
          description %(

            This will look through the Specimen resource for the following must support elements:

            * Specimen
            * collection
            * collection.bodySite
            * collection.fastingStatus[x]
            * collection.method
            * subject
            * subject.reference
            * type

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        must_supports = IpsSpecimenuvipsSequenceDefinitions::MUST_SUPPORTS

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
