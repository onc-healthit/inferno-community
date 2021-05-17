# frozen_string_literal: true

module Inferno
  module Sequence
    module SharedIpsBundleTests
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
        def support_operation(index:, resource_type:, operation_name:, operation_definition:)
          test :support_operation do
            metadata do
              id index
              link operation_definition
              name "IPS Server declares support $#{operation_name} operation in CapabilityStatement"
              description %(
                The IPS Server SHALL declare support #{resource_type}/[id]/$#{operation_name} operation in its server CapabilityStatement
              )
            end

            @client.set_no_auth
            @conformance = @client.conformance_statement
            assert @conformance.present?, 'Cannot read server CapabilityStatement.'

            operation = nil

            @conformance.rest&.each do |rest|
              resource = rest.resource&.find { |r| r.type == resource_type && r.respond_to?(:operation) }

              next if resource.nil?

              # It is better to match with op.definition which is not exist at this time.
              operation = resource.operation&.find { |op| op.definition == operation_definition }
              break if operation.present?
            end

            assert operation.present?, "Server CapabilityStatement did not declare support for $#{operation_name} operation in #{resource_type} resource."
          end
        end

        def resource_validate_bundle(index:)
          test :resource_validate_bundle do
            metadata do
              id index
              name 'Bundle resource returned matches the Bundle (IPS) profile'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Bundle-uv-ips'
              description %(
              This test will validate that the Bundle resource returned from the server matches the Bundle (IPS) profile.
            )
              versions :r4
            end

            skip 'No Bundle resource returned/provided' unless @bundle.present?

            class_name = @bundle.class.name.demodulize
            assert class_name == 'Bundle', "Expected FHIR Bundle but found: #{class_name}"

            errors = test_resource_against_profile(@bundle, IpsBundleuvipsSequenceDefinition::PROFILE_URL)
            assert(errors.empty?, "\n* " + errors.join("\n* "))
          end
        end

        def resource_validate_composition(index:)
          test :validate_composition do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid Composition (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition-Composition-uv-ips.html'
              description %(
                IPS Server return valid Composition (IPS) resource in the Bundle as first entry
              )
            end

            skip 'No bundle returned from previous test' unless @bundle

            assert(@bundle.entry.length.positive?, 'Bundle has empty entry')

            entry = @bundle.entry.first

            assert(entry.resource.instance_of?(FHIR::Composition), 'The first entry in Bundle is not Composition')

            errors = test_resource_against_profile(entry.resource, IpsCompositionuvipsSequenceDefinition::PROFILE_URL)
            errors.map! { |e| "Bundle.#{entry.resource.class.name.demodulize}: #{e}" }
            assert(errors.empty?, "\n* " + errors.join("\n* "))
          end
        end

        def resource_validate_medication_statement(index:)
          test :validate_medication_statement do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid MedicaitonStatement (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition-MedicationStatement-uv-ips.html'
              description %(
                IPS Server return valid MedicaitonStatement (IPS) resource in the Bundle as first entry
              )
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::MedicationStatement, IpsMedicationstatementipsSequenceDefinition::PROFILE_URL)
          end
        end

        def resource_validate_allergy_intolerance(index:)
          test :validate_allergy_intolerance do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid AllergyIntolerance (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition-Condition-uv-ips.html'
              description %(
                IPS Server return valid AllergyIntolerance (IPS) resource in the Bundle as first entry
              )
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::AllergyIntolerance, IpsAllergyintoleranceuvipsSequenceDefinition::PROFILE_URL)
          end
        end

        def resource_validate_condition(index:)
          test :validate_condition do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid Condition (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition-Condition-uv-ips.html'
              description %(
                IPS Server return valid Condition (IPS) resource in the Bundle as first entry
              )
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::Condition, IpsConditionuvipsSequenceDefinition::PROFILE_URL)
          end
        end
      end
    end
  end
end
