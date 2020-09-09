# frozen_string_literal: true

require_relative './data_absent_reason_checker'
require_relative './profile_definitions/us_core_location_definitions'

module Inferno
  module Sequence
    class USCore310LocationSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker
      include Inferno::USCore310ProfileDefinitions

      title 'Location Tests'

      description 'Verify support for the server capabilities required by the US Core Location Profile.'

      details %(
        # Background

        The US Core #{title} sequence verifies that the system under test is able to provide correct responses
        for Location queries.  These queries must contain resources conforming to US Core Location Profile as specified
        in the US Core v3.1.0 Implementation Guide.

        # Testing Methodology


        Because Location resources are not present or do not exist in USCDI, no searches are performed on this test sequence. Instead, references to
        this profile found in other resources are used for testing. If no references can be found this way, then all the tests
        in this sequence are skipped.


        ## Must Support
        Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
        at least once. If at least one cannot be found, the test will fail. The test will look through the Location
        resources found for these elements.

        ## Profile Validation
        Each resource returned from the first search is expected to conform to the [US Core Location Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-location).
        Each element is checked against teminology binding and cardinality requirements.

        Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
        of the valueset, then the test will fail.

        ## Reference Validation
        Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
        and will fail if any attempted read fails.
      )

      test_id_prefix 'USCL'

      requires :token
      conformance_supports :Location
      delayed_sequence

      def validate_resource_item(resource, property, value)
        case property

        when 'name'
          values_found = resolve_path(resource, 'name')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "name in Location/#{resource.id} (#{values_found}) does not match name requested (#{value})"

        when 'address'
          values_found = resolve_path(resource, 'address')
          match_found = values_found.any? do |address|
            address&.text&.start_with?(value) ||
              address&.city&.start_with?(value) ||
              address&.state&.start_with?(value) ||
              address&.postalCode&.start_with?(value) ||
              address&.country&.start_with?(value)
          end
          assert match_found, "address in Location/#{resource.id} (#{values_found}) does not match address requested (#{value})"

        when 'address-city'
          values_found = resolve_path(resource, 'address.city')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "address-city in Location/#{resource.id} (#{values_found}) does not match address-city requested (#{value})"

        when 'address-state'
          values_found = resolve_path(resource, 'address.state')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "address-state in Location/#{resource.id} (#{values_found}) does not match address-state requested (#{value})"

        when 'address-postalcode'
          values_found = resolve_path(resource, 'address.postalCode')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "address-postalcode in Location/#{resource.id} (#{values_found}) does not match address-postalcode requested (#{value})"

        end
      end

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

      @resources_found = false

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Location resource from the Location read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            This test will attempt to Reference to Location can be resolved and read.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Location, [:read])

        location_references = @instance.resource_references.select { |reference| reference.resource_type == 'Location' }
        skip 'No Location references found from the prior searches' if location_references.blank?

        @location_ary = location_references.map do |reference|
          validate_read_reply(
            FHIR::Location.new(id: reference.resource_id),
            FHIR::Location,
            check_for_data_absent_reasons
          )
        end
        @location = @location_ary.first
        @resources_found = @location.present?
      end

      test :validate_resources do
        metadata do
          id '02'
          name 'Location resources returned from previous search conform to the US Core Location Profile.'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-location'
          description %(

            This test verifies resources returned from the first search conform to the [US Core Location Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-location).
            It verifies the presence of mandatory elements and that elements with required bindings contain appropriate values.
            CodeableConcept element bindings will fail if none of its codings have a code/system that is part of the bound ValueSet.
            Quantity, Coding, and code element bindings will fail if its code/system is not found in the valueset.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Location', delayed: true)
        test_resources_against_profile('Location')
      end

      test 'All must support elements are provided in the Location resources returned.' do
        metadata do
          id '03'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through the Location resources found previously for the following must support elements:

            * status
            * name
            * telecom
            * address
            * address.line
            * address.city
            * address.state
            * address.postalCode
            * managingOrganization
          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Location', delayed: true)
        must_supports = USCore310LocationSequenceDefinitions::MUST_SUPPORTS

        missing_must_support_elements = must_supports[:elements].reject do |element|
          @location_ary&.any? do |resource|
            value_found = resolve_element_from_path(resource, element[:path]) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@location_ary&.length} provided Location resource(s)"
        @instance.save!
      end

      test 'Every reference within Location resources can be read.' do
        metadata do
          id '04'
          link 'http://hl7.org/fhir/references.html'
          description %(

            This test will attempt to read the first 50 reference found in the resources from the first search.
            The test will fail if Inferno fails to read any of those references.

          )
          versions :r4
        end

        skip_if_known_not_supported(:Location, [:search, :read])
        skip_if_not_found(resource_type: 'Location', delayed: true)

        validated_resources = Set.new
        max_resolutions = 50

        @location_ary&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
