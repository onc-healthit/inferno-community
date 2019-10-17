# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore300DiagnosticreportNoteSequence < SequenceBase
      title 'DiagnosticReport for Report and Note exchange Tests'

      description 'Verify that DiagnosticReport resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'USCDRRN'

      requires :token, :patient_id
      conformance_supports :DiagnosticReport

      def validate_resource_item(resource, property, value)
        case property

        when 'status'
          value_found = can_resolve_path(resource, 'status') { |value_in_resource| value_in_resource == value }
          assert value_found, 'status on resource does not match status requested'

        when 'patient'
          value_found = can_resolve_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found, 'patient on resource does not match patient requested'

        when 'category'
          value_found = can_resolve_path(resource, 'category.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'category on resource does not match category requested'

        when 'code'
          value_found = can_resolve_path(resource, 'code.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'code on resource does not match code requested'

        when 'date'
          value_found = can_resolve_path(resource, 'effectiveDateTime') do |date|
            validate_date_search(value, date)
          end
          assert value_found, 'date on resource does not match date requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.

      )

      @resources_found = false

      test 'Server rejects DiagnosticReport search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          description %(
          )
          versions :r4
        end

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = { patient: @instance.patient_id, code: 'LP29684-5' }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from DiagnosticReport search by patient+category' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
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

        @diagnosticreport = reply&.resource&.entry&.first&.resource
        @diagnosticreport_ary = fetch_all_bundled_resources(reply&.resource)
        save_resource_ids_in_bundle(versioned_resource_class('DiagnosticReport'), reply, Inferno::ValidationUtil::US_CORE_R4_URIS[:diagnostic_report_note])
        save_delayed_sequence_references(@diagnosticreport)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
      end

      test 'Server returns expected results from DiagnosticReport search by patient+code' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@diagnosticreport.nil?, 'Expected valid DiagnosticReport resource to be present'

        patient_val = @instance.patient_id
        code_val = get_value_for_search_param(resolve_element_from_path(@diagnosticreport_ary, 'code'))
        search_params = { 'patient': patient_val, 'code': code_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DiagnosticReport search by patient+category+date' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@diagnosticreport.nil?, 'Expected valid DiagnosticReport resource to be present'

        patient_val = @instance.patient_id
        category_val = get_value_for_search_param(resolve_element_from_path(@diagnosticreport_ary, 'category'))
        date_val = get_value_for_search_param(resolve_element_from_path(@diagnosticreport_ary, 'effectiveDateTime'))
        search_params = { 'patient': patient_val, 'category': category_val, 'date': date_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
        assert_response_ok(reply)

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, date_val)
          comparator_search_params = { 'patient': patient_val, 'category': category_val, 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), comparator_search_params)
          validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, comparator_search_params)
          assert_response_ok(reply)
        end
      end

      test 'Server returns expected results from DiagnosticReport search by patient+code+date' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@diagnosticreport.nil?, 'Expected valid DiagnosticReport resource to be present'

        patient_val = @instance.patient_id
        code_val = get_value_for_search_param(resolve_element_from_path(@diagnosticreport_ary, 'code'))
        date_val = get_value_for_search_param(resolve_element_from_path(@diagnosticreport_ary, 'effectiveDateTime'))
        search_params = { 'patient': patient_val, 'code': code_val, 'date': date_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
        assert_response_ok(reply)

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, date_val)
          comparator_search_params = { 'patient': patient_val, 'code': code_val, 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), comparator_search_params)
          validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, comparator_search_params)
          assert_response_ok(reply)
        end
      end

      test 'Server returns expected results from DiagnosticReport search by patient+status' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@diagnosticreport.nil?, 'Expected valid DiagnosticReport resource to be present'

        patient_val = @instance.patient_id
        status_val = get_value_for_search_param(resolve_element_from_path(@diagnosticreport_ary, 'status'))
        search_params = { 'patient': patient_val, 'status': status_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DiagnosticReport search by patient+category' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@diagnosticreport.nil?, 'Expected valid DiagnosticReport resource to be present'

        search_params = { patient: @instance.patient_id, code: 'LP29684-5' }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DiagnosticReport search by patient+category+date' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@diagnosticreport.nil?, 'Expected valid DiagnosticReport resource to be present'

        patient_val = @instance.patient_id
        category_val = get_value_for_search_param(resolve_element_from_path(@diagnosticreport_ary, 'category'))
        date_val = get_value_for_search_param(resolve_element_from_path(@diagnosticreport_ary, 'effectiveDateTime'))
        search_params = { 'patient': patient_val, 'category': category_val, 'date': date_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
        assert_response_ok(reply)

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, date_val)
          comparator_search_params = { 'patient': patient_val, 'category': category_val, 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), comparator_search_params)
          validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, comparator_search_params)
          assert_response_ok(reply)
        end
      end

      test 'DiagnosticReport create resource supported' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
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
          description %(
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
          description %(
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
          description %(
          )
          versions :r4
        end

        skip_if_not_supported(:DiagnosticReport, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@diagnosticreport, versioned_resource_class('DiagnosticReport'))
      end

      test 'DiagnosticReport resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '13'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('DiagnosticReport', Inferno::ValidationUtil::US_CORE_R4_URIS[:diagnostic_report_note])
      end

      test 'At least one of every must support element is provided in any DiagnosticReport for this patient.' do
        metadata do
          id '14'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @diagnosticreport_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'DiagnosticReport.status',
          'DiagnosticReport.category',
          'DiagnosticReport.code',
          'DiagnosticReport.subject',
          'DiagnosticReport.encounter',
          'DiagnosticReport.effectiveDateTime',
          'DiagnosticReport.effectivePeriod',
          'DiagnosticReport.issued',
          'DiagnosticReport.performer',
          'DiagnosticReport.media',
          'DiagnosticReport.presentedForm'
        ]
        must_support_elements.each do |path|
          @diagnosticreport_ary&.each do |resource|
            truncated_path = path.gsub('DiagnosticReport.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @diagnosticreport_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided DiagnosticReport resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '15'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          description %(
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
