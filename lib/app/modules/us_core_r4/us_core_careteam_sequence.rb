# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4CareteamSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Careteam Tests'

      description 'Verify that CareTeam resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'CareTeam' # change me

      requires :token, :patient_id
      conformance_supports :CareTeam

      def validate_resource_item(resource, property, value)
        case property

        when 'patient'
          assert resource&.subject&.reference&.include?(value), 'patient on resource does not match patient requested'

        when 'status'
          assert resource&.status == value, 'status on resource did not match status requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Careteam Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-careteam)

      )

      @resources_found = false

      test 'Server rejects CareTeam search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('CareTeam'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from CareTeam search by patient+status' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
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

        @careteam = reply.try(:resource).try(:entry).try(:first).try(:resource)
        @careteam_ary = reply&.resource&.entry&.map { |entry| entry&.resource }
        validate_search_reply(versioned_resource_class('CareTeam'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('CareTeam'), reply)
      end

      test 'CareTeam read resource supported' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
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
          desc %(
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
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:CareTeam, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@careteam, versioned_resource_class('CareTeam'))
      end

      test 'CareTeam resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-careteam.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('CareTeam')
      end

      test 'At least one of every must support element is provided in any CareTeam for this patient.' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
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
          id '08'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
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
