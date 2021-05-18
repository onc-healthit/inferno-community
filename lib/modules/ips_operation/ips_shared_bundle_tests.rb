# frozen_string_literal: true

Dir['lib/modules/ips/profile_definitions/*'].sort.each { |file| require './' + file }

module Inferno
  module Sequence
    module SharedIpsBundleTests
      # include IpsProfileDefinitions

      # def profile_definitions
      #   {
      #     AllergyIntolerance.name.demodulize => [
      #       IpsAllergyintoleranceuvipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::Condition.name.demodulize => [
      #       IpsConditionuvipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::Device.name.demodulize => [
      #       IpsDeviceobserveruvipsSequenceDefinition::PROFILE_URL,
      #       IpsDeviceuvipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::DeviceUseStatement.name.demodulize => [
      #       IpsDeviceusestatementuvipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::DiagnosticReport.name.demodulize => [
      #       IpsDiagnosticreportuvipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::ImagingStudy.name.demodulize => [
      #       IpsImagingstudyuvipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::Immunization.name.demodulize => [
      #       IpsImmunizationuvipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::Media.name.demodulize => [
      #       IpsMediaobservationuvipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::Medication.name.demodulize => [
      #       IpsMedicationipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::MedicationStatement.name.demodulize => [
      #       IpsMedicationstatementipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::Observation.name.demodulize => [
      #       IpsObservationalcoholuseuvipsSequenceDefinition::PROFILE_URL,
      #       IpsObservationpregnancyedduvipsSequenceDefinition::PROFILE_URL,
      #       IpsObservationpregnancyoutcomeuvipsSequenceDefinition::PROFILE_URL,
      #       IpsObservationpregnancystatusuvipsSequenceDefinition::PROFILE_URL,
      #       IpsObservationresultslaboratoryuvipsSequenceDefinition::PROFILE_URL,
      #       IpsObservationresultspathologyuvipsSequenceDefinition::PROFILE_URL,
      #       IpsObservationresultsradiologyuvipsSequenceDefinition::PROFILE_URL,
      #       IpsObservationresultsuvipsSequenceDefinition::PROFILE_URL,
      #       IpsObservationtobaccouseuvipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::Organization.name.demodulize => [
      #       IpsOrganizationuvipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::Patient.name.demodulize => [
      #       IpsPatientuvipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::Practitioner.name.demodulize => [
      #       IpsPractitionerroleuvipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::PractitionerRole.name.demodulize => [
      #       IpsPractitioneruvipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::Procedure.name.demodulize => [
      #       IpsProcedureuvipsSequenceDefinition::PROFILE_URL
      #     ],
      #     FHIR::Specimen.name.demodulize => [
      #       IpsSpecimenuvipsSequenceDefinition.PROFILE_URL
      #     ]
      #   }
      # end

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      # def validate_bundle_entries
      #   @bundle.entry.each do |entry|
      #     profiles = profile_definitions[entry.resource.class.name.demodulize]
      #     next if profiles.nil? ||profiles.empty

      #   end
      # end

      def validate_bundle_entry(resource_type, profile_urls)
        index = 0
        error_collection = []
        @valid_entry ||= []

        @bundle.entry.each do |entry|
          next unless entry.resource.instance_of?(resource_type)

          errors = []

          profile_urls.each do |p|
            errors = test_resource_against_profile(entry.resource, p)

            next unless errors.empty?

            @valid_entry << {
              resource_type: resource_type.name.demodulize,
              profile: p,
              resource_id: entry.resource.id
            }
            break
          end

          error_collection << errors.map! { |err| "Bundle.#{entry.resource.class.name.demodulize}[#{index}]: #{err}" } if profile_urls.length == 1 && !errors.empty?

          index += 1
        end

        assert(index.positive?, "Bundle does NOT have any #{resource_type.name.demodulize} entries")
        assert(error_collection.empty?, "\n* " + error_collection.join("\n* "))
      end

      def process_bundle_missing_entry_error(errors)
        parsed_errors = []

        errors.each do |error|
          if error.match(/Bundle.entry:composition: minimum required = 1, but only found 0/) &&
             @bundle.entry.any? { |entry| entry.resource.instance_of?(FHIR::Composition) }
            next
          elsif error.match(/Bundle.entry:problem: minimum required = 1, but only found 0/) &&
                @bundle.entry.any? { |entry| entry.resource.instance_of?(FHIR::Condition) }
            next
          elsif error.match(/Bundle.entry:allergy: minimum required = 1, but only found 0/) &&
                @bundle.entry.any? { |entry| entry.resource.instance_of?(FHIR::AllergyIntolerance) }
            next
          elsif error.match(/Bundle.entry:medication: minimum required = 1, but only found 0/) &&
                @bundle.entry.any? { |entry| entry.resource.instance_of?(FHIR::MedicationStatement) }
            next
          else
            parsed_errors << error
          end

          # parsed_errors = errors.reject { |e| e.match(/Bundle.entry:[\w]+: minimum required = 1, but only found 0/)
        end

        parsed_errors
      end

      def process_composition_missing_section_error(errors)
        # skip the missing entry error
        # keep the missing section error which has regex: /Composition.section:section[\w]+: minimum required = 1, but only found 0/
        parsed_errors = errors.reject { |e| e.match(/Composition.section:section[\w]+.entry:[\w]+: minimum required = 1, but only found 0/) }
        parsed_errors
      end

      def test_resource_against_profile(resource, profile_url)
        resource_validation_errors = Inferno::RESOURCE_VALIDATOR.validate(resource, versioned_resource_class, profile_url)

        errors = resource_validation_errors[:errors]

        @test_warnings.concat resource_validation_errors[:warnings]
        @information_messages.concat resource_validation_errors[:information]

        errors
      end

      module ClassMethods
        include IpsProfileDefinitions

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

            errors = test_resource_against_profile(@bundle, [IpsBundleuvipsSequenceDefinition::PROFILE_URL])
            assert(errors.empty?, "\n* " + errors.join("\n* "))
          end
        end

        def resource_validate_composition(index:)
          test :validate_composition do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid Composition (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips'
              description %(
                IPS Server return valid Composition (IPS) resource in the Bundle as first entry
              )
            end

            skip 'No bundle returned from previous test' unless @bundle

            assert(@bundle.entry.length.positive?, 'Bundle has empty entry')

            entry = @bundle.entry.first

            assert(entry.resource.instance_of?(FHIR::Composition), 'The first entry in Bundle is not Composition')

            errors = test_resource_against_profile(entry.resource, [IpsCompositionuvipsSequenceDefinition::PROFILE_URL])

            errors = process_composition_missing_section_error(errors)

            errors.map! { |e| "Bundle.#{entry.resource.class.name.demodulize}: #{e}" }
            assert(errors.empty?, "\n* " + errors.join("\n* "))
          end
        end

        def resource_validate_medication_statement(index:)
          test :validate_medication_statement do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid MedicaitonStatement (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips'
              description %(
                IPS Server return valid MedicaitonStatement (IPS) resource in the Bundle
              )
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::MedicationStatement, [IpsMedicationstatementipsSequenceDefinition::PROFILE_URL])
          end
        end

        def resource_validate_allergy_intolerance(index:)
          test :validate_allergy_intolerance do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid Allergy Intolerance (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/AllergyIntolerance-uv-ips'
              description %(
                IPS Server return valid Allergy Intolerance (IPS) resource in the Bundle
              )
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::AllergyIntolerance, [IpsAllergyintoleranceuvipsSequenceDefinition::PROFILE_URL])
          end
        end

        def resource_validate_condition(index:)
          test :validate_condition do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid Condition (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips'
              description %(
                IPS Server return valid Condition (IPS) resource in the Bundle
              )
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::Condition, [IpsConditionuvipsSequenceDefinition::PROFILE_URL])
          end
        end

        def resource_validate_device(index:)
          test :validate_device do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid Device entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Device-uv-ips'
              description %(
                IPS Server return valid Device resource in the Bundle matching one of these profiles:

                * Device (IPS)
                * Device (performer, observer)
              )
              optional
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::Device,
                                  [
                                    IpsDeviceuvipsSequenceDefinition::PROFILE_URL,
                                    IpsDeviceobserveruvipsSequenceDefinition::PROFILE_URL
                                  ])
          end
        end

        def resource_validate_device_use_statement(index:)
          test :validate_device_use_statement do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid Device Use Statement (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips'
              description %(
                IPS Server return valid Device Use Statement (IPS) resource in the Bundle
              )
              optional
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::DeviceUseStatement, [IpsDeviceusestatementuvipsSequenceDefinition::PROFILE_URL])
          end
        end

        def resource_validate_diagnostic_report(index:)
          test :validate_diagnostic_report do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid Diagnostic Report (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/DiagnosticReport-uv-ips'
              description %(
                IPS Server return valid Diagnostic Report (IPS) resource in the Bundle
              )
              optional
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::DiagnosticReport, [IpsDiagnosticreportuvipsSequenceDefinition::PROFILE_URL])
          end
        end

        def resource_validate_immunization(index:)
          test :validate_immunization do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid Immunization (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips'
              description %(
                IPS Server return valid Immunization (IPS) resource in the Bundle
              )
              optional
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::Immunization, [IpsImmunizationuvipsSequenceDefinition::PROFILE_URL])
          end
        end

        def resource_validate_medication(index:)
          test :validate_medication do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid Medication (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Medication-uv-ips'
              description %(
                IPS Server return valid Medication (IPS) resource in the Bundle
              )
              optional
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::Medication, [IpsMedicationipsSequenceDefinition::PROFILE_URL])
          end
        end

        def resource_validate_observation(index:)
          test :validate_observation do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid Observation entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-uv-ips'
              description %(
                IPS Server return valid Observation resource in the Bundle matching one of these profiles:

                * Observation (Pregnancy: EDD)
                * Observation (Pregnancy: outcome)
                * Observation (Pregnancy: status)
                * Observation (SH: alcohol use)
                * Observation (SH: tobacco use)
                * Observation Results (IPS)
                * Observation Results: laboratory (IPS)
                * Observation Results: pathology (IPS)
                * Observation Results: radiology (IPS)
              )
              optional
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::Observation,
                                  [
                                    IpsObservationalcoholuseuvipsSequenceDefinition::PROFILE_URL,
                                    IpsObservationpregnancyedduvipsSequenceDefinition::PROFILE_URL,
                                    IpsObservationpregnancyoutcomeuvipsSequenceDefinition::PROFILE_URL,
                                    IpsObservationpregnancystatusuvipsSequenceDefinition::PROFILE_URL,
                                    IpsObservationresultslaboratoryuvipsSequenceDefinition::PROFILE_URL,
                                    IpsObservationresultspathologyuvipsSequenceDefinition::PROFILE_URL,
                                    IpsObservationresultsradiologyuvipsSequenceDefinition::PROFILE_URL,
                                    IpsObservationresultsuvipsSequenceDefinition::PROFILE_URL,
                                    IpsObservationtobaccouseuvipsSequenceDefinition::PROFILE_URL
                                  ])
          end
        end

        def resource_validate_organization(index:)
          test :validate_organization do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid Organization (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Organization-uv-ips'
              description %(
                IPS Server return valid Organization (IPS) resource in the Bundle
              )
              optional
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::Organization, [IpsOrganizationuvipsSequenceDefinition::PROFILE_URL])
          end
        end

        def resource_validate_patient(index:)
          test :validate_patient do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid Patient (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Patient-uv-ips'
              description %(
                IPS Server return valid Patient (IPS) resource in the Bundle
              )
              optional
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::Patient, [IpsPatientuvipsSequenceDefinition::PROFILE_URL])
          end
        end

        def resource_validate_practitioner(index:)
          test :validate_practitioner do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid Practitioner (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Practitioner-uv-ips'
              description %(
                IPS Server return valid Practitioner (IPS) resource in the Bundle
              )
              optional
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::Practitioner, [IpsPractitioneruvipsSequenceDefinition::PROFILE_URL])
          end
        end

        def resource_validate_practitioner_role(index:)
          test :validate_practitioner_role do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid PractitionerRole (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/PractitionerRole-uv-ips'
              description %(
                IPS Server return valid PractitionerRole (IPS) resource in the Bundle
              )
              optional
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::PractitionerRole, [IpsPractitionerroleuvipsSequenceDefinition::PROFILE_URL])
          end
        end

        def resource_validate_procedure(index:)
          test :validate_procedure do
            metadata do
              id index
              name 'IPS Server returns Bundle resource contains valid Procedure (IPS) entry'
              link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Procedure-uv-ips'
              description %(
                IPS Server return valid Procedure (IPS) resource in the Bundle
              )
              optional
            end

            skip 'No bundle returned from previous test' unless @bundle

            validate_bundle_entry(FHIR::Procedure, [IpsProcedureuvipsSequenceDefinition::PROFILE_URL])
          end
        end
      end
    end
  end
end
