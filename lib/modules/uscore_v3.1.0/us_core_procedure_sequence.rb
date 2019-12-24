# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310ProcedureSequence < SequenceBase
      title 'Procedure Tests'

      description 'Verify that Procedure resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCPROC'

      requires :token, :patient_id
      conformance_supports :Procedure

      def validate_resource_item(resource, property, value)
        case property

        when 'status'
          value_found = resolve_element_from_path(resource, 'status') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'status on resource does not match status requested'

        when 'patient'
          value_found = resolve_element_from_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found.present?, 'patient on resource does not match patient requested'

        when 'date'
          value_found = resolve_element_from_path(resource, 'performed') { |date| validate_date_search(value, date) }
          assert value_found.present?, 'date on resource does not match date requested'

        when 'code'
          value_found = resolve_element_from_path(resource, 'code.coding.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'code on resource does not match code requested'

        end
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      @resources_found = []

      test :unauthorized_search do
        metadata do
          id '01'
          name 'Server rejects Procedure search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_not_supported(:Procedure, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test :search_by_patient do
        metadata do
          id '02'
          name 'Server returns expected results from Procedure search by patient'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient on the Procedure resource

          )
          versions :r4
        end

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        @resources_found = fetch_all_bundled_resources(reply.resource, 'Procedure')
        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found.present?

        save_resource_ids_in_bundle(versioned_resource_class('Procedure'), reply)
        save_delayed_sequence_references(@resources_found)
        validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
      end

      test :search_by_patient_date do
        metadata do
          id '03'
          name 'Server returns expected results from Procedure search by patient+date'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+date on the Procedure resource

              including support for these date comparators: gt, lt, le, ge
          )
          versions :r4
        end

        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found.present?

        search_params = {
          'patient': @instance.patient_id,
          'date': get_value_for_search_param(resolve_element_from_path(@resources_found, 'performed'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
        assert_response_ok(reply)
        @resources_found += fetch_all_bundled_resources(reply.resource, 'Procedure')

        ['gt', 'lt', 'le', 'ge'].each do |comparator|
          comparator_val = date_comparator_value(comparator, search_params[:date])
          comparator_search_params = { 'patient': search_params[:patient], 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('Procedure'), comparator_search_params)
          validate_search_reply(versioned_resource_class('Procedure'), reply, comparator_search_params)
        end
      end

      test :search_by_patient_code_date do
        metadata do
          id '04'
          name 'Server returns expected results from Procedure search by patient+code+date'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+code+date on the Procedure resource

              including support for these date comparators: gt, lt, le, ge
          )
          versions :r4
        end

        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found.present?

        search_params = {
          'patient': @instance.patient_id,
          'code': get_value_for_search_param(resolve_element_from_path(@resources_found, 'code')),
          'date': get_value_for_search_param(resolve_element_from_path(@resources_found, 'performed'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
        assert_response_ok(reply)
        @resources_found += fetch_all_bundled_resources(reply.resource, 'Procedure')

        ['gt', 'lt', 'le', 'ge'].each do |comparator|
          comparator_val = date_comparator_value(comparator, search_params[:date])
          comparator_search_params = { 'patient': search_params[:patient], 'code': search_params[:code], 'date': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('Procedure'), comparator_search_params)
          validate_search_reply(versioned_resource_class('Procedure'), reply, comparator_search_params)
        end
      end

      test :search_by_patient_status do
        metadata do
          id '05'
          name 'Server returns expected results from Procedure search by patient+status'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+status on the Procedure resource

          )
          versions :r4
        end

        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found.present?

        search_params = {
          'patient': @instance.patient_id,
          'status': get_value_for_search_param(resolve_element_from_path(@resources_found, 'status'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        validate_search_reply(versioned_resource_class('Procedure'), reply, search_params)
        assert_response_ok(reply)
        @resources_found += fetch_all_bundled_resources(reply.resource, 'Procedure')
      end

      test :read_interaction do
        metadata do
          id '06'
          name 'Server returns correct Procedure resource from Procedure read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the Procedure read interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Procedure, [:read])
        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found.present?
        validate_read_reply(@resources_found.first, versioned_resource_class('Procedure'))
      end

      test :vread_interaction do
        metadata do
          id '07'
          name 'Server returns correct Procedure resource from Procedure vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Procedure vread interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Procedure, [:vread])
        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found.present?
        validate_vread_reply(@resources_found.first, versioned_resource_class('Procedure'))
      end

      test :history_interaction do
        metadata do
          id '08'
          name 'Server returns correct Procedure resource from Procedure history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Procedure history interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:Procedure, [:history])
        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found.present?
        validate_history_reply(@resources_found.first, versioned_resource_class('Procedure'))
      end

      test 'Server returns Provenance resources from Procedure search by patient + _revIncludes: Provenance:target' do
        metadata do
          id '09'
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
        reply = get_resource_by_params(versioned_resource_class('Procedure'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = fetch_all_bundled_resources(reply.resource).select { |resource| resource.resourceType == 'Provenance' }
        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
        provenance_results.each { |reference| @instance.save_resource_reference('Provenance', reference.id) }
      end

      test 'Procedure resources returned conform to US Core R4 profiles' do
        metadata do
          id '10'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-procedure'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found.present?
        test_resources_against_profile('Procedure')
      end

      test 'All must support elements are provided in the Procedure resources returned.' do
        metadata do
          id '11'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Procedure resources returned from prior searches to see if any of them provide the following must support elements:

            Procedure.status

            Procedure.code

            Procedure.subject

            Procedure.performedDateTime

            Procedure.performedPeriod

          )
          versions :r4
        end

        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found.present?
        must_support_confirmed = {}

        must_support_elements = [
          'Procedure.status',
          'Procedure.code',
          'Procedure.subject',
          'Procedure.performedDateTime',
          'Procedure.performedPeriod'
        ]
        must_support_elements.each do |path|
          @resources_found&.each do |resource|
            truncated_path = path.gsub('Procedure.', '')
            must_support_confirmed[path] = true if resolve_element_from_path(resource, truncated_path).present?
            break if must_support_confirmed[path]
          end
          resource_count = @resources_found.length

          skip "Could not find #{path} in any of the #{resource_count} provided Procedure resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'Every reference within Procedure resource is valid and can be read.' do
        metadata do
          id '12'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_not_supported(:Procedure, [:search, :read])
        skip 'No Procedure resources appear to be available. Please use patients with more information.' unless @resources_found.present?

        validate_reference_resolutions(@resources_found.first)
      end
    end
  end
end
