# frozen_string_literal: true

require_relative '../health_cards/shared_health_cards_tests'

module Inferno
  module Sequence
    class VciBundleSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Validates VCI FHIR Bundles'

      test_id_prefix 'VCIB'

      requires :file_download_url

      description 'VCI bundle validation '

      details %(
        Validates VCI Bundle
      )

      requires :vci_bundle_json

      attr_accessor :vci_bundle

      def validate_bundle(is_dm)
        appendex = is_dm ? '-dm' : ''
        error_collection = []
        errors = test_resource_against_profile(@vci_bundle, "http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle#{appendex}")

        if errors.present?
          errors.map! { |e| "Bundle: #{e}" }
          error_collection << errors
        end

        immunization_index = 0

        @vci_bundle.entry.each do |entry|
          if entry.resource.class.name.demodulize == 'Patient'
            errors = test_resource_against_profile(entry.resource, "http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-patient#{appendex}")

            if errors.present?
              errors.map! { |e| "Bundle.Patient: #{e}" }
              error_collection << errors
            end
          elsif entry.resource.class.name.demodulize == 'Immunization'
            errors = test_resource_against_profile(entry.resource, "http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-immunization#{appendex}")

            if errors.present?
              errors.map! { |e| "Bundle.Immunization[#{immunization_index}]: #{e}" }
              error_collection << errors
            end

            immunization_index += 1
          end
        end

        assert(error_collection.empty?, "\n* " + error_collection.join("\n* "))
      end

      def test_resource_against_profile(resource, profile_url)
        resource_validation_errors = Inferno::RESOURCE_VALIDATOR.validate(resource, versioned_resource_class, profile_url)

        errors = resource_validation_errors[:errors]

        @test_warnings.concat resource_validation_errors[:warnings]
        @information_messages.concat resource_validation_errors[:information]

        errors
      end

      test :resource_validate_bundle do
        metadata do
          id '01'
          name 'Bundle resource returned matches the Vaccine Credential Bundle profile'
          link 'http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle'
          description %(
            This test will validate that the Bundle resource returned from the server matches the Vaccine Credential Bundle profile.
          )
          versions :r4
        end

        skip 'No resource returned/provided' unless @vci_bundle.present? || @instance.vci_bundle_json.present?

        @vci_bundle = FHIR::Bundle.new(JSON.parse(@instance.vci_bundle_json)) if @vci_bundle.nil?

        validate_bundle(false)
      end

      test :resource_validate_bundle_dm do
        metadata do
          id '02'
          name 'Patient resource in returned Bundle matches the Vaccine Credential Bundle Data Minimization profiles'
          link 'http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle-dm'
          description %(
            This test will validate that the Bundle resource returned from the server matches the Vaccine Credential Bundle Data Minimization profiles.
          )
          versions :r4
          optional
        end

        skip 'No resource returned/provided' unless @vci_bundle.present?

        validate_bundle(true)
      end
    end
  end
end
