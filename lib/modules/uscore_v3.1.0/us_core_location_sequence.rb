# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310LocationSequence < SequenceBase
      title 'Location Tests'

      description 'Verify that Location resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCL'

      requires :token
      conformance_supports :Location
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

        when 'address-city'
          value_found = resolve_element_from_path(resource, 'address.city') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'address-city on resource does not match address-city requested'

        when 'address-state'
          value_found = resolve_element_from_path(resource, 'address.state') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'address-state on resource does not match address-state requested'

        when 'address-postalcode'
          value_found = resolve_element_from_path(resource, 'address.postalCode') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'address-postalcode on resource does not match address-postalcode requested'

        end
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      @resources_found = false

      test :resource_read do
        metadata do
          id '01'
          name 'Can read Location from the server'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            Reference to Location can be resolved and read.
          )
          versions :r4
        end

        skip_if_not_supported(:Location, [:read])

        location_id = @instance.resource_references.find { |reference| reference.resource_type == 'Location' }&.resource_id
        skip 'No Location references found from the prior searches' if location_id.nil?

        @location = validate_read_reply(
          FHIR::Location.new(id: location_id),
          FHIR::Location
        )
        @location_ary = Array.wrap(@location).compact
        @resources_found = @location.present?
      end

      test :unauthorized_search do
        metadata do
          id '02'
          name 'Server rejects Location search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_not_supported(:Location, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = {
          'name': get_value_for_search_param(resolve_element_from_path(@location_ary, 'name'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test :search_by_name do
        metadata do
          id '03'
          name 'Server returns expected results from Location search by name'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by name on the Location resource

          )
          versions :r4
        end

        search_params = {
          'name': get_value_for_search_param(resolve_element_from_path(@location_ary, 'name'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        @resources_found = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Location' }

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @location = reply.resource.entry
          .find { |entry| entry&.resource&.resourceType == 'Location' }
          .resource
        @location_ary = fetch_all_bundled_resources(reply.resource)
        save_resource_ids_in_bundle(versioned_resource_class('Location'), reply)
        save_delayed_sequence_references(@location_ary)
        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
      end

      test :search_by_address do
        metadata do
          id '04'
          name 'Server returns expected results from Location search by address'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by address on the Location resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'address': get_value_for_search_param(resolve_element_from_path(@location_ary, 'address'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
        assert_response_ok(reply)
      end

      test :search_by_address_city do
        metadata do
          id '05'
          name 'Server returns expected results from Location search by address-city'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by address-city on the Location resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'address-city': get_value_for_search_param(resolve_element_from_path(@location_ary, 'address.city'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
        assert_response_ok(reply)
      end

      test :search_by_address_state do
        metadata do
          id '06'
          name 'Server returns expected results from Location search by address-state'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by address-state on the Location resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'address-state': get_value_for_search_param(resolve_element_from_path(@location_ary, 'address.state'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
        assert_response_ok(reply)
      end

      test :search_by_address_postalcode do
        metadata do
          id '07'
          name 'Server returns expected results from Location search by address-postalcode'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by address-postalcode on the Location resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'address-postalcode': get_value_for_search_param(resolve_element_from_path(@location_ary, 'address.postalCode'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
        assert_response_ok(reply)
      end

      test :vread_interaction do
        metadata do
          id '08'
          name 'Location vread interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Location vread interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Location, [:vread])
        skip 'No Location resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@location, versioned_resource_class('Location'))
      end

      test :history_interaction do
        metadata do
          id '09'
          name 'Location history interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Location history interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Location, [:history])
        skip 'No Location resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@location, versioned_resource_class('Location'))
      end

      test 'Server returns the appropriate resources from the following _revincludes: Provenance:target' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end

        search_params = {
          'name': get_value_for_search_param(resolve_element_from_path(@location_ary, 'name'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
        assert provenance_results, 'No Provenance resources were returned from this search'
      end

      test 'Location resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '11'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-location'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Location')
      end

      test 'At least one of every must support element is provided in any Location for this patient.' do
        metadata do
          id '12'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Location resources returned from prior searches to see if any of them provide the following must support elements:

            Location.status

            Location.name

            Location.telecom

            Location.address

            Location.address.line

            Location.address.city

            Location.address.state

            Location.address.postalCode

            Location.managingOrganization

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @location_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'Location.status',
          'Location.name',
          'Location.telecom',
          'Location.address',
          'Location.address.line',
          'Location.address.city',
          'Location.address.state',
          'Location.address.postalCode',
          'Location.managingOrganization'
        ]
        must_support_elements.each do |path|
          @location_ary&.each do |resource|
            truncated_path = path.gsub('Location.', '')
            must_support_confirmed[path] = true if resolve_element_from_path(resource, truncated_path).present?
            break if must_support_confirmed[path]
          end
          resource_count = @location_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided Location resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '13'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_not_supported(:Location, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@location)
      end
    end
  end
end
