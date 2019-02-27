module Inferno
  module Sequence
    class ArgonautGoalSequence < SequenceBase

      group 'Argonaut Profile Conformance'

      title 'Goal'

      description 'Verify that Goal resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ADQ'

      requires :token, :patient_id
      conformance_supports :Goal

      details %(
        # Background

        The #{title} Sequence tests `#{title.gsub(/\s+/,"")}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [#{title} Argonaut Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-#{title.gsub(/\s+/,"").downcase}.html)

        # Test Methodology

        This test suite accesses the server endpoint at `/#{title.gsub(/\s+/,"")}/?patient={id}` using a `GET` request.
        It parses the #{title} and verifies that it conforms to the profile.

        It collects the following information that is saved in the testing session for use by later tests:

        * List of `#{title.gsub(/\s+/,"")}` resources

        For more information on the #{title}, visit these links:

        * [FHIR DSTU2 #{title}](https://www.hl7.org/fhir/DSTU2/#{title.gsub(/\s+/,"")}.html)
        * [Argonauts #{title} Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-#{title.gsub(/\s+/,"").downcase}.html)
              )

      @resources_found = false

      test 'Server rejects Goal search without authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A Goal search does not work without proper authorization.
          )
          versions :dstu2
        }

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Goal'), {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test 'Server returns expected results from Goal search by patient' do

        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning all of a patient's goals.
          )
          versions :dstu2
        }

        reply = get_resource_by_params(versioned_resource_class('Goal'), {patient: @instance.patient_id})
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @goal = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('Goal'), reply)
        save_resource_ids_in_bundle(versioned_resource_class('Goal'), reply)

      end

      test 'Server returns expected results from Goal search by patient + date' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning all of all of a patient's goals over a specified time period.
          )
          versions :dstu2
        }

        skip_if_not_supported(:Goal, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        assert !@goal.nil?, 'Expected valid Goal resource to be present'
        date = @goal.try(:statusDate) || @goal.try(:targetDate) || @goal.try(:startDate)
        assert !date.nil?, "Goal statusDate, targetDate, nor startDate returned"
        reply = get_resource_by_params(versioned_resource_class('Goal'), {patient: @instance.patient_id, date: date})
        validate_search_reply(versioned_resource_class('Goal'), reply) do |resource|
          date_received = resource.try(:statusDate) || resource.try(:targetDate) || resource.try(:startDate)
          assert !date_received.nil? && date_received == date
        end

      end

      test 'Goal read resource supported' do

        metadata {
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        }

        skip_if_not_supported(:Goal, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@goal, versioned_resource_class('Goal'))

      end

      test 'Goal history resource supported' do

        metadata {
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        }

        skip_if_not_supported(:Goal, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@goal, versioned_resource_class('Goal'))

      end

      test 'Goal vread resource supported' do

        metadata {
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        }

        skip_if_not_supported(:Goal, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@goal, versioned_resource_class('Goal'))

      end

      test 'Goal resources associated with Patient conform to Argonaut profiles' do

        metadata {
          id '07'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-goal.html'
          desc %(
            Goal resources associated with Patient conform to Argonaut profiles.
          )
          versions :dstu2
        }
        test_resources_against_profile('Goal')
      end

      test 'All references can be resolved' do

        metadata {
          id '08'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
            All references in the Goal resource should be resolveable.
          )
          versions :dstu2
        }

        skip_if_not_supported(:Goal, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@goal)

      end


    end

  end
end
