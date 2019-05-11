module Inferno
  module Sequence
    class USCoreR4CarePlanSequence < SequenceBase

      group 'US Core R4 Profile Conformance'

      title 'US Core R4 Care Plan'

      description 'Verify that CarePlan resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'R4CP'

      requires :token, :patient_id
      conformance_supports :CarePlan

      def validate_resource_item (resource, property, value)
        case property
        when "patient"
          assert (resource.subject && resource.subject.reference.include?(value)), "Subject on resource does not match patient requested"
        when "category"
          categories = resource.try(:category)
          assert !categories.nil? && categories.length > 0, "Category on resource did not match category requested"
          categories.each do |category|
            codings = category.try(:coding)
            assert !codings.nil?, "Category on resource did not match category requested"
            assert codings.any? {|coding| !coding.try(:code).nil? && coding.try(:code) == value}, "Category on resource did not match category requested"
          end
        when "date"
          # todo
        when "status"
          status = resource.try(:status)
          assert !status.nil? && status == value, "Status on resource did not match status requested"
        end
      end

      details %(

        CarePlan profile requirements from [US Core R4 Server Capability Statement](http://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-r4-server.html#encounter).

        Search requirements (as of 1 May 19):

        | Conformance | Parameter                          | Type                     | Modifiers                         |
        |-------------|------------------------------------|--------------------------|-----------------------------------|
        | SHALL       | patient + category                 | reference + token        |                                   |
        | SHALL       | patient + category + date          | reference + token + date | date modifiers‘ge’,‘le’,’gt’,’lt’ |
        | SHOULD      | patient + category + status        | reference + token        |                                   |
        | SHOULD      | patient + category + date + status | reference + token + date | date modifiers‘ge’,‘le’,’gt’,’lt’ |

        Note: Terminology validation currently disabled.

        TODO:
        * Validating responses are between correct dates
        * date modifiers
     
              )

      @resources_found = false

      test 'Server rejects CarePlan search without authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A CarePlan search does not work without proper authorization.
          )
          versions :r4
        }


        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('CarePlan'), {patient: @instance.patient_id, category: "assess-plan"})
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
          optional
          versions :r4
        }



        search_params = {patient: @instance.patient_id, category: "assess-plan"}
        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @careplan = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('CarePlan'), reply)

      end

      test 'Server returns expected results from CarePlan search by patient + category + date' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            A server SHOULD be capable of returning a patient's Assessment and Plan of Treatment information over a specified time period.
          )
          versions :r4
        }

        skip_if_not_supported(:CarePlan, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        assert !@careplan.nil?, 'Expected valid CarePlan resource to be present'

        date = @careplan.try(:period).try(:start)
        assert !date.nil?, "CarePlan period not returned"
        search_params = {patient: @instance.patient_id, category: "assess-plan", date: date}
        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)

      end

      test 'Server returns expected results from CarePlan search by patient + category + status' do

        metadata {
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            A server SHOULD be capable returning all of a patient's active Assessment and Plan of Treatment information.
          )
          versions :r4
        }

        skip_if_not_supported(:CarePlan, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {patient: @instance.patient_id, category: "assess-plan", status: "active"}
        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)

      end

      test 'Server returns expected results from CarePlan search by patient + category + status + date' do

        metadata {
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            A server SHOULD be capable returning a patient's active Assessment and Plan of Treatment information over a specified time period.
          )
          versions :r4
        }

        skip_if_not_supported(:CarePlan, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        assert !@careplan.nil?, 'Expected valid CarePlan resource to be present'
        date = @careplan.try(:period).try(:start)
        assert !date.nil?, "CarePlan period not returned"
        search_params = {patient: @instance.patient_id, category: "assess-plan", status: "active", date: date}
        reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
        validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)

      end

      test 'Server returns expected results from CarePlan read resource' do

        metadata {
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :r4
        }

        skip_if_not_supported(:CarePlan, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@careplan, versioned_resource_class('CarePlan'))

      end

      test 'Careplan history resource supported' do

        metadata {
          id '07'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :r4
        }

        skip_if_not_supported(:CarePlan, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@careplan, versioned_resource_class('CarePlan'))

      end

      test 'CarePlan vread resource supported' do

        metadata {
          id '08'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :r4
        }

        skip_if_not_supported(:CarePlan, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@careplan, versioned_resource_class('CarePlan'))

      end

      test 'CarePlan resources associated with Patient conform to Argonaut profiles' do

        metadata {
          id '09'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-careplan.html'
          desc %(
            CarePlan resources associated with Patient conform to Argonaut profiles.
          )
          versions :r4
        }
        test_resources_against_profile('CarePlan')
      end

      test 'All references can be resolved' do

        metadata {
          id '10'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
            All references in the CarePlan resource should be resolveable.
          )
          versions :r4
        }

        skip_if_not_supported(:CarePlan, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@careplan)

      end

    end

  end
end
