# frozen_string_literal: true

require_relative './profile_definitions/ips_observationtobaccouseuvips_sequence_definitions'

module Inferno
  module Sequence
    class IpsObservationtobaccouseuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities
      include Inferno::IpsProfileDefinitions

      title 'Observation (SH: tobacco use) Tests'
      description 'Verify support for the server capabilities required by the Observation (SH: tobacco use) profile.'
      details %(
      )
      test_id_prefix 'OTUUI'
      requires :observation_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Observation resource from the Observation read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-tobaccouse-uv-ips'
          description %(
            This test will verify that Observation resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.observation_id
        @resource_found = validate_read_reply(FHIR::Observation.new(id: resource_id), FHIR::Observation)
        save_resource_references(versioned_resource_class('Observation'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-tobaccouse-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Observation resource that matches the Observation (SH: tobacco use) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-tobaccouse-uv-ips'
          description %(
            This test will validate that the Observation resource returned from the server matches the Observation (SH: tobacco use) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Observation', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-tobaccouse-uv-ips')
      end

      test :must_support do
        metadata do
          id '03'
          name 'All must support elements are provided in the Observation resources returned.'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-tobaccouse-uv-ips'
          optional
          description %(

            This will look through the Observation resource for the following must support elements:

            * Observation
            * Observation.effective[x].extension
            * Observation.value[x]:valueCodeableConcept
            * code.coding.code
            * effective[x]
            * subject
            * subject.reference

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        must_supports = IpsObservationtobaccouseuvipsSequenceDefinition::MUST_SUPPORTS

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
