# frozen_string_literal: true

require_relative '../health_cards/shared_health_cards_tests'

module Inferno
  module Sequence
    class VciFileDownloadSequence < HealthCardsFileDownloadSequence
      extends_sequence HealthCardsFileDownloadSequence
      title 'Validates File Download against VCI profiles'

      test_id_prefix 'VCIFD'

      requires :file_download_url

      description 'VCI file download validation '

      details %(
        Validates jws content
      )

      def validate_bundles(is_dm = false)
        bundle_index = 0
        error_collection = []

        appendex = is_dm ? '-dm' : ''

        @verifiable_credentials_bundles.each do |bundle|
          errors = test_resource_against_profile(bundle, "http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle#{appendex}")

          if errors.present?
            errors.map! { |e| "Bundle[#{bundle_index}]: #{e}" }
            error_collection << errors
          end

          immunization_index = 0

          bundle.entry.each do |entry|
            if entry.resource.class.name.demodulize == 'Patient'
              errors = test_resource_against_profile(entry.resource, "http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-patient#{appendex}")

              if errors.present?
                errors.map! { |e| "Bundle[#{bundle_index}].Patient: #{e}" }
                error_collection << errors
              end
            elsif entry.resource.class.name.demodulize == 'Immunization'
              errors = test_resource_against_profile(entry.resource, "http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-immunization#{appendex}")

              if errors.present?
                errors.map! { |e| "Bundle[#{bundle_index}].Immunization[#{immunization_index}]: #{e}" }
                error_collection << errors
              end

              immunization_index += 1
            end
          end

          bundle_index += 1
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

        skip 'No resource returned/provided' unless @verifiable_credentials_bundles.present?

        validate_bundles(false)
      end

      
      test :resource_validate_bundle_dm do
        metadata do
          id '02'
          name 'Bundle resource returned matches the Vaccine Credential Bundle Data Minimization profile'
          link 'http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle-dm'
          description %(
            This test will validate that the Bundle resource returned from the server matches the Vaccine Credential Bundle Data Minimization  profile.
          )
          versions :r4
          optional
        end

        skip 'No resource returned/provided' unless @verifiable_credentials_bundles.present?

        validate_bundles(true)
      end
    end
  end
end
