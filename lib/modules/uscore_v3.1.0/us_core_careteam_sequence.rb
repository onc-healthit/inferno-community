# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310CareteamSequence < SequenceBase
      title 'CareTeam Tests'

      description 'Verify that CareTeam resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCCT'

      requires :token, :patient_id
      conformance_supports :CareTeam

      def validate_resource_item(resource, property, value)
        case property

        when 'patient'
          value_found = can_resolve_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found, 'patient on resource does not match patient requested'

        when 'status'
          value_found = can_resolve_path(resource, 'status') { |value_in_resource| value_in_resource == value }
          assert value_found, 'status on resource does not match status requested'

        end
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

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

        skip_if_not_supported(:CareTeam, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = {
          'patient': @instance.patient_id,
          'status': 'proposed'
        }

        reply = get_resource_by_params(versioned_resource_class('CareTeam'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from CareTeam search by patient+status' do
        metadata do
          id '02'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+status on the CareTeam resource

          )
          versions :r4
        end

        status_val = ['proposed', 'active', 'suspended', 'inactive', 'entered-in-error']
        status_val.each do |val|
          search_params = { 'patient': @instance.patient_id, 'status': val }
          reply = get_resource_by_params(versioned_resource_class('CareTeam'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          resource_count = reply&.resource&.entry&.length || 0
          @resources_found = true if resource_count.positive?
          next unless @resources_found

          @care_team = reply&.resource&.entry&.first&.resource
          @care_team_ary = fetch_all_bundled_resources(reply&.resource)

          save_resource_ids_in_bundle(versioned_resource_class('CareTeam'), reply)
          save_delayed_sequence_references(@care_team_ary)
          validate_search_reply(versioned_resource_class('CareTeam'), reply, search_params)
          break
        end
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
      end

      test :read_interaction do
        metadata do
          id '03'
          name 'CareTeam read interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the CareTeam read interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:CareTeam, [:read])
        skip 'No CareTeam resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@care_team, versioned_resource_class('CareTeam'))
      end

      test :vread_interaction do
        metadata do
          id '04'
          name 'CareTeam vread interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the CareTeam vread interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:CareTeam, [:vread])
        skip 'No CareTeam resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@care_team, versioned_resource_class('CareTeam'))
      end

      test :history_interaction do
        metadata do
          id '05'
          name 'CareTeam history interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the CareTeam history interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:CareTeam, [:history])
        skip 'No CareTeam resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@care_team, versioned_resource_class('CareTeam'))
      end

      test 'Server returns the appropriate resources from the following _revincludes: Provenance:target' do
        metadata do
          id '06'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end

        search_params = {
          'patient': @instance.patient_id,
          'status': get_value_for_search_param(resolve_element_from_path(@care_team_ary, 'status'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('CareTeam'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
        assert provenance_results, 'No Provenance resources were returned from this search'
      end

      test 'CareTeam resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '07'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-careteam'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('CareTeam')
      end

      test 'At least one of every must support element is provided in any CareTeam for this patient.' do
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

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @care_team_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'CareTeam.status',
          'CareTeam.subject',
          'CareTeam.participant',
          'CareTeam.participant.role',
          'CareTeam.participant.member'
        ]
        must_support_elements.each do |path|
          @care_team_ary&.each do |resource|
            truncated_path = path.gsub('CareTeam.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @care_team_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided CareTeam resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '09'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_not_supported(:CareTeam, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@care_team)
      end
    end
  end
end
