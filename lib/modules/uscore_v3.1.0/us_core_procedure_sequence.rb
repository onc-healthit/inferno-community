# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310ProcedureSequence < SequenceBase
      title 'Procedure Tests'

      description 'Verify that Procedure resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCPROC'

      requires :token, :patient_id
      conformance_supports :Procedure

      def validate_resource_item(resource, property, value)
        case property

        when 'status'
          value_found = can_resolve_path(resource, 'status') { |value_in_resource| value_in_resource == value }
          assert value_found, 'status on resource does not match status requested'

        when 'patient'
          value_found = can_resolve_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found, 'patient on resource does not match patient requested'

        when 'date'
          value_found = can_resolve_path(resource, 'occurrenceDateTime') do |date|
            validate_date_search(value, date)
          end
          assert value_found, 'date on resource does not match date requested'

        when 'code'
          value_found = can_resolve_path(resource, 'code.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'code on resource does not match code requested'

        end
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      @resources_found = false

      test :unauthorized_search do
        metadata do
          id '01'
          name 'Server rejects Procedure search without authorization'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_not_supported(:Procedure, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Procedure search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL be able to support searching by patient on the Procedure resource

          )
          versions :r4
        end

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @procedure = reply&.resource&.entry&.first&.resource
        @procedure_ary = fetch_all_bundled_resources(reply&.resource)
        save_resource_ids_in_bundle(versioned_resource_class('Procedure'), reply)
        save_delayed_sequence_references(@procedure_ary)
        validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
      end

      test 'Server returns expected results from Procedure search by patient+date' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL be able to support searching by patient+date on the Procedure resource

              including support for these date comparators: gt, lt, le
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@procedure.nil?, 'Expected valid Procedure resource to be present'

        search_params = {
          'patient': @instance.patient_id,
          'date': get_value_for_search_param(resolve_element_from_path(@procedure_ary, 'occurrenceDateTime'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
        assert_response_ok(reply)

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, search_params[:date])
          comparator_search_params = { 'patient': search_params[:patient], 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('Procedure'), comparator_search_params)
          validate_search_reply(versioned_resource_class('Procedure'), reply, comparator_search_params)
          assert_response_ok(reply)
        end
      end

      test 'Server returns expected results from Procedure search by patient+code+date' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD be able to support searching by patient+code+date on the Procedure resource

              including support for these date comparators: gt, lt, le
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@procedure.nil?, 'Expected valid Procedure resource to be present'

        search_params = {
          'patient': @instance.patient_id,
          'code': get_value_for_search_param(resolve_element_from_path(@procedure_ary, 'code')),
          'date': get_value_for_search_param(resolve_element_from_path(@procedure_ary, 'occurrenceDateTime'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
        assert_response_ok(reply)

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, search_params[:date])
          comparator_search_params = { 'patient': search_params[:patient], 'code': search_params[:code], 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('Procedure'), comparator_search_params)
          validate_search_reply(versioned_resource_class('Procedure'), reply, comparator_search_params)
          assert_response_ok(reply)
        end
      end

      test 'Server returns expected results from Procedure search by patient+status' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD be able to support searching by patient+status on the Procedure resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@procedure.nil?, 'Expected valid Procedure resource to be present'

        search_params = {
          'patient': @instance.patient_id,
          'status': get_value_for_search_param(resolve_element_from_path(@procedure_ary, 'status'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
        assert_response_ok(reply)
      end

      test :read_interaction do
        metadata do
          id '06'
          name 'Procedure read interaction supported'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
            All servers SHALL make available read interactions on Procedure
          )
          versions :r4
        end

        skip_if_not_supported(:Procedure, [:read])
        skip 'No Procedure resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@procedure, versioned_resource_class('Procedure'))
      end

      test :vread_interaction do
        metadata do
          id '07'
          name 'Procedure vread interaction supported'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
            All servers SHOULD make available vread interactions on Procedure
          )
          versions :r4
        end

        skip_if_not_supported(:Procedure, [:vread])
        skip 'No Procedure resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@procedure, versioned_resource_class('Procedure'))
      end

      test :history_interaction do
        metadata do
          id '08'
          name 'Procedure history interaction supported'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
            All servers SHOULD make available history interactions on Procedure
          )
          versions :r4
        end

        skip_if_not_supported(:Procedure, [:history])
        skip 'No Procedure resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@procedure, versioned_resource_class('Procedure'))
      end

      test 'Server returns the appropriate resources from the following _revincludes: Provenance:target' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end

        search_params = {
          'patient': @instance.patient_id
        }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
        assert provenance_results, 'No Provenance resources were returned from this search'
      end

      test 'Procedure resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '10'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-procedure'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Procedure')
      end

      test 'At least one of every must support element is provided in any Procedure for this patient.' do
        metadata do
          id '11'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Procedure resources returned from prior searches too see if any of them provide the following must support elements:

            Procedure.status

            Procedure.code

            Procedure.subject

            Procedure.performedDateTime

            Procedure.performedPeriod

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @procedure_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'Procedure.status',
          'Procedure.code',
          'Procedure.subject',
          'Procedure.performedDateTime',
          'Procedure.performedPeriod'
        ]
        must_support_elements.each do |path|
          @procedure_ary&.each do |resource|
            truncated_path = path.gsub('Procedure.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @procedure_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided Procedure resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '12'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_not_supported(:Procedure, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@procedure)
      end
    end
  end
end
