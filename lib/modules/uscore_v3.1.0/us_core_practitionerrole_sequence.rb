# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310PractitionerroleSequence < SequenceBase
      title 'PractitionerRole Tests'

      description 'Verify that PractitionerRole resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCPRO'

      requires :token
      conformance_supports :PractitionerRole
      delayed_sequence

      def validate_resource_item(resource, property, value)
        case property

        when 'specialty'
          value_found = can_resolve_path(resource, 'specialty.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'specialty on resource does not match specialty requested'

        when 'practitioner'
          value_found = can_resolve_path(resource, 'practitioner.reference') { |value_in_resource| value_in_resource == value }
          assert value_found, 'practitioner on resource does not match practitioner requested'

        end
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      @resources_found = false

      test :resource_read do
        metadata do
          id '01'
          name 'Can read PractitionerRole from the server'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            Reference to PractitionerRole can be resolved and read.
          )
          versions :r4
        end

        skip_if_not_supported(:PractitionerRole, [:read])

        practitioner_role_id = @instance.resource_references.find { |reference| reference.resource_type == 'PractitionerRole' }&.resource_id
        skip 'No PractitionerRole references found from the prior searches' if practitioner_role_id.nil?

        @practitioner_role = validate_read_reply(
          FHIR::PractitionerRole.new(id: practitioner_role_id),
          FHIR::PractitionerRole
        )
        @practitioner_role_ary = Array.wrap(@practitioner_role).compact
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

        skip_if_not_supported(:PractitionerRole, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = {
          'specialty': get_value_for_search_param(resolve_element_from_path(@practitioner_role_ary, 'specialty'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from PractitionerRole search by specialty' do
        metadata do
          id '03'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by specialty on the PractitionerRole resource

          )
          versions :r4
        end

        search_params = {
          'specialty': get_value_for_search_param(resolve_element_from_path(@practitioner_role_ary, 'specialty'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @practitioner_role = reply&.resource&.entry&.first&.resource
        @practitioner_role_ary = fetch_all_bundled_resources(reply&.resource)
        save_resource_ids_in_bundle(versioned_resource_class('PractitionerRole'), reply)
        save_delayed_sequence_references(@practitioner_role_ary)
        validate_search_reply(versioned_resource_class('PractitionerRole'), reply, search_params)
      end

      test 'Server returns expected results from PractitionerRole search by practitioner' do
        metadata do
          id '04'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by practitioner on the PractitionerRole resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@practitioner_role.nil?, 'Expected valid PractitionerRole resource to be present'

        search_params = {
          'practitioner': get_value_for_search_param(resolve_element_from_path(@practitioner_role_ary, 'practitioner'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)
        validate_search_reply(versioned_resource_class('PractitionerRole'), reply, search_params)
        assert_response_ok(reply)
      end

      test :vread_interaction do
        metadata do
          id '05'
          name 'PractitionerRole vread interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHOULD support the PractitionerRole vread interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:PractitionerRole, [:vread])
        skip 'No PractitionerRole resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@practitioner_role, versioned_resource_class('PractitionerRole'))
      end

      test :history_interaction do
        metadata do
          id '06'
          name 'PractitionerRole history interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHOULD support the PractitionerRole history interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:PractitionerRole, [:history])
        skip 'No PractitionerRole resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@practitioner_role, versioned_resource_class('PractitionerRole'))
      end

      test 'Server returns the appropriate resource from the following _includes: PractitionerRole:endpoint, PractitionerRole:practitioner' do
        metadata do
          id '07'
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
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

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

      test 'Server returns the appropriate resources from the following _revincludes: Provenance:target' do
        metadata do
          id '08'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end

        search_params = {
          'specialty': get_value_for_search_param(resolve_element_from_path(@practitioner_role_ary, 'specialty'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
        assert provenance_results, 'No Provenance resources were returned from this search'
      end

      test 'PractitionerRole resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '09'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitionerrole'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('PractitionerRole')
      end

      test 'At least one of every must support element is provided in any PractitionerRole for this patient.' do
        metadata do
          id '10'
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

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @practitioner_role_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'PractitionerRole.practitioner',
          'PractitionerRole.organization',
          'PractitionerRole.code',
          'PractitionerRole.specialty',
          'PractitionerRole.location',
          'PractitionerRole.telecom',
          'PractitionerRole.telecom.system',
          'PractitionerRole.telecom.value',
          'PractitionerRole.endpoint'
        ]
        must_support_elements.each do |path|
          @practitioner_role_ary&.each do |resource|
            truncated_path = path.gsub('PractitionerRole.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @practitioner_role_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided PractitionerRole resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '11'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_not_supported(:PractitionerRole, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@practitioner_role)
      end
    end
  end
end
