# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310ConditionSequence < SequenceBase
      title 'Condition Tests'

      description 'Verify that Condition resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCC'

      requires :token, :patient_id
      conformance_supports :Condition

      def validate_resource_item(resource, property, value)
        case property

        when 'category'
          value_found = can_resolve_path(resource, 'category.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'category on resource does not match category requested'

        when 'clinical-status'
          value_found = can_resolve_path(resource, 'clinicalStatus.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'clinical-status on resource does not match clinical-status requested'

        when 'patient'
          value_found = can_resolve_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found, 'patient on resource does not match patient requested'

        when 'onset-date'
          value_found = can_resolve_path(resource, 'onsetDateTime') do |date|
            validate_date_search(value, date)
          end
          assert value_found, 'onset-date on resource does not match onset-date requested'

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
          name 'Server rejects Condition search without authorization'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_not_supported(:Condition, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Condition search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL be able to support searching by patient on the Condition resource

          )
          versions :r4
        end

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @condition = reply&.resource&.entry&.first&.resource
        @condition_ary = fetch_all_bundled_resources(reply&.resource)
        save_resource_ids_in_bundle(versioned_resource_class('Condition'), reply)
        save_delayed_sequence_references(@condition_ary)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
      end

      test 'Server returns expected results from Condition search by patient+category' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD be able to support searching by patient+category on the Condition resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@condition.nil?, 'Expected valid Condition resource to be present'

        search_params = {
          'patient': @instance.patient_id,
          'category': get_value_for_search_param(resolve_element_from_path(@condition_ary, 'category'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Condition search by patient+onset-date' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD be able to support searching by patient+onset-date on the Condition resource

              including support for these onset-date comparators: gt, lt, le
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@condition.nil?, 'Expected valid Condition resource to be present'

        search_params = {
          'patient': @instance.patient_id,
          'onset-date': get_value_for_search_param(resolve_element_from_path(@condition_ary, 'onsetDateTime'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
        assert_response_ok(reply)

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, search_params[:'onset-date'])
          comparator_search_params = { 'patient': search_params[:patient], 'onset-date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('Condition'), comparator_search_params)
          validate_search_reply(versioned_resource_class('Condition'), reply, comparator_search_params)
          assert_response_ok(reply)
        end
      end

      test 'Server returns expected results from Condition search by patient+clinical-status' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD be able to support searching by patient+clinical-status on the Condition resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@condition.nil?, 'Expected valid Condition resource to be present'

        search_params = {
          'patient': @instance.patient_id,
          'clinical-status': get_value_for_search_param(resolve_element_from_path(@condition_ary, 'clinicalStatus'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Condition search by patient+code' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD be able to support searching by patient+code on the Condition resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@condition.nil?, 'Expected valid Condition resource to be present'

        search_params = {
          'patient': @instance.patient_id,
          'code': get_value_for_search_param(resolve_element_from_path(@condition_ary, 'code'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
        assert_response_ok(reply)
      end

      test :read_interaction do
        metadata do
          id '07'
          name 'Condition read interaction supported'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
            All servers SHALL make available read interactions on Condition
          )
          versions :r4
        end

        skip_if_not_supported(:Condition, [:read])
        skip 'No Condition resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@condition, versioned_resource_class('Condition'))
      end

      test :vread_interaction do
        metadata do
          id '08'
          name 'Condition vread interaction supported'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
            All servers SHOULD make available vread interactions on Condition
          )
          versions :r4
        end

        skip_if_not_supported(:Condition, [:vread])
        skip 'No Condition resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@condition, versioned_resource_class('Condition'))
      end

      test :history_interaction do
        metadata do
          id '09'
          name 'Condition history interaction supported'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
            All servers SHOULD make available history interactions on Condition
          )
          versions :r4
        end

        skip_if_not_supported(:Condition, [:history])
        skip 'No Condition resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@condition, versioned_resource_class('Condition'))
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
          'patient': @instance.patient_id
        }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
        assert provenance_results, 'No Provenance resources were returned from this search'
      end

      test 'Condition resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '11'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Condition')
      end

      test 'At least one of every must support element is provided in any Condition for this patient.' do
        metadata do
          id '12'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Condition resources returned from prior searches too see if any of them provide the following must support elements:

            Condition.clinicalStatus

            Condition.verificationStatus

            Condition.category

            Condition.code

            Condition.subject

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @condition_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'Condition.clinicalStatus',
          'Condition.verificationStatus',
          'Condition.category',
          'Condition.code',
          'Condition.subject'
        ]
        must_support_elements.each do |path|
          @condition_ary&.each do |resource|
            truncated_path = path.gsub('Condition.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @condition_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided Condition resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '13'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_not_supported(:Condition, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@condition)
      end
    end
  end
end
