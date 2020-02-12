# frozen_string_literal: true

require_relative './data_absent_reason_checker'

module Inferno
  module Sequence
    class USCore310GoalSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker

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

      def perform_search_with_status(reply, search_param)
        begin
          parsed_reply = JSON.parse(reply.body)
          assert parsed_reply['resourceType'] == 'OperationOutcome', 'Server returned a status of 400 without an OperationOutcome.'
        rescue JSON::ParserError
          assert false, 'Server returned a status of 400 without an OperationOutcome.'
        end

        warning do
          assert @instance.server_capabilities.search_documented?('Goal'),
                 %(Server returned a status of 400 with an OperationOutcome, but the
                 search interaction for this resource is not documented in the
                 CapabilityStatement. If this response was due to the server
                 requiring a status parameter, the server must document this
                 requirement in its CapabilityStatement.)
        end

        ['proposed', 'planned', 'accepted', 'active', 'on-hold', 'completed', 'cancelled', 'entered-in-error', 'rejected'].each do |status_value|
          params_with_status = search_param.merge('lifecycle-status': status_value)
          reply = get_resource_by_params(versioned_resource_class('Goal'), params_with_status)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          entries = reply.resource.entry.select { |entry| entry.resource.resourceType == 'Goal' }
          next if entries.blank?

          search_param.merge!('lifecycle-status': status_value)
          break
        end

        reply
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

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          assert_response_ok(reply)
          assert_bundle_response(reply)

          any_resources = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Goal' }

          next unless any_resources

          @goal_ary[patient] = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)

          @goal = @goal_ary[patient]
            .find { |resource| resource.resourceType == 'Goal' }
          @resources_found = @goal.present?

          save_resource_references(versioned_resource_class('Goal'), @goal_ary[patient])
          save_delayed_sequence_references(@goal_ary[patient])
          validate_search_reply(versioned_resource_class('Goal'), reply, search_params)
        end

        skip_if_not_found(resource_type: 'Goal', delayed: false)
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

        skip_if_not_found(resource_type: 'Goal', delayed: false)

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

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('Goal'), reply, search_params)

          ['gt', 'lt', 'le', 'ge'].each do |comparator|
            comparator_val = date_comparator_value(comparator, search_params[:'target-date'])
            comparator_search_params = search_params.merge('target-date': comparator_val)
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

        skip_if_not_found(resource_type: 'Goal', delayed: false)

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
        skip_if_not_found(resource_type: 'Goal', delayed: false)

        validate_read_reply(@goal, versioned_resource_class('Goal'), check_for_data_absent_reasons)
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
        skip_if_not_found(resource_type: 'Goal', delayed: false)

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
        skip_if_not_found(resource_type: 'Goal', delayed: false)

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
        skip_if_not_found(resource_type: 'Goal', delayed: false)
        provenance_results = []
        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          search_params['_revinclude'] = 'Provenance:target'
          reply = get_resource_by_params(versioned_resource_class('Goal'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          assert_response_ok(reply)
          assert_bundle_response(reply)
          provenance_results += fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
            .select { |resource| resource.resourceType == 'Provenance' }
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

        skip_if_not_found(resource_type: 'Goal', delayed: false)
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

            Goal.target.due[x]:dueDate

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Goal', delayed: false)

        must_support_slices = [
          {
            name: 'Goal.target.due[x]:dueDate',
            path: 'Goal.target.due',
            discriminator: {
              type: 'type',
              code: 'Date'
            }
          }
        ]
        missing_slices = must_support_slices.reject do |slice|
          truncated_path = slice[:path].gsub('Goal.', '')
          @goal_ary&.values&.flatten&.any? do |resource|
            slice_found = find_slice(resource, truncated_path, slice[:discriminator])
            slice_found.present?
          end
        end

        must_support_elements = [
          { path: 'Goal.lifecycleStatus' },
          { path: 'Goal.description' },
          { path: 'Goal.subject' },
          { path: 'Goal.target' }
        ]

        missing_must_support_elements = must_support_elements.reject do |element|
          truncated_path = element[:path].gsub('Goal.', '')
          @goal_ary&.values&.flatten&.any? do |resource|
            value_found = resolve_element_from_path(resource, truncated_path) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        missing_must_support_elements += missing_slices.map { |slice| slice[:name] }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@goal_ary&.values&.flatten&.length} provided Goal resource(s)"
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
        skip_if_not_found(resource_type: 'Goal', delayed: false)

        validated_resources = Set.new
        max_resolutions = 50

        @goal_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
