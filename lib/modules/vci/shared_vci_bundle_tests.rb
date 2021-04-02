# frozen_string_literal: true

module Inferno
  module Sequence
    module SharedVciBundleTests
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      def validate_bundles(is_dm = false)
        bundle_index = 0
        error_collection = []

        appendix = is_dm ? '-dm' : ''

        @verifiable_credentials_bundles.each do |bundle|
          errors = test_resource_against_profile(bundle, "http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-bundle#{appendix}")

          if errors.present?
            errors.map! { |e| "Bundle[#{bundle_index}]: #{e}" }
            error_collection << errors
          end

          immunization_index = 0

          bundle.entry.each do |entry|
            if entry.resource.class.name.demodulize == 'Patient'
              errors = test_resource_against_profile(entry.resource, "http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-patient#{appendix}")

              if errors.present?
                errors.map! { |e| "Bundle[#{bundle_index}].Patient: #{e}" }
                error_collection << errors
              end
            elsif entry.resource.class.name.demodulize == 'Immunization'
              errors = test_resource_against_profile(entry.resource, "http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccine-credential-immunization#{appendix}")

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
