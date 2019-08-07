# frozen_string_literal: true

module Inferno
  module Sequence
    class USCoreR4LocationSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Location Tests'

      description 'Verify that Location resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Location' # change me

      requires :token, :location
      conformance_supports :Location

      def validate_resource_item(resource, property, value)
        case property

        when 'name'
          value_found = can_resolve_path(resource, 'name') { |value_in_resource| value_in_resource == value }
          assert value_found, 'name on resource does not match name requested'

        when 'address'
          value_found = can_resolve_path(resource, 'address') { |value_in_resource| value_in_resource == value }
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

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Location Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-location)

      )

      @resources_found = false

      test 'Can read Location from the server' do
        metadata do
          id '01'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        @location = fetch_resource('Location', @instance.location)
        validate_read_reply(@location, versioned_resource_class('Location'))
        @resources_found = !@location.nil?
      end

      test 'Server rejects Location search without authorization' do
        metadata do
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        search_params = { patient: @instance.patient_id, name: 'Boston' }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Location search by name' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@location.nil?, 'Expected valid Location resource to be present'

        search_params = { patient: @instance.patient_id, name: 'Boston' }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Location search by address' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@location.nil?, 'Expected valid Location resource to be present'

        address_val = resolve_element_from_path(@location, 'address')
        search_params = { 'address': address_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Location search by address-city' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@location.nil?, 'Expected valid Location resource to be present'

        address_city_val = resolve_element_from_path(@location, 'address.city')
        search_params = { 'address-city': address_city_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Location search by address-state' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@location.nil?, 'Expected valid Location resource to be present'

        address_state_val = resolve_element_from_path(@location, 'address.state')
        search_params = { 'address-state': address_state_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Location search by address-postalcode' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@location.nil?, 'Expected valid Location resource to be present'

        address_postalcode_val = resolve_element_from_path(@location, 'address.postalCode')
        search_params = { 'address-postalcode': address_postalcode_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Location vread resource supported' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Location, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@location, versioned_resource_class('Location'))
      end

      test 'Location history resource supported' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Location, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@location, versioned_resource_class('Location'))
      end

      test 'Location resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '10'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-location.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Location')
      end

      test 'At least one of every must support element is provided in any Location for this patient.' do
        metadata do
          id '11'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
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
          id '12'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
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
