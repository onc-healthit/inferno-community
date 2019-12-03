# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310PulseOximetrySequence < SequenceBase
      title 'Pulse Oximetry Tests'

      description 'Verify that Observation resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCPO'

      requires :token, :patient_id
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
          value_found = resolve_element_from_path(resource, 'effective') do |date|
            validate_date_search(value, date)
          end
          assert value_found.present?, 'date on resource does not match date requested'

        when 'patient'
          value_found = resolve_element_from_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found.present?, 'patient on resource does not match patient requested'

        end
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

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

        skip_if_not_supported(:Observation, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = {
          'patient': @instance.patient_id,
          'code': '2708-6'
        }

        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
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

        code_val = ['2708-6', '59408-5']
        code_val.each do |val|
          search_params = { 'patient': @instance.patient_id, 'code': val }
          reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          @resources_found = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Observation' }
          next unless @resources_found

          @observation = reply.resource.entry
            .find { |entry| entry&.resource&.resourceType == 'Observation' }
            .resource
          @observation_ary = fetch_all_bundled_resources(reply.resource)

          save_resource_ids_in_bundle(versioned_resource_class('Observation'), reply, Inferno::ValidationUtil::US_CORE_R4_URIS[:pulse_oximetry])
          save_delayed_sequence_references(@observation_ary)
          validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
          break
        end
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
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

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'category': get_value_for_search_param(resolve_element_from_path(@observation_ary, 'category')),
          'date': get_value_for_search_param(resolve_element_from_path(@observation_ary, 'effective'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
        assert_response_ok(reply)

        ['gt', 'lt', 'le', 'ge'].each do |comparator|
          comparator_val = date_comparator_value(comparator, search_params[:date])
          comparator_search_params = { 'patient': search_params[:patient], 'category': search_params[:category], 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('Observation'), comparator_search_params)
          validate_search_reply(versioned_resource_class('Observation'), reply, comparator_search_params)
        end
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

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'category': get_value_for_search_param(resolve_element_from_path(@observation_ary, 'category'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
        assert_response_ok(reply)
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

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'code': get_value_for_search_param(resolve_element_from_path(@observation_ary, 'code')),
          'date': get_value_for_search_param(resolve_element_from_path(@observation_ary, 'effective'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
        assert_response_ok(reply)

        ['gt', 'lt', 'le', 'ge'].each do |comparator|
          comparator_val = date_comparator_value(comparator, search_params[:date])
          comparator_search_params = { 'patient': search_params[:patient], 'code': search_params[:code], 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('Observation'), comparator_search_params)
          validate_search_reply(versioned_resource_class('Observation'), reply, comparator_search_params)
        end
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

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'category': get_value_for_search_param(resolve_element_from_path(@observation_ary, 'category')),
          'status': get_value_for_search_param(resolve_element_from_path(@observation_ary, 'status'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
        assert_response_ok(reply)
      end

      test :read_interaction do
        metadata do
          id '07'
          name 'Observation read interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the Observation read interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Observation, [:read])
        skip 'No Observation resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@observation, versioned_resource_class('Observation'))
      end

      test :vread_interaction do
        metadata do
          id '08'
          name 'Observation vread interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Observation vread interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Observation, [:vread])
        skip 'No Observation resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@observation, versioned_resource_class('Observation'))
      end

      test :history_interaction do
        metadata do
          id '09'
          name 'Observation history interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Observation history interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Observation, [:history])
        skip 'No Observation resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@observation, versioned_resource_class('Observation'))
      end

      test 'Server returns the appropriate resources from the following _revincludes: Provenance:target' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end

        search_params = {
          'patient': @instance.patient_id,
          'code': get_value_for_search_param(resolve_element_from_path(@observation_ary, 'code'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
        assert provenance_results, 'No Provenance resources were returned from this search'
      end

      test 'Observation resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '11'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-pulse-oximetry'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Observation', Inferno::ValidationUtil::US_CORE_R4_URIS[:pulse_oximetry])
      end

      test 'At least one of every must support element is provided in any Observation for this patient.' do
        metadata do
          id '12'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Observation resources returned from prior searches to see if any of them provide the following must support elements:

            Observation.status

            Observation.category

            Observation.category

            Observation.category.coding

            Observation.category.coding.system

            Observation.category.coding.code

            Observation.code

            Observation.code.coding

            Observation.code.coding

            Observation.code.coding.system

            Observation.code.coding.code

            Observation.subject

            Observation.effectiveDateTime

            Observation.effectivePeriod

            Observation.valueQuantity

            Observation.valueQuantity

            Observation.valueQuantity.value

            Observation.valueQuantity.unit

            Observation.valueQuantity.system

            Observation.valueQuantity.code

            Observation.dataAbsentReason

            Observation.component

            Observation.component.code

            Observation.component.valueQuantity

            Observation.component.valueCodeableConcept

            Observation.component.valueString

            Observation.component.valueBoolean

            Observation.component.valueInteger

            Observation.component.valueRange

            Observation.component.valueRatio

            Observation.component.valueSampledData

            Observation.component.valueTime

            Observation.component.valueDateTime

            Observation.component.valuePeriod

            Observation.component.dataAbsentReason

            Observation.component

            Observation.component.code

            Observation.component.valueQuantity

            Observation.component.valueCodeableConcept

            Observation.component.valueString

            Observation.component.valueBoolean

            Observation.component.valueInteger

            Observation.component.valueRange

            Observation.component.valueRatio

            Observation.component.valueSampledData

            Observation.component.valueTime

            Observation.component.valueDateTime

            Observation.component.valuePeriod

            Observation.component.valueQuantity.value

            Observation.component.valueCodeableConcept.value

            Observation.component.valueString.value

            Observation.component.valueBoolean.value

            Observation.component.valueInteger.value

            Observation.component.valueRange.value

            Observation.component.valueRatio.value

            Observation.component.valueSampledData.value

            Observation.component.valueTime.value

            Observation.component.valueDateTime.value

            Observation.component.valuePeriod.value

            Observation.component.valueQuantity.unit

            Observation.component.valueCodeableConcept.unit

            Observation.component.valueString.unit

            Observation.component.valueBoolean.unit

            Observation.component.valueInteger.unit

            Observation.component.valueRange.unit

            Observation.component.valueRatio.unit

            Observation.component.valueSampledData.unit

            Observation.component.valueTime.unit

            Observation.component.valueDateTime.unit

            Observation.component.valuePeriod.unit

            Observation.component.valueQuantity.system

            Observation.component.valueCodeableConcept.system

            Observation.component.valueString.system

            Observation.component.valueBoolean.system

            Observation.component.valueInteger.system

            Observation.component.valueRange.system

            Observation.component.valueRatio.system

            Observation.component.valueSampledData.system

            Observation.component.valueTime.system

            Observation.component.valueDateTime.system

            Observation.component.valuePeriod.system

            Observation.component.valueQuantity.code

            Observation.component.valueCodeableConcept.code

            Observation.component.valueString.code

            Observation.component.valueBoolean.code

            Observation.component.valueInteger.code

            Observation.component.valueRange.code

            Observation.component.valueRatio.code

            Observation.component.valueSampledData.code

            Observation.component.valueTime.code

            Observation.component.valueDateTime.code

            Observation.component.valuePeriod.code

            Observation.component.dataAbsentReason

            Observation.component

            Observation.component.code

            Observation.component.valueQuantity

            Observation.component.valueCodeableConcept

            Observation.component.valueString

            Observation.component.valueBoolean

            Observation.component.valueInteger

            Observation.component.valueRange

            Observation.component.valueRatio

            Observation.component.valueSampledData

            Observation.component.valueTime

            Observation.component.valueDateTime

            Observation.component.valuePeriod

            Observation.component.valueQuantity.value

            Observation.component.valueCodeableConcept.value

            Observation.component.valueString.value

            Observation.component.valueBoolean.value

            Observation.component.valueInteger.value

            Observation.component.valueRange.value

            Observation.component.valueRatio.value

            Observation.component.valueSampledData.value

            Observation.component.valueTime.value

            Observation.component.valueDateTime.value

            Observation.component.valuePeriod.value

            Observation.component.valueQuantity.unit

            Observation.component.valueCodeableConcept.unit

            Observation.component.valueString.unit

            Observation.component.valueBoolean.unit

            Observation.component.valueInteger.unit

            Observation.component.valueRange.unit

            Observation.component.valueRatio.unit

            Observation.component.valueSampledData.unit

            Observation.component.valueTime.unit

            Observation.component.valueDateTime.unit

            Observation.component.valuePeriod.unit

            Observation.component.valueQuantity.system

            Observation.component.valueCodeableConcept.system

            Observation.component.valueString.system

            Observation.component.valueBoolean.system

            Observation.component.valueInteger.system

            Observation.component.valueRange.system

            Observation.component.valueRatio.system

            Observation.component.valueSampledData.system

            Observation.component.valueTime.system

            Observation.component.valueDateTime.system

            Observation.component.valuePeriod.system

            Observation.component.valueQuantity.code

            Observation.component.valueCodeableConcept.code

            Observation.component.valueString.code

            Observation.component.valueBoolean.code

            Observation.component.valueInteger.code

            Observation.component.valueRange.code

            Observation.component.valueRatio.code

            Observation.component.valueSampledData.code

            Observation.component.valueTime.code

            Observation.component.valueDateTime.code

            Observation.component.valuePeriod.code

            Observation.component.dataAbsentReason

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @observation_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'Observation.status',
          'Observation.category',
          'Observation.category',
          'Observation.category.coding',
          'Observation.category.coding.system',
          'Observation.category.coding.code',
          'Observation.code',
          'Observation.code.coding',
          'Observation.code.coding',
          'Observation.code.coding.system',
          'Observation.code.coding.code',
          'Observation.subject',
          'Observation.effectiveDateTime',
          'Observation.effectivePeriod',
          'Observation.valueQuantity',
          'Observation.valueQuantity',
          'Observation.valueQuantity.value',
          'Observation.valueQuantity.unit',
          'Observation.valueQuantity.system',
          'Observation.valueQuantity.code',
          'Observation.dataAbsentReason',
          'Observation.component',
          'Observation.component.code',
          'Observation.component.valueQuantity',
          'Observation.component.valueCodeableConcept',
          'Observation.component.valueString',
          'Observation.component.valueBoolean',
          'Observation.component.valueInteger',
          'Observation.component.valueRange',
          'Observation.component.valueRatio',
          'Observation.component.valueSampledData',
          'Observation.component.valueTime',
          'Observation.component.valueDateTime',
          'Observation.component.valuePeriod',
          'Observation.component.dataAbsentReason',
          'Observation.component',
          'Observation.component.code',
          'Observation.component.valueQuantity',
          'Observation.component.valueCodeableConcept',
          'Observation.component.valueString',
          'Observation.component.valueBoolean',
          'Observation.component.valueInteger',
          'Observation.component.valueRange',
          'Observation.component.valueRatio',
          'Observation.component.valueSampledData',
          'Observation.component.valueTime',
          'Observation.component.valueDateTime',
          'Observation.component.valuePeriod',
          'Observation.component.valueQuantity.value',
          'Observation.component.valueCodeableConcept.value',
          'Observation.component.valueString.value',
          'Observation.component.valueBoolean.value',
          'Observation.component.valueInteger.value',
          'Observation.component.valueRange.value',
          'Observation.component.valueRatio.value',
          'Observation.component.valueSampledData.value',
          'Observation.component.valueTime.value',
          'Observation.component.valueDateTime.value',
          'Observation.component.valuePeriod.value',
          'Observation.component.valueQuantity.unit',
          'Observation.component.valueCodeableConcept.unit',
          'Observation.component.valueString.unit',
          'Observation.component.valueBoolean.unit',
          'Observation.component.valueInteger.unit',
          'Observation.component.valueRange.unit',
          'Observation.component.valueRatio.unit',
          'Observation.component.valueSampledData.unit',
          'Observation.component.valueTime.unit',
          'Observation.component.valueDateTime.unit',
          'Observation.component.valuePeriod.unit',
          'Observation.component.valueQuantity.system',
          'Observation.component.valueCodeableConcept.system',
          'Observation.component.valueString.system',
          'Observation.component.valueBoolean.system',
          'Observation.component.valueInteger.system',
          'Observation.component.valueRange.system',
          'Observation.component.valueRatio.system',
          'Observation.component.valueSampledData.system',
          'Observation.component.valueTime.system',
          'Observation.component.valueDateTime.system',
          'Observation.component.valuePeriod.system',
          'Observation.component.valueQuantity.code',
          'Observation.component.valueCodeableConcept.code',
          'Observation.component.valueString.code',
          'Observation.component.valueBoolean.code',
          'Observation.component.valueInteger.code',
          'Observation.component.valueRange.code',
          'Observation.component.valueRatio.code',
          'Observation.component.valueSampledData.code',
          'Observation.component.valueTime.code',
          'Observation.component.valueDateTime.code',
          'Observation.component.valuePeriod.code',
          'Observation.component.dataAbsentReason',
          'Observation.component',
          'Observation.component.code',
          'Observation.component.valueQuantity',
          'Observation.component.valueCodeableConcept',
          'Observation.component.valueString',
          'Observation.component.valueBoolean',
          'Observation.component.valueInteger',
          'Observation.component.valueRange',
          'Observation.component.valueRatio',
          'Observation.component.valueSampledData',
          'Observation.component.valueTime',
          'Observation.component.valueDateTime',
          'Observation.component.valuePeriod',
          'Observation.component.valueQuantity.value',
          'Observation.component.valueCodeableConcept.value',
          'Observation.component.valueString.value',
          'Observation.component.valueBoolean.value',
          'Observation.component.valueInteger.value',
          'Observation.component.valueRange.value',
          'Observation.component.valueRatio.value',
          'Observation.component.valueSampledData.value',
          'Observation.component.valueTime.value',
          'Observation.component.valueDateTime.value',
          'Observation.component.valuePeriod.value',
          'Observation.component.valueQuantity.unit',
          'Observation.component.valueCodeableConcept.unit',
          'Observation.component.valueString.unit',
          'Observation.component.valueBoolean.unit',
          'Observation.component.valueInteger.unit',
          'Observation.component.valueRange.unit',
          'Observation.component.valueRatio.unit',
          'Observation.component.valueSampledData.unit',
          'Observation.component.valueTime.unit',
          'Observation.component.valueDateTime.unit',
          'Observation.component.valuePeriod.unit',
          'Observation.component.valueQuantity.system',
          'Observation.component.valueCodeableConcept.system',
          'Observation.component.valueString.system',
          'Observation.component.valueBoolean.system',
          'Observation.component.valueInteger.system',
          'Observation.component.valueRange.system',
          'Observation.component.valueRatio.system',
          'Observation.component.valueSampledData.system',
          'Observation.component.valueTime.system',
          'Observation.component.valueDateTime.system',
          'Observation.component.valuePeriod.system',
          'Observation.component.valueQuantity.code',
          'Observation.component.valueCodeableConcept.code',
          'Observation.component.valueString.code',
          'Observation.component.valueBoolean.code',
          'Observation.component.valueInteger.code',
          'Observation.component.valueRange.code',
          'Observation.component.valueRatio.code',
          'Observation.component.valueSampledData.code',
          'Observation.component.valueTime.code',
          'Observation.component.valueDateTime.code',
          'Observation.component.valuePeriod.code',
          'Observation.component.dataAbsentReason'
        ]
        must_support_elements.each do |path|
          @observation_ary&.each do |resource|
            truncated_path = path.gsub('Observation.', '')
            must_support_confirmed[path] = true if resolve_element_from_path(resource, truncated_path).present?
            break if must_support_confirmed[path]
          end
          resource_count = @observation_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided Observation resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '13'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_not_supported(:Observation, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@observation)
      end
    end
  end
end
