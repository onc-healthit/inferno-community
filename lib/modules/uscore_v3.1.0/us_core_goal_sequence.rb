# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310GoalSequence < SequenceBase
      title 'Goal Tests'

      description 'Verify that Goal resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCG'

      requires :token, :patient_ids
      conformance_supports :Goal

      def validate_resource_item(resource, property, value)
        case property

        when 'lifecycle-status'
          value_found = resolve_element_from_path(resource, 'lifecycleStatus') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'lifecycle-status on resource does not match lifecycle-status requested'

        when 'patient'
          value_found = resolve_element_from_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found.present?, 'patient on resource does not match patient requested'

        when 'target-date'
          value_found = resolve_element_from_path(resource, 'target.dueDate') { |date| validate_date_search(value, date) }
          assert value_found.present?, 'target-date on resource does not match target-date requested'

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
          name 'Server rejects Goal search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Goal, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          reply = get_resource_by_params(versioned_resource_class('Goal'), search_params)
          assert_response_unauthorized reply
        end

        @client.set_bearer_token(@instance.token)
      end

      test :search_by_patient do
        metadata do
          id '02'
          name 'Server returns expected results from Goal search by patient'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient on the Goal resource

          )
          versions :r4
        end

        @goal_ary = {}
        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          reply = get_resource_by_params(versioned_resource_class('Goal'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          any_resources = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Goal' }

          next unless any_resources

          @resources_found = true

          @goal = reply.resource.entry
            .find { |entry| entry&.resource&.resourceType == 'Goal' }
            .resource
          @goal_ary[patient] = fetch_all_bundled_resources(reply.resource)
          save_resource_ids_in_bundle(versioned_resource_class('Goal'), reply)
          save_delayed_sequence_references(@goal_ary[patient])
          validate_search_reply(versioned_resource_class('Goal'), reply, search_params)
        end

        skip 'No Goal resources appear to be available. Please use patients with more information.' unless @resources_found
      end

      test :search_by_patient_target_date do
        metadata do
          id '03'
          name 'Server returns expected results from Goal search by patient+target-date'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+target-date on the Goal resource

              including support for these target-date comparators: gt, lt, le, ge
          )
          versions :r4
        end

        skip 'No Goal resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'target-date': get_value_for_search_param(resolve_element_from_path(@goal_ary[patient], 'target.dueDate'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Goal'), search_params)
          validate_search_reply(versioned_resource_class('Goal'), reply, search_params)

          ['gt', 'lt', 'le', 'ge'].each do |comparator|
            comparator_val = date_comparator_value(comparator, search_params[:'target-date'])
            comparator_search_params = { 'patient': search_params[:patient], 'target-date': comparator_val }
            reply = get_resource_by_params(versioned_resource_class('Goal'), comparator_search_params)
            validate_search_reply(versioned_resource_class('Goal'), reply, comparator_search_params)
          end
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :search_by_patient_lifecycle_status do
        metadata do
          id '04'
          name 'Server returns expected results from Goal search by patient+lifecycle-status'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+lifecycle-status on the Goal resource

          )
          versions :r4
        end

        skip 'No Goal resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'lifecycle-status': get_value_for_search_param(resolve_element_from_path(@goal_ary[patient], 'lifecycleStatus'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Goal'), search_params)
          validate_search_reply(versioned_resource_class('Goal'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :read_interaction do
        metadata do
          id '05'
          name 'Server returns correct Goal resource from Goal read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the Goal read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Goal, [:read])
        skip 'No Goal resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@goal, versioned_resource_class('Goal'))
      end

      test :vread_interaction do
        metadata do
          id '06'
          name 'Server returns correct Goal resource from Goal vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Goal vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Goal, [:vread])
        skip 'No Goal resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@goal, versioned_resource_class('Goal'))
      end

      test :history_interaction do
        metadata do
          id '07'
          name 'Server returns correct Goal resource from Goal history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Goal history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Goal, [:history])
        skip 'No Goal resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@goal, versioned_resource_class('Goal'))
      end

      test 'Server returns Provenance resources from Goal search by patient + _revIncludes: Provenance:target' do
        metadata do
          id '08'
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
          reply = get_resource_by_params(versioned_resource_class('Goal'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)
          provenance_results += fetch_all_bundled_resources(reply.resource).select { |resource| resource.resourceType == 'Provenance' }
          provenance_results.each { |reference| @instance.save_resource_reference('Provenance', reference.id) }
        end

        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '09'
          name 'Goal resources returned conform to US Core R4 profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-goal'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No Goal resources appear to be available. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Goal')
      end

      test 'All must support elements are provided in the Goal resources returned.' do
        metadata do
          id '10'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Goal resources returned from prior searches to see if any of them provide the following must support elements:

            Goal.lifecycleStatus

            Goal.description

            Goal.subject

            Goal.target

            Goal.target.dueDate

          )
          versions :r4
        end

        skip 'No Goal resources appear to be available. Please use patients with more information.' unless @resources_found

        must_support_elements = [
          'Goal.lifecycleStatus',
          'Goal.description',
          'Goal.subject',
          'Goal.target',
          'Goal.target.dueDate'
        ]

        missing_must_support_elements = must_support_elements.reject do |path|
          truncated_path = path.gsub('Goal.', '')
          @goal_aryy&.values&.flatten&.any? do |resource|
            resolve_element_from_path(resource, truncated_path).present?
          end
        end

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@goal_aryy&.values&.flatten&.length} provided Goal resource(s)"
        @instance.save!
      end

      test 'Every reference within Goal resource is valid and can be read.' do
        metadata do
          id '11'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Goal, [:search, :read])
        skip 'No Goal resources appear to be available. Please use patients with more information.' unless @resources_found

        @goal_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource)
        end
      end
    end
  end
end
