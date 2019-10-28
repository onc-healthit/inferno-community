# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore301CareteamSequence < SequenceBase
      title 'CareTeam Tests'

      description 'Verify that CareTeam resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

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

      test 'Server rejects CareTeam search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
          )
          versions :r4
        end

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = { patient: @instance.patient_id, status: 'active' }

        reply = get_resource_by_params(versioned_resource_class('CareTeam'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from CareTeam search by patient+status' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        search_params = { patient: @instance.patient_id, status: 'active' }

        reply = get_resource_by_params(versioned_resource_class('CareTeam'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @careteam = reply&.resource&.entry&.first&.resource
        @careteam_ary = fetch_all_bundled_resources(reply&.resource)
        save_resource_ids_in_bundle(versioned_resource_class('CareTeam'), reply)
        save_delayed_sequence_references(@careteam_ary)
        validate_search_reply(versioned_resource_class('CareTeam'), reply, search_params)
      end

      test 'CareTeam read resource supported' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:CareTeam, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@careteam, versioned_resource_class('CareTeam'))
      end

      test 'CareTeam vread resource supported' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:CareTeam, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@careteam, versioned_resource_class('CareTeam'))
      end

      test 'CareTeam history resource supported' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:CareTeam, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@careteam, versioned_resource_class('CareTeam'))
      end

      test 'Server returns the appropriate resources from the following _revincludes: Provenance:target' do
        metadata do
          id '06'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
          )
          versions :r4
        end

        search_params = { patient: @instance.patient_id, status: 'active' }

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
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('CareTeam')
      end

      test 'At least one of every must support element is provided in any CareTeam for this patient.' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @careteam_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'CareTeam.status',
          'CareTeam.subject',
          'CareTeam.participant',
          'CareTeam.participant.role',
          'CareTeam.participant.member'
        ]
        must_support_elements.each do |path|
          @careteam_ary&.each do |resource|
            truncated_path = path.gsub('CareTeam.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @careteam_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided CareTeam resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:CareTeam, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@careteam)
      end
    end
  end
end
