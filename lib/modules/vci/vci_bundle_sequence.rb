# frozen_string_literal: true

require_relative '../health_cards/shared_health_cards_tests'

module Inferno
  module Sequence
    class VciBundleSequence < SequenceBase
      include Inferno::SequenceUtilities

      title 'Validates VCI Bundles (FOR DEMO ONLY, REMOVE)'

      test_id_prefix 'VCIB'

      requires :file_download_url

      description 'VCI bundle validation '

      details %(
        Validates VCI Bundle
      )

      requires :vci_bundle_json

      attr_accessor :vci_bundle


      def validate_vci(resource_type, resource, profile_url)
        errors = test_resource_against_profile(@vci_bundle, profile_url)

        errors.map! { |e| "#{resource_type}: #{e}" }

        assert(errors.empty?, "\n* " + errors.join("\n* "))
      end

      def validate_vci_dm(resource_type, profile_url)
        entry_index = 0
        error_collection = []

        @vci_bundle.entry.each do |entry|
          next unless entry.resource.class.name.demodulize == resource_type

          errors = test_resource_against_profile(entry.resource, profile_url)

          if errors.present?
            # TODO: use entry.fullUrl or index?
            errors.map! { |e| "#{resource_type}/#{entry.fullUrl}: #{e}" }
            error_collection << errors if errors.present?
          end

          entry_index += 1
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

        skip 'No resource returned/provided' unless @vci_bundle.present? || @instance.vci_bundle_json.present?

        @vci_bundle = FHIR::Bundle.new(JSON.parse(@instance.vci_bundle_json)) if @vci_bundle.nil?

        validate_vci('Bundle', @vci_bundle, 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle')

      end

      test :resource_validate_patient do
        metadata do
          id '02'
          name 'Patient resource in returned Bundle matches the Vaccine Credential Patient Allowable Data profiles'
          link 'http://build.fhir.org/ig/dvci/vaccine-credential-ig/branches/main/StructureDefinition-vaccine-credential-patient'
          description %(
            This test will validate that the Patient resource in returned Bundle from the server matches the Vaccine Credential Patient Allowable Data profiles.
          )
          versions :r4
        end
        # FHIR Validator has a bug which could not return correct error message when the Patient resource is not correct in a Bundle.
        # We add this test sequence to

        skip 'No resource returned/provided' unless @vci_bundle.present?

        resource_type = 'Patient'

        entry = @vci_bundle.entry.select { |entry| entry.resource.class.name.demodulize == resource_type}.first

        if (entry.present?)
          validate_vci(resource_type, entry.resource, 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-patient')
        else
          assert false, 'VCI Bundle does NOT have VCI Patient entry'
        end
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

        skip 'No resource returned/provided' unless @vci_bundle.present?

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

        skip 'No resource returned/provided' unless @vci_bundle.present?

        validate_vci_dm('Immunization', 'http://hl7.org/fhir/us/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-immunization-dm')
      end
    end
  end
end
