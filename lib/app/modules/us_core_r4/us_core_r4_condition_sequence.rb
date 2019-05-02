module Inferno
  module Sequence
    class USCoreR4ConditionSequence < SequenceBase

      group 'Argonaut Profile Conformance'

      title 'US Core R4 Condition'

      description 'Verify that Condition resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'R4CO'

      requires :token, :patient_id
      conformance_supports :Condition

      def validate_resource_item (resource, property, value)
        case property
        when "patient"
          assert resource&.patient&.reference&.include?(value), "Patient on resource does not match patient requested"
        when "category"
          codings = resource.try(:category).try(:coding)
          assert !codings.nil?, "Category on resource did not match category requested"
          assert codings.any? {|coding| !coding.try(:code).nil? && coding.try(:code) == value}, "Category on resource did not match category requested"
        when "clinicalstatus"
          clinicalstatus = resource&.clinicalStatus
          assert !clinicalstatus.nil? && value.split(',').include?(clinicalstatus), "Clinical status on resource did not match the clinical status requested"
        end
      end

      details %(
        # Background

        The #{title} Sequence tests `#{title.gsub(/\s+/,"")}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [#{title} Argonaut Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-#{title.gsub(/\s+/,"").downcase}.html)

        # Test Methodology

        This test suite accesses the server endpoint at `/#{title.gsub(/\s+/,"")}/?patient={id}` using a `GET` request.
        It parses the #{title} and verifies that it contains:

        * A code representing the status of the #{title}
        * A code representing the #{title}
        * A reference to the patient to whom the #{title} belongs
        * A code representing the category of the #{title}
        * A code representing the verification status

        It collects the following information that is saved in the testing session for use by later tests:

        * List of `#{title.gsub(/\s+/,"")}` resources

        For more information on the #{title}, visit these links:

        * [FHIR DSTU2 #{title}](https://www.hl7.org/fhir/DSTU2/#{title.gsub(/\s+/,"")}.html)
        * [Argonauts #{title} Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-#{title.gsub(/\s+/,"").downcase}.html)
              )

      @resources_found = false

      test 'Server rejects Condition search without authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A Condition search does not work without proper authorization.
          )
          versions :r4
        }

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Condition'), {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test 'Server returns expected results from Condition search by patient' do

        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning a patients conditions list.
          )
          versions :r4
        }



        search_params = {patient: @instance.patient_id}
        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @condition = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('Condition'), reply)

      end

      test 'Server returns expected results from Condition search by patient + clinicalstatus' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            A server SHOULD be capable returning all of a patients active problems and health concerns.
          )
          versions :r4
        }

        skip_if_not_supported(:Condition, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {patient: @instance.patient_id, clinicalstatus: "active,recurrance,remission"}
        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)

      end

      test 'Server returns expected results from Condition search by patient + problem category' do

        metadata {
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            A server SHOULD be capable returning all of a patients problems or all of patients health concerns.

            This test will fail unless the server returns at least one `Condition` in the `problem`
            category for this patient.  This may be the result of data completeness, and not a true
            server error.  However, this test is optionalt wi so a test failure will not affect the overall
            test pass or fail status.
          )
          versions :r4
        }

        skip_if_not_supported(:Condition, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {patient: @instance.patient_id, category: "problem"}
        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)

      end

      test 'Server returns expected results from Condition search by patient + health-concern category' do

        metadata {
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            A server SHOULD be capable returning all of a patients problems or all of patients health concerns.

            This test will fail unless the server returns at least one `Condition` in the `health-concern`
            category for this patient.  This may be the result of data completeness, and not a true
            server error.  However, this test is optional so a test failure will not affect the overall
            test pass or fail status.
          )
          versions :r4
        }

        skip_if_not_supported(:Condition, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {patient: @instance.patient_id, category: "health-concern"}
        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)

      end

      test 'Condition read resource supported' do

        metadata {
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :r4
        }

        skip_if_not_supported(:Condition, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@condition, versioned_resource_class('Condition'))

      end

      test 'Condition history resource supported' do

        metadata {
          id '07'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :r4
        }

        skip_if_not_supported(:Condition, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@condition, versioned_resource_class('Condition'))

      end

      test 'Condition vread resource supported' do

        metadata {
          id '08'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :r4
        }

        skip_if_not_supported(:Condition, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@condition, versioned_resource_class('Condition'))

      end

      test 'Condition resources associated with Patient conform to Argonaut profiles' do

        metadata {
          id '09'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-condition.html'
          desc %(
            Condition resources associated with Patient conform to Argonaut profiles.
          )
          versions :r4
        }
        test_resources_against_profile('Condition')
      end

      test 'All references can be resolved' do

        metadata {
          id '10'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
            All references in the Condition resource should be resolveable.
          )
          versions :r4
        }

        skip_if_not_supported(:Condition, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@condition)

      end

    end

  end
end
