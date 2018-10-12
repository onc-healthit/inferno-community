module Inferno
  module Sequence
    class ArgonautCareTeamSequence < SequenceBase

      group 'Argonaut Profile Conformance'

      title 'Care Team'

      description 'Verify that CareTeam resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARCT'

      requires :token, :patient_id

      @resources_found = false

      test 'Server returns expected CareTeam results from CarePlan search by patient + category' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning all of a patient's Assessment and Plan of Treatment information.
          )
        }

        skip_if_not_supported(:CarePlan, [:search, :read])

        reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "careteam"})
        @careteam = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(FHIR::DSTU2::CarePlan, reply)
        # save_resource_ids_in_bundle(FHIR::DSTU2::CarePlan, reply)

      end

      test 'CareTeam resources associated with Patient conform to Argonaut profiles' do

        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careteam.html'
          desc %(
            CareTeam resources associated with Patient conform to Argonaut profiles.
          )
        }
        test_resources_against_profile('CarePlan', Inferno::ValidationUtil::CARE_TEAM_URL)
        skip_unless @profiles_encountered.include?(Inferno::ValidationUtil::CARE_TEAM_URL), 'No CareTeams found.'
        assert !@profiles_failed.include?(Inferno::ValidationUtil::CARE_TEAM_URL), "CareTeams failed validation.<br/>#{@profiles_failed[Inferno::ValidationUtil::CARE_TEAM_URL]}"
      end

      test 'All references can be resolved' do

        metadata {
          id '03'
          link ''
          desc %(
            All references in the CareTeam resource should be resolveable.
          )
        }

        skip_if_not_supported(:CareTeam, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@careteam)

      end

    end

  end
end
