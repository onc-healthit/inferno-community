module Inferno
  module Sequence
    class ArgonautDiagnosticReportSequence < SequenceBase

      group 'Argonaut Profile Conformance'

      title 'Diagnostic Report'

      description 'Verify that DiagnosticReport resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARDR'

      requires :token, :patient_id
      conformance_supports :DiagnosticReport

      test 'Server rejects DiagnosticReport search without authorization' do

        metadata {
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A DiagnosticReport search does not work without proper authorization.
          )
        }

         

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB"})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test 'Server returns expected results from DiagnosticReport search by patient + category' do

        metadata {
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning all of a patient's laboratory diagnostic reports queried by category.
          )
        }

         

        reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB"})
        assert_bundle_response(reply)

        @no_resources_found = false
        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        if resource_count === 0
          @no_resources_found = true
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        @diagnosticreport = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)

      end

      test 'Server returns expected results from DiagnosticReport search by patient + category + date' do

        metadata {
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning all of a patient's laboratory diagnostic reports queried by category code and date range.
          )
        }

         
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        assert !@diagnosticreport.nil?, 'Expected valid DSTU2 DiagnosticReport resource to be present'
        date = @diagnosticreport.try(:effectiveDateTime)
        assert !date.nil?, "DiagnosticReport effectiveDateTime not returned"
        reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB", date: date})
        validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)

      end

      test 'Server returns expected results from DiagnosticReport search by patient + category + code' do

        metadata {
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            A server is capable of returning all of a patient's laboratory diagnostic reports queried by category and code.
          )
        }

         
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        assert !@diagnosticreport.nil?, 'Expected valid DSTU2 DiagnosticReport resource to be present'
        code = @diagnosticreport.try(:code).try(:coding).try(:first).try(:code)
        assert !code.nil?, "DiagnosticReport code not returned"
        reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB", code: code})
        validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)

      end

      test 'Server returns expected results from DiagnosticReport search by patient + category + code' do

        metadata {
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            A server SHOULD be capable of returning all of a patient's laboratory diagnostic reports queried by category and one or more codes and date range.
          )
        }

         
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        assert !@diagnosticreport.nil?, 'Expected valid DSTU2 DiagnosticReport resource to be present'
        code = @diagnosticreport.try(:code).try(:coding).try(:first).try(:code)
        assert !code.nil?, "DiagnosticReport code not returned"
        date = @diagnosticreport.try(:effectiveDateTime)
        assert !date.nil?, "DiagnosticReport effectiveDateTime not returned"
        reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB", code: code, date: date})
        validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)

      end

      test 'DiagnosticReport read resource supported' do

        metadata {
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
        }

         
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_read_reply(@diagnosticreport, FHIR::DSTU2::DiagnosticReport)

      end

      test 'DiagnosticReport history resource supported' do

        metadata {
          id '07'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        }

         
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_history_reply(@diagnosticreport, FHIR::DSTU2::DiagnosticReport)

      end

      test 'DiagnosticReport vread resource supported' do

        metadata {
          id '08'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          desc %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
        }

         
        skip 'No resources appear to be available for this patient. Please use patients with more information.' if @no_resources_found

        validate_vread_reply(@diagnosticreport, FHIR::DSTU2::DiagnosticReport)

      end

      test 'DiagnosticReport resources associated with Patient conform to Argonaut profiles' do

        metadata {
          id '09'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-diagnosticreport.html'
          desc %(
            DiagnosticReport resources associated with Patient conform to Argonaut profiles.
          )
        }
        test_resources_against_profile('DiagnosticReport')

      end

    end

  end
end
