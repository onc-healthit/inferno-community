# frozen_string_literal: true

require_relative './data_absent_reason_checker'

module Inferno
  module Sequence
    class USCore310DocumentreferenceSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker

      title 'DocumentReference Tests'

      description 'Verify that DocumentReference resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCDR'

      requires :token
      new_requires :patient_ids
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

      def perform_search_with_status(reply, search_param)
        begin
          parsed_reply = JSON.parse(reply.body)
          assert parsed_reply['resourceType'] == 'OperationOutcome', 'Server returned a status of 400 without an OperationOutcome.'
        rescue JSON::ParserError
          assert false, 'Server returned a status of 400 without an OperationOutcome.'
        end

        warning do
          assert @instance.server_capabilities.search_documented?('DocumentReference'),
                 %(Server returned a status of 400 with an OperationOutcome, but the
                 search interaction for this resource is not documented in the
                 CapabilityStatement. If this response was due to the server
                 requiring a status parameter, the server must document this
                 requirement in its CapabilityStatement.)
        end

        ['current,superseded,entered-in-error'].each do |status_value|
          params_with_status = search_param.merge('status': status_value)
          reply = get_resource_by_params(versioned_resource_class('DocumentReference'), params_with_status)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          entries = reply.resource.entry.select { |entry| entry.resource.resourceType == 'DocumentReference' }
          next if entries.blank?

          search_param.merge!('status': status_value)
          break
        end

        reply
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      def patient_ids
        @instance.get_requirement_value('patient_ids').split(',').map(&:strip)
      end

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

        skip_if_known_not_supported(:DocumentReference, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
          assert_response_unauthorized reply
        end

        @client.set_bearer_token(@instance.token)
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

        @document_reference_ary = {}
        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          assert_response_ok(reply)
          assert_bundle_response(reply)

          any_resources = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'DocumentReference' }

          next unless any_resources

          @document_reference_ary[patient] = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)

          @document_reference = @document_reference_ary[patient]
            .find { |resource| resource.resourceType == 'DocumentReference' }
          @resources_found = @document_reference.present?

          save_resource_references(versioned_resource_class('DocumentReference'), @document_reference_ary[patient])
          save_delayed_sequence_references(@document_reference_ary[patient])
          validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        end

        skip_if_not_found(resource_type: 'DocumentReference', delayed: false)
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

        skip_if_not_found(resource_type: 'DocumentReference', delayed: false)

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            '_id': get_value_for_search_param(resolve_element_from_path(@document_reference_ary[patient], 'id'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
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

        skip_if_not_found(resource_type: 'DocumentReference', delayed: false)

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'type': get_value_for_search_param(resolve_element_from_path(@document_reference_ary[patient], 'type'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
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

        skip_if_not_found(resource_type: 'DocumentReference', delayed: false)

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@document_reference_ary[patient], 'category')),
            'date': get_value_for_search_param(resolve_element_from_path(@document_reference_ary[patient], 'date'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
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

        skip_if_not_found(resource_type: 'DocumentReference', delayed: false)

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@document_reference_ary[patient], 'category'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
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

        skip_if_not_found(resource_type: 'DocumentReference', delayed: false)

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'type': get_value_for_search_param(resolve_element_from_path(@document_reference_ary[patient], 'type')),
            'period': get_value_for_search_param(resolve_element_from_path(@document_reference_ary[patient], 'context.period'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)

          ['gt', 'lt', 'le', 'ge'].each do |comparator|
            comparator_val = date_comparator_value(comparator, search_params[:period])
            comparator_search_params = search_params.merge('period': comparator_val)
            reply = get_resource_by_params(versioned_resource_class('DocumentReference'), comparator_search_params)
            validate_search_reply(versioned_resource_class('DocumentReference'), reply, comparator_search_params)
          end
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
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

        skip_if_not_found(resource_type: 'DocumentReference', delayed: false)

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'status': get_value_for_search_param(resolve_element_from_path(@document_reference_ary[patient], 'status'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)

          validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
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

        skip_if_known_not_supported(:DocumentReference, [:read])
        skip_if_not_found(resource_type: 'DocumentReference', delayed: false)

        validate_read_reply(@document_reference, versioned_resource_class('DocumentReference'), check_for_data_absent_reasons)
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

        skip_if_known_not_supported(:DocumentReference, [:vread])
        skip_if_not_found(resource_type: 'DocumentReference', delayed: false)

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

        skip_if_known_not_supported(:DocumentReference, [:history])
        skip_if_not_found(resource_type: 'DocumentReference', delayed: false)

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

        skip_if_known_not_supported(:DocumentReference, [], [:docref])
        search_string = "/DocumentReference/$docref?patient=#{@instance.patient_id}"
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
        skip_if_not_found(resource_type: 'DocumentReference', delayed: false)
        provenance_results = []
        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          search_params['_revinclude'] = 'Provenance:target'
          reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          assert_response_ok(reply)
          assert_bundle_response(reply)
          provenance_results += fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
            .select { |resource| resource.resourceType == 'Provenance' }
          save_resource_references(versioned_resource_class('Provenance'), provenance_results)
        end

        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '14'
          name 'DocumentReference resources returned conform to US Core R4 profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-documentreference'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

            This test also checks that the following CodeableConcepts with
            required ValueSet bindings include a code rather than just text:
            'type'

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'DocumentReference', delayed: false)
        test_resources_against_profile('DocumentReference') do |resource|
          ['type'].flat_map do |path|
            concepts = resolve_path(resource, path)
            next if concepts.blank?

            code_present = concepts.any? { |concept| concept.coding.any? { |coding| coding.code.present? } }

            unless code_present # rubocop:disable Style/IfUnlessModifier
              "The CodeableConcept at '#{path}' is bound to a required ValueSet but does not contain any codes."
            end
          end.compact
        end
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

        skip_if_not_found(resource_type: 'DocumentReference', delayed: false)

        must_support_elements = [
          { path: 'DocumentReference.identifier' },
          { path: 'DocumentReference.status' },
          { path: 'DocumentReference.type' },
          { path: 'DocumentReference.category' },
          { path: 'DocumentReference.subject' },
          { path: 'DocumentReference.date' },
          { path: 'DocumentReference.author' },
          { path: 'DocumentReference.custodian' },
          { path: 'DocumentReference.content' },
          { path: 'DocumentReference.content.attachment' },
          { path: 'DocumentReference.content.attachment.contentType' },
          { path: 'DocumentReference.content.attachment.data' },
          { path: 'DocumentReference.content.attachment.url' },
          { path: 'DocumentReference.content.format' },
          { path: 'DocumentReference.context' },
          { path: 'DocumentReference.context.encounter' },
          { path: 'DocumentReference.context.period' }
        ]

        missing_must_support_elements = must_support_elements.reject do |element|
          truncated_path = element[:path].gsub('DocumentReference.', '')
          @document_reference_ary&.values&.flatten&.any? do |resource|
            value_found = resolve_element_from_path(resource, truncated_path) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@document_reference_ary&.values&.flatten&.length} provided DocumentReference resource(s)"
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

        skip_if_known_not_supported(:DocumentReference, [:search, :read])
        skip_if_not_found(resource_type: 'DocumentReference', delayed: false)

        validated_resources = Set.new
        max_resolutions = 50

        @document_reference_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
