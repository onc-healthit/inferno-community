# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsMedicationipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Medication (IPS) Tests'
      description 'Verify support for the server capabilities required by the Medication (IPS) profile.'
      details %(
      )
      test_id_prefix 'MIPS'
      requires :medication_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Medication resource from the Medication read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Medication-uv-ips'
          description %(
            This test will verify that Medication resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.medication_id
        @resource_found = validate_read_reply(FHIR::Medication.new(id: resource_id), FHIR::Medication)
        save_resource_references(versioned_resource_class('Medication'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Medication-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Medication resource that matches the Medication (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Medication-uv-ips'
          description %(
            This test will validate that the Medication resource returned from the server matches the Medication (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Medication', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Medication-uv-ips')
      end

      test :must_support do
        metadata do
          id '03'
          name 'All must support elements are provided in the Medication resources returned.'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Medication-uv-ips'
          optional
          description %(

            This will look through the Medication resource for the following must support elements:

            * Medication
            * Medication.code.coding:atcClass
            * Medication.code.coding:snomed
            * Medication.ingredient.item[x]:itemCodeableConcept
            * code
            * code.coding
            * code.text
            * form
            * ingredient
            * ingredient.strength

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        must_supports = IpsMedicationipsSequenceDefinitions::MUST_SUPPORTS

        missing_slices = must_supports[:slices]
          .select { |slice| slice[:discriminator].present? }
          .reject do |slice|
            slice_found = find_slice(@resource_found, slice[:path], slice[:discriminator])
            slice_found.present?
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

        missing_must_support_elements += missing_slices.map { |slice| slice[:name] }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the provided resource"
        @instance.save!
      end
    end
  end
end
