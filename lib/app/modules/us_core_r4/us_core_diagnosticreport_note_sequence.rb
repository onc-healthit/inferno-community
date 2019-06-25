# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4DiagnosticreportNoteSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'DiagnosticreportNote Tests'

      description 'Verify that DiagnosticReport resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'DiagnosticReport' # change me

      requires :token, :patient_id
      conformance_supports :DiagnosticReport

      def validate_resource_item(resource, property, value)
        case property

        when 'status'
          assert resource&.status == value, 'status on resource did not match status requested'

        when 'patient'
          assert resource&.subject&.reference&.include?(value), 'patient on resource does not match patient requested'

        when 'category'
          codings = resource&.category&.first&.coding
          assert !codings.nil?, 'category on resource did not match category requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'category on resource did not match category requested'

        when 'code'
          codings = resource&.code&.coding
          assert !codings.nil?, 'code on resource did not match code requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'code on resource did not match code requested'

        when 'date'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [DiagnosticreportNote Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-diagnosticreport-note)

      )

      @resources_found = false

      test 'Server rejects DiagnosticReport search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from DiagnosticReport search by patient+category' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        search_params = { patient: @instance.patient_id, code: 'LP29684-5' }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @diagnosticreport = reply.try(:resource).try(:entry).try(:first).try(:resource)
        @diagnosticreport_ary = reply&.resource&.entry&.map { |entry| entry&.resource }
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('DiagnosticReport'), reply)
      end

      test 'Server returns expected results from DiagnosticReport search by patient+code' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@diagnosticreport.nil?, 'Expected valid DiagnosticReport resource to be present'

        patient_val = @instance.patient_id
        code_val = @diagnosticreport&.code&.coding&.first&.code
        search_params = { 'patient': patient_val, 'code': code_val }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DiagnosticReport search by patient+category+date' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@diagnosticreport.nil?, 'Expected valid DiagnosticReport resource to be present'

        patient_val = @instance.patient_id
        category_val = @diagnosticreport&.category&.first&.coding&.first&.code
        date_val = @diagnosticreport&.effectiveDateTime
        search_params = { 'patient': patient_val, 'category': category_val, 'date': date_val }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DiagnosticReport search by patient+code+date' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@diagnosticreport.nil?, 'Expected valid DiagnosticReport resource to be present'

        patient_val = @instance.patient_id
        code_val = @diagnosticreport&.code&.coding&.first&.code
        date_val = @diagnosticreport&.effectiveDateTime
        search_params = { 'patient': patient_val, 'code': code_val, 'date': date_val }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DiagnosticReport search by patient+status' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@diagnosticreport.nil?, 'Expected valid DiagnosticReport resource to be present'

        patient_val = @instance.patient_id
        status_val = @diagnosticreport&.status
        search_params = { 'patient': patient_val, 'status': status_val }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DiagnosticReport search by patient+category' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@diagnosticreport.nil?, 'Expected valid DiagnosticReport resource to be present'

        search_params = { patient: @instance.patient_id, code: 'LP29684-5' }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DiagnosticReport search by patient+category+date' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@diagnosticreport.nil?, 'Expected valid DiagnosticReport resource to be present'

        patient_val = @instance.patient_id
        category_val = @diagnosticreport&.category&.first&.coding&.first&.code
        date_val = @diagnosticreport&.effectiveDateTime
        search_params = { 'patient': patient_val, 'category': category_val, 'date': date_val }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        assert_response_ok(reply)
      end

      test 'DiagnosticReport create resource supported' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:DiagnosticReport, [:create])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_create_reply(@diagnosticreport, versioned_resource_class('DiagnosticReport'))
      end

      test 'DiagnosticReport read resource supported' do
        metadata do
          id '10'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:DiagnosticReport, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@diagnosticreport, versioned_resource_class('DiagnosticReport'))
      end

      test 'DiagnosticReport vread resource supported' do
        metadata do
          id '11'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:DiagnosticReport, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@diagnosticreport, versioned_resource_class('DiagnosticReport'))
      end

      test 'DiagnosticReport history resource supported' do
        metadata do
          id '12'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:DiagnosticReport, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@diagnosticreport, versioned_resource_class('DiagnosticReport'))
      end

      test 'Demonstrates that the server can supply must supported elements' do
        metadata do
          id '13'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @diagnosticreport_ary&.any?
        must_support_elements = [
          'DiagnosticReport.status',
          'DiagnosticReport.category',
          'DiagnosticReport.code',
          'DiagnosticReport.subject',
          'DiagnosticReport.encounter',
          'DiagnosticReport.effectivedateTime',
          'DiagnosticReport.effectivePeriod',
          'DiagnosticReport.issued',
          'DiagnosticReport.performer',
          'DiagnosticReport.media',
          'DiagnosticReport.presentedForm'
        ]
        must_support_elements.each do |path|
          element_found = false
          @diagnosticreport_ary&.each do |resource|
            truncated_path = path.gsub('DiagnosticReport.', '')
            already_found = @instance.must_support_confirmed.include?(path)
            element_found = already_found || can_resolve_path(resource, truncated_path)
            @instance.must_support_confirmed += "#{path}," if element_found && !already_found
            break if element_found
          end
          skip "Could not find #{path} in the provided resource" unless element_found
        end
        @instance.save!
      end

      test 'DiagnosticReport resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '14'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-diagnosticreport-note.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('DiagnosticReport')
      end

      test 'All references can be resolved' do
        metadata do
          id '15'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:DiagnosticReport, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@diagnosticreport)
      end
    end
  end
end
