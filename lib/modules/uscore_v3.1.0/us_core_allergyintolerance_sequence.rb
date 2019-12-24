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
          value_found = resolve_element_from_path(resource, 'clinicalStatus.coding.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'clinical-status on resource does not match clinical-status requested'

        when 'patient'
          value_found = resolve_element_from_path(resource, 'patient.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found.present?, 'patient on resource does not match patient requested'

        end
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      @resources_found = []

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

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        @resources_found = fetch_all_bundled_resources(reply.resource, 'AllergyIntolerance')
        skip 'No AllergyIntolerance resources appear to be available. Please use patients with more information.' unless @resources_found.present?

        save_resource_ids_in_bundle(versioned_resource_class('AllergyIntolerance'), reply)
        save_delayed_sequence_references(@resources_found)
        validate_search_reply(versioned_resource_class('AllergyIntolerance'), reply, search_params)
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

        skip 'No AllergyIntolerance resources appear to be available. Please use patients with more information.' unless @resources_found.present?

        search_params = {
          'patient': @instance.patient_id,
          'clinical-status': get_value_for_search_param(resolve_element_from_path(@resources_found, 'clinicalStatus'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)
        validate_search_reply(versioned_resource_class('AllergyIntolerance'), reply, search_params)
        assert_response_ok(reply)
        @resources_found += fetch_all_bundled_resources(reply.resource, 'AllergyIntolerance')
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

        skip_if_not_supported(:AllergyIntolerance, [:read])
        skip 'No AllergyIntolerance resources appear to be available. Please use patients with more information.' unless @resources_found.present?
        validate_read_reply(@resources_found.first, versioned_resource_class('AllergyIntolerance'))
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

        skip_if_not_supported(:AllergyIntolerance, [:vread])
        skip 'No AllergyIntolerance resources appear to be available. Please use patients with more information.' unless @resources_found.present?
        validate_vread_reply(@resources_found.first, versioned_resource_class('AllergyIntolerance'))
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

        skip_if_not_supported(:AllergyIntolerance, [:history])
        skip 'No AllergyIntolerance resources appear to be available. Please use patients with more information.' unless @resources_found.present?
        validate_history_reply(@resources_found.first, versioned_resource_class('AllergyIntolerance'))
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

        search_params = {
          'patient': @instance.patient_id
        }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('AllergyIntolerance'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = fetch_all_bundled_resources(reply.resource).select { |resource| resource.resourceType == 'Provenance' }
        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
        provenance_results.each { |reference| @instance.save_resource_reference('Provenance', reference.id) }
      end

      test 'AllergyIntolerance resources returned conform to US Core R4 profiles' do
        metadata do
          id '08'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No AllergyIntolerance resources appear to be available. Please use patients with more information.' unless @resources_found.present?
        test_resources_against_profile('AllergyIntolerance')
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

        skip 'No AllergyIntolerance resources appear to be available. Please use patients with more information.' unless @resources_found.present?
        must_support_confirmed = {}

        must_support_elements = [
          'AllergyIntolerance.clinicalStatus',
          'AllergyIntolerance.verificationStatus',
          'AllergyIntolerance.code',
          'AllergyIntolerance.patient'
        ]
        must_support_elements.each do |path|
          @resources_found&.each do |resource|
            truncated_path = path.gsub('AllergyIntolerance.', '')
            must_support_confirmed[path] = true if resolve_element_from_path(resource, truncated_path).present?
            break if must_support_confirmed[path]
          end
          resource_count = @resources_found.length

          skip "Could not find #{path} in any of the #{resource_count} provided AllergyIntolerance resource(s)" unless must_support_confirmed[path]
        end
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

        skip_if_not_supported(:AllergyIntolerance, [:search, :read])
        skip 'No AllergyIntolerance resources appear to be available. Please use patients with more information.' unless @resources_found.present?

        validate_reference_resolutions(@resources_found.first)
      end
    end
  end
end
