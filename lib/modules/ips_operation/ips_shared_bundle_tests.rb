# frozen_string_literal: true

module Inferno
  module Sequence
    module SharedVciBundleTests
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      def validate_bundle_entry(resource_type, profile_url)
        index = 0
        error_collection = []

        @bundle.entry.each do |entry|
          next unless entry.resource.instance_of?(resource_type)

          errors = test_resource_against_profile(entry.resource, profile_url)
          error_collection << errors.map! { |err| "Bundle.#{entry.resource.class.name.demodulize}[#{index}]: #{err}" } unless errors.empty?
          index += 1
        end

        assert(index.positive?, "Bundle does NOT have any #{resource_type.name.demodulize} entries")
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


    end
  end
end