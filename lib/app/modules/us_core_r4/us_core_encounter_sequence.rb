# frozen_string_literal: true

module Inferno
  module Sequence
    class USCoreR4EncounterSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Encounter Tests'

      description 'Verify that Encounter resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Encounter' # change me

      requires :token, :patient_id
      conformance_supports :Encounter

      def validate_resource_item(resource, property, value)
        case property

        when '_id'
          value_found = can_resolve_path(resource, 'id') { |value_in_resource| value_in_resource == value }
          assert value_found, '_id on resource does not match _id requested'

        when 'class'
          value_found = can_resolve_path(resource, 'local_class.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'class on resource does not match class requested'

        when 'date'
          value_found = can_resolve_path(resource, 'period') do |period|
            validate_period_search(value, period)
          end
          assert value_found, 'date on resource does not match date requested'

        when 'identifier'
          value_found = can_resolve_path(resource, 'identifier.value') { |value_in_resource| value_in_resource == value }
          assert value_found, 'identifier on resource does not match identifier requested'

        when 'patient'
          value_found = can_resolve_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found, 'patient on resource does not match patient requested'

        when 'status'
          value_found = can_resolve_path(resource, 'status') { |value_in_resource| value_in_resource == value }
          assert value_found, 'status on resource does not match status requested'

        when 'type'
          value_found = can_resolve_path(resource, 'type.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'type on resource does not match type requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Encounter Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-encounter)

      )

      @resources_found = false

      test 'Server rejects Encounter search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Encounter search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @search_results = {}
        @encounter = reply.try(:resource).try(:entry).try(:first).try(:resource)
        @search_results['patient'] = reply&.resource&.entry&.map { |entry| entry&.resource }
        save_resource_ids_in_bundle(versioned_resource_class('Encounter'), reply)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
      end

      test 'Server returns expected results from Encounter search by _id' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@encounter.nil?, 'Expected valid Encounter resource to be present'

        id_val = resolve_element_from_path(@encounter, 'id')
        search_params = { '_id': id_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
        assert_response_ok(reply)
        @search_results['_id'] = reply&.resource&.entry&.map { |entry| entry&.resource }
      end

      test 'Server returns expected results from Encounter search by date+patient' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@encounter.nil?, 'Expected valid Encounter resource to be present'

        date_val = resolve_element_from_path(@encounter, 'period.start')
        patient_val = @instance.patient_id
        search_params = { 'date': date_val, 'patient': patient_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
        assert_response_ok(reply)
        @search_results['date,patient'] = reply&.resource&.entry&.map { |entry| entry&.resource }

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, date_val)
          comparator_search_params = { 'date': comparator_val, 'patient': patient_val }
          reply = get_resource_by_params(versioned_resource_class('Encounter'), comparator_search_params)
          validate_search_reply(versioned_resource_class('Encounter'), reply, comparator_search_params)
          assert_response_ok(reply)
        end
      end

      test 'Server returns expected results from Encounter search by identifier' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@encounter.nil?, 'Expected valid Encounter resource to be present'

        identifier_val = resolve_element_from_path(@encounter, 'identifier.value')
        search_params = { 'identifier': identifier_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
        assert_response_ok(reply)
        @search_results['identifier'] = reply&.resource&.entry&.map { |entry| entry&.resource }
      end

      test 'Server returns expected results from Encounter search by patient+status' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@encounter.nil?, 'Expected valid Encounter resource to be present'

        patient_val = @instance.patient_id
        status_val = resolve_element_from_path(@encounter, 'status')
        search_params = { 'patient': patient_val, 'status': status_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
        assert_response_ok(reply)
        @search_results['patient,status'] = reply&.resource&.entry&.map { |entry| entry&.resource }
      end

      test 'Server returns expected results from Encounter search by class+patient' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@encounter.nil?, 'Expected valid Encounter resource to be present'

        class_val = resolve_element_from_path(@encounter, 'class.code')
        patient_val = @instance.patient_id
        search_params = { 'class': class_val, 'patient': patient_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
        assert_response_ok(reply)
        @search_results['class,patient'] = reply&.resource&.entry&.map { |entry| entry&.resource }
      end

      test 'Server returns expected results from Encounter search by patient+type' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@encounter.nil?, 'Expected valid Encounter resource to be present'

        patient_val = @instance.patient_id
        type_val = resolve_element_from_path(@encounter, 'type.coding.code')
        search_params = { 'patient': patient_val, 'type': type_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
        assert_response_ok(reply)
        @search_results['patient,type'] = reply&.resource&.entry&.map { |entry| entry&.resource }
      end

      test 'Encounter read resource supported' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Encounter, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@encounter, versioned_resource_class('Encounter'))
      end

      test 'Encounter vread resource supported' do
        metadata do
          id '10'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Encounter, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@encounter, versioned_resource_class('Encounter'))
      end

      test 'Encounter history resource supported' do
        metadata do
          id '11'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Encounter, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@encounter, versioned_resource_class('Encounter'))
      end

      test 'Encounter resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '12'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-encounter.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Encounter')
      end

      test 'At least one of every must support element is provided in any Encounter for this patient.' do
        metadata do
          id '13'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        must_support_confirmed = {}
        must_support_elements = [
          'Encounter.identifier',
          'Encounter.identifier.system',
          'Encounter.identifier.value',
          'Encounter.status',
          'Encounter.local_class',
          'Encounter.type',
          'Encounter.subject',
          'Encounter.participant',
          'Encounter.participant.type',
          'Encounter.participant.period',
          'Encounter.participant.individual',
          'Encounter.period',
          'Encounter.reasonCode',
          'Encounter.hospitalization',
          'Encounter.hospitalization.dischargeDisposition',
          'Encounter.location',
          'Encounter.location.location'
        ]
        must_support_elements.each do |path|
          @search_results.each do |_params, resources|
            resources&.each do |resource|
              truncated_path = path.gsub('Encounter.', '')
              must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
              break if must_support_confirmed[path]
            end
          end

          skip "Could not find #{path} in any of the provided Encounter resource(s)" unless must_support_confirmed[path]
        end
      end

      test 'No results are being filtered. Each resource returned from a ' do
        metadata do
          id '14'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        validate_filters(@search_results)
      end

      test 'All references can be resolved' do
        metadata do
          id '15'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Encounter, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@encounter)
      end
    end
  end
end
