# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310EncounterSequence < SequenceBase
      title 'Encounter Tests'

      description 'Verify that Encounter resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCE'

      requires :token, :patient_ids
      conformance_supports :Encounter

      def validate_resource_item(resource, property, value)
        case property

        when '_id'
          value_found = resolve_element_from_path(resource, 'id') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, '_id on resource does not match _id requested'

        when 'class'
          value_found = resolve_element_from_path(resource, 'local_class.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'class on resource does not match class requested'

        when 'date'
          value_found = resolve_element_from_path(resource, 'period') { |date| validate_date_search(value, date) }
          assert value_found.present?, 'date on resource does not match date requested'

        when 'identifier'
          value_found = resolve_element_from_path(resource, 'identifier.value') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'identifier on resource does not match identifier requested'

        when 'patient'
          value_found = resolve_element_from_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found.present?, 'patient on resource does not match patient requested'

        when 'status'
          value_found = resolve_element_from_path(resource, 'status') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'status on resource does not match status requested'

        when 'type'
          value_found = resolve_element_from_path(resource, 'type.coding.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'type on resource does not match type requested'

        end
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

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

        skip_if_known_not_supported(:Encounter, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
          assert_response_unauthorized reply
        end

        @client.set_bearer_token(@instance.token)
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

        @encounter_ary = {}
        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          any_resources = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Encounter' }

          next unless any_resources

          @resources_found = true

          @encounter = reply.resource.entry
            .find { |entry| entry&.resource&.resourceType == 'Encounter' }
            .resource
          @encounter_ary[patient] = fetch_all_bundled_resources(reply.resource)
          save_resource_ids_in_bundle(versioned_resource_class('Encounter'), reply)
          save_delayed_sequence_references(@encounter_ary[patient])
          validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
        end

        skip 'No Encounter resources appear to be available. Please use patients with more information.' unless @resources_found
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

        skip 'No Encounter resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            '_id': get_value_for_search_param(resolve_element_from_path(@encounter_ary[patient], 'id'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
          validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
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

        skip 'No Encounter resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'date': get_value_for_search_param(resolve_element_from_path(@encounter_ary[patient], 'period')),
            'patient': patient
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
          validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)

          ['gt', 'lt', 'le', 'ge'].each do |comparator|
            comparator_val = date_comparator_value(comparator, search_params[:date])
            comparator_search_params = { 'date': comparator_val, 'patient': search_params[:patient] }
            reply = get_resource_by_params(versioned_resource_class('Encounter'), comparator_search_params)
            validate_search_reply(versioned_resource_class('Encounter'), reply, comparator_search_params)
          end
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
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

        skip 'No Encounter resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'identifier': get_value_for_search_param(resolve_element_from_path(@encounter_ary[patient], 'identifier'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
          validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
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

        skip 'No Encounter resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'status': get_value_for_search_param(resolve_element_from_path(@encounter_ary[patient], 'status'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
          validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
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

        skip 'No Encounter resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'class': get_value_for_search_param(resolve_element_from_path(@encounter_ary[patient], 'local_class')),
            'patient': patient
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
          validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
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

        skip 'No Encounter resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'type': get_value_for_search_param(resolve_element_from_path(@encounter_ary[patient], 'type'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
          validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :read_interaction do
        metadata do
          id '09'
          name 'Server returns correct Encounter resource from Encounter read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the Encounter read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Encounter, [:read])
        skip 'No Encounter resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@encounter, versioned_resource_class('Encounter'))
      end

      test :vread_interaction do
        metadata do
          id '10'
          name 'Server returns correct Encounter resource from Encounter vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Encounter vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Encounter, [:vread])
        skip 'No Encounter resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@encounter, versioned_resource_class('Encounter'))
      end

      test :history_interaction do
        metadata do
          id '11'
          name 'Server returns correct Encounter resource from Encounter history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Encounter history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Encounter, [:history])
        skip 'No Encounter resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@encounter, versioned_resource_class('Encounter'))
      end

      test 'Server returns Provenance resources from Encounter search by patient + _revIncludes: Provenance:target' do
        metadata do
          id '12'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end

        provenance_results = []
        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          search_params['_revinclude'] = 'Provenance:target'
          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)
          provenance_results += fetch_all_bundled_resources(reply.resource).select { |resource| resource.resourceType == 'Provenance' }
          provenance_results.each { |reference| @instance.save_resource_reference('Provenance', reference.id) }
        end

        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '13'
          name 'Encounter resources returned conform to US Core R4 profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No Encounter resources appear to be available. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Encounter')
      end

      test 'All must support elements are provided in the Encounter resources returned.' do
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

        skip 'No Encounter resources appear to be available. Please use patients with more information.' unless @resources_found

        must_support_elements = [
          { path: 'Encounter.identifier', fixed_value: '' },
          { path: 'Encounter.identifier.system', fixed_value: '' },
          { path: 'Encounter.identifier.value', fixed_value: '' },
          { path: 'Encounter.status', fixed_value: '' },
          { path: 'Encounter.local_class', fixed_value: '' },
          { path: 'Encounter.type', fixed_value: '' },
          { path: 'Encounter.subject', fixed_value: '' },
          { path: 'Encounter.participant', fixed_value: '' },
          { path: 'Encounter.participant.type', fixed_value: '' },
          { path: 'Encounter.participant.period', fixed_value: '' },
          { path: 'Encounter.participant.individual', fixed_value: '' },
          { path: 'Encounter.period', fixed_value: '' },
          { path: 'Encounter.reasonCode', fixed_value: '' },
          { path: 'Encounter.hospitalization', fixed_value: '' },
          { path: 'Encounter.hospitalization.dischargeDisposition', fixed_value: '' },
          { path: 'Encounter.location', fixed_value: '' },
          { path: 'Encounter.location.location', fixed_value: '' }
        ]

        missing_must_support_elements = must_support_elements.reject do |element|
          truncated_path = element[:path].gsub('Encounter.', '')
          @encounter_ary&.any? do |resource|
            value_found = resolve_element_from_path(resource, truncated_path) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@encounter_ary&.values&.flatten&.length} provided Encounter resource(s)"
        @instance.save!
      end

      test 'Every reference within Encounter resource is valid and can be read.' do
        metadata do
          id '15'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Encounter, [:search, :read])
        skip 'No Encounter resources appear to be available. Please use patients with more information.' unless @resources_found

        validated_resources = Set.new
        max_resolutions = 50

        @encounter_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
