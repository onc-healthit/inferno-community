# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4DocumentreferenceSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Documentreference Tests'

      description 'Verify that DocumentReference resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'DocumentReference' # change me

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

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Documentreference Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-documentreference)

      )

      @resources_found = false

      test 'Server rejects DocumentReference search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from DocumentReference search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply&.resource&.entry&.length || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @documentreference = reply.try(:resource).try(:entry).try(:first).try(:resource)
        @documentreference_ary = reply&.resource&.entry&.map { |entry| entry&.resource }
        save_resource_ids_in_bundle(versioned_resource_class('DocumentReference'), reply)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
      end

      test 'Server returns expected results from DocumentReference search by _id' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@documentreference.nil?, 'Expected valid DocumentReference resource to be present'

        id_val = resolve_element_from_path(@documentreference, 'id')
        search_params = { '_id': id_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DocumentReference search by patient+category' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@documentreference.nil?, 'Expected valid DocumentReference resource to be present'

        patient_val = @instance.patient_id
        category_val = resolve_element_from_path(@documentreference, 'category.coding.code')
        search_params = { 'patient': patient_val, 'category': category_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DocumentReference search by patient+category+date' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@documentreference.nil?, 'Expected valid DocumentReference resource to be present'

        patient_val = @instance.patient_id
        category_val = resolve_element_from_path(@documentreference, 'category.coding.code')
        date_val = resolve_element_from_path(@documentreference, 'date')
        search_params = { 'patient': patient_val, 'category': category_val, 'date': date_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DocumentReference search by patient+type' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@documentreference.nil?, 'Expected valid DocumentReference resource to be present'

        patient_val = @instance.patient_id
        type_val = resolve_element_from_path(@documentreference, 'type.coding.code')
        search_params = { 'patient': patient_val, 'type': type_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DocumentReference search by patient+status' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@documentreference.nil?, 'Expected valid DocumentReference resource to be present'

        patient_val = @instance.patient_id
        status_val = resolve_element_from_path(@documentreference, 'status')
        search_params = { 'patient': patient_val, 'status': status_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from DocumentReference search by patient+type+period' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@documentreference.nil?, 'Expected valid DocumentReference resource to be present'

        patient_val = @instance.patient_id
        type_val = resolve_element_from_path(@documentreference, 'type.coding.code')
        period_val = resolve_element_from_path(@documentreference, 'context.period.start')
        search_params = { 'patient': patient_val, 'type': type_val, 'period': period_val }
        search_params.each { |param, value| skip "Could not resolve #{param} in given resource" if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('DocumentReference'), search_params)
        validate_search_reply(versioned_resource_class('DocumentReference'), reply, search_params)
        assert_response_ok(reply)

        ['gt', 'lt', 'le'].each do |comparator|
          comparator_val = date_comparator_value(comparator, period_val)
          comparator_search_params = { 'patient': patient_val, 'type': type_val, 'period': comparator_val }
          reply = get_resource_by_params(versioned_resource_class('DocumentReference'), comparator_search_params)
          validate_search_reply(versioned_resource_class('DocumentReference'), reply, comparator_search_params)
          assert_response_ok(reply)
        end
      end

      test 'DocumentReference create resource supported' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:create])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_create_reply(@documentreference, versioned_resource_class('DocumentReference'))
      end

      test 'DocumentReference read resource supported' do
        metadata do
          id '10'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@documentreference, versioned_resource_class('DocumentReference'))
      end

      test 'DocumentReference vread resource supported' do
        metadata do
          id '11'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@documentreference, versioned_resource_class('DocumentReference'))
      end

      test 'DocumentReference history resource supported' do
        metadata do
          id '12'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@documentreference, versioned_resource_class('DocumentReference'))
      end

      test 'DocumentReference resources associated with Patient conform to US Core R4 profiles' do
        metadata do
          id '13'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-documentreference.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('DocumentReference')
      end

      test 'At least one of every must support element is provided in any DocumentReference for this patient.' do
        metadata do
          id '14'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information' unless @documentreference_ary&.any?
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
          @documentreference_ary&.each do |resource|
            truncated_path = path.gsub('DocumentReference.', '')
            must_support_confirmed[path] = true if can_resolve_path(resource, truncated_path)
            break if must_support_confirmed[path]
          end
          resource_count = @documentreference_ary.length

          skip "Could not find #{path} in any of the #{resource_count} provided DocumentReference resource(s)" unless must_support_confirmed[path]
        end
        @instance.save!
      end

      test 'All references can be resolved' do
        metadata do
          id '15'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:DocumentReference, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@documentreference)
      end
    end
  end
end
