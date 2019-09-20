# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore301PractitionerSequence < SequenceBase
      title 'Practitioner Tests'

      description 'Verify that Practitioner resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Practitioner' # change me

      requires :token
      conformance_supports :Practitioner
      delayed_sequence

      def validate_resource_item(resource, property, value)
        case property

        when 'name'
          value = value.downcase
          value_found = can_resolve_path(resource, 'name') do |name|
            name&.text&.start_with?(value) ||
              name&.family&.downcase&.include?(value) ||
              name&.given&.any? { |given| given.downcase.start_with?(value) } ||
              name&.prefix&.any? { |prefix| prefix.downcase.start_with?(value) } ||
              name&.suffix&.any? { |suffix| suffix.downcase.start_with?(value) }
          end
          assert value_found, 'name on resource does not match name requested'

        when 'identifier'
          value_found = can_resolve_path(resource, 'identifier.value') { |value_in_resource| value_in_resource == value }
          assert value_found, 'identifier on resource does not match identifier requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.

      )

      @resources_found = false

      test 'Can read Practitioner from the server' do
        metadata do
          id '01'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        practitioner_id = @instance.resource_references.find { |reference| reference.resource_type == 'Practitioner' }&.resource_id
        skip 'No Practitioner references found from the prior searches' if practitioner_id.nil?
        @practitioner = fetch_resource('Practitioner', practitioner_id)
        @resources_found = !@practitioner.nil?
      end

      test 'Server rejects Practitioner search without authorization' do
        metadata do
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        name_val = resolve_element_from_path(@practitioner, 'name.family')
        search_params = { 'name': name_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Practitioner'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Practitioner search by name' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        name_val = resolve_element_from_path(@practitioner, 'name.family')
        search_params = { 'name': name_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Practitioner'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @practitioner = reply.try(:resource).try(:entry).try(:first).try(:resource)
        @practitioner_ary = reply&.resource&.entry&.map { |entry| entry&.resource }
        save_resource_ids_in_bundle(versioned_resource_class('Practitioner'), reply)
        save_delayed_sequence_references(@practitioner)
        validate_search_reply(versioned_resource_class('Practitioner'), reply, search_params)
      end

      test 'Server returns expected results from Practitioner search by identifier' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@practitioner.nil?, 'Expected valid Practitioner resource to be present'

        identifier_val = resolve_element_from_path(@practitioner, 'identifier.value')
        search_params = { 'identifier': identifier_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Practitioner'), search_params)
        validate_search_reply(versioned_resource_class('Practitioner'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Practitioner vread resource supported' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Practitioner, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@practitioner, versioned_resource_class('Practitioner'))
      end

      test 'Practitioner history resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Practitioner, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@practitioner, versioned_resource_class('Practitioner'))
      end

      test 'Practitioner resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '07'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Practitioner')
      end

      test 'At least one of every must support element is provided in any Practitioner for this patient.' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @practitioner_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'Practitioner.identifier',
          'Practitioner.identifier.system',
          'Practitioner.identifier.value',
          'Practitioner.identifier',
          'Practitioner.name',
          'Practitioner.name.family'
        ]
        must_support_elements.each do |path|
          @practitioner_ary&.each do |resource|
            truncated_path = path.gsub('Practitioner.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @practitioner_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided Practitioner resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Practitioner, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@practitioner)
      end
    end
  end
end
