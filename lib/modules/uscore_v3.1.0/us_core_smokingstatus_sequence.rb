# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310SmokingstatusSequence < SequenceBase
      title 'Smoking Status Observation Tests'

      description 'Verify that Observation resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCSSO'

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
          'code': '72166-2'
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

        @observation_ary = []

        code_val = ['72166-2']
        code_val.each do |val|
          search_params = { 'patient': @instance.patient_id, 'code': val }
          reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          next unless reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Observation' }

          @resources_found = true
          @observation = reply.resource.entry
            .find { |entry| entry&.resource&.resourceType == 'Observation' }
            .resource
          @observation_ary += fetch_all_bundled_resources(reply.resource)

          save_resource_ids_in_bundle(versioned_resource_class('Observation'), reply, Inferno::ValidationUtil::US_CORE_R4_URIS[:smoking_status])
          save_delayed_sequence_references(@observation_ary)
          validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
          break
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

        skip 'No Observation resources appear to be available. Please use patients with more information.' unless @resources_found

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

        skip 'No Observation resources appear to be available. Please use patients with more information.' unless @resources_found

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

        skip 'No Observation resources appear to be available. Please use patients with more information.' unless @resources_found

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
          name 'Server returns correct Observation resource from Observation read interaction'
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
          name 'Server returns correct Observation resource from Observation vread interaction'
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
          name 'Server returns correct Observation resource from Observation history interaction'
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

      test 'Server returns Provenance resources from Observation search by patient + code + _revIncludes: Provenance:target' do
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
        provenance_results = fetch_all_bundled_resources(reply.resource).select { |resource| resource.resourceType == 'Provenance' }
        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
        provenance_results.each { |reference| @instance.save_resource_reference('Provenance', reference.id) }
      end

      test 'Observation resources returned conform to US Core R4 profiles' do
        metadata do
          id '11'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No Observation resources appear to be available. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Observation', Inferno::ValidationUtil::US_CORE_R4_URIS[:smoking_status])
      end

      test 'All must support elements are provided in the Observation resources returned.' do
        metadata do
          id '12'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Observation resources returned from prior searches to see if any of them provide the following must support elements:

            Observation.status

            Observation.code

            Observation.subject

            Observation.issued

            Observation.valueCodeableConcept

          )
          versions :r4
        end

        skip 'No Observation resources appear to be available. Please use patients with more information.' unless @resources_found
        must_support_confirmed = {}

        must_support_elements = [
          'Observation.status',
          'Observation.code',
          'Observation.subject',
          'Observation.issued',
          'Observation.valueCodeableConcept'
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

      test 'Every reference within Observation resource is valid and can be read.' do
        metadata do
          id '13'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_not_supported(:Observation, [:search, :read])
        skip 'No Observation resources appear to be available. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@observation)
      end
    end
  end
end
