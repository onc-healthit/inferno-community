# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsImmunizationuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Immunization (IPS) Tests'
      description 'Verify support for the server capabilities required by the Immunization (IPS) profile.'
      details %(
      )
      test_id_prefix 'IUI'
      requires :immunization_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Immunization resource from the Immunization read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips'
          description %(
            This test will verify that Immunization resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.immunization_id
        @resource_found = validate_read_reply(FHIR::Immunization.new(id: resource_id), FHIR::Immunization)
        save_resource_references(versioned_resource_class('Immunization'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Immunization resource that matches the Immunization (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips'
          description %(
            This test will validate that the Immunization resource returned from the server matches the Immunization (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Immunization', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips')
      end

      test :must_support do
        metadata do
          id '03'
          name 'All must support elements are provided in the Immunization resources returned.'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips'
          optional
          description %(

            This will look through the Immunization resource for the following must support elements:

            * Immunization
            * Immunization.occurrence[x].extension:data-absent-reason
            * Immunization.protocolApplied.targetDisease:targetDiseaseGPSCode
            * Immunization.vaccineCode.coding:absentOrUnknownImmunization
            * Immunization.vaccineCode.coding:atcClass
            * Immunization.vaccineCode.coding:vaccineGPSCode
            * occurrence[x]
            * patient
            * patient.reference
            * performer
            * performer.actor
            * route
            * site
            * status
            * vaccineCode
            * vaccineCode.coding
            * vaccineCode.text

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        must_supports = IpsImmunizationuvipsSequenceDefinitions::MUST_SUPPORTS

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
