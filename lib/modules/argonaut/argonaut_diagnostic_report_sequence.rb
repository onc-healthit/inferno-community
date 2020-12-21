# frozen_string_literal: true

module Inferno
  module Sequence
    class ArgonautDiagnosticReportSequence < SequenceBase
      group 'Argonaut Profile Conformance'

      title 'Diagnostic Report'

      description 'Verify that DiagnosticReport resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'ARDR'

      requires :token, :patient_id
      conformance_supports :DiagnosticReport

      def validate_resource_item(resource, property, value)
        case property
        when 'patient'
          assert resource.subject&.reference&.include?(value), 'Subject on resource does not match patient requested'
        when 'category'
          codings = resource.try(:category).try(:coding)
          assert !codings.nil?, 'Category on resource did not match category requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'Category on resource did not match category requested'
        when 'date'
          # todo
        when 'code'
          codings = resource.try(:code).try(:coding)
          assert !codings.nil?, 'Code on resource did not match code requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'Code on resource did not match code requested'
        end
      end

      details %(
        # Background

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [#{title} Argonaut Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-#{title.gsub(/\s+/, '').downcase}.html)

        # Test Methodology

        This test suite accesses the server endpoint at `/#{title.gsub(/\s+/, '')}/?category=LAB&patient={id}` using a `GET` request.
        It parses the #{title} and verifies that it conforms to the profile.

        It collects the following information that is saved in the testing session for use by later tests:

        * List of `#{title.gsub(/\s+/, '')}` resources

        For more information on the #{title}, visit these links:

        * [FHIR DSTU2 #{title}](https://www.hl7.org/fhir/DSTU2/#{title.gsub(/\s+/, '')}.html)
        * [Argonauts #{title} Profile](https://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-#{title.gsub(/\s+/, '').downcase}.html)
              )

      @resources_found = false

      test 'Server rejects DiagnosticReport search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            A DiagnosticReport search does not work without proper authorization.
          )
          versions :dstu2
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), patient: @instance.patient_id, category: 'LAB')
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from DiagnosticReport search by patient + category' do
        metadata do
          id '02'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            A server is capable of returning all of a patient's laboratory diagnostic reports queried by category.
          )
          versions :dstu2
        end

        search_params = { patient: @instance.patient_id, category: 'LAB' }
        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @diagnosticreport = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('DiagnosticReport'), reply)
      end

      test 'Server returns expected results from DiagnosticReport search by patient + category + date' do
        metadata do
          id '03'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            A server is capable of returning all of a patient's laboratory diagnostic reports queried by category code and date range.
          )
          versions :dstu2
        end

        skip_if_not_supported(:DiagnosticReport, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        assert !@diagnosticreport.nil?, 'Expected valid DiagnosticReport resource to be present'
        date = @diagnosticreport.try(:effectiveDateTime)
        assert !date.nil?, 'DiagnosticReport effectiveDateTime not returned'
        search_params = { patient: @instance.patient_id, category: 'LAB', date: date }
        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
      end

      test 'Server returns expected results from DiagnosticReport search by patient + category + code' do
        metadata do
          id '04'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            A server is capable of returning all of a patient's laboratory diagnostic reports queried by category and code.
          )
          versions :dstu2
        end
        skip_if_not_supported(:DiagnosticReport, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        assert !@diagnosticreport.nil?, 'Expected valid DiagnosticReport resource to be present'
        code = @diagnosticreport.try(:code).try(:coding).try(:first).try(:code)
        assert !code.nil?, 'DiagnosticReport code not returned'
        search_params = { patient: @instance.patient_id, category: 'LAB', code: code }
        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
      end

      test 'Server returns expected results from DiagnosticReport search by patient + category + code + date' do
        metadata do
          id '05'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          description %(
            A server SHOULD be capable of returning all of a patient's laboratory diagnostic reports queried by category and one or more codes and date range.
          )
          versions :dstu2
        end

        skip_if_not_supported(:DiagnosticReport, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        assert !@diagnosticreport.nil?, 'Expected valid DiagnosticReport resource to be present'
        code = @diagnosticreport.try(:code).try(:coding).try(:first).try(:code)
        assert !code.nil?, 'DiagnosticReport code not returned'
        date = @diagnosticreport.try(:effectiveDateTime)
        assert !date.nil?, 'DiagnosticReport effectiveDateTime not returned'
        search_params = { patient: @instance.patient_id, category: 'LAB', code: code, date: date }
        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
      end

      test 'DiagnosticReport read resource supported' do
        metadata do
          id '06'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
            All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        end

        skip_if_not_supported(:DiagnosticReport, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@diagnosticreport, versioned_resource_class('DiagnosticReport'))
      end

      test 'DiagnosticReport history resource supported' do
        metadata do
          id '07'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          description %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        end

        skip_if_not_supported(:DiagnosticReport, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@diagnosticreport, versioned_resource_class('DiagnosticReport'))
      end

      test 'DiagnosticReport vread resource supported' do
        metadata do
          id '08'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          optional
          description %(
            All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.
          )
          versions :dstu2
        end

        skip_if_not_supported(:DiagnosticReport, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@diagnosticreport, versioned_resource_class('DiagnosticReport'))
      end

      test 'DiagnosticReport resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '09'
          link 'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-diagnosticreport.html'
          description %(
            DiagnosticReport resources associated with Patient conform to Argonaut profiles.
          )
          versions :dstu2
        end
        test_resources_against_profile('DiagnosticReport')
      end

      test 'All references can be resolved' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          description %(
            All references in the DiagnosticReport resource should be resolveable.
          )
          versions :dstu2
        end

        skip_if_not_supported(:DiagnosticReport, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@diagnosticreport)
      end
    end
  end
end
