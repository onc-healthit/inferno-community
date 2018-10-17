module Inferno
  module Sequence
    class ArgonautCarePlanSequence < SequenceBase

      group 'Argonaut Profile Conformance'

      title 'Care Plan'

      description 'Verify that CarePlan resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARCP'

      requires :token, :patient_id
      conformance_supports :CarePlan

      test 'Server rejects CarePlan search without authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A CarePlan search does not work without proper authorization.
          )
        }

        skip_if_not_supported(:CarePlan, [:search, :read])
        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan"})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test 'Server returns expected results from CarePlan search by patient + category' do

        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning all of a patient's Assessment and Plan of Treatment information.
          )
        }

        skip_if_not_supported(:CarePlan, [:search, :read])

        reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan"})
        assert_bundle_response(reply)

        @no_resources_found = false
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count === 0
          @no_resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @careplan = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(FHIR::DSTU2::CarePlan, reply)
        save_resource_ids_in_bundle(FHIR::DSTU2::CarePlan, reply)

      end

      test 'Server returns expected results from CarePlan search by patient + category + date' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            A server SHOULD be capable of returning a patient's Assessment and Plan of Treatment information over a specified time period.
          )
        }

        skip_if_not_supported(:CarePlan, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        assert !@careplan.nil?, 'Expected valid DSTU2 CarePlan resource to be present'

        date = @careplan.try(:period).try(:start)
        assert !date.nil?, "CarePlan period not returned"
        reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan", date: date})
        validate_search_reply(FHIR::DSTU2::CarePlan, reply)

      end

      test 'Server returns expected results from CarePlan search by patient + category + status' do

        metadata {
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            A server SHOULD be capable returning all of a patient's active Assessment and Plan of Treatment information.
          )
        }

        skip_if_not_supported(:CarePlan, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan", status: "active"})
        validate_search_reply(FHIR::DSTU2::CarePlan, reply)

      end

      test 'Server returns expected results from CarePlan search by patient + category + status + date' do

        metadata {
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            A server SHOULD be capable returning a patient's active Assessment and Plan of Treatment information over a specified time period.
          )
        }

        skip_if_not_supported(:CarePlan, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        assert !@careplan.nil?, 'Expected valid DSTU2 CarePlan resource to be present'
        date = @careplan.try(:period).try(:start)
        assert !date.nil?, "CarePlan period not returned"
        reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan", status: "active", date: date})
        validate_search_reply(FHIR::DSTU2::CarePlan, reply)

      end

      test 'Server returns expected results from CarePlan read resource' do

        metadata {
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:CarePlan, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_read_reply(@careplan, FHIR::DSTU2::CarePlan)

      end

      test 'Careplan history resource supported' do

        metadata {
          id '07'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:CarePlan, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_history_reply(@careplan, FHIR::DSTU2::CarePlan)

      end

      test 'CarePlan vread resource supported' do

        metadata {
          id '08'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        }

        skip_if_not_supported(:CarePlan, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_vread_reply(@careplan, FHIR::DSTU2::CarePlan)

      end

      test 'CarePlan vread resource supported' do

        metadata {
          id '09'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careplan.html'
          desc %(
            CarePlan resources associated with Patient conform to Argonaut profiles.
          )
        }
        test_resources_against_profile('CarePlan', Inferno::ValidationUtil::CARE_PLAN_URL)
        skip_unless @profiles_encountered.include?(Inferno::ValidationUtil::CARE_PLAN_URL), 'No CarePlans found.'
        assert !@profiles_failed.include?(Inferno::ValidationUtil::CARE_PLAN_URL), "CarePlans failed validation.<br/>#{@profiles_failed[Inferno::ValidationUtil::CARE_PLAN_URL]}"
      end

    end

  end
end
