# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4LocationSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'US Core R4 Location Tests'

      description 'Verify that Location resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Location' # change me

      requires :token, :patient_id
      conformance_supports :Location

      def validate_resource_item(resource, property, value)
        case property

        when 'name'
          assert !resource&.name.nil? && resource&.name == value, 'name on resource did not match name requested'

        when 'address'

        when 'address-city'
          assert !resource&.address&.city.nil? && resource&.address&.city == value, 'address-city on resource did not match address-city requested'

        when 'address-state'
          assert !resource&.address&.state.nil? && resource&.address&.state == value, 'address-state on resource did not match address-state requested'

        when 'address-postalcode'
          assert !resource&.address&.postalCode.nil? && resource&.address&.postalCode == value, 'address-postalcode on resource did not match address-postalcode requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Location Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-location)

      )

      @resources_found = false

      test 'Server rejects Location search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Location'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Location search by name' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        search_params = { patient: @instance.patient_id, name: 'Boston' }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @location = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('Location'), reply)
      end

      test 'Server returns expected results from Location search by address' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@location.nil?, 'Expected valid Location resource to be present'

        address_val = @location&.address
        search_params = { 'address': address_val }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Location search by address-city' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@location.nil?, 'Expected valid Location resource to be present'

        address_city_val = @location&.address&.city
        search_params = { 'address-city': address_city_val }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Location search by address-state' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@location.nil?, 'Expected valid Location resource to be present'

        address_state_val = @location&.address&.state
        search_params = { 'address-state': address_state_val }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Location search by address-postalcode' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@location.nil?, 'Expected valid Location resource to be present'

        address_postalcode_val = @location&.address&.postalCode
        search_params = { 'address-postalcode': address_postalcode_val }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)
        assert_response_ok(reply)
      end

      test 'Location read resource supported' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Location, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@location, versioned_resource_class('Location'))
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

      test 'Location resources associated with Patient conform to Argonaut profiles' do
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

      test 'All references can be resolved' do
        metadata do
          id '11'
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
