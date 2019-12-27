# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310ProcedureSequence < SequenceBase
      title 'Procedure Tests'

      description 'Verify that Procedure resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCPROC'

      requires :token, :patient_ids
      conformance_supports :Procedure

      def validate_resource_item(resource, property, value)
        case property

        when 'status'
          value_found = resolve_element_from_path(resource, 'status') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'status on resource does not match status requested'

        when 'patient'
          value_found = resolve_element_from_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found.present?, 'patient on resource does not match patient requested'

        when 'date'
          value_found = resolve_element_from_path(resource, 'performed') { |date| validate_date_search(value, date) }
          assert value_found.present?, 'date on resource does not match date requested'

        when 'code'
          value_found = resolve_element_from_path(resource, 'code.coding.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'code on resource does not match code requested'

        end
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

      @resources_found = false

      test :unauthorized_search do
        metadata do
          id '01'
          name 'Server rejects Procedure search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Procedure, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
          assert_response_unauthorized reply
        end

        @client.set_bearer_token(@instance.token)
      end

      test :search_by_patient do
        metadata do
          id '02'
          name 'Server returns expected results from Procedure search by patient'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient on the Procedure resource

          )
          versions :r4
        end

        @procedure_ary = {}
        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          any_resources = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Procedure' }

          next unless any_resources

          @resources_found = true

          @procedure = reply.resource.entry
            .find { |entry| entry&.resource&.resourceType == 'Procedure' }
            .resource
          @procedure_ary[patient] = fetch_all_bundled_resources(reply.resource)
          save_resource_ids_in_bundle(versioned_resource_class('Procedure'), reply)
          save_delayed_sequence_references(@procedure_ary[patient])
          validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
        end

        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found
      end

      test :search_by_patient_date do
        metadata do
          id '03'
          name 'Server returns expected results from Procedure search by patient+date'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+date on the Procedure resource

              including support for these date comparators: gt, lt, le, ge
          )
          versions :r4
        end

        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'date': get_value_for_search_param(resolve_element_from_path(@procedure_ary[patient], 'performed'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
          validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)

          ['gt', 'lt', 'le', 'ge'].each do |comparator|
            comparator_val = date_comparator_value(comparator, search_params[:date])
            comparator_search_params = { 'patient': search_params[:patient], 'date': comparator_val }
            reply = get_resource_by_params(versioned_resource_class('Procedure'), comparator_search_params)
            validate_search_reply(versioned_resource_class('Procedure'), reply, comparator_search_params)
          end
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :search_by_patient_code_date do
        metadata do
          id '04'
          name 'Server returns expected results from Procedure search by patient+code+date'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+code+date on the Procedure resource

              including support for these date comparators: gt, lt, le, ge
          )
          versions :r4
        end

        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'code': get_value_for_search_param(resolve_element_from_path(@procedure_ary[patient], 'code')),
            'date': get_value_for_search_param(resolve_element_from_path(@procedure_ary[patient], 'performed'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
          validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)

          ['gt', 'lt', 'le', 'ge'].each do |comparator|
            comparator_val = date_comparator_value(comparator, search_params[:date])
            comparator_search_params = { 'patient': search_params[:patient], 'code': search_params[:code], 'date': comparator_val }
            reply = get_resource_by_params(versioned_resource_class('Procedure'), comparator_search_params)
            validate_search_reply(versioned_resource_class('Procedure'), reply, comparator_search_params)
          end
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :search_by_patient_status do
        metadata do
          id '05'
          name 'Server returns expected results from Procedure search by patient+status'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+status on the Procedure resource

          )
          versions :r4
        end

        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'status': get_value_for_search_param(resolve_element_from_path(@procedure_ary[patient], 'status'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
          validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :read_interaction do
        metadata do
          id '06'
          name 'Server returns correct Procedure resource from Procedure read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the Procedure read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Procedure, [:read])
        skip 'No Procedure resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@procedure, versioned_resource_class('Procedure'))
      end

      test :vread_interaction do
        metadata do
          id '07'
          name 'Server returns correct Procedure resource from Procedure vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Procedure vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Procedure, [:vread])
        skip 'No Procedure resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@procedure, versioned_resource_class('Procedure'))
      end

      test :history_interaction do
        metadata do
          id '08'
          name 'Server returns correct Procedure resource from Procedure history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Procedure history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Procedure, [:history])
        skip 'No Procedure resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@procedure, versioned_resource_class('Procedure'))
      end

      test 'Server returns Provenance resources from Procedure search by patient + _revIncludes: Provenance:target' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end

        provenance_results = []
        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          search_params['_revinclude'] = 'Provenance:target'
          reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)
          provenance_results += fetch_all_bundled_resources(reply.resource).select { |resource| resource.resourceType == 'Provenance' }
          provenance_results.each { |reference| @instance.save_resource_reference('Provenance', reference.id) }
        end

        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '10'
          name 'Procedure resources returned conform to US Core R4 profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-procedure'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Procedure')
      end

      test 'All must support elements are provided in the Procedure resources returned.' do
        metadata do
          id '11'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Procedure resources returned from prior searches to see if any of them provide the following must support elements:

            Procedure.status

            Procedure.code

            Procedure.subject

            Procedure.performedDateTime

            Procedure.performedPeriod

          )
          versions :r4
        end

        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found

        must_support_elements = [
          { path: 'Procedure.status', fixed_value: '' },
          { path: 'Procedure.code', fixed_value: '' },
          { path: 'Procedure.subject', fixed_value: '' },
          { path: 'Procedure.performedDateTime', fixed_value: '' },
          { path: 'Procedure.performedPeriod', fixed_value: '' }
        ]

        missing_must_support_elements = must_support_elements.reject do |path|
          truncated_path = path.gsub('Procedure.', '')
          @procedure_ary&.any? do |resource|
            value_found = resolve_element_from_path(resource, truncated_path) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@procedure_ary&.values&.flatten&.length} provided Procedure resource(s)"
        @instance.save!
      end

      test 'Every reference within Procedure resource is valid and can be read.' do
        metadata do
          id '12'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Procedure, [:search, :read])
        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found

        validated_resources = Set.new
        max_resolutions = 50

        @procedure_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
