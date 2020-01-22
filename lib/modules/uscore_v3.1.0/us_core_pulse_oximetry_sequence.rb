# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310PulseOximetrySequence < SequenceBase
      title 'Pulse Oximetry Tests'

      description 'Verify that Observation resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCPO'

      requires :token, :patient_ids
      conformance_supports :Observation

      def validate_resource_item(resource, property, value)
        case property

        when 'status'
          value_found = resolve_element_from_path(resource, 'status') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'status on resource does not match status requested'

        when 'category'
          value_found = resolve_element_from_path(resource, 'category.coding.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'category on resource does not match category requested'

        when 'code'
          value_found = resolve_element_from_path(resource, 'code.coding.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'code on resource does not match code requested'

        when 'date'
          value_found = resolve_element_from_path(resource, 'effective') { |date| validate_date_search(value, date) }
          assert value_found.present?, 'date on resource does not match date requested'

        when 'patient'
          value_found = resolve_element_from_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found.present?, 'patient on resource does not match patient requested'

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
          name 'Server rejects Observation search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Observation, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'code': '2708-6'
          }

          reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
          assert_response_unauthorized reply
        end

        @client.set_bearer_token(@instance.token)
      end

      test :search_by_patient_code do
        metadata do
          id '02'
          name 'Server returns expected results from Observation search by patient+code'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+code on the Observation resource

          )
          versions :r4
        end

        @observation_ary = {}
        @resources_found = false

        code_val = ['2708-6', '59408-5']
        patient_ids.each do |patient|
          @observation_ary[patient] = []
          code_val.each do |val|
            search_params = { 'patient': patient, 'code': val }
            reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
            assert_response_ok(reply)
            assert_bundle_response(reply)

            next unless reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Observation' }

            @resources_found = true
            @observation = reply.resource.entry
              .find { |entry| entry&.resource&.resourceType == 'Observation' }
              .resource
            @observation_ary[patient] += fetch_all_bundled_resources(reply.resource)

            save_resource_ids_in_bundle(versioned_resource_class('Observation'), reply, Inferno::ValidationUtil::US_CORE_R4_URIS[:pulse_oximetry])
            save_delayed_sequence_references(@observation_ary[patient])
            validate_search_reply(versioned_resource_class('Observation'), reply, search_params)

            break
          end
        end
        skip 'No Observation resources appear to be available. Please use patients with more information.' unless @resources_found
      end

      test :search_by_patient_category_date do
        metadata do
          id '03'
          name 'Server returns expected results from Observation search by patient+category+date'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+category+date on the Observation resource

              including support for these date comparators: gt, lt, le, ge
          )
          versions :r4
        end

        skip 'No Observation resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'category')),
            'date': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'effective'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
          validate_search_reply(versioned_resource_class('Observation'), reply, search_params)

          ['gt', 'lt', 'le', 'ge'].each do |comparator|
            comparator_val = date_comparator_value(comparator, search_params[:date])
            comparator_search_params = { 'patient': search_params[:patient], 'category': search_params[:category], 'date': comparator_val }
            reply = get_resource_by_params(versioned_resource_class('Observation'), comparator_search_params)
            validate_search_reply(versioned_resource_class('Observation'), reply, comparator_search_params)
          end
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :search_by_patient_category do
        metadata do
          id '04'
          name 'Server returns expected results from Observation search by patient+category'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+category on the Observation resource

          )
          versions :r4
        end

        skip 'No Observation resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'category'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
          validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :search_by_patient_code_date do
        metadata do
          id '05'
          name 'Server returns expected results from Observation search by patient+code+date'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+code+date on the Observation resource

              including support for these date comparators: gt, lt, le, ge
          )
          versions :r4
        end

        skip 'No Observation resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'code': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'code')),
            'date': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'effective'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
          validate_search_reply(versioned_resource_class('Observation'), reply, search_params)

          ['gt', 'lt', 'le', 'ge'].each do |comparator|
            comparator_val = date_comparator_value(comparator, search_params[:date])
            comparator_search_params = { 'patient': search_params[:patient], 'code': search_params[:code], 'date': comparator_val }
            reply = get_resource_by_params(versioned_resource_class('Observation'), comparator_search_params)
            validate_search_reply(versioned_resource_class('Observation'), reply, comparator_search_params)
          end
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :search_by_patient_category_status do
        metadata do
          id '06'
          name 'Server returns expected results from Observation search by patient+category+status'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+category+status on the Observation resource

          )
          versions :r4
        end

        skip 'No Observation resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'category')),
            'status': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'status'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
          validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :read_interaction do
        metadata do
          id '07'
          name 'Server returns correct Observation resource from Observation read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the Observation read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Observation, [:read])
        skip 'No Observation resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@observation, versioned_resource_class('Observation'))
      end

      test :vread_interaction do
        metadata do
          id '08'
          name 'Server returns correct Observation resource from Observation vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Observation vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Observation, [:vread])
        skip 'No Observation resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@observation, versioned_resource_class('Observation'))
      end

      test :history_interaction do
        metadata do
          id '09'
          name 'Server returns correct Observation resource from Observation history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Observation history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Observation, [:history])
        skip 'No Observation resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@observation, versioned_resource_class('Observation'))
      end

      test 'Server returns Provenance resources from Observation search by patient + code + _revIncludes: Provenance:target' do
        metadata do
          id '10'
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
            'code': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'code'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          search_params['_revinclude'] = 'Provenance:target'
          reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
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
          id '11'
          name 'Observation resources returned conform to US Core R4 profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-pulse-oximetry'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No Observation resources appear to be available. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Observation', Inferno::ValidationUtil::US_CORE_R4_URIS[:pulse_oximetry])
      end

      test 'All must support elements are provided in the Observation resources returned.' do
        metadata do
          id '12'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Observation resources returned from prior searches to see if any of them provide the following must support elements:

            Observation.status

            Observation.category

            Observation.category.coding

            Observation.category.coding.system

            Observation.category.coding.code

            Observation.code

            Observation.code.coding

            Observation.code.coding.system

            Observation.code.coding.code

            Observation.subject

            Observation.effective[x]

            Observation.value[x]

            Observation.value[x].value

            Observation.value[x].unit

            Observation.value[x].system

            Observation.value[x].code

            Observation.dataAbsentReason

            Observation.component

            Observation.component.code

            Observation.component.code.coding.code

            Observation.component.value[x].system

            Observation.component.value[x].code

            Observation.component.code.coding.code

            Observation.component.value[x]

            Observation.component.value[x].value

            Observation.component.value[x].unit

            Observation.component.value[x].code

            Observation.component.dataAbsentReason

            Observation.category:VSCat

            Observation.code.coding:PulseOx

            Observation.value[x]:valueQuantity

            Observation.component:FlowRate

            Observation.component:Concentration

          )
          versions :r4
        end

        skip 'No Observation resources appear to be available. Please use patients with more information.' unless @resources_found

        must_support_slices = [
          {
            name: 'Observation.category:VSCat',
            path: 'Observation.category',
            discriminator: {
              type: 'value',
              values: [
                {
                  path: 'coding.code',
                  value: 'vital-signs'
                },
                {
                  path: 'coding.system',
                  value: 'http://terminology.hl7.org/CodeSystem/observation-category'
                }
              ]
            }
          },
          {
            name: 'Observation.code.coding:PulseOx',
            path: 'Observation.code.coding',
            discriminator: {
              type: 'value',
              values: [
                {
                  path: 'code',
                  value: '59408-5'
                },
                {
                  path: 'system',
                  value: 'http://loinc.org'
                }
              ]
            }
          },
          {
            name: 'Observation.value[x]:valueQuantity',
            path: 'Observation.value',
            discriminator: {
              type: 'type',
              code: 'Quantity'
            }
          },
          {
            name: 'Observation.component:FlowRate',
            path: 'Observation.component',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '3151-8',
              system: 'http://loinc.org'
            }
          },
          {
            name: 'Observation.component:Concentration',
            path: 'Observation.component',
            discriminator: {
              type: 'patternCodeableConcept',
              path: 'code',
              code: '3150-0',
              system: 'http://loinc.org'
            }
          }
        ]
        missing_slices = must_support_slices.reject do |slice|
          truncated_path = slice[:path].gsub('Observation.', '')
          @observation_ary&.any? do |resource|
            slice_found = find_slice(resource, truncated_path, slice[:discriminator])
            slice_found.present?
          end
        end

        must_support_elements = [
          { path: 'Observation.status' },
          { path: 'Observation.category' },
          { path: 'Observation.category.coding' },
          { path: 'Observation.category.coding.system', fixed_value: 'http://terminology.hl7.org/CodeSystem/observation-category' },
          { path: 'Observation.category.coding.code', fixed_value: 'vital-signs' },
          { path: 'Observation.code' },
          { path: 'Observation.code.coding' },
          { path: 'Observation.code.coding.system', fixed_value: 'http://loinc.org' },
          { path: 'Observation.code.coding.code', fixed_value: '59408-5' },
          { path: 'Observation.subject' },
          { path: 'Observation.effective' },
          { path: 'Observation.value' },
          { path: 'Observation.value.value' },
          { path: 'Observation.value.unit' },
          { path: 'Observation.value.system', fixed_value: 'http://unitsofmeasure.org' },
          { path: 'Observation.value.code', fixed_value: '%' },
          { path: 'Observation.dataAbsentReason' },
          { path: 'Observation.component' },
          { path: 'Observation.component.code' },
          { path: 'Observation.component.code.coding.code', fixed_value: '3151-8' },
          { path: 'Observation.component.value.system', fixed_value: 'http://unitsofmeasure.org' },
          { path: 'Observation.component.value.code', fixed_value: 'l/min' },
          { path: 'Observation.component.code.coding.code', fixed_value: '3150-0' },
          { path: 'Observation.component.value' },
          { path: 'Observation.component.value.value' },
          { path: 'Observation.component.value.unit' },
          { path: 'Observation.component.value.code', fixed_value: '%' },
          { path: 'Observation.component.dataAbsentReason' }
        ]

        missing_must_support_elements = must_support_elements.reject do |element|
          truncated_path = element[:path].gsub('Observation.', '')
          @observation_ary&.any? do |resource|
            value_found = resolve_element_from_path(resource, truncated_path) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        missing_must_support_elements += missing_slices.map { |slice| slice[:name] }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@observation_ary&.values&.flatten&.length} provided Observation resource(s)"
        @instance.save!
      end

      test 'Every reference within Observation resource is valid and can be read.' do
        metadata do
          id '13'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Observation, [:search, :read])
        skip 'No Observation resources appear to be available. Please use patients with more information.' unless @resources_found

        validated_resources = Set.new
        max_resolutions = 50

        @observation_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
