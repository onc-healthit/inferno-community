# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310ImmunizationSequence < SequenceBase
      title 'Immunization Tests'

      description 'Verify that Immunization resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCI'

      requires :token, :patient_id
      conformance_supports :Immunization

      def validate_resource_item(resource, property, value)
        case property

        when 'patient'
          value_found = can_resolve_path(resource, 'patient.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found, 'patient on resource does not match patient requested'

        when 'status'
          value_found = can_resolve_path(resource, 'status') { |value_in_resource| value_in_resource == value }
          assert value_found, 'status on resource does not match status requested'

        when 'date'
          value_found = can_resolve_path(resource, 'occurrenceDateTime') do |date|
            validate_date_search(value, date)
          end
          assert value_found, 'date on resource does not match date requested'

        end
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      @resources_found = false

      test :unauthorized_search do
        metadata do
          id '01'
          name 'Server rejects Immunization search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_not_supported(:Immunization, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('Immunization'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test :search_by_patient do
        metadata do
          id '02'
          name 'Server returns expected results from Immunization search by patient'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient on the Immunization resource

          )
          versions :r4
        end

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('Immunization'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        @resources_found = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Immunization' }

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @immunization = reply.resource.entry
          .find { |entry| entry&.resource&.resourceType == 'Immunization' }
          .resource
        @immunization_ary = fetch_all_bundled_resources(reply.resource)
        save_resource_ids_in_bundle(versioned_resource_class('Immunization'), reply)
        save_delayed_sequence_references(@immunization_ary)
        validate_search_reply(versioned_resource_class('Immunization'), reply, search_params)
      end

      test :search_by_patient_date do
        metadata do
          id '03'
          name 'Server returns expected results from Immunization search by patient+date'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+date on the Immunization resource

              including support for these date comparators: gt, lt, le
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'date': get_value_for_search_param(resolve_element_from_path(@immunization_ary, 'occurrenceDateTime'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Immunization'), search_params)
        validate_search_reply(versioned_resource_class('Immunization'), reply, search_params)

        ['gt', 'lt', 'le', 'ge'].each do |comparator|
          comparator_val = date_comparator_value(comparator, search_params[:date])
          comparator_search_params = { 'patient': search_params[:patient], 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('Immunization'), comparator_search_params)
          validate_search_reply(versioned_resource_class('Immunization'), reply, comparator_search_params)
        end
      end

      test :search_by_patient_status do
        metadata do
          id '04'
          name 'Server returns expected results from Immunization search by patient+status'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+status on the Immunization resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'status': get_value_for_search_param(resolve_element_from_path(@immunization_ary, 'status'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Immunization'), search_params)
        validate_search_reply(versioned_resource_class('Immunization'), reply, search_params)
      end

      test :read_interaction do
        metadata do
          id '05'
          name 'Immunization read interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the Immunization read interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Immunization, [:read])
        skip 'No Immunization resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@immunization, versioned_resource_class('Immunization'))
      end

      test :vread_interaction do
        metadata do
          id '06'
          name 'Immunization vread interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Immunization vread interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Immunization, [:vread])
        skip 'No Immunization resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@immunization, versioned_resource_class('Immunization'))
      end

      test :history_interaction do
        metadata do
          id '07'
          name 'Immunization history interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Immunization history interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Immunization, [:history])
        skip 'No Immunization resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@immunization, versioned_resource_class('Immunization'))
      end

      test 'Server returns the appropriate resources from the following _revincludes: Provenance:target' do
        metadata do
          id '08'
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
        reply = get_resource_by_params(versioned_resource_class('Immunization'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
        assert provenance_results, 'No Provenance resources were returned from this search'
      end

      test 'Immunization resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '09'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-immunization'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Immunization')
      end

      test 'At least one of every must support element is provided in any Immunization for this patient.' do
        metadata do
          id '10'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Immunization resources returned from prior searches to see if any of them provide the following must support elements:

            Immunization.status

            Immunization.statusReason

            Immunization.vaccineCode

            Immunization.patient

            Immunization.occurrenceDateTime

            Immunization.occurrenceString

            Immunization.primarySource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @immunization_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'Immunization.status',
          'Immunization.statusReason',
          'Immunization.vaccineCode',
          'Immunization.patient',
          'Immunization.occurrenceDateTime',
          'Immunization.occurrenceString',
          'Immunization.primarySource'
        ]
        must_support_elements.each do |path|
          @immunization_ary&.each do |resource|
            truncated_path = path.gsub('Immunization.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @immunization_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided Immunization resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '11'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_not_supported(:Immunization, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@immunization)
      end
    end
  end
end
