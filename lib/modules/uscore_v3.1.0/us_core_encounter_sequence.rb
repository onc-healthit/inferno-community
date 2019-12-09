# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310EncounterSequence < SequenceBase
      title 'Encounter Tests'

      description 'Verify that Encounter resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCE'

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
          value_found = can_resolve_path(resource, 'period') do |date|
            validate_date_search(value, date)
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
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      @resources_found = false

      test :unauthorized_search do
        metadata do
          id '01'
          name 'Server rejects Encounter search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_not_supported(:Encounter, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test :search_by_patient do
        metadata do
          id '02'
          name 'Server returns expected results from Encounter search by patient'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient on the Encounter resource

          )
          versions :r4
        end

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        @resources_found = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Encounter' }

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @encounter = reply.resource.entry
          .find { |entry| entry&.resource&.resourceType == 'Encounter' }
          .resource
        @encounter_ary = fetch_all_bundled_resources(reply.resource)
        save_resource_ids_in_bundle(versioned_resource_class('Encounter'), reply)
        save_delayed_sequence_references(@encounter_ary)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
      end

      test :search_by__id do
        metadata do
          id '03'
          name 'Server returns expected results from Encounter search by _id'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by _id on the Encounter resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          '_id': get_value_for_search_param(resolve_element_from_path(@encounter_ary, 'id'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
      end

      test :search_by_date_patient do
        metadata do
          id '04'
          name 'Server returns expected results from Encounter search by date+patient'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by date+patient on the Encounter resource

              including support for these date comparators: gt, lt, le, ge
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'date': get_value_for_search_param(resolve_element_from_path(@encounter_ary, 'period')),
          'patient': @instance.patient_id
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)

        ['gt', 'lt', 'le', 'ge'].each do |comparator|
          comparator_val = date_comparator_value(comparator, search_params[:date])
          comparator_search_params = { 'date': comparator_val, 'patient': search_params[:patient] }
          reply = get_resource_by_params(versioned_resource_class('Encounter'), comparator_search_params)
          validate_search_reply(versioned_resource_class('Encounter'), reply, comparator_search_params)
        end
      end

      test :search_by_identifier do
        metadata do
          id '05'
          name 'Server returns expected results from Encounter search by identifier'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by identifier on the Encounter resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'identifier': get_value_for_search_param(resolve_element_from_path(@encounter_ary, 'identifier'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
      end

      test :search_by_patient_status do
        metadata do
          id '06'
          name 'Server returns expected results from Encounter search by patient+status'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+status on the Encounter resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'status': get_value_for_search_param(resolve_element_from_path(@encounter_ary, 'status'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
      end

      test :search_by_class_patient do
        metadata do
          id '07'
          name 'Server returns expected results from Encounter search by class+patient'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by class+patient on the Encounter resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'class': get_value_for_search_param(resolve_element_from_path(@encounter_ary, 'local_class')),
          'patient': @instance.patient_id
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
      end

      test :search_by_patient_type do
        metadata do
          id '08'
          name 'Server returns expected results from Encounter search by patient+type'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+type on the Encounter resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'type': get_value_for_search_param(resolve_element_from_path(@encounter_ary, 'type'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
      end

      test :read_interaction do
        metadata do
          id '09'
          name 'Encounter read interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the Encounter read interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Encounter, [:read])
        skip 'No Encounter resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@encounter, versioned_resource_class('Encounter'))
      end

      test :vread_interaction do
        metadata do
          id '10'
          name 'Encounter vread interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Encounter vread interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Encounter, [:vread])
        skip 'No Encounter resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@encounter, versioned_resource_class('Encounter'))
      end

      test :history_interaction do
        metadata do
          id '11'
          name 'Encounter history interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Encounter history interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Encounter, [:history])
        skip 'No Encounter resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@encounter, versioned_resource_class('Encounter'))
      end

      test 'Server returns the appropriate resources from the following _revincludes: Provenance:target' do
        metadata do
          id '12'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end

        search_params = {
          'patient': @instance.patient_id
        }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
        assert provenance_results, 'No Provenance resources were returned from this search'
      end

      test 'Encounter resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '13'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Encounter')
      end

      test 'At least one of every must support element is provided in any Encounter for this patient.' do
        metadata do
          id '14'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Encounter resources returned from prior searches to see if any of them provide the following must support elements:

            Encounter.identifier

            Encounter.identifier.system

            Encounter.identifier.value

            Encounter.status

            Encounter.class

            Encounter.type

            Encounter.subject

            Encounter.participant

            Encounter.participant.type

            Encounter.participant.period

            Encounter.participant.individual

            Encounter.period

            Encounter.reasonCode

            Encounter.hospitalization

            Encounter.hospitalization.dischargeDisposition

            Encounter.location

            Encounter.location.location

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @encounter_ary&.any?
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
          @encounter_ary&.each do |resource|
            truncated_path = path.gsub('Encounter.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @encounter_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided Encounter resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '15'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
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
