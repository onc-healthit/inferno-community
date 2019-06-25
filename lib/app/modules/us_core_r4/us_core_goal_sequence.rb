# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4GoalSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Goal Tests'

      description 'Verify that Goal resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Goal' # change me

      requires :token, :patient_id
      conformance_supports :Goal

      def validate_resource_item(resource, property, value)
        case property

        when 'lifecycle-status'
          assert resource&.lifecycleStatus == value, 'lifecycle-status on resource did not match lifecycle-status requested'

        when 'patient'
          assert resource&.subject&.reference&.include?(value), 'patient on resource does not match patient requested'

        when 'target-date'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Goal Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-goal)

      )

      @resources_found = false

      test 'Server rejects Goal search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Goal'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Goal search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }

        reply = get_resource_by_params(versioned_resource_class('Goal'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @goal = reply.try(:resource).try(:entry).try(:first).try(:resource)
        @goal_ary = reply&.resource&.entry&.map { |entry| entry&.resource }
        validate_search_reply(versioned_resource_class('Goal'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('Goal'), reply)
      end

      test 'Server returns expected results from Goal search by patient+target-date' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@goal.nil?, 'Expected valid Goal resource to be present'

        patient_val = @instance.patient_id
        target_date_val = @goal&.target&.first&.dueDate
        search_params = { 'patient': patient_val, 'target-date': target_date_val }

        reply = get_resource_by_params(versioned_resource_class('Goal'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Goal search by patient+lifecycle-status' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@goal.nil?, 'Expected valid Goal resource to be present'

        patient_val = @instance.patient_id
        lifecycle_status_val = @goal&.lifecycleStatus
        search_params = { 'patient': patient_val, 'lifecycle-status': lifecycle_status_val }

        reply = get_resource_by_params(versioned_resource_class('Goal'), search_params)
        assert_response_ok(reply)
      end

      test 'Goal read resource supported' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Goal, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@goal, versioned_resource_class('Goal'))
      end

      test 'Goal vread resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Goal, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@goal, versioned_resource_class('Goal'))
      end

      test 'Goal history resource supported' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Goal, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@goal, versioned_resource_class('Goal'))
      end

      test 'Demonstrates that the server can supply must supported elements' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @goal_ary&.any?
        must_support_elements = [
          'Goal.lifecycleStatus',
          'Goal.description',
          'Goal.subject',
          'Goal.target',
          'Goal.target.duedate',
          'Goal.target.dueDuration'
        ]
        must_support_elements.each do |path|
          @goal_ary&.each do |resource|
            truncated_path = path.gsub('Goal.', '')
            already_found = @instance.must_support_confirmed.include?(path)
            element_found = already_found || can_resolve_path(resource, truncated_path)
            skip "Could not find #{path} in the provided resource" unless element_found
            @instance.must_support_confirmed += "#{path}," unless already_found
          end
        end
        @instance.save!
      end

      test 'Goal resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-goal.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Goal')
      end

      test 'All references can be resolved' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Goal, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@goal)
      end
    end
  end
end
