# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310DocumentreferenceSequence < SequenceBase
      title 'DocumentReference Tests'

      description 'Verify that DocumentReference resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCDR'

      requires :token, :patient_id
      conformance_supports :DocumentReference

      def validate_resource_item(resource, property, value)
        case property

        when '_id'
          value_found = can_resolve_path(resource, 'id') { |value_in_resource| value_in_resource == value }
          assert value_found, '_id on resource does not match _id requested'

        when 'status'
          value_found = can_resolve_path(resource, 'status') { |value_in_resource| value_in_resource == value }
          assert value_found, 'status on resource does not match status requested'

        when 'patient'
          value_found = can_resolve_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found, 'patient on resource does not match patient requested'

        when 'category'
          value_found = can_resolve_path(resource, 'category.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'category on resource does not match category requested'

        when 'type'
          value_found = can_resolve_path(resource, 'type.coding.code') { |value_in_resource| value_in_resource == value }
          assert value_found, 'type on resource does not match type requested'

        when 'date'
          value_found = can_resolve_path(resource, 'date') { |value_in_resource| value_in_resource == value }
          assert value_found, 'date on resource does not match date requested'

        when 'period'
          value_found = can_resolve_path(resource, 'context.period') do |period|
            validate_period_search(value, period)
          end
          assert value_found, 'period on resource does not match period requested'

        end
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      @resources_found = false

      test :unauthorized_search do
        metadata do
          id '01'
          name 'Server rejects DocumentReference search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test :search_by_patient do
        metadata do
          id '02'
          name 'Server returns expected results from DocumentReference search by patient'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient on the DocumentReference resource

          )
          versions :r4
        end

        search_params = {
          'patient': @instance.patient_id
        }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        @resources_found = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'DocumentReference' }

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @document_reference = reply.resource.entry
          .find { |entry| entry&.resource&.resourceType == 'DocumentReference' }
          .resource
        @document_reference_ary = fetch_all_bundled_resources(reply.resource)
        save_resource_ids_in_bundle(versioned_resource_class('DocumentReference'), reply)
        save_delayed_sequence_references(@document_reference_ary)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
      end

      test :search_by__id do
        metadata do
          id '03'
          name 'Server returns expected results from DocumentReference search by _id'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by _id on the DocumentReference resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          '_id': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'id'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
      end

      test :search_by_patient_type do
        metadata do
          id '04'
          name 'Server returns expected results from DocumentReference search by patient+type'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+type on the DocumentReference resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'type': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'type'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
      end

      test :search_by_patient_category_date do
        metadata do
          id '05'
          name 'Server returns expected results from DocumentReference search by patient+category+date'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+category+date on the DocumentReference resource

              including support for these date comparators: gt, lt, le
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'category': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'category')),
          'date': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'date'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
      end

      test :search_by_patient_category do
        metadata do
          id '06'
          name 'Server returns expected results from DocumentReference search by patient+category'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+category on the DocumentReference resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'category': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'category'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
      end

      test :search_by_patient_type_period do
        metadata do
          id '07'
          name 'Server returns expected results from DocumentReference search by patient+type+period'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+type+period on the DocumentReference resource

              including support for these period comparators: gt, lt, le
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'type': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'type')),
          'period': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'context.period'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, search_params[:period])
          comparator_search_params = { 'patient': search_params[:patient], 'type': search_params[:type], 'period': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('DocumentReference'), comparator_search_params)
          validate_search_reply(versioned_resource_class('DocumentReference'), reply, comparator_search_params)
        end
      end

      test :search_by_patient_status do
        metadata do
          id '08'
          name 'Server returns expected results from DocumentReference search by patient+status'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+status on the DocumentReference resource

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'status': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'status'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
      end

      test :read_interaction do
        metadata do
          id '09'
          name 'DocumentReference read interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the DocumentReference read interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:read])
        skip 'No DocumentReference resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@document_reference, versioned_resource_class('DocumentReference'))
      end

      test :vread_interaction do
        metadata do
          id '10'
          name 'DocumentReference vread interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the DocumentReference vread interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:vread])
        skip 'No DocumentReference resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@document_reference, versioned_resource_class('DocumentReference'))
      end

      test :history_interaction do
        metadata do
          id '11'
          name 'DocumentReference history interaction supported'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the DocumentReference history interaction.
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:history])
        skip 'No DocumentReference resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@document_reference, versioned_resource_class('DocumentReference'))
      end

      test 'Server returns the appropriate resources from the following _revincludes: Provenance:target' do
        metadata do
          id '12'
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
        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Provenance' }
        assert provenance_results, 'No Provenance resources were returned from this search'
      end

      test 'DocumentReference resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '13'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-documentreference'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('DocumentReference')
      end

      test 'At least one of every must support element is provided in any DocumentReference for this patient.' do
        metadata do
          id '14'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all DocumentReference resources returned from prior searches to see if any of them provide the following must support elements:

            DocumentReference.identifier

            DocumentReference.status

            DocumentReference.type

            DocumentReference.category

            DocumentReference.subject

            DocumentReference.date

            DocumentReference.author

            DocumentReference.custodian

            DocumentReference.content

            DocumentReference.content.attachment

            DocumentReference.content.attachment.contentType

            DocumentReference.content.attachment.data

            DocumentReference.content.attachment.url

            DocumentReference.content.format

            DocumentReference.context

            DocumentReference.context.encounter

            DocumentReference.context.period

          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @document_reference_ary&.any?
        must_support_confirmed = {}
        must_support_elements = [
          'DocumentReference.identifier',
          'DocumentReference.status',
          'DocumentReference.type',
          'DocumentReference.category',
          'DocumentReference.subject',
          'DocumentReference.date',
          'DocumentReference.author',
          'DocumentReference.custodian',
          'DocumentReference.content',
          'DocumentReference.content.attachment',
          'DocumentReference.content.attachment.contentType',
          'DocumentReference.content.attachment.data',
          'DocumentReference.content.attachment.url',
          'DocumentReference.content.format',
          'DocumentReference.context',
          'DocumentReference.context.encounter',
          'DocumentReference.context.period'
        ]
        must_support_elements.each do |path|
          @document_reference_ary&.each do |resource|
            truncated_path = path.gsub('DocumentReference.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @document_reference_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided DocumentReference resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '15'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@document_reference)
      end
    end
  end
end
