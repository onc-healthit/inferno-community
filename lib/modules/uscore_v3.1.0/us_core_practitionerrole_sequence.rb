# frozen_string_literal: true

require_relative './data_absent_reason_checker'

module Inferno
  module Sequence
    class USCore310PractitionerroleSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker

      title 'PractitionerRole Tests'

      description 'Verify that PractitionerRole resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCPRO'

      requires :token
      new_requires
      conformance_supports :PractitionerRole
      delayed_sequence

      def validate_resource_item(resource, property, value)
        case property

        when 'specialty'
          value_found = resolve_element_from_path(resource, 'specialty.coding.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'specialty on resource does not match specialty requested'

        when 'practitioner'
          value_found = resolve_element_from_path(resource, 'practitioner.reference') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'practitioner on resource does not match practitioner requested'

        end
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

      @resources_found = false

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct PractitionerRole resource from the PractitionerRole read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            Reference to PractitionerRole can be resolved and read.
          )
          versions :r4
        end

        skip_if_known_not_supported(:PractitionerRole, [:read])

        practitioner_role_references = @instance.resource_references.select { |reference| reference.resource_type == 'PractitionerRole' }
        skip 'No PractitionerRole references found from the prior searches' if practitioner_role_references.blank?

        @practitioner_role_ary = practitioner_role_references.map do |reference|
          validate_read_reply(
            FHIR::PractitionerRole.new(id: reference.resource_id),
            FHIR::PractitionerRole,
            check_for_data_absent_reasons
          )
        end
        @practitioner_role = @practitioner_role_ary.first
        @resources_found = @practitioner_role.present?
      end

      test :unauthorized_search do
        metadata do
          id '02'
          name 'Server rejects PractitionerRole search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_known_not_supported(:PractitionerRole, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = {
          'specialty': get_value_for_search_param(resolve_element_from_path(@practitioner_role_ary, 'specialty'))
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)
        assert_response_unauthorized reply

        @client.set_bearer_token(@instance.token)
      end

      test :search_by_specialty do
        metadata do
          id '03'
          name 'Server returns expected results from PractitionerRole search by specialty'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by specialty on the PractitionerRole resource

          )
          versions :r4
        end

        search_params = {
          'specialty': get_value_for_search_param(resolve_element_from_path(@practitioner_role_ary, 'specialty'))
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)

        assert_response_ok(reply)
        assert_bundle_response(reply)

        @resources_found = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'PractitionerRole' }
        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)
        @practitioner_role_ary = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
        @practitioner_role = @practitioner_role_ary
          .find { |resource| resource.resourceType == 'PractitionerRole' }

        save_resource_references(versioned_resource_class('PractitionerRole'), @practitioner_role_ary)
        save_delayed_sequence_references(@practitioner_role_ary)
        validate_search_reply(versioned_resource_class('PractitionerRole'), reply, search_params)
      end

      test :search_by_practitioner do
        metadata do
          id '04'
          name 'Server returns expected results from PractitionerRole search by practitioner'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by practitioner on the PractitionerRole resource

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)

        search_params = {
          'practitioner': get_value_for_search_param(resolve_element_from_path(@practitioner_role_ary, 'practitioner'))
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)

        validate_search_reply(versioned_resource_class('PractitionerRole'), reply, search_params)
      end

      test :chained_search_by_practitioner do
        metadata do
          id '05'
          name 'Server returns expected results from PractitionerRole chained search by practitioner.identifier and practitioner.name'
          link 'https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-practitionerrole.html#mandatory-search-parameters'
          description %(

            A server SHALL support searching the PractitionerRole resource
            with the chained parameters practitioner.identifier and practitioner.name

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)

        practitioner_role = @practitioner_role_ary.find { |role| role.practitioner&.reference.present? }
        skip_if practitioner_role.blank?, 'No PractitionerRoles containing a Practitioner reference were found'

        begin
          practitioner = practitioner_role.practitioner.read
        rescue ClientException => e
          assert false, "Unable to resolve Practitioner reference: #{e}"
        end

        assert practitioner.resourceType == 'Practitioner', "Expected FHIR Practitioner but found: #{practitioner.resourceType}"

        name = practitioner.name&.first&.family
        skip_if name.blank?, 'Practitioner has no family name'

        name_search_response = @client.search(FHIR::PractitionerRole, search: { parameters: { 'practitioner.name': name } })
        assert_response_ok(name_search_response)
        assert_bundle_response(name_search_response)

        name_bundle_entries = fetch_all_bundled_resources(name_search_response, check_for_data_absent_reasons)

        practitioner_role_found = name_bundle_entries.any? { |entry| entry.id == practitioner_role.id }
        assert practitioner_role_found, "PractitionerRole with id #{practitioner_role.id} not found in search results for practitioner.name = #{name}"

        identifier = practitioner.identifier.first
        skip_if identifier.blank?, 'Practitioner has no identifier'
        identifier_string = "#{identifier.system}|#{identifier.value}"

        identifier_search_response = @client.search(
          FHIR::PractitionerRole,
          search: { parameters: { 'practitioner.identifier': identifier_string } }
        )
        assert_response_ok(identifier_search_response)
        assert_bundle_response(identifier_search_response)

        identifier_bundle_entries = fetch_all_bundled_resources(identifier_search_response, check_for_data_absent_reasons)

        practitioner_role_found = identifier_bundle_entries.any? { |entry| entry.id == practitioner_role.id }
        assert practitioner_role_found, "PractitionerRole with id #{practitioner_role.id} not found in search results for practitioner.identifier = #{identifier_string}"
      end

      test :vread_interaction do
        metadata do
          id '06'
          name 'Server returns correct PractitionerRole resource from PractitionerRole vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the PractitionerRole vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:PractitionerRole, [:vread])
        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)

        validate_vread_reply(@practitioner_role, versioned_resource_class('PractitionerRole'))
      end

      test :history_interaction do
        metadata do
          id '07'
          name 'Server returns correct PractitionerRole resource from PractitionerRole history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the PractitionerRole history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:PractitionerRole, [:history])
        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)

        validate_history_reply(@practitioner_role, versioned_resource_class('PractitionerRole'))
      end

      test 'Server returns the appropriate resource from the following _includes: PractitionerRole:endpoint, PractitionerRole:practitioner' do
        metadata do
          id '08'
          link 'https://www.hl7.org/fhir/search.html#include'
          optional
          description %(
            A Server SHOULD be capable of supporting the following _includes: PractitionerRole:endpoint, PractitionerRole:practitioner
          )
          versions :r4
        end

        search_params = {
          'specialty': get_value_for_search_param(resolve_element_from_path(@practitioner_role_ary, 'specialty'))
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        search_params['_include'] = 'PractitionerRole:endpoint'
        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        endpoint_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Endpoint' }
        assert endpoint_results, 'No Endpoint resources were returned from this search'

        search_params['_include'] = 'PractitionerRole:practitioner'
        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        practitioner_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Practitioner' }
        assert practitioner_results, 'No Practitioner resources were returned from this search'
      end

      test 'Server returns Provenance resources from PractitionerRole search by specialty + _revIncludes: Provenance:target' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end
        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)
        provenance_results = []

        search_params = {
          'specialty': get_value_for_search_param(resolve_element_from_path(@practitioner_role_ary, 'specialty'))
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)

        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results += fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
          .select { |resource| resource.resourceType == 'Provenance' }
        save_resource_references(versioned_resource_class('Provenance'), provenance_results)

        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '10'
          name 'PractitionerRole resources returned conform to US Core R4 profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitionerrole'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)
        test_resources_against_profile('PractitionerRole')
      end

      test 'All must support elements are provided in the PractitionerRole resources returned.' do
        metadata do
          id '11'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all PractitionerRole resources returned from prior searches to see if any of them provide the following must support elements:

            PractitionerRole.practitioner

            PractitionerRole.organization

            PractitionerRole.code

            PractitionerRole.specialty

            PractitionerRole.location

            PractitionerRole.telecom

            PractitionerRole.telecom.system

            PractitionerRole.telecom.value

            PractitionerRole.endpoint

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)

        must_support_elements = [
          { path: 'PractitionerRole.practitioner' },
          { path: 'PractitionerRole.organization' },
          { path: 'PractitionerRole.code' },
          { path: 'PractitionerRole.specialty' },
          { path: 'PractitionerRole.location' },
          { path: 'PractitionerRole.telecom' },
          { path: 'PractitionerRole.telecom.system' },
          { path: 'PractitionerRole.telecom.value' },
          { path: 'PractitionerRole.endpoint' }
        ]

        missing_must_support_elements = must_support_elements.reject do |element|
          truncated_path = element[:path].gsub('PractitionerRole.', '')
          @practitioner_role_ary&.any? do |resource|
            value_found = resolve_element_from_path(resource, truncated_path) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@practitioner_role_ary&.length} provided PractitionerRole resource(s)"
        @instance.save!
      end

      test 'Every reference within PractitionerRole resource is valid and can be read.' do
        metadata do
          id '12'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_known_not_supported(:PractitionerRole, [:search, :read])
        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)

        validated_resources = Set.new
        max_resolutions = 50

        @practitioner_role_ary&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
