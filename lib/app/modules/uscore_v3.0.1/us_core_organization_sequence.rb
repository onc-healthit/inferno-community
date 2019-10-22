# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore301OrganizationSequence < SequenceBase
      title 'Organization Tests'

      description 'Verify that Organization resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'USCO'

      requires :token
      conformance_supports :Organization
      delayed_sequence

      def validate_resource_item(resource, property, value)
        case property

        when 'name'
          value_found = can_resolve_path(resource, 'name') { |value_in_resource| value_in_resource == value }
          assert value_found, 'name on resource does not match name requested'

        when 'address'
          value_found = can_resolve_path(resource, 'address.city') { |value_in_resource| value_in_resource == value }
          assert value_found, 'address on resource does not match address requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.

      )

      @resources_found = false

      test 'Can read Organization from the server' do
        metadata do
          id '01'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        organization_id = @instance.resource_references.find { |reference| reference.resource_type == 'Organization' }&.resource_id
        skip 'No Organization references found from the prior searches' if organization_id.nil?
        @organization = fetch_resource('Organization', organization_id)
        @resources_found = !@organization.nil?
      end

      test 'Server rejects Organization search without authorization' do
        metadata do
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
          )
          versions :r4
        end

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        name_val = resolve_element_from_path(@organization, 'name')
        search_params = { 'name': name_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Organization'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Organization search by name' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        name_val = resolve_element_from_path(@organization, 'name')
        search_params = { 'name': name_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Organization'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @organization = reply&.resource&.entry&.first&.resource
        @organization_ary = fetch_all_bundled_resources(reply&.resource)
        save_resource_ids_in_bundle(versioned_resource_class('Organization'), reply)
        save_delayed_sequence_references(@organization)
        validate_search_reply(versioned_resource_class('Organization'), reply, search_params)
      end

      test 'Server returns expected results from Organization search by address' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@organization.nil?, 'Expected valid Organization resource to be present'

        address_val = resolve_element_from_path(@organization, 'address.city')
        search_params = { 'address': address_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Organization'), search_params)
        validate_search_reply(versioned_resource_class('Organization'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Organization vread resource supported' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:Organization, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@organization, versioned_resource_class('Organization'))
      end

      test 'Organization history resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:Organization, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@organization, versioned_resource_class('Organization'))
      end

      test 'A Server SHALL be capable of supporting the following _revincludes: Provenance:target' do
        metadata do
          id '07'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
          )
          versions :r4
        end

        name_val = resolve_element_from_path(@organization, 'name')
        search_params = { 'name': name_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('Organization'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
        assert provenance_results, 'No provenance resources were returned from this search'
      end

      test 'Organization resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '08'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Organization')
      end

      test 'At least one of every must support element is provided in any Organization for this patient.' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @organization_ary&.any?
        must_support_confirmed = {}
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
          'Organization.address.country',
          'Organization.endpoint'
        ]
        must_support_elements.each do |path|
          @organization_ary&.each do |resource|
            truncated_path = path.gsub('Organization.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @organization_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided Organization resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:Organization, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@organization)
      end
    end
  end
end
