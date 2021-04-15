# frozen_string_literal: true

module Inferno
  module Sequence
    module SharedVciBundleTests
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      def vci_bundle_profile_url
        'http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccination-credential-bundle'
      end

      def vci_patient_profile_url
        'http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccination-credential-patient'
      end

      def vci_immunization_profile_url
        'http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccination-credential-immunization'
      end

      def vci_observation_profile_url
        'http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccination-credential-observation'
      end

      def validate_bundles(is_dm = false)
        bundle_index = 0
        error_collection = []

        appendix = is_dm ? '-dm' : ''

        @verifiable_credentials_bundles.each do |bundle|
          errors = test_resource_against_profile(bundle, vci_bundle_profile_url + appendix)

          if errors.present?
            errors.map! { |e| "Bundle[#{bundle_index}]: #{e}" }
            error_collection << errors
          end

          immunization_index = 0
          observation_index = 0

          bundle.entry.each do |entry|
            msg_prefix = "Bundle[#{bundle_index}].#{entry.resource.class.name.demodulize}"
            if entry.resource.class == FHIR::Patient
              errors = test_resource_against_profile(entry.resource, vci_patient_profile_url + appendix)

              if errors.present?
                errors.map! { |e| "#{msg_prefix}: #{e}" }
                error_collection << errors
              end
            elsif entry.resource.class == FHIR::Immunization
              errors = test_resource_against_profile(entry.resource, vci_immunization_profile_url + appendix)

              if errors.present?
                errors.map! { |e| "#{msg_prefix}[#{immunization_index}]: #{e}" }
                error_collection << errors
              end
              immunization_index += 1
            elsif entry.resource.class == FHIR::Observation
              errors = test_resource_against_profile(entry.resource, vci_observation_profile_url + appendix)

              if errors.present?
                errors.map! { |e| "#{msg_prefix}[#{observation_index}]: #{e}" }
                error_collection << errors
              end
              observation_index += 1
            end
          end

          bundle_index += 1
        end

        assert(error_collection.empty?, "\n* " + error_collection.join("\n* "))
      end

      def test_resource_against_profile(resource, profile_url)
        resource_validation_errors = Inferno::RESOURCE_VALIDATOR.validate(resource, versioned_resource_class, profile_url)

        errors = parse_resource_validation_errors(resource_validation_errors[:errors], resource)

        @test_warnings.concat resource_validation_errors[:warnings]
        @information_messages.concat resource_validation_errors[:information]

        errors
      end

      def parse_resource_validation_errors(resource_validation_errors, resource)
        return resource_validation_errors if resource.class.name.demodulize != 'Bundle'

        errors = []
        resource_validation_errors.each do |error|
          if error.match(/Bundle.entry:vaccineCredentialPatient: minimum required = 1, but only found 0/) &&
             resource.entry.any? { |e| e.resource.class == FHIR::Patient }
            next
          elsif error.match(/Bundle.entry:vaccineCredentialImmunization: minimum required = 1, but only found 0/) &&
                resource.entry.any? { |e| e.resource.class == FHIR::Immunization }
            next
          end

          errors << error
        end

        errors
      end

      # def convert_to_uuid(full_url)
      #   if full_url.blank? || !full_url.start_with?('resource:')
      #     return full_url
      #   end

      #   id = full_url[9..-1] # skip 'resource:'
      #   id.gsub!(/[^A-Za-z0-9]/, '') #remove any non alphanumeric characters
      #   id.downcase!

      #   "urn:uuid:#{id}"
      # end

      module ClassMethods
        def resource_validate_bundle(index:)
          test :resource_validate_bundle do
            metadata do
              id index
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
        end

        def resource_validate_bundle_dm(index:)
          test :resource_validate_bundle_dm do
            metadata do
              id index
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
  end
end
