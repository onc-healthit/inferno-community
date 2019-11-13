# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310AllergyintoleranceSequence < SequenceBase
      title 'AllergyIntolerance Tests'

      description 'Verify that AllergyIntolerance resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCAI'

      requires :token, :patient_id
      conformance_supports :AllergyIntolerance

      def validate_resource_item(resource, property, value)
        case property

        when 'clinical-status'
          value_found = can_resolve_path(resource, 'clinicalStatus.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'clinical-status on resource does not match clinical-status requested'

        when 'patient'
          value_found = can_resolve_path(resource, 'patient.reference') { |reference| [value, 'Patient/' + value].include? reference }
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
          name 'Server rejects AllergyIntolerance search without authorization'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_not_supported(:AllergyIntolerance, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from AllergyIntolerance search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL be able to support searching by patient on the AllergyIntolerance resource

          )
          versions :r4
        end

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @allergy_intolerance = reply&.resource&.entry&.first&.resource
        @allergy_intolerance_ary = fetch_all_bundled_resources(reply&.resource)
        save_resource_ids_in_bundle(versioned_resource_class('AllergyIntolerance'), reply)
        save_delayed_sequence_references(@allergy_intolerance_ary)
        validate_search_reply(versioned_resource_class('AllergyIntolerance'), reply, search_params)
      end

      test 'Server returns expected results from AllergyIntolerance search by patient+clinical-status' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD be able to support searching by patient+clinical-status on the AllergyIntolerance resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@allergy_intolerance.nil?, 'Expected valid AllergyIntolerance resource to be present'

        search_params = {
          'patient': @instance.patient_id,
          'clinical-status': get_value_for_search_param(resolve_element_from_path(@allergy_intolerance_ary, 'clinicalStatus'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)
        validate_search_reply(versioned_resource_class('AllergyIntolerance'), reply, search_params)
        assert_response_ok(reply)
      end

      test :read_interaction do
        metadata do
          id '04'
          name 'AllergyIntolerance read interaction supported'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
            All servers SHALL make available read interactions on AllergyIntolerance
          )
          versions :r4
        end

        skip_if_not_supported(:AllergyIntolerance, [:read])
        skip 'No AllergyIntolerance resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@allergy_intolerance, versioned_resource_class('AllergyIntolerance'))
      end

      test :vread_interaction do
        metadata do
          id '05'
          name 'AllergyIntolerance vread interaction supported'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
            All servers SHOULD make available vread interactions on AllergyIntolerance
          )
          versions :r4
        end

        skip_if_not_supported(:AllergyIntolerance, [:vread])
        skip 'No AllergyIntolerance resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@allergy_intolerance, versioned_resource_class('AllergyIntolerance'))
      end

      test :history_interaction do
        metadata do
          id '06'
          name 'AllergyIntolerance history interaction supported'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          description %(
            All servers SHOULD make available history interactions on AllergyIntolerance
          )
          versions :r4
        end

        skip_if_not_supported(:AllergyIntolerance, [:history])
        skip 'No AllergyIntolerance resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@allergy_intolerance, versioned_resource_class('AllergyIntolerance'))
      end

      test 'Server returns the appropriate resources from the following _revincludes: Provenance:target' do
        metadata do
          id '07'
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
        reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
        assert provenance_results, 'No Provenance resources were returned from this search'
      end

      test 'AllergyIntolerance resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '08'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('AllergyIntolerance')
      end

      test 'At least one of every must support element is provided in any AllergyIntolerance for this patient.' do
        metadata do
          id '09'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all AllergyIntolerance resources returned from prior searches too see if any of them provide the following must support elements:

            AllergyIntolerance.clinicalStatus

            AllergyIntolerance.verificationStatus

            AllergyIntolerance.code

            AllergyIntolerance.patient

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @allergy_intolerance_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'AllergyIntolerance.clinicalStatus',
          'AllergyIntolerance.verificationStatus',
          'AllergyIntolerance.code',
          'AllergyIntolerance.patient'
        ]
        must_support_elements.each do |path|
          @allergy_intolerance_ary&.each do |resource|
            truncated_path = path.gsub('AllergyIntolerance.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @allergy_intolerance_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided AllergyIntolerance resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_not_supported(:AllergyIntolerance, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@allergy_intolerance)
      end
    end
  end
end
