# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsRangeipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Range (IPS) Tests'
      description 'Verify support for the server capabilities required by the Range (IPS) profile.'
      details %(
      )
      test_id_prefix 'RIPS'
      requires :range_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Range resource from the Range read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Range-uv-ips'
          description %(
            This test will verify that Range resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.range_id
        @resource_found = validate_read_reply(FHIR::Range.new(id: resource_id), FHIR::Range)
        save_resource_references(versioned_resource_class('Range'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Range-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Range resource that matches the Range (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Range-uv-ips'
          description %(
            This test will validate that the Range resource returned from the server matches the Range (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Range', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Range-uv-ips')
      end

      test :must_support do
        metadata do
          id '03'
          name 'All must support elements are provided in the Range resources returned.'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Range-uv-ips'
          optional
          description %(

            This will look through the Range resource for the following must support elements:

            * Range
            * high
            * low

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        must_supports = IpsRangeipsSequenceDefinitions::MUST_SUPPORTS

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
