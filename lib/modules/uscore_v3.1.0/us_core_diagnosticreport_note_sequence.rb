# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310DiagnosticreportNoteSequence < SequenceBase
      title 'DiagnosticReport for Report and Note exchange Tests'

      description 'Verify that DiagnosticReport resources on the FHIR server follow the US Core Implementation Guide'

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

      test :unauthorized_search do
        metadata do
          id '01'
          name 'Server rejects DiagnosticReport search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_not_supported(:DiagnosticReport, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = {
          'patient': @instance.patient_id,
          'category': 'LP29684-5'
        }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test :search_by_patient_category do
        metadata do
          id '02'
          name 'Server returns expected results from DiagnosticReport search by patient+category'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+category on the DiagnosticReport resource

          )
          versions :r4
        end

        category_val = ['LP29684-5', 'LP29708-2', 'LP7839-6']
        category_val.each do |val|
          search_params = { 'patient': @instance.patient_id, 'category': val }
          reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          @resources_found = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'DiagnosticReport' }
          next unless @resources_found

          @diagnostic_report = reply.resource.entry
            .find { |entry| entry&.resource&.resourceType == 'DiagnosticReport' }
            .resource
          @diagnostic_report_ary = fetch_all_bundled_resources(reply.resource)

          save_resource_ids_in_bundle(versioned_resource_class('DiagnosticReport'), reply, Inferno::ValidationUtil::US_CORE_R4_URIS[:diagnostic_report_note])
          save_delayed_sequence_references(@diagnostic_report_ary)
          validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
          break
        end
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
      end

      test :search_by_patient do
        metadata do
          id '03'
          name 'Server returns expected results from DiagnosticReport search by patient'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient on the DiagnosticReport resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
      end

      test :search_by_patient_code do
        metadata do
          id '04'
          name 'Server returns expected results from DiagnosticReport search by patient+code'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+code on the DiagnosticReport resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'code': get_value_for_search_param(resolve_element_from_path(@diagnostic_report_ary, 'code'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
      end

      test :search_by_patient_category_date do
        metadata do
          id '05'
          name 'Server returns expected results from DiagnosticReport search by patient+category+date'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+category+date on the DiagnosticReport resource

              including support for these date comparators: gt, lt, le
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'category': get_value_for_search_param(resolve_element_from_path(@diagnostic_report_ary, 'category')),
          'date': get_value_for_search_param(resolve_element_from_path(@diagnostic_report_ary, 'effectiveDateTime'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, search_params[:date])
          comparator_search_params = { 'patient': search_params[:patient], 'category': search_params[:category], 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), comparator_search_params)
          validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, comparator_search_params)
        end
      end

      test :search_by_patient_status do
        metadata do
          id '06'
          name 'Server returns expected results from DiagnosticReport search by patient+status'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+status on the DiagnosticReport resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'status': get_value_for_search_param(resolve_element_from_path(@diagnostic_report_ary, 'status'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)
      end

      test :search_by_patient_code_date do
        metadata do
          id '07'
          name 'Server returns expected results from DiagnosticReport search by patient+code+date'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+code+date on the DiagnosticReport resource

              including support for these date comparators: gt, lt, le
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'code': get_value_for_search_param(resolve_element_from_path(@diagnostic_report_ary, 'code')),
          'date': get_value_for_search_param(resolve_element_from_path(@diagnostic_report_ary, 'effectiveDateTime'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, search_params)

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, search_params[:date])
          comparator_search_params = { 'patient': search_params[:patient], 'code': search_params[:code], 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), comparator_search_params)
          validate_search_reply(versioned_resource_class('DiagnosticReport'), reply, comparator_search_params)
        end
      end

      test :read_interaction do
        metadata do
          id '08'
          name 'DiagnosticReport read interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the DiagnosticReport read interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:DiagnosticReport, [:read])
        skip 'No DiagnosticReport resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@diagnostic_report, versioned_resource_class('DiagnosticReport'))
      end

      test :vread_interaction do
        metadata do
          id '09'
          name 'DiagnosticReport vread interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the DiagnosticReport vread interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:DiagnosticReport, [:vread])
        skip 'No DiagnosticReport resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@diagnostic_report, versioned_resource_class('DiagnosticReport'))
      end

      test :history_interaction do
        metadata do
          id '10'
          name 'DiagnosticReport history interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the DiagnosticReport history interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:DiagnosticReport, [:history])
        skip 'No DiagnosticReport resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@diagnostic_report, versioned_resource_class('DiagnosticReport'))
      end

      test 'Server returns the appropriate resources from the following _revincludes: Provenance:target' do
        metadata do
          id '11'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end

        search_params = {
          'patient': @instance.patient_id,
          'category': get_value_for_search_param(resolve_element_from_path(@diagnostic_report_ary, 'category'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('DiagnosticReport'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
        assert provenance_results, 'No Provenance resources were returned from this search'
      end

      test 'DiagnosticReport resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '12'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('DiagnosticReport', Inferno::ValidationUtil::US_CORE_R4_URIS[:diagnostic_report_note])
      end

      test 'At least one of every must support element is provided in any DiagnosticReport for this patient.' do
        metadata do
          id '13'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all DiagnosticReport resources returned from prior searches to see if any of them provide the following must support elements:

            DiagnosticReport.status

            DiagnosticReport.category

            DiagnosticReport.code

            DiagnosticReport.subject

            DiagnosticReport.encounter

            DiagnosticReport.effectiveDateTime

            DiagnosticReport.effectivePeriod

            DiagnosticReport.issued

            DiagnosticReport.performer

            DiagnosticReport.presentedForm

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @diagnostic_report_ary&.any?
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
          'DiagnosticReport.presentedForm'
        ]
        must_support_elements.each do |path|
          @diagnostic_report_ary&.each do |resource|
            truncated_path = path.gsub('DiagnosticReport.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @diagnostic_report_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided DiagnosticReport resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '14'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_not_supported(:DiagnosticReport, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@diagnostic_report)
      end
    end
  end
end
