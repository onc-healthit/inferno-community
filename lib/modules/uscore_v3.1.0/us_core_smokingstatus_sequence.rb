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
          value_found = can_resolve_path(resource, 'status') { |value_in_resource| value_in_resource == value }
          assert value_found, 'status on resource does not match status requested'

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

        when 'patient'
          value_found = can_resolve_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found, 'patient on resource does not match patient requested'

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
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html#behavior'
          description %(
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

      test 'Server returns expected results from Observation search by patient+code' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        code_val = ['72166-2']
        code_val.each do |val|
          search_params = { 'patient': @instance.patient_id, 'code': val }
          reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          resource_count = reply&.resource&.entry&.length || 0
          @resources_found = true if resource_count.positive?
          next unless @resources_found

          @observation = reply&.resource&.entry&.first&.resource
          @observation_ary = fetch_all_bundled_resources(reply&.resource)

          save_resource_ids_in_bundle(versioned_resource_class('Observation'), reply, Inferno::ValidationUtil::US_CORE_R4_URIS[:smoking_status])
          save_delayed_sequence_references(@observation_ary)
          validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
          break
        end
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
      end

      test 'Server returns expected results from Observation search by patient+category+date' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@observation.nil?, 'Expected valid Observation resource to be present'

        search_params = {
          'patient': @instance.patient_id,
          'category': get_value_for_search_param(resolve_element_from_path(@observation_ary, 'category')),
          'date': get_value_for_search_param(resolve_element_from_path(@observation_ary, 'effectiveDateTime'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
        assert_response_ok(reply)

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, search_params[:date])
          comparator_search_params = { 'patient': search_params[:patient], 'category': search_params[:category], 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('Observation'), comparator_search_params)
          validate_search_reply(versioned_resource_class('Observation'), reply, comparator_search_params)
          assert_response_ok(reply)
        end
      end

      test 'Server returns expected results from Observation search by patient+category' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@observation.nil?, 'Expected valid Observation resource to be present'

        search_params = {
          'patient': @instance.patient_id,
          'category': get_value_for_search_param(resolve_element_from_path(@observation_ary, 'category'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Observation search by patient+code+date' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@observation.nil?, 'Expected valid Observation resource to be present'

        search_params = {
          'patient': @instance.patient_id,
          'code': get_value_for_search_param(resolve_element_from_path(@observation_ary, 'code')),
          'date': get_value_for_search_param(resolve_element_from_path(@observation_ary, 'effectiveDateTime'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)
        validate_search_reply(versioned_resource_class('Observation'), reply, search_params)
        assert_response_ok(reply)

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, search_params[:date])
          comparator_search_params = { 'patient': search_params[:patient], 'code': search_params[:code], 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('Observation'), comparator_search_params)
          validate_search_reply(versioned_resource_class('Observation'), reply, comparator_search_params)
          assert_response_ok(reply)
        end
      end

      test 'Server returns expected results from Observation search by patient+category+status' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@observation.nil?, 'Expected valid Observation resource to be present'

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
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
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
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
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
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
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
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Observation', Inferno::ValidationUtil::US_CORE_R4_URIS[:smoking_status])
      end

      test 'At least one of every must support element is provided in any Observation for this patient.' do
        metadata do
          id '12'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          description %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @observation_ary&.any?
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
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
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
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          description %(
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
