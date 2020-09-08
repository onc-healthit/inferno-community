# frozen_string_literal: true

require_relative './data_absent_reason_checker'
require_relative './profile_definitions/us_core_implantable_device_definitions'

module Inferno
  module Sequence
    class USCore311ImplantableDeviceSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker
      include Inferno::USCore310ProfileDefinitions

      title 'Implantable Device Tests'

      description 'Verify support for the server capabilities required by the US Core Implantable Device Profile.'

      details %(
        # Background

        The US Core #{title} sequence verifies that the system under test is able to provide correct responses
        for Device queries.  These queries must contain resources conforming to US Core Implantable Device Profile as specified
        in the US Core v3.1.0 Implementation Guide. If the system under test contains Device
        resources that are not implantable, and therefore do not conform to the US Core Implantable Device profile,
        the tester should provide an Implantable Device Code to the test to ensure that only the appropriate device types
        are validated against this profile.

        # Testing Methodology


        ## Searching
        This test sequence will first perform each required search associated with this resource. This sequence will perform searches
        with the following parameters:

          * patient



        ### Search Parameters
        The first search uses the selected patient(s) from the prior launch sequence. Any subsequent searches will look for its
        parameter values from the results of the first search. For example, the `identifier` search in the patient sequence is
        performed by looking for an existing `Patient.identifier` from any of the resources returned in the `_id` search. If a
        value cannot be found this way, the search is skipped.

        ### Search Validation
        Inferno will retrieve up to the first 20 bundle pages of the reply for Device resources and save them
        for subsequent tests.
        Each of these resources is then checked to see if it matches the searched parameters in accordance
        with [FHIR search guidelines](https://www.hl7.org/fhir/search.html). The test will fail, for example, if a patient search
        for gender=male returns a female patient.

        ## Must Support
        Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
        at least once. If at least one cannot be found, the test will fail. The test will look through the Device
        resources found for these elements.

        ## Profile Validation
        Each resource returned from the first search is expected to conform to the [US Core Implantable Device Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-implantable-device).
        Each element is checked against teminology binding and cardinality requirements.

        Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
        of the valueset, then the test will fail.

        ## Reference Validation
        Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
        and will fail if any attempted read fails.
      )

      test_id_prefix 'USCID'

      requires :token, :patient_ids, :device_codes
      conformance_supports :Device

      def validate_resource_item(resource, property, value)
        case property

        when 'patient'
          values_found = resolve_path(resource, 'patient.reference')
          value = value.split('Patient/').last
          match_found = values_found.any? { |reference| [value, 'Patient/' + value, "#{@instance.url}/Patient/#{value}"].include? reference }
          assert match_found, "patient in Device/#{resource.id} (#{values_found}) does not match patient requested (#{value})"

        when 'type'
          values_found = resolve_path(resource, 'type')
          coding_system = value.split('|').first.empty? ? nil : value.split('|').first
          coding_value = value.split('|').last
          match_found = values_found.any? do |codeable_concept|
            if value.include? '|'
              codeable_concept.coding.any? { |coding| coding.system == coding_system && coding.code == coding_value }
            else
              codeable_concept.coding.any? { |coding| coding.code == value }
            end
          end
          assert match_found, "type in Device/#{resource.id} (#{values_found}) does not match type requested (#{value})"

        end
      end

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

      @resources_found = false

      test :search_by_patient do
        metadata do
          id '01'
          name 'Server returns valid results for Device search by patient.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient on the Device resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.
            Because this is the first search of the sequence, resources in the response will be used for subsequent tests.
          )
          versions :r4
        end

        skip_if_known_search_not_supported('Device', ['patient'])
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

          @device_ary[patient], non_implantable_devices = @device_ary[patient].partition do |resource|
            device_codes = @instance&.device_codes&.split(',')&.map(&:strip)
            device_codes.blank? || resource&.type&.coding&.any? do |coding|
              device_codes.include?(coding.code)
            end
          end
          validate_reply_entries(non_implantable_devices, search_params)
          if @device_ary[patient].blank? && reply&.resource&.entry&.present?
            @skip_if_not_found_message = "No Devices of the specified type (#{@instance&.device_codes}) were found"
          end

          @device = @device_ary[patient]
            .find { |resource| resource.resourceType == 'Device' }
          @resources_found = @device.present?

          save_resource_references(versioned_resource_class('Device'), @device_ary[patient])
          save_delayed_sequence_references(@device_ary[patient], USCore311ImplantableDeviceSequenceDefinitions::DELAYED_REFERENCES)
          validate_reply_entries(@device_ary[patient], search_params)

          search_params = search_params.merge('patient': "Patient/#{patient}")
          reply = get_resource_by_params(versioned_resource_class('Device'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)
          search_with_type = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
          assert search_with_type.length == @device_ary[patient].length, 'Expected search by Patient/ID to have the same results as search by ID'
        end

        skip_if_not_found(resource_type: 'Device', delayed: false)
      end

      test :search_by_patient_type do
        metadata do
          id '02'
          name 'Server returns valid results for Device search by patient+type.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+type on the Device resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Device', ['patient', 'type'])
        skip_if_not_found(resource_type: 'Device', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'type': get_value_for_search_param(resolve_element_from_path(@device_ary[patient], 'type') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Device'), search_params)

          validate_search_reply(versioned_resource_class('Device'), reply, search_params)

          value_with_system = get_value_for_search_param(resolve_element_from_path(@device_ary[patient], 'type'), true)
          token_with_system_search_params = search_params.merge('type': value_with_system)
          reply = get_resource_by_params(versioned_resource_class('Device'), token_with_system_search_params)
          validate_search_reply(versioned_resource_class('Device'), reply, token_with_system_search_params)
        end

        skip 'Could not resolve all parameters (patient, type) in any resource.' unless resolved_one
      end

      test :read_interaction do
        metadata do
          id '03'
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
          id '04'
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
          id '05'
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
          id '06'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(

            A Server SHALL be capable of supporting the following _revincludes: Provenance:target.

            This test will perform a search for patient + _revIncludes: Provenance:target and will pass
            if a Provenance resource is found in the reponse.

          )
          versions :r4
        end

        skip_if_known_revinclude_not_supported('Device', 'Provenance:target')
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
        end
        save_resource_references(versioned_resource_class('Provenance'), provenance_results)
        save_delayed_sequence_references(provenance_results, USCore311ImplantableDeviceSequenceDefinitions::DELAYED_REFERENCES)

        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '07'
          name 'Device resources returned from previous search conform to the US Core Implantable Device Profile.'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-implantable-device'
          description %(

            This test verifies resources returned from the first search conform to the [US Core Device Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-implantable-device).
            It verifies the presence of mandatory elements and that elements with required bindings contain appropriate values.
            CodeableConcept element bindings will fail if none of its codings have a code/system that is part of the bound ValueSet.
            Quantity, Coding, and code element bindings will fail if its code/system is not found in the valueset.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Device', delayed: false)
        test_resources_against_profile('Device')
      end

      test 'All must support elements are provided in the Device resources returned.' do
        metadata do
          id '08'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through the Device resources found previously for the following must support elements:

            * udiCarrier
            * udiCarrier.deviceIdentifier
            * udiCarrier.carrierAIDC
            * udiCarrier.carrierHRF
            * distinctIdentifier
            * manufactureDate
            * expirationDate
            * lotNumber
            * serialNumber
            * type
            * patient
          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Device', delayed: false)
        must_supports = USCore311ImplantableDeviceSequenceDefinitions::MUST_SUPPORTS

        missing_must_support_elements = must_supports[:elements].reject do |element|
          @device_ary&.values&.flatten&.any? do |resource|
            value_found = resolve_element_from_path(resource, element[:path]) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@device_ary&.values&.flatten&.length} provided Device resource(s)"
        @instance.save!
      end

      test 'Every reference within Device resources can be read.' do
        metadata do
          id '09'
          link 'http://hl7.org/fhir/references.html'
          description %(

            This test will attempt to read the first 50 reference found in the resources from the first search.
            The test will fail if Inferno fails to read any of those references.

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
