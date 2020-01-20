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
          value_found = resolve_element_from_path(resource, 'category.coding.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'category on resource does not match category requested'

        when 'clinical-status'
          value_found = resolve_element_from_path(resource, 'clinicalStatus.coding.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'clinical-status on resource does not match clinical-status requested'

        when 'patient'
          value_found = resolve_element_from_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found.present?, 'patient on resource does not match patient requested'

        when 'onset-date'
          value_found = resolve_element_from_path(resource, 'onsetDateTime') { |date| validate_date_search(value, date) }
          assert value_found.present?, 'onset-date on resource does not match onset-date requested'

        when 'code'
          value_found = resolve_element_from_path(resource, 'code.coding.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'code on resource does not match code requested'

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
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Condition, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test :search_by_patient do
        metadata do
          id '02'
          name 'Server returns expected results from Condition search by patient'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient on the Condition resource

          )
          versions :r4
        end

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        @resources_found = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Condition' }

        skip 'No Condition resources appear to be available. Please use patients with more information.' unless @resources_found

        @condition = reply.resource.entry
          .find { |entry| entry&.resource&.resourceType == 'Condition' }
          .resource
        @condition_ary = fetch_all_bundled_resources(reply.resource)
        save_resource_ids_in_bundle(versioned_resource_class('Condition'), reply)
        save_delayed_sequence_references(@condition_ary)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
      end

      test :search_by_patient_category do
        metadata do
          id '03'
          name 'Server returns expected results from Condition search by patient+category'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+category on the Condition resource

          )
          versions :r4
        end

        skip 'No Condition resources appear to be available. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'category': get_value_for_search_param(resolve_element_from_path(@condition_ary, 'category'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
      end

      test :search_by_patient_onset_date do
        metadata do
          id '04'
          name 'Server returns expected results from Condition search by patient+onset-date'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+onset-date on the Condition resource

              including support for these onset-date comparators: gt, lt, le, ge
          )
          versions :r4
        end

        skip 'No Condition resources appear to be available. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'onset-date': get_value_for_search_param(resolve_element_from_path(@condition_ary, 'onsetDateTime'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)

        ['gt', 'lt', 'le', 'ge'].each do |comparator|
          comparator_val = date_comparator_value(comparator, search_params[:'onset-date'])
          comparator_search_params = { 'patient': search_params[:patient], 'onset-date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('Condition'), comparator_search_params)
          validate_search_reply(versioned_resource_class('Condition'), reply, comparator_search_params)
        end
      end

      test :search_by_patient_clinical_status do
        metadata do
          id '05'
          name 'Server returns expected results from Condition search by patient+clinical-status'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+clinical-status on the Condition resource

          )
          versions :r4
        end

        skip 'No Condition resources appear to be available. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'clinical-status': get_value_for_search_param(resolve_element_from_path(@condition_ary, 'clinicalStatus'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
      end

      test :search_by_patient_code do
        metadata do
          id '06'
          name 'Server returns expected results from Condition search by patient+code'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+code on the Condition resource

          )
          versions :r4
        end

        skip 'No Condition resources appear to be available. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'code': get_value_for_search_param(resolve_element_from_path(@condition_ary, 'code'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Condition'), search_params)
        validate_search_reply(versioned_resource_class('Condition'), reply, search_params)
      end

      test :read_interaction do
        metadata do
          id '07'
          name 'Server returns correct Condition resource from Condition read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the Condition read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Condition, [:read])
        skip 'No Condition resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@condition, versioned_resource_class('Condition'))
      end

      test :vread_interaction do
        metadata do
          id '08'
          name 'Server returns correct Condition resource from Condition vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Condition vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Condition, [:vread])
        skip 'No Condition resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@condition, versioned_resource_class('Condition'))
      end

      test :history_interaction do
        metadata do
          id '09'
          name 'Server returns correct Condition resource from Condition history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Condition history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Condition, [:history])
        skip 'No Condition resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@condition, versioned_resource_class('Condition'))
      end

      test 'Server returns Provenance resources from Condition search by patient + _revIncludes: Provenance:target' do
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
        provenance_results = fetch_all_bundled_resources(reply.resource).select { |resource| resource.resourceType == 'Provenance' }
        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
        provenance_results.each { |reference| @instance.save_resource_reference('Provenance', reference.id) }
      end

      test :validate_resources do
        metadata do
          id '11'
          name 'Condition resources returned conform to US Core R4 profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

            This test also checks that the following CodeableConcepts with
            required ValueSet bindings include a code rather than just text:
            'clinicalStatus' and 'verificationStatus'

          )
          versions :r4
        end

        skip 'No Condition resources appear to be available. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Condition') do |resource|
          ['clinicalStatus', 'verificationStatus'].flat_map do |path|
            concepts = resolve_path(resource, path)
            next if concepts.blank?

            code_present = concepts.any? { |concept| concept.coding.any? { |coding| coding.code.present? } }

            unless code_present # rubocop:disable Style/IfUnlessModifier
              "The CodeableConcept at '#{path}' is bound to a required ValueSet but does not contain any codes."
            end
          end.compact
        end
      end

      test 'All must support elements are provided in the Condition resources returned.' do
        metadata do
          id '12'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Condition resources returned from prior searches to see if any of them provide the following must support elements:

            Condition.clinicalStatus

            Condition.verificationStatus

            Condition.category

            Condition.code

            Condition.subject

          )
          versions :r4
        end

        skip 'No Condition resources appear to be available. Please use patients with more information.' unless @resources_found

        must_support_elements = [
          'Condition.clinicalStatus',
          'Condition.verificationStatus',
          'Condition.category',
          'Condition.code',
          'Condition.subject'
        ]

        missing_must_support_elements = must_support_elements.reject do |path|
          truncated_path = path.gsub('Condition.', '')
          @condition_ary&.any? do |resource|
            resolve_element_from_path(resource, truncated_path).present?
          end
        end

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@condition_ary&.length} provided Condition resource(s)"

        @instance.save!
      end

      test 'Every reference within Condition resource is valid and can be read.' do
        metadata do
          id '13'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Condition, [:search, :read])
        skip 'No Condition resources appear to be available. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@condition)
      end
    end
  end
end
