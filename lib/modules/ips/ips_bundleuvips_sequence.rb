# frozen_string_literal: true

require_relative './profile_definitions/ips_bundleuvips_sequence_definitions'

module Inferno
  module Sequence
    class IpsBundleuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities
      include Inferno::IpsProfileDefinitions

      title 'Bundle (IPS) Tests'
      description 'Verify support for the server capabilities required by the Bundle (IPS) profile.'
      details %(
      )
      test_id_prefix 'BUI'
      requires :bundle_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Bundle resource from the Bundle read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Bundle-uv-ips'
          description %(
            This test will verify that Bundle resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.bundle_id
        @resource_found = validate_read_reply(FHIR::Bundle.new(id: resource_id), FHIR::Bundle)
        save_resource_references(versioned_resource_class('Bundle'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/Bundle-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns Bundle resource that matches the Bundle (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Bundle-uv-ips'
          description %(
            This test will validate that the Bundle resource returned from the server matches the Bundle (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('Bundle', 'http://hl7.org/fhir/uv/ips/StructureDefinition/Bundle-uv-ips')
      end

      test :must_support do
        metadata do
          id '03'
          name 'All must support elements are provided in the Bundle resources returned.'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Bundle-uv-ips'
          optional
          description %(

            This will look through the Bundle resource for the following must support elements:

            * Bundle
            * Bundle.entry:allergy
            * Bundle.entry:composition
            * Bundle.entry:medication
            * Bundle.entry:problem
            * entry
            * entry.fullUrl
            * entry.resource
            * identifier
            * timestamp

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        must_supports = IpsBundleuvipsSequenceDefinition::MUST_SUPPORTS

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
