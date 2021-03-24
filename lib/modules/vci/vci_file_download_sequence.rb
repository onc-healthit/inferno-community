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

      def validate_bundles
        bundle_index = 0
        error_collection = []

        @verifiable_credentials_bundles.each do |bundle|
          errors = test_resource_against_profile(bundle, 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle')

          if errors.present?
            errors.map! { |e| "Bundle[#{bundle_index}]: #{e}" }
            error_collection << errors
          end

          bundle_index += 1
        end

        assert(error_collection.empty?, "\n* " + error_collection.join("\n* "))
      end

      def validate_vci_dm(resource_type, profile_url)
        bundle_index = 0
        entry_index = 0
        error_collection = []

        @verifiable_credentials_bundles.each do |bundle|
          bundle.entry.each do |entry|
            next unless entry.resource.class.name.demodulize == resource_type

            errors = test_resource_against_profile(entry.resource, profile_url)

            if errors.present?
              errors.map! { |e| "Bundle[#{index}]/#{resource_type}/#{entry.fullUrl}: #{e}" }
              error_collection << errors if errors.present?
            end

            entry_index += 1
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
          link 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle'
          description %(
            This test will validate that the Bundle resource returned from the server matches the Vaccine Credential Bundle profile.
          )
          versions :r4
        end

        skip 'No resource returned/provided' unless @verifiable_credentials_bundles.present?

        validate_bundles
      end

      test :resource_validate_patient_dm do
        metadata do
          id '03'
          name 'Patient resource in returned Bundle matches the Vaccine Credential Patient Data Minimization profiles'
          link 'http://build.fhir.org/ig/dvci/vaccine-credential-ig/branches/main/StructureDefinition-vaccine-credential-patient-dm'
          description %(
            This test will validate that the Patient resource in returned Bundle from the server matches the Vaccine Credential Patient Data Minimization profiles.
          )
          versions :r4
          optional
        end

        skip 'No resource returned/provided' unless @verifiable_credentials_bundles.present?

        validate_vci_dm('Patient', 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-patient-dm')
      end

      test :resource_validate_immunization_dm do
        metadata do
          id '04'
          name 'Immunization resources in returned Bundle matches the Vaccine Credential Immunization Data Minimization profiles'
          link 'http://build.fhir.org/ig/dvci/vaccine-credential-ig/branches/main/StructureDefinition-vaccine-credential-immunization-dm'
          description %(
            This test will validate that the Patient resource in returned Bundle from the server matches the Vaccine Credential Immunization Data Minimizationprofile.
          )
          versions :r4
          optional
        end

        skip 'No resource returned/provided' unless @verifiable_credentials_bundles.present?

        validate_vci_dm('Immunization', 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-immunization-dm')
      end
    end
  end
end
