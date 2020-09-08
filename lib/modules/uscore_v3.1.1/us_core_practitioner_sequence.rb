# frozen_string_literal: true

require_relative './data_absent_reason_checker'
require_relative './profile_definitions/us_core_practitioner_definitions'

module Inferno
  module Sequence
    class USCore311PractitionerSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker
      include Inferno::USCore310ProfileDefinitions

      title 'Practitioner Tests'

      description 'Verify support for the server capabilities required by the US Core Practitioner Profile.'

      details %(
        # Background

        The US Core #{title} sequence verifies that the system under test is able to provide correct responses
        for Practitioner queries.  These queries must contain resources conforming to US Core Practitioner Profile as specified
        in the US Core v3.1.0 Implementation Guide.

        # Testing Methodology


        Because Practitioner resources are not present or do not exist in USCDI, no searches are performed on this test sequence. Instead, references to
        this profile found in other resources are used for testing. If no references can be found this way, then all the tests
        in this sequence are skipped.


        ## Must Support
        Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
        at least once. If at least one cannot be found, the test will fail. The test will look through the Practitioner
        resources found for these elements.

        ## Profile Validation
        Each resource returned from the first search is expected to conform to the [US Core Practitioner Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner).
        Each element is checked against teminology binding and cardinality requirements.

        Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
        of the valueset, then the test will fail.

        ## Reference Validation
        Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
        and will fail if any attempted read fails.
      )

      test_id_prefix 'USCPR'

      requires :token
      conformance_supports :Practitioner
      delayed_sequence

      def validate_resource_item(resource, property, value)
        case property

        when 'name'
          values_found = resolve_path(resource, 'name')
          value_downcase = value.downcase
          match_found = values_found.any? do |name|
            name&.text&.downcase&.start_with?(value_downcase) ||
              name&.family&.downcase&.include?(value_downcase) ||
              name&.given&.any? { |given| given.downcase.start_with?(value_downcase) } ||
              name&.prefix&.any? { |prefix| prefix.downcase.start_with?(value_downcase) } ||
              name&.suffix&.any? { |suffix| suffix.downcase.start_with?(value_downcase) }
          end
          assert match_found, "name in Practitioner/#{resource.id} (#{values_found}) does not match name requested (#{value})"

        when 'identifier'
          values_found = resolve_path(resource, 'identifier')
          identifier_system = value.split('|').first.empty? ? nil : value.split('|').first
          identifier_value = value.split('|').last
          match_found = values_found.any? do |identifier|
            identifier.value == identifier_value && (!value.include?('|') || identifier.system == identifier_system)
          end
          assert match_found, "identifier in Practitioner/#{resource.id} (#{values_found}) does not match identifier requested (#{value})"

        end
      end

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

      @resources_found = false

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Practitioner resource from the Practitioner read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            This test will attempt to Reference to Practitioner can be resolved and read.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Practitioner, [:read])

        practitioner_references = @instance.resource_references.select { |reference| reference.resource_type == 'Practitioner' }
        skip 'No Practitioner references found from the prior searches' if practitioner_references.blank?

        @practitioner_ary = practitioner_references.map do |reference|
          validate_read_reply(
            FHIR::Practitioner.new(id: reference.resource_id),
            FHIR::Practitioner,
            check_for_data_absent_reasons
          )
        end
        @practitioner = @practitioner_ary.first
        @resources_found = @practitioner.present?
      end

      test :validate_resources do
        metadata do
          id '02'
          name 'Practitioner resources returned from previous search conform to the US Core Practitioner Profile.'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner'
          description %(

            This test verifies resources returned from the first search conform to the [US Core Practitioner Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner).
            It verifies the presence of mandatory elements and that elements with required bindings contain appropriate values.
            CodeableConcept element bindings will fail if none of its codings have a code/system that is part of the bound ValueSet.
            Quantity, Coding, and code element bindings will fail if its code/system is not found in the valueset.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Practitioner', delayed: true)
        test_resources_against_profile('Practitioner')
      end

      test 'All must support elements are provided in the Practitioner resources returned.' do
        metadata do
          id '03'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through the Practitioner resources found previously for the following must support elements:

            * identifier
            * identifier.system
            * identifier.value
            * name
            * name.family
            * Practitioner.identifier:NPI
          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Practitioner', delayed: true)
        must_supports = USCore311PractitionerSequenceDefinitions::MUST_SUPPORTS

        missing_slices = must_supports[:slices].reject do |slice|
          @practitioner_ary&.any? do |resource|
            slice_found = find_slice(resource, slice[:path], slice[:discriminator])
            slice_found.present?
          end
        end

        missing_must_support_elements = must_supports[:elements].reject do |element|
          @practitioner_ary&.any? do |resource|
            value_found = resolve_element_from_path(resource, element[:path]) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        missing_must_support_elements += missing_slices.map { |slice| slice[:name] }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@practitioner_ary&.length} provided Practitioner resource(s)"
        @instance.save!
      end

      test 'Every reference within Practitioner resources can be read.' do
        metadata do
          id '04'
          link 'http://hl7.org/fhir/references.html'
          description %(

            This test will attempt to read the first 50 reference found in the resources from the first search.
            The test will fail if Inferno fails to read any of those references.

          )
          versions :r4
        end

        skip_if_known_not_supported(:Practitioner, [:search, :read])
        skip_if_not_found(resource_type: 'Practitioner', delayed: true)

        validated_resources = Set.new
        max_resolutions = 50

        @practitioner_ary&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
