# frozen_string_literal: true

require_relative './profile_definitions/ips_codingips_sequence_definitions'

module Inferno
  module Sequence
    class IpsCodingipsSequence < SequenceBase
      include Inferno::SequenceUtilities
      include Inferno::IpsProfileDefinitions

      title 'Coding with translations Tests'
      description 'Verify support for the server capabilities required by the Coding with translations profile.'
      details %(
      )
      test_id_prefix 'CIPS'
      requires :coding_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Coding resource from the Coding read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Coding-uv-ips'
          description %(
            This test will verify that Coding resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.coding_id
        @resource_found = validate_read_reply(FHIR::Coding.new(id: resource_id), FHIR::Coding)
        save_resource_references(versioned_resource_class('Coding'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Coding-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Coding resource that matches the Coding with translations profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Coding-uv-ips'
          description %(
            This test will validate that the Coding resource returned from the server matches the Coding with translations profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Coding', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Coding-uv-ips')
      end

      test :must_support do
        metadata do
          id '03'
          name 'All must support elements are provided in the Coding resources returned.'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Coding-uv-ips'
          optional
          description %(

            This will look through the Coding resource for the following must support elements:

            * Coding
            * Coding.display.extension:translation
            * code
            * display
            * system
            * version

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        must_supports = IpsCodingipsSequenceDefinition::MUST_SUPPORTS

        missing_must_support_extensions = must_supports[:extensions].reject do |must_support_extension|
          @resource_found.extension.any? { |extension| extension.url == must_support_extension[:url] }
        end

        missing_must_support_elements = must_supports[:elements].reject do |element|
          value_found = resolve_element_from_path(@resource_found, element[:path]) do |value|
            value_without_extensions = value.respond_to?(:to_hash) ? value.to_hash.reject { |key, _| key == 'extension' } : value
            (value_without_extensions.present? || value_without_extensions == false) && (element[:fixed_value].blank? || value == element[:fixed_value])
          end

          # Note that false.present? => false, which is why we need to add this extra check
          value_found.present? || value_found == false
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        missing_must_support_elements += missing_must_support_extensions.map { |must_support| must_support[:id] }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the provided resource"
        @instance.save!
      end
    end
  end
end
