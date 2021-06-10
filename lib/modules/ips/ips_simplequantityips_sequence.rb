# frozen_string_literal: true

require_relative './profile_definitions/ips_simplequantityips_sequence_definitions'

module Inferno
  module Sequence
    class IpsSimplequantityipsSequence < SequenceBase
      include Inferno::SequenceUtilities
      include Inferno::IpsProfileDefinitions

      title 'SimpleQuantity (IPS) Tests'
      description 'Verify support for the server capabilities required by the SimpleQuantity (IPS) profile.'
      details %(
      )
      test_id_prefix 'SQIPS'
      requires :quantity_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Quantity resource from the Quantity read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/SimpleQuantity-uv-ips'
          description %(
            This test will verify that Quantity resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.quantity_id
        @resource_found = validate_read_reply(FHIR::Quantity.new(id: resource_id), FHIR::Quantity)
        save_resource_references(versioned_resource_class('Quantity'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/SimpleQuantity-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Quantity resource that matches the SimpleQuantity (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/SimpleQuantity-uv-ips'
          description %(
            This test will validate that the Quantity resource returned from the server matches the SimpleQuantity (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Quantity', 'http://hl7.org/fhir/uv/ips/StructureDefinition/SimpleQuantity-uv-ips')
      end

      test :must_support do
        metadata do
          id '03'
          name 'All must support elements are provided in the Quantity resources returned.'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/SimpleQuantity-uv-ips'
          optional
          description %(

            This will look through the Quantity resource for the following must support elements:

            * Quantity
            * code
            * system

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        must_supports = IpsSimplequantityipsSequenceDefinition::MUST_SUPPORTS

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
