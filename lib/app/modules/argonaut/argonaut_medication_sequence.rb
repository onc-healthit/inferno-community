module Inferno
  module Sequence
    class ArgonautMedicationSequence < SequenceBase

      group 'Argonaut Profile Conformance'

      title 'Medication'

      description 'Verify that Medication resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARMP'

      inactive

      requires :token, :patient_id

      @resources_found = false

      test 'Server rejects MedicationStatement search without authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            An MedicationStatement search does not work without proper authorization.
          )
          versions :dstu2
        }

        skip_if_not_supported(:MedicationStatement, [:search, :read])

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('MedicationStatement'), {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test 'Server returns expected results from MedicationStatement search by patient' do

        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning a patient's medications.
          )
          versions :dstu2
        }

        skip_if_not_supported(:MedicationStatement, [:search, :read])

        reply = get_resource_by_params(versioned_resource_class('MedicationStatement'), {patient: @instance.patient_id})
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count > 0
          @resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @medicationstatement = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('MedicationStatement'), reply)
        save_resource_ids_in_bundle(versioned_resource_class('MedicationStatement'), reply)

      end

      test 'MedicationStatement read resource supported' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        }

        skip_if_not_supported(:MedicationStatement, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@medicationstatement, versioned_resource_class('MedicationStatement'))

      end

      test 'MedicationStatement history resource supported' do

        metadata {
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        }

        skip_if_not_supported(:MedicationStatement, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@medicationstatement, versioned_resource_class('MedicationStatement'))

      end

      test 'MedicationStatement vread resource supported' do

        metadata {
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        }

        skip_if_not_supported(:MedicationStatement, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@medicationstatement, versioned_resource_class('MedicationStatement'))

      end

      test 'Medication resources associated with Patient conform to Argonaut profiles' do

        metadata {
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-medication.html'
          desc %(
            MedicationSatement resources associated with Patient conform to Argonaut profiles.
          )
          versions :dstu2
        }
        test_resources_against_profile('MedicationStatement')
      end

      test 'All references can be resolved' do

        metadata {
          id '07'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
            All references in the MedicationStatement resource should be resolveable.
          )
          versions :dstu2
        }

        skip_if_not_supported(:MedicationStatement, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@medicationstatement)

      end


    end

  end
end
