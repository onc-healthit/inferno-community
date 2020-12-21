# frozen_string_literal: true

require_relative './data_absent_reason_checker'
require_relative './profile_definitions/us_core_organization_definitions'

module Inferno
  module Sequence
    class USCore311OrganizationSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker
      include Inferno::USCore311ProfileDefinitions

      title 'Organization Tests'

      description 'Verify support for the server capabilities required by the US Core Organization Profile.'

      details %(
        # Background

        The US Core #{title} sequence verifies that the system under test is able to provide correct responses
        for Organization queries.  These queries must contain resources conforming to US Core Organization Profile as specified
        in the US Core v3.1.1 Implementation Guide.

        # Testing Methodology


        Because Organization resources are not present or do not exist in USCDI, no searches are performed on this test sequence. Instead, references to
        this profile found in other resources are used for testing. If no references can be found this way, then all the tests
        in this sequence are skipped.


        ## Must Support
        Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
        at least once. If at least one cannot be found, the test will fail. The test will look through the Organization
        resources found for these elements.

        ## Profile Validation
        Each resource returned from the first search is expected to conform to the [US Core Organization Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization).
        Each element is checked against teminology binding and cardinality requirements.

        Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
        of the valueset, then the test will fail.

        ## Reference Validation
        Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
        and will fail if any attempted read fails.
      )

      test_id_prefix 'USCO'

      requires :token
      conformance_supports :Organization
      delayed_sequence

      def validate_resource_item(resource, property, value)
        case property

        when 'name'
          values_found = resolve_path(resource, 'name')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "name in Organization/#{resource.id} (#{values_found}) does not match name requested (#{value})"

        when 'address'
          values_found = resolve_path(resource, 'address')
          match_found = values_found.any? do |address|
            address&.text&.start_with?(value) ||
              address&.city&.start_with?(value) ||
              address&.state&.start_with?(value) ||
              address&.postalCode&.start_with?(value) ||
              address&.country&.start_with?(value)
          end
          assert match_found, "address in Organization/#{resource.id} (#{values_found}) does not match address requested (#{value})"

        end
      end

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

      @resources_found = false

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Organization resource from the Organization read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            This test will attempt to Reference to Organization can be resolved and read.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Organization, [:read])

        organization_references = @instance.resource_references.select { |reference| reference.resource_type == 'Organization' }
        skip 'No Organization references found from the prior searches' if organization_references.blank?

        @organization_ary = organization_references.map do |reference|
          validate_read_reply(
            FHIR::Organization.new(id: reference.resource_id),
            FHIR::Organization,
            check_for_data_absent_reasons
          )
        end
        @organization = @organization_ary.first
        @resources_found = @organization.present?
      end

      test 'All must support elements are provided in the Organization resources returned.' do
        metadata do
          id '02'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through the Organization resources found previously for the following must support elements:

            * Organization.identifier:NPI
            * active
            * address
            * address.city
            * address.country
            * address.line
            * address.postalCode
            * address.state
            * identifier
            * identifier.system
            * identifier.value
            * name
            * telecom

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Organization', delayed: true)
        must_supports = USCore311OrganizationSequenceDefinitions::MUST_SUPPORTS

        missing_slices = must_supports[:slices].reject do |slice|
          @organization_ary&.any? do |resource|
            slice_found = find_slice(resource, slice[:path], slice[:discriminator])
            slice_found.present?
          end
        end

        missing_must_support_elements = must_supports[:elements].reject do |element|
          @organization_ary&.any? do |resource|
            value_found = resolve_element_from_path(resource, element[:path]) do |value|
              value_without_extensions = value.respond_to?(:to_hash) ? value.to_hash.reject { |key, _| key == 'extension' } : value
              value_without_extensions.present? && (element[:fixed_value].blank? || value == element[:fixed_value])
            end

            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        missing_must_support_elements += missing_slices.map { |slice| slice[:name] }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@organization_ary&.length} provided Organization resource(s)"
        @instance.save!
      end

      test 'Every reference within Organization resources can be read.' do
        metadata do
          id '03'
          link 'http://hl7.org/fhir/references.html'
          description %(

            This test will attempt to read the first 50 reference found in the resources from the first search.
            The test will fail if Inferno fails to read any of those references.

          )
          versions :r4
        end

        skip_if_known_not_supported(:Organization, [:search, :read])
        skip_if_not_found(resource_type: 'Organization', delayed: true)

        validated_resources = Set.new
        max_resolutions = 50

        @organization_ary&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
