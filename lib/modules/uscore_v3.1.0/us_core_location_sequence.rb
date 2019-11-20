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
          value_found = can_resolve_path(resource, 'name') { |value_in_resource| value_in_resource == value }
          assert value_found, 'name on resource does not match name requested'

        when 'address'
          value_found = can_resolve_path(resource, 'address') do |address|
            address&.text&.start_with?(value) ||
              address&.city&.start_with?(value) ||
              address&.state&.start_with?(value) ||
              address&.postalCode&.start_with?(value) ||
              address&.country&.start_with?(value)
          end
          assert value_found, 'address on resource does not match address requested'

        when 'address-city'
          value_found = can_resolve_path(resource, 'address.city') { |value_in_resource| value_in_resource == value }
          assert value_found, 'address-city on resource does not match address-city requested'

        when 'address-state'
          value_found = can_resolve_path(resource, 'address.state') { |value_in_resource| value_in_resource == value }
          assert value_found, 'address-state on resource does not match address-state requested'

        when 'address-postalcode'
          value_found = can_resolve_path(resource, 'address.postalCode') { |value_in_resource| value_in_resource == value }
          assert value_found, 'address-postalcode on resource does not match address-postalcode requested'

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
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
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
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html#behavior'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:Location, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = { patient: @instance.patient_id }
        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Location search by name' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
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

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @location = reply&.resource&.entry&.first&.resource
        @location_ary = fetch_all_bundled_resources(reply&.resource)
        save_resource_ids_in_bundle(versioned_resource_class('Location'), reply)
        save_delayed_sequence_references(@location_ary)
        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
      end

      test 'Server returns expected results from Location search by address' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@location.nil?, 'Expected valid Location resource to be present'

        search_params = {
          'address': get_value_for_search_param(resolve_element_from_path(@location_ary, 'address'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Location search by address-city' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@location.nil?, 'Expected valid Location resource to be present'

        search_params = {
          'address-city': get_value_for_search_param(resolve_element_from_path(@location_ary, 'address.city'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Location search by address-state' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@location.nil?, 'Expected valid Location resource to be present'

        search_params = {
          'address-state': get_value_for_search_param(resolve_element_from_path(@location_ary, 'address.state'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Location search by address-postalcode' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@location.nil?, 'Expected valid Location resource to be present'

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
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
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
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
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
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Location')
      end

      test 'At least one of every must support element is provided in any Location for this patient.' do
        metadata do
          id '12'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          description %(
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
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
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
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          description %(
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
