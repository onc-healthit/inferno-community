# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310OrganizationSequence < SequenceBase
      title 'Organization Tests'

      description 'Verify that Organization resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCO'

      requires :token
      conformance_supports :Organization
      delayed_sequence

      def validate_resource_item(resource, property, value)
        case property

        when 'name'
          value_found = resolve_element_from_path(resource, 'name') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'name on resource does not match name requested'

        when 'address'
          value_found = resolve_element_from_path(resource, 'address') do |address|
            address&.text&.start_with?(value) ||
              address&.city&.start_with?(value) ||
              address&.state&.start_with?(value) ||
              address&.postalCode&.start_with?(value) ||
              address&.country&.start_with?(value)
          end
          assert value_found.present?, 'address on resource does not match address requested'

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
          name 'Server returns correct Organization resource from the Organization read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            Reference to Organization can be resolved and read.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Organization, [:read])

        organization_references = @instance.resource_references.select { |reference| reference.resource_type == 'Organization' }
        skip 'No Organization references found from the prior searches' if organization_references.blank?

        @organization_ary = organization_references.map do |reference|
          validate_read_reply(
            FHIR::Organization.new(id: reference.resource_id),
            FHIR::Organization
          )
        end
        @organization = @organization_ary.first
        @resources_found = @organization.present?
      end

      test :unauthorized_search do
        metadata do
          id '02'
          name 'Server rejects Organization search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Organization, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = {
          'name': get_value_for_search_param(resolve_element_from_path(@organization_ary, 'name'))
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Organization'), search_params)
        assert_response_unauthorized reply

        @client.set_bearer_token(@instance.token)
      end

      test :search_by_name do
        metadata do
          id '03'
          name 'Server returns expected results from Organization search by name'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by name on the Organization resource

          )
          versions :r4
        end

        search_params = {
          'name': get_value_for_search_param(resolve_element_from_path(@organization_ary, 'name'))
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Organization'), search_params)

        assert_response_ok(reply)
        assert_bundle_response(reply)
        @resources_found = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Organization' }
        skip 'No Organization resources appear to be available.' unless @resources_found
        @organization = reply.resource.entry
          .find { |entry| entry&.resource&.resourceType == 'Organization' }
          .resource
        @organization_ary = fetch_all_bundled_resources(reply.resource)
        save_resource_ids_in_bundle(versioned_resource_class('Organization'), reply)
        save_delayed_sequence_references(@organization_ary)
        validate_search_reply(versioned_resource_class('Organization'), reply, search_params)
      end

      test :search_by_address do
        metadata do
          id '04'
          name 'Server returns expected results from Organization search by address'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by address on the Organization resource

          )
          versions :r4
        end

        skip 'No Organization resources appear to be available.' unless @resources_found

        search_params = {
          'address': get_value_for_search_param(resolve_element_from_path(@organization_ary, 'address'))
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Organization'), search_params)

        validate_search_reply(versioned_resource_class('Organization'), reply, search_params)
      end

      test :vread_interaction do
        metadata do
          id '05'
          name 'Server returns correct Organization resource from Organization vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Organization vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Organization, [:vread])
        skip 'No Organization resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@organization, versioned_resource_class('Organization'))
      end

      test :history_interaction do
        metadata do
          id '06'
          name 'Server returns correct Organization resource from Organization history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Organization history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Organization, [:history])
        skip 'No Organization resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@organization, versioned_resource_class('Organization'))
      end

      test 'Server returns Provenance resources from Organization search by name + _revIncludes: Provenance:target' do
        metadata do
          id '07'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end

        provenance_results = []

        search_params = {
          'name': get_value_for_search_param(resolve_element_from_path(@organization_ary, 'name'))
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('Organization'), search_params)

        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results += fetch_all_bundled_resources(reply.resource).select { |resource| resource.resourceType == 'Provenance' }
        provenance_results.each { |reference| @instance.save_resource_reference('Provenance', reference.id) }

        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '08'
          name 'Organization resources returned conform to US Core R4 profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No Organization resources appear to be available.' unless @resources_found
        test_resources_against_profile('Organization')
      end

      test 'All must support elements are provided in the Organization resources returned.' do
        metadata do
          id '09'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Organization resources returned from prior searches to see if any of them provide the following must support elements:

            Organization.identifier

            Organization.identifier.system

            Organization.identifier.value

            Organization.identifier

            Organization.identifier

            Organization.active

            Organization.name

            Organization.telecom

            Organization.address

            Organization.address.line

            Organization.address.city

            Organization.address.state

            Organization.address.postalCode

            Organization.address.country

          )
          versions :r4
        end

        skip 'No Organization resources appear to be available.' unless @resources_found

        must_support_elements = [
          'Organization.identifier',
          'Organization.identifier.system',
          'Organization.identifier.value',
          'Organization.identifier',
          'Organization.identifier',
          'Organization.active',
          'Organization.name',
          'Organization.telecom',
          'Organization.address',
          'Organization.address.line',
          'Organization.address.city',
          'Organization.address.state',
          'Organization.address.postalCode',
          'Organization.address.country'
        ]

        missing_must_support_elements = must_support_elements.reject do |path|
          truncated_path = path.gsub('Organization.', '')
          @organization_ary&.any? do |resource|
            resolve_element_from_path(resource, truncated_path).present?
          end
        end

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@organization_ary&.length} provided Organization resource(s)"
        @instance.save!
      end

      test 'Every reference within Organization resource is valid and can be read.' do
        metadata do
          id '10'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Organization, [:search, :read])
        skip 'No Organization resources appear to be available.' unless @resources_found

        validated_resources = Set.new
        max_resolutions = 50

        @organization_ary&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
