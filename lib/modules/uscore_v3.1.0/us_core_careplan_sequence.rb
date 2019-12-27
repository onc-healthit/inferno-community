# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310CareplanSequence < SequenceBase
      title 'CarePlan Tests'

      description 'Verify that CarePlan resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCCP'

      requires :token, :patient_ids
      conformance_supports :CarePlan

      def validate_resource_item(resource, property, value)
        case property

        when 'category'
          value_found = resolve_element_from_path(resource, 'category.coding.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'category on resource does not match category requested'

        when 'date'
          value_found = resolve_element_from_path(resource, 'period') { |date| validate_date_search(value, date) }
          assert value_found.present?, 'date on resource does not match date requested'

        when 'patient'
          value_found = resolve_element_from_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found.present?, 'patient on resource does not match patient requested'

        when 'status'
          value_found = resolve_element_from_path(resource, 'status') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'status on resource does not match status requested'

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
          name 'Server rejects CarePlan search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_known_not_supported(:CarePlan, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': 'assess-plan'
          }

          reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
          assert_response_unauthorized reply
        end

        @client.set_bearer_token(@instance.token)
      end

      test :search_by_patient_category do
        metadata do
          id '02'
          name 'Server returns expected results from CarePlan search by patient+category'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+category on the CarePlan resource

          )
          versions :r4
        end

        @care_plan_ary = {}
        @resources_found = false

        category_val = ['assess-plan']
        patient_ids.each do |patient|
          @care_plan_ary[patient] = []
          category_val.each do |val|
            search_params = { 'patient': patient, 'category': val }
            reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
            assert_response_ok(reply)
            assert_bundle_response(reply)

            next unless reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'CarePlan' }

            @resources_found = true
            @care_plan = reply.resource.entry
              .find { |entry| entry&.resource&.resourceType == 'CarePlan' }
              .resource
            @care_plan_ary[patient] += fetch_all_bundled_resources(reply.resource)

            save_resource_ids_in_bundle(versioned_resource_class('CarePlan'), reply)
            save_delayed_sequence_references(@care_plan_ary[patient])
            validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)

            break
          end
        end
        skip 'No CarePlan resources appear to be available. Please use patients with more information.' unless @resources_found
      end

      test :search_by_patient_category_date do
        metadata do
          id '03'
          name 'Server returns expected results from CarePlan search by patient+category+date'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+category+date on the CarePlan resource

              including support for these date comparators: gt, lt, le, ge
          )
          versions :r4
        end

        skip 'No CarePlan resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'category')),
            'date': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'period'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
          validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)

          ['gt', 'lt', 'le', 'ge'].each do |comparator|
            comparator_val = date_comparator_value(comparator, search_params[:date])
            comparator_search_params = { 'patient': search_params[:patient], 'category': search_params[:category], 'date': comparator_val }
            reply = get_resource_by_params(versioned_resource_class('CarePlan'), comparator_search_params)
            validate_search_reply(versioned_resource_class('CarePlan'), reply, comparator_search_params)
          end
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :search_by_patient_category_status_date do
        metadata do
          id '04'
          name 'Server returns expected results from CarePlan search by patient+category+status+date'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+category+status+date on the CarePlan resource

              including support for these date comparators: gt, lt, le, ge
          )
          versions :r4
        end

        skip 'No CarePlan resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'category')),
            'status': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'status')),
            'date': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'period'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
          validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)

          ['gt', 'lt', 'le', 'ge'].each do |comparator|
            comparator_val = date_comparator_value(comparator, search_params[:date])
            comparator_search_params = { 'patient': search_params[:patient], 'category': search_params[:category], 'status': search_params[:status], 'date': comparator_val }
            reply = get_resource_by_params(versioned_resource_class('CarePlan'), comparator_search_params)
            validate_search_reply(versioned_resource_class('CarePlan'), reply, comparator_search_params)
          end
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :search_by_patient_category_status do
        metadata do
          id '05'
          name 'Server returns expected results from CarePlan search by patient+category+status'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+category+status on the CarePlan resource

          )
          versions :r4
        end

        skip 'No CarePlan resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'category')),
            'status': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'status'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
          validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :read_interaction do
        metadata do
          id '06'
          name 'Server returns correct CarePlan resource from CarePlan read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the CarePlan read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:CarePlan, [:read])
        skip 'No CarePlan resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@care_plan, versioned_resource_class('CarePlan'))
      end

      test :vread_interaction do
        metadata do
          id '07'
          name 'Server returns correct CarePlan resource from CarePlan vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the CarePlan vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:CarePlan, [:vread])
        skip 'No CarePlan resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@care_plan, versioned_resource_class('CarePlan'))
      end

      test :history_interaction do
        metadata do
          id '08'
          name 'Server returns correct CarePlan resource from CarePlan history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the CarePlan history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:CarePlan, [:history])
        skip 'No CarePlan resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@care_plan, versioned_resource_class('CarePlan'))
      end

      test 'Server returns Provenance resources from CarePlan search by patient + category + _revIncludes: Provenance:target' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end

        could_not_resolve_all = []
        resolved_one = false

        provenance_results = []
        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'category'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          search_params['_revinclude'] = 'Provenance:target'
          reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)
          provenance_results += fetch_all_bundled_resources(reply.resource).select { |resource| resource.resourceType == 'Provenance' }
          provenance_results.each { |reference| @instance.save_resource_reference('Provenance', reference.id) }
        end
        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '10'
          name 'CarePlan resources returned conform to US Core R4 profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-careplan'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No CarePlan resources appear to be available. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('CarePlan')
      end

      test 'All must support elements are provided in the CarePlan resources returned.' do
        metadata do
          id '11'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all CarePlan resources returned from prior searches to see if any of them provide the following must support elements:

            CarePlan.text

            CarePlan.text.status

            CarePlan.status

            CarePlan.intent

            CarePlan.category

            CarePlan.category.coding.code

            CarePlan.subject

          )
          versions :r4
        end

        skip 'No CarePlan resources appear to be available. Please use patients with more information.' unless @resources_found

        must_support_elements = [
          { path: 'CarePlan.text', fixed_value: '' },
          { path: 'CarePlan.text.status', fixed_value: '' },
          { path: 'CarePlan.status', fixed_value: '' },
          { path: 'CarePlan.intent', fixed_value: '' },
          { path: 'CarePlan.category', fixed_value: '' },
          { path: 'CarePlan.category.coding.code', fixed_value: 'assess-plan' },
          { path: 'CarePlan.subject', fixed_value: '' }
        ]

        missing_must_support_elements = must_support_elements.reject do |path|
          truncated_path = path.gsub('CarePlan.', '')
          @care_plan_ary&.any? do |resource|
            value_found = resolve_element_from_path(resource, truncated_path) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@care_plan_ary&.values&.flatten&.length} provided CarePlan resource(s)"
        @instance.save!
      end

      test 'Every reference within CarePlan resource is valid and can be read.' do
        metadata do
          id '12'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_known_not_supported(:CarePlan, [:search, :read])
        skip 'No CarePlan resources appear to be available. Please use patients with more information.' unless @resources_found

        validated_resources = Set.new
        max_resolutions = 50

        @care_plan_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
