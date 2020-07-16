# frozen_string_literal: true

require_relative './data_absent_reason_checker'

module Inferno
  module Sequence
    class USCore310CareteamSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker

      title 'CareTeam Tests'

      description 'Verify that CareTeam resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCCT'

      requires :token
      new_requires :patient_ids
      conformance_supports :CareTeam

      def validate_resource_item(resource, property, value)
        case property

        when 'patient'
          value_found = resolve_element_from_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found.present?, 'patient on resource does not match patient requested'

        when 'status'
          value_found = resolve_element_from_path(resource, 'status') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'status on resource does not match status requested'

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
          assert @instance.server_capabilities.search_documented?('CareTeam'),
                 %(Server returned a status of 400 with an OperationOutcome, but the
                 search interaction for this resource is not documented in the
                 CapabilityStatement. If this response was due to the server
                 requiring a status parameter, the server must document this
                 requirement in its CapabilityStatement.)
        end

        ['proposed,active,suspended,inactive,entered-in-error'].each do |status_value|
          params_with_status = search_param.merge('status': status_value)
          reply = get_resource_by_params(versioned_resource_class('CareTeam'), params_with_status)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          entries = reply.resource.entry.select { |entry| entry.resource.resourceType == 'CareTeam' }
          next if entries.blank?

          search_param.merge!('status': status_value)
          break
        end

        reply
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      def patient_ids
        @instance.get_requirement_value('patient_ids').split(',').map(&:strip)
      end

      @resources_found = false

      test :unauthorized_search do
        metadata do
          id '01'
          name 'Server rejects CareTeam search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_known_not_supported(:CareTeam, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'status': 'proposed'
          }

          reply = get_resource_by_params(versioned_resource_class('CareTeam'), search_params)
          assert_response_unauthorized reply
        end

        @client.set_bearer_token(@instance.token)
      end

      test :search_by_patient_status do
        metadata do
          id '02'
          name 'Server returns expected results from CareTeam search by patient+status'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+status on the CareTeam resource

          )
          versions :r4
        end

        @care_team_ary = {}
        @resources_found = false
        values_found = 0
        status_val = ['proposed', 'active', 'suspended', 'inactive', 'entered-in-error']
        patient_ids.each do |patient|
          @care_team_ary[patient] = []
          status_val.each do |val|
            search_params = { 'patient': patient, 'status': val }
            reply = get_resource_by_params(versioned_resource_class('CareTeam'), search_params)

            assert_response_ok(reply)
            assert_bundle_response(reply)

            next unless reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'CareTeam' }

            @resources_found = true
            @care_team = reply.resource.entry
              .find { |entry| entry&.resource&.resourceType == 'CareTeam' }
              .resource
            @care_team_ary[patient] += fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
            values_found += 1

            save_resource_references(versioned_resource_class('CareTeam'), @care_team_ary[patient])
            save_delayed_sequence_references(@care_team_ary[patient])
            validate_search_reply(versioned_resource_class('CareTeam'), reply, search_params)

            break if values_found == 2
          end
        end
        skip_if_not_found(resource_type: 'CareTeam', delayed: false)
      end

      test :read_interaction do
        metadata do
          id '03'
          name 'Server returns correct CareTeam resource from CareTeam read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the CareTeam read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:CareTeam, [:read])
        skip_if_not_found(resource_type: 'CareTeam', delayed: false)

        validate_read_reply(@care_team, versioned_resource_class('CareTeam'), check_for_data_absent_reasons)
      end

      test :vread_interaction do
        metadata do
          id '04'
          name 'Server returns correct CareTeam resource from CareTeam vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the CareTeam vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:CareTeam, [:vread])
        skip_if_not_found(resource_type: 'CareTeam', delayed: false)

        validate_vread_reply(@care_team, versioned_resource_class('CareTeam'))
      end

      test :history_interaction do
        metadata do
          id '05'
          name 'Server returns correct CareTeam resource from CareTeam history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the CareTeam history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:CareTeam, [:history])
        skip_if_not_found(resource_type: 'CareTeam', delayed: false)

        validate_history_reply(@care_team, versioned_resource_class('CareTeam'))
      end

      test 'Server returns Provenance resources from CareTeam search by patient + status + _revIncludes: Provenance:target' do
        metadata do
          id '06'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end
        skip_if_not_found(resource_type: 'CareTeam', delayed: false)

        could_not_resolve_all = []
        resolved_one = false

        provenance_results = []
        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'status': get_value_for_search_param(resolve_element_from_path(@care_team_ary[patient], 'status'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          search_params['_revinclude'] = 'Provenance:target'
          reply = get_resource_by_params(versioned_resource_class('CareTeam'), search_params)

          assert_response_ok(reply)
          assert_bundle_response(reply)
          provenance_results += fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
            .select { |resource| resource.resourceType == 'Provenance' }
          save_resource_references(versioned_resource_class('Provenance'), provenance_results)
        end
        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '07'
          name 'CareTeam resources returned conform to US Core R4 profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-careteam'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'CareTeam', delayed: false)
        test_resources_against_profile('CareTeam')
      end

      test 'All must support elements are provided in the CareTeam resources returned.' do
        metadata do
          id '08'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all CareTeam resources returned from prior searches to see if any of them provide the following must support elements:

            CareTeam.status

            CareTeam.subject

            CareTeam.participant

            CareTeam.participant.role

            CareTeam.participant.member

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'CareTeam', delayed: false)

        must_support_elements = [
          { path: 'CareTeam.status' },
          { path: 'CareTeam.subject' },
          { path: 'CareTeam.participant' },
          { path: 'CareTeam.participant.role' },
          { path: 'CareTeam.participant.member' }
        ]

        missing_must_support_elements = must_support_elements.reject do |element|
          truncated_path = element[:path].gsub('CareTeam.', '')
          @care_team_ary&.values&.flatten&.any? do |resource|
            value_found = resolve_element_from_path(resource, truncated_path) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@care_team_ary&.values&.flatten&.length} provided CareTeam resource(s)"
        @instance.save!
      end

      test 'The server returns expected results when parameters use composite-or' do
        metadata do
          id '09'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-careteam'
          description %(

          )
          versions :r4
        end

        could_not_resolve_all = []
        resolved_one = false

        found_second_val = false
        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'status': get_value_for_search_param(resolve_element_from_path(@care_team_ary[patient], 'status'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          second_status_val = resolve_element_from_path(@care_team_ary[patient], 'status') { |el| get_value_for_search_param(el) != search_params[:status] }
          next if second_status_val.nil?

          found_second_val = true
          search_params[:status] += ',' + get_value_for_search_param(second_status_val)
          reply = get_resource_by_params(versioned_resource_class('CareTeam'), search_params)
          validate_search_reply(versioned_resource_class('CareTeam'), reply, search_params)
          assert_response_ok(reply)
          resources_returned = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
          missing_values = search_params[:status].split(',').reject do |val|
            resolve_element_from_path(resources_returned, 'status') { |val_found| val_found == val }
          end
          assert missing_values.blank?, "Could not find #{missing_values.join(',')} values from status in any of the resources returned"
        end
        skip 'Cannot find second value for status to perform a multipleOr search' unless found_second_val
      end

      test 'Every reference within CareTeam resource is valid and can be read.' do
        metadata do
          id '10'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_known_not_supported(:CareTeam, [:search, :read])
        skip_if_not_found(resource_type: 'CareTeam', delayed: false)

        validated_resources = Set.new
        max_resolutions = 50

        @care_team_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
