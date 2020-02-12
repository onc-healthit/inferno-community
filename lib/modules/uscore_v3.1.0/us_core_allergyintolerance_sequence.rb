# frozen_string_literal: true

require_relative './data_absent_reason_checker'

module Inferno
  module Sequence
    class USCore310AllergyintoleranceSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker

      title 'AllergyIntolerance Tests'

      description 'Verify that AllergyIntolerance resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCAI'

      requires :token, :patient_ids
      conformance_supports :AllergyIntolerance

      def validate_resource_item(resource, property, value)
        case property

        when 'clinical-status'
          value_found = resolve_element_from_path(resource, 'clinicalStatus.coding.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'clinical-status on resource does not match clinical-status requested'

        when 'patient'
          value_found = resolve_element_from_path(resource, 'patient.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found.present?, 'patient on resource does not match patient requested'

        end
      end

      def perform_search_with_status(reply, search_param)
        begin
          parsed_reply = JSON.parse(reply.body)
          assert parsed_reply['resourceType'] == 'OperationOutcome', 'Server returned a status of 400 without an OperationOutcome.'
        rescue JSON::ParserError
          assert false, 'Server returned a status of 400 without an OperationOutcome.'
        end

        warning do
          assert @instance.server_capabilities.search_documented?('AllergyIntolerance'),
                 %(Server returned a status of 400 with an OperationOutcome, but the
                 search interaction for this resource is not documented in the
                 CapabilityStatement. If this response was due to the server
                 requiring a status parameter, the server must document this
                 requirement in its CapabilityStatement.)
        end

        ['active', 'inactive', 'resolved'].each do |status_value|
          params_with_status = search_param.merge('clinical-status': status_value)
          reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), params_with_status)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          entries = reply.resource.entry.select { |entry| entry.resource.resourceType == 'AllergyIntolerance' }
          next if entries.blank?

          search_param.merge!('clinical-status': status_value)
          break
        end

        reply
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
          name 'Server rejects AllergyIntolerance search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_known_not_supported(:AllergyIntolerance, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)
          assert_response_unauthorized reply
        end

        @client.set_bearer_token(@instance.token)
      end

      test :search_by_patient do
        metadata do
          id '02'
          name 'Server returns expected results from AllergyIntolerance search by patient'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient on the AllergyIntolerance resource

          )
          versions :r4
        end

        @allergy_intolerance_ary = {}
        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          assert_response_ok(reply)
          assert_bundle_response(reply)

          any_resources = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'AllergyIntolerance' }

          next unless any_resources

          @resources_found = true

          @allergy_intolerance = reply.resource.entry
            .find { |entry| entry&.resource&.resourceType == 'AllergyIntolerance' }
            .resource
          @allergy_intolerance_ary[patient] = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
          save_resource_ids_in_bundle(versioned_resource_class('AllergyIntolerance'), reply)
          save_delayed_sequence_references(@allergy_intolerance_ary[patient])
          validate_search_reply(versioned_resource_class('AllergyIntolerance'), reply, search_params)
        end

        skip 'No AllergyIntolerance resources appear to be available. Please use patients with more information.' unless @resources_found
      end

      test :search_by_patient_clinical_status do
        metadata do
          id '03'
          name 'Server returns expected results from AllergyIntolerance search by patient+clinical-status'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+clinical-status on the AllergyIntolerance resource

          )
          versions :r4
        end

        skip 'No AllergyIntolerance resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'clinical-status': get_value_for_search_param(resolve_element_from_path(@allergy_intolerance_ary[patient], 'clinicalStatus'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)

          validate_search_reply(versioned_resource_class('AllergyIntolerance'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :read_interaction do
        metadata do
          id '04'
          name 'Server returns correct AllergyIntolerance resource from AllergyIntolerance read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the AllergyIntolerance read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:AllergyIntolerance, [:read])
        skip 'No AllergyIntolerance resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@allergy_intolerance, versioned_resource_class('AllergyIntolerance'), check_for_data_absent_reasons)
      end

      test :vread_interaction do
        metadata do
          id '05'
          name 'Server returns correct AllergyIntolerance resource from AllergyIntolerance vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the AllergyIntolerance vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:AllergyIntolerance, [:vread])
        skip 'No AllergyIntolerance resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@allergy_intolerance, versioned_resource_class('AllergyIntolerance'))
      end

      test :history_interaction do
        metadata do
          id '06'
          name 'Server returns correct AllergyIntolerance resource from AllergyIntolerance history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the AllergyIntolerance history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:AllergyIntolerance, [:history])
        skip 'No AllergyIntolerance resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@allergy_intolerance, versioned_resource_class('AllergyIntolerance'))
      end

      test 'Server returns Provenance resources from AllergyIntolerance search by patient + _revIncludes: Provenance:target' do
        metadata do
          id '07'
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
          reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          assert_response_ok(reply)
          assert_bundle_response(reply)
          provenance_results += fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
            .select { |resource| resource.resourceType == 'Provenance' }
          provenance_results.each { |reference| @instance.save_resource_reference('Provenance', reference.id) }
        end

        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '08'
          name 'AllergyIntolerance resources returned conform to US Core R4 profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

            This test also checks that the following CodeableConcepts with
            required ValueSet bindings include a code rather than just text:
            'clinicalStatus' and 'verificationStatus'

          )
          versions :r4
        end

        skip 'No AllergyIntolerance resources appear to be available. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('AllergyIntolerance') do |resource|
          ['clinicalStatus', 'verificationStatus'].flat_map do |path|
            concepts = resolve_path(resource, path)
            next if concepts.blank?

            code_present = concepts.any? { |concept| concept.coding.any? { |coding| coding.code.present? } }

            unless code_present # rubocop:disable Style/IfUnlessModifier
              "The CodeableConcept at '#{path}' is bound to a required ValueSet but does not contain any codes."
            end
          end.compact
        end

        bindings = [
          {
            type: 'CodeableConcept',
            strength: 'required',
            system: 'http://hl7.org/fhir/ValueSet/allergyintolerance-clinical',
            path: 'clinicalStatus'
          },
          {
            type: 'CodeableConcept',
            strength: 'required',
            system: 'http://hl7.org/fhir/ValueSet/allergyintolerance-verification',
            path: 'verificationStatus'
          },
          {
            type: 'code',
            strength: 'required',
            system: 'http://hl7.org/fhir/ValueSet/allergy-intolerance-type|4.0.1',
            path: 'type'
          },
          {
            type: 'code',
            strength: 'required',
            system: 'http://hl7.org/fhir/ValueSet/allergy-intolerance-category|4.0.1',
            path: 'category'
          },
          {
            type: 'code',
            strength: 'required',
            system: 'http://hl7.org/fhir/ValueSet/allergy-intolerance-criticality|4.0.1',
            path: 'criticality'
          },
          {
            type: 'code',
            strength: 'required',
            system: 'http://hl7.org/fhir/ValueSet/reaction-event-severity|4.0.1',
            path: 'reaction.severity'
          }
        ]
        bindings.each do |binding|
          validate_terminology(binding, @allergy_intolerance_ary&.values&.flatten)
        end
      end

      test 'All must support elements are provided in the AllergyIntolerance resources returned.' do
        metadata do
          id '09'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all AllergyIntolerance resources returned from prior searches to see if any of them provide the following must support elements:

            AllergyIntolerance.clinicalStatus

            AllergyIntolerance.verificationStatus

            AllergyIntolerance.code

            AllergyIntolerance.patient

          )
          versions :r4
        end

        skip 'No AllergyIntolerance resources appear to be available. Please use patients with more information.' unless @resources_found

        must_support_elements = [
          { path: 'AllergyIntolerance.clinicalStatus' },
          { path: 'AllergyIntolerance.verificationStatus' },
          { path: 'AllergyIntolerance.code' },
          { path: 'AllergyIntolerance.patient' }
        ]

        missing_must_support_elements = must_support_elements.reject do |element|
          truncated_path = element[:path].gsub('AllergyIntolerance.', '')
          @allergy_intolerance_ary&.values&.flatten&.any? do |resource|
            value_found = resolve_element_from_path(resource, truncated_path) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@allergy_intolerance_ary&.values&.flatten&.length} provided AllergyIntolerance resource(s)"
        @instance.save!
      end

      test 'Every reference within AllergyIntolerance resource is valid and can be read.' do
        metadata do
          id '10'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_known_not_supported(:AllergyIntolerance, [:search, :read])
        skip 'No AllergyIntolerance resources appear to be available. Please use patients with more information.' unless @resources_found

        validated_resources = Set.new
        max_resolutions = 50

        @allergy_intolerance_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
