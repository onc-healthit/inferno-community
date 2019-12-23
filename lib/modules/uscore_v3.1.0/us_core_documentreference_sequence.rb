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
          value_found = resolve_element_from_path(resource, 'id') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, '_id on resource does not match _id requested'

        when 'status'
          value_found = resolve_element_from_path(resource, 'status') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'status on resource does not match status requested'

        when 'patient'
          value_found = resolve_element_from_path(resource, 'subject.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found.present?, 'patient on resource does not match patient requested'

        when 'category'
          value_found = resolve_element_from_path(resource, 'category.coding.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'category on resource does not match category requested'

        when 'type'
          value_found = resolve_element_from_path(resource, 'type.coding.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'type on resource does not match type requested'

        when 'date'
          value_found = resolve_element_from_path(resource, 'date') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'date on resource does not match date requested'

        when 'period'
          value_found = resolve_element_from_path(resource, 'context.period') { |date| validate_date_search(value, date) }
          assert value_found.present?, 'period on resource does not match period requested'

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

        skip 'No DocumentReference resources appear to be available. Please use patients with more information.' unless @resources_found

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

        skip 'No DocumentReference resources appear to be available. Please use patients with more information.' unless @resources_found

        search_params = {
          '_id': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'id'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        assert_response_ok(reply)
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

        skip 'No DocumentReference resources appear to be available. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'type': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'type'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        assert_response_ok(reply)
      end

      test :search_by_patient_category_date do
        metadata do
          id '05'
          name 'Server returns expected results from DocumentReference search by patient+category+date'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+category+date on the DocumentReference resource

              including support for these date comparators: gt, lt, le, ge
          )
          versions :r4
        end

        skip 'No DocumentReference resources appear to be available. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'category': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'category')),
          'date': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'date'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        assert_response_ok(reply)
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

        skip 'No DocumentReference resources appear to be available. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'category': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'category'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        assert_response_ok(reply)
      end

      test :search_by_patient_type_period do
        metadata do
          id '07'
          name 'Server returns expected results from DocumentReference search by patient+type+period'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+type+period on the DocumentReference resource

              including support for these period comparators: gt, lt, le, ge
          )
          versions :r4
        end

        skip 'No DocumentReference resources appear to be available. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'type': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'type')),
          'period': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'context.period'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        assert_response_ok(reply)

        ['gt', 'lt', 'le', 'ge'].each do |comparator|
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

        skip 'No DocumentReference resources appear to be available. Please use patients with more information.' unless @resources_found

        search_params = {
          'patient': @instance.patient_id,
          'status': get_value_for_search_param(resolve_element_from_path(@document_reference_ary, 'status'))
        }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        assert_response_ok(reply)
      end

      test :read_interaction do
        metadata do
          id '09'
          name 'Server returns correct DocumentReference resource from DocumentReference read interaction'
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
          name 'Server returns correct DocumentReference resource from DocumentReference vread interaction'
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
          name 'Server returns correct DocumentReference resource from DocumentReference history interaction'
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

      test 'The server is capable of returning a reference to a generated CDA document in response to the $docref operation' do
        metadata do
          id '12'
          link 'http://hl7.org/fhir/us/core/2019Sep/CapabilityStatement-us-core-server.html#documentreference'
          description %(
            A server SHALL be capable of responding to a $docref operation and capable of returning at least a reference to a generated CCD document, if available.
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [], [:docref])
        search_string = "/DocumentRefernce/$docref?patient=#{@instance.patient_id}"
        reply = @client.get(search_string, @client.fhir_headers)
        assert_response_ok(reply)
      end

      test 'Server returns Provenance resources from DocumentReference search by patient + _revIncludes: Provenance:target' do
        metadata do
          id '13'
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
        provenance_results = fetch_all_bundled_resources(reply.resource).select { |resource| resource.resourceType == 'Provenance' }
        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
        provenance_results.each { |reference| @instance.save_resource_reference('Provenance', reference.id) }
      end

      test 'DocumentReference resources returned conform to US Core R4 profiles' do
        metadata do
          id '14'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-documentreference'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No DocumentReference resources appear to be available. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('DocumentReference')
      end

      test 'All must support elements are provided in the DocumentReference resources returned.' do
        metadata do
          id '15'
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

        skip 'No DocumentReference resources appear to be available. Please use patients with more information.' unless @resources_found
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
            must_support_confirmed[path] = true if resolve_element_from_path(resource, truncated_path).present?
            break if must_support_confirmed[path]
          end
          resource_count = @document_reference_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided DocumentReference resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'Every reference within DocumentReference resource is valid and can be read.' do
        metadata do
          id '16'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:search, :read])
        skip 'No DocumentReference resources appear to be available. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@document_reference)
      end
    end
  end
end
