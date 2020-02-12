# frozen_string_literal: true

require_relative './data_absent_reason_checker'

module Inferno
  module Sequence
    class USCore310ImplantableDeviceSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker

      title 'Implantable Device Tests'

      description 'Verify that Device resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCID'

      requires :token, :patient_ids, :device_codes
      conformance_supports :Device

      def validate_resource_item(resource, property, value)
        case property

        when 'patient'
          value_found = resolve_element_from_path(resource, 'patient.reference') { |reference| [value, 'Patient/' + value].include? reference }
          assert value_found.present?, 'patient on resource does not match patient requested'

        when 'type'
          value_found = resolve_element_from_path(resource, 'type.coding.code') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'type on resource does not match type requested'

        end
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
          name 'Server rejects Device search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Device, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          reply = get_resource_by_params(versioned_resource_class('Device'), search_params)
          assert_response_unauthorized reply
        end

        @client.set_bearer_token(@instance.token)
      end

      test :search_by_patient do
        metadata do
          id '02'
          name 'Server returns expected results from Device search by patient'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient on the Device resource

          )
          versions :r4
        end

        @device_ary = {}
        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          reply = get_resource_by_params(versioned_resource_class('Device'), search_params)

          assert_response_ok(reply)
          assert_bundle_response(reply)

          any_resources = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Device' }

          next unless any_resources

          @device_ary[patient] = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
            .select do |resource|
            device_codes = @instance&.device_codes&.split(',')&.map(&:strip)
            device_codes.blank? || resource&.type&.coding&.any? do |coding|
              device_codes.include?(coding.code)
            end
          end
          if @device_ary[patient].blank? && reply&.resource&.entry&.present?
            @skip_if_not_found_message = "No Devices of the specified type (#{@instance&.device_codes}) were found"
          end

          @device = @device_ary[patient]
            .find { |resource| resource.resourceType == 'Device' }
          @resources_found = @device.present?

          save_resource_references(versioned_resource_class('Device'), @device_ary[patient])
          save_delayed_sequence_references(@device_ary[patient])
          validate_search_reply(versioned_resource_class('Device'), reply, search_params)
        end

        skip_if_not_found(resource_type: 'Device', delayed: false)
      end

      test :search_by_patient_type do
        metadata do
          id '03'
          name 'Server returns expected results from Device search by patient+type'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+type on the Device resource

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Device', delayed: false)

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'type': get_value_for_search_param(resolve_element_from_path(@device_ary[patient], 'type'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Device'), search_params)

          validate_search_reply(versioned_resource_class('Device'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :read_interaction do
        metadata do
          id '04'
          name 'Server returns correct Device resource from Device read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the Device read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Device, [:read])
        skip_if_not_found(resource_type: 'Device', delayed: false)

        validate_read_reply(@device, versioned_resource_class('Device'), check_for_data_absent_reasons)
      end

      test :vread_interaction do
        metadata do
          id '05'
          name 'Server returns correct Device resource from Device vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Device vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Device, [:vread])
        skip_if_not_found(resource_type: 'Device', delayed: false)

        validate_vread_reply(@device, versioned_resource_class('Device'))
      end

      test :history_interaction do
        metadata do
          id '06'
          name 'Server returns correct Device resource from Device history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Device history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Device, [:history])
        skip_if_not_found(resource_type: 'Device', delayed: false)

        validate_history_reply(@device, versioned_resource_class('Device'))
      end

      test 'Server returns Provenance resources from Device search by patient + _revIncludes: Provenance:target' do
        metadata do
          id '07'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end
        skip_if_not_found(resource_type: 'Device', delayed: false)
        provenance_results = []
        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          search_params['_revinclude'] = 'Provenance:target'
          reply = get_resource_by_params(versioned_resource_class('Device'), search_params)

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
          name 'Device resources returned conform to US Core R4 profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-implantable-device'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Device', delayed: false)
        test_resources_against_profile('Device')
      end

      test 'All must support elements are provided in the Device resources returned.' do
        metadata do
          id '09'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Device resources returned from prior searches to see if any of them provide the following must support elements:

            Device.udiCarrier

            Device.udiCarrier.deviceIdentifier

            Device.udiCarrier.carrierAIDC

            Device.udiCarrier.carrierHRF

            Device.distinctIdentifier

            Device.manufactureDate

            Device.expirationDate

            Device.lotNumber

            Device.serialNumber

            Device.type

            Device.patient

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Device', delayed: false)

        must_support_elements = [
          { path: 'Device.udiCarrier' },
          { path: 'Device.udiCarrier.deviceIdentifier' },
          { path: 'Device.udiCarrier.carrierAIDC' },
          { path: 'Device.udiCarrier.carrierHRF' },
          { path: 'Device.distinctIdentifier' },
          { path: 'Device.manufactureDate' },
          { path: 'Device.expirationDate' },
          { path: 'Device.lotNumber' },
          { path: 'Device.serialNumber' },
          { path: 'Device.type' },
          { path: 'Device.patient' }
        ]

        missing_must_support_elements = must_support_elements.reject do |element|
          truncated_path = element[:path].gsub('Device.', '')
          @device_ary&.values&.flatten&.any? do |resource|
            value_found = resolve_element_from_path(resource, truncated_path) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@device_ary&.values&.flatten&.length} provided Device resource(s)"
        @instance.save!
      end

      test 'Every reference within Device resource is valid and can be read.' do
        metadata do
          id '10'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Device, [:search, :read])
        skip_if_not_found(resource_type: 'Device', delayed: false)

        validated_resources = Set.new
        max_resolutions = 50

        @device_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
