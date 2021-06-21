# frozen_string_literal: true

require_relative './profile_definitions/ips_medicationstatementips_sequence_definitions'

module Inferno
  module Sequence
    class IpsMedicationstatementipsSequence < SequenceBase
      include Inferno::SequenceUtilities
      include Inferno::IpsProfileDefinitions

      title 'Medication Statement (IPS) Tests'
      description 'Verify support for the server capabilities required by the Medication Statement (IPS) profile.'
      details %(
      )
      test_id_prefix 'MSIPS'
      requires :medication_statement_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct MedicationStatement resource from the MedicationStatement read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips'
          description %(
            This test will verify that MedicationStatement resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.medication_statement_id
        @resource_found = validate_read_reply(FHIR::MedicationStatement.new(id: resource_id), FHIR::MedicationStatement)
        save_resource_references(versioned_resource_class('MedicationStatement'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns MedicationStatement resource that matches the Medication Statement (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips'
          description %(
            This test will validate that the MedicationStatement resource returned from the server matches the Medication Statement (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('MedicationStatement', 'http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips')
      end

      test :must_support do
        metadata do
          id '03'
          name 'All must support elements are provided in the MedicationStatement resources returned.'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips'
          optional
          description %(

            This will look through the MedicationStatement resource for the following must support elements:

            * MedicationStatement
            * MedicationStatement.effective[x].extension
            * MedicationStatement.medication[x]:medicationCodeableConcept
            * MedicationStatement.medication[x]:medicationCodeableConcept.coding:absentOrUnknownProblem
            * MedicationStatement.medication[x]:medicationReference
            * dosage
            * dosage.route
            * dosage.text
            * dosage.timing
            * effective[x]
            * informationSource
            * medication[x]
            * medication[x].coding
            * medication[x].text
            * status
            * subject
            * subject.reference

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        must_supports = IpsMedicationstatementipsSequenceDefinition::MUST_SUPPORTS

        missing_must_support_extensions = must_supports[:extensions].reject do |must_support_extension|
          @resource_found.extension.any? { |extension| extension.url == must_support_extension[:url] }
        end

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

        missing_must_support_elements += missing_must_support_extensions.map { |must_support| must_support[:id] }

        missing_must_support_elements += missing_slices.map { |slice| slice[:name] }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the provided resource"
        @instance.save!
      end
    end
  end
end
