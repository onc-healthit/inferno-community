# frozen_string_literal: true

module Inferno
  module Sequence
    class IpsDeviceusestatementuvipsSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Device Use Statement (IPS) Tests'
      description 'Verify support for the server capabilities required by the Device Use Statement (IPS) profile.'
      details %(
      )
      test_id_prefix 'DUSUI'
      requires :device_use_statement_id

      @resource_found = nil

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct DeviceUseStatement resource from the DeviceUseStatement read interaction'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips'
          description %(
            This test will verify that DeviceUseStatement resources can be read from the server.
          )
          versions :r4
        end

        resource_id = @instance.device_use_statement_id
        @resource_found = validate_read_reply(FHIR::DeviceUseStatement.new(id: resource_id), FHIR::DeviceUseStatement)
        save_resource_references(versioned_resource_class('DeviceUseStatement'), [@resource_found], 'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips')
      end

      test :resource_validate_profile do
        metadata do
          id '02'
          name 'Server returns DeviceUseStatement resource that matches the Device Use Statement (IPS) profile'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips'
          description %(
            This test will validate that the DeviceUseStatement resource returned from the server matches the Device Use Statement (IPS) profile.
          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        test_resources_against_profile('DeviceUseStatement', 'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips')
      end

      test :must_support do
        metadata do
          id '03'
          name 'All must support elements are provided in the DeviceUseStatement resources returned.'
          link 'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips'
          optional
          description %(

            This will look through the DeviceUseStatement resource for the following must support elements:

            * DeviceUseStatement
            * DeviceUseStatement.timing[x].extension:data-absent-reason
            * bodySite
            * device
            * source
            * subject
            * subject.reference
            * timing[x]

          )
          versions :r4
        end

        skip 'No resource found from Read test' unless @resource_found.present?
        must_supports = IpsDeviceusestatementuvipsSequenceDefinitions::MUST_SUPPORTS

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
