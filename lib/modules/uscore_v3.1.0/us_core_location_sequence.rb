# frozen_string_literal: true

require_relative './data_absent_reason_checker'
require_relative './profile_definitions/us_core_location_definitions'

module Inferno
  module Sequence
    class USCore310LocationSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker
      include Inferno::USCore310ProfileDefinitions

      title 'Location Tests'

      description 'Verify support for the server capabilities required by the US Core Location Profile.'

      details %(
        # Background

        The US Core #{title} sequence verifies that the system under test is able to provide correct responses
        for Location queries.  These queries must contain resources conforming to US Core Location Profile as specified
        in the US Core v3.1.0 Implementation Guide.

        # Testing Methodology


        Because Location resources are not present o not exist in USCDI, no searches are performed on this test sequence. Instead, references to
        this profile found in other resources are used for testing. If no references can be found this way, then all the tests
        in this sequence are skipped.


        ## Must Support
        Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
        at least once. If at least one cannot be found, the test will fail. The test will look through the `#{title.gsub(/\s+/, '')}`
        resources found for these elements.

        ## Profile Validation
        Each resource returned from the first search is expected to conform to the [US Core Location Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-location).
        Each element is checked against teminology binding and cardinality requirements.

        Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
        of the valueset, then the test will fail.

        ## Reference Validation
        Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
        and will fail if any attempted read fails.
      )

      test_id_prefix 'USCL'

      requires :token
      conformance_supports :Location
      delayed_sequence

      def validate_resource_item(resource, property, value)
        case property

        when 'name'
          values_found = resolve_path(resource, 'name')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "name in Location/#{resource.id} (#{values_found}) does not match name requested (#{value})"

        when 'address'
          values_found = resolve_path(resource, 'address')
          match_found = values_found.any? do |address|
            address&.text&.start_with?(value) ||
              address&.city&.start_with?(value) ||
              address&.state&.start_with?(value) ||
              address&.postalCode&.start_with?(value) ||
              address&.country&.start_with?(value)
          end
          assert match_found, "address in Location/#{resource.id} (#{values_found}) does not match address requested (#{value})"

        when 'address-city'
          values_found = resolve_path(resource, 'address.city')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "address-city in Location/#{resource.id} (#{values_found}) does not match address-city requested (#{value})"

        when 'address-state'
          values_found = resolve_path(resource, 'address.state')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "address-state in Location/#{resource.id} (#{values_found}) does not match address-state requested (#{value})"

        when 'address-postalcode'
          values_found = resolve_path(resource, 'address.postalCode')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "address-postalcode in Location/#{resource.id} (#{values_found}) does not match address-postalcode requested (#{value})"

        end
      end

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

      @resources_found = false

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Location resource from the Location read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            This test will attempt to Reference to Location can be resolved and read.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Location, [:read])

        location_references = @instance.resource_references.select { |reference| reference.resource_type == 'Location' }
        skip 'No Location references found from the prior searches' if location_references.blank?

        @location_ary = location_references.map do |reference|
          validate_read_reply(
            FHIR::Location.new(id: reference.resource_id),
            FHIR::Location,
            check_for_data_absent_reasons
          )
        end
        @location = @location_ary.first
        @resources_found = @location.present?
      end

      test :search_by_name do
        metadata do
          id '02'
          name 'Server returns valid results for Location search by name.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by name on the Location resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.
            Because this is the first search of the sequence, resources in the response will be used for subsequent tests.
          )
          versions :r4
        end

        skip_if_known_search_not_supported('Location', ['name'])

        search_params = {
          'name': get_value_for_search_param(resolve_element_from_path(@location_ary, 'name') { |el| get_value_for_search_param(el).present? })
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)

        assert_response_ok(reply)
        assert_bundle_response(reply)

        @resources_found = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Location' }
        skip_if_not_found(resource_type: 'Location', delayed: true)
        search_result_resources = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
        @location_ary += search_result_resources
        @location = @location_ary
          .find { |resource| resource.resourceType == 'Location' }

        save_resource_references(versioned_resource_class('Location'), @location_ary)
        save_delayed_sequence_references(@location_ary, USCore310LocationSequenceDefinitions::DELAYED_REFERENCES)
        validate_reply_entries(search_result_resources, search_params)
      end

      test :search_by_address do
        metadata do
          id '03'
          name 'Server returns valid results for Location search by address.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by address on the Location resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Location', ['address'])
        skip_if_not_found(resource_type: 'Location', delayed: true)

        search_params = {
          'address': get_value_for_search_param(resolve_element_from_path(@location_ary, 'address') { |el| get_value_for_search_param(el).present? })
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)

        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
      end

      test :search_by_address_city do
        metadata do
          id '04'
          name 'Server returns valid results for Location search by address-city.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by address-city on the Location resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Location', ['address-city'])
        skip_if_not_found(resource_type: 'Location', delayed: true)

        search_params = {
          'address-city': get_value_for_search_param(resolve_element_from_path(@location_ary, 'address.city') { |el| get_value_for_search_param(el).present? })
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)

        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
      end

      test :search_by_address_state do
        metadata do
          id '05'
          name 'Server returns valid results for Location search by address-state.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by address-state on the Location resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Location', ['address-state'])
        skip_if_not_found(resource_type: 'Location', delayed: true)

        search_params = {
          'address-state': get_value_for_search_param(resolve_element_from_path(@location_ary, 'address.state') { |el| get_value_for_search_param(el).present? })
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)

        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
      end

      test :search_by_address_postalcode do
        metadata do
          id '06'
          name 'Server returns valid results for Location search by address-postalcode.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by address-postalcode on the Location resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Location', ['address-postalcode'])
        skip_if_not_found(resource_type: 'Location', delayed: true)

        search_params = {
          'address-postalcode': get_value_for_search_param(resolve_element_from_path(@location_ary, 'address.postalCode') { |el| get_value_for_search_param(el).present? })
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)

        validate_search_reply(versioned_resource_class('Location'), reply, search_params)
      end

      test :vread_interaction do
        metadata do
          id '07'
          name 'Server returns correct Location resource from Location vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Location vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Location, [:vread])
        skip_if_not_found(resource_type: 'Location', delayed: true)

        validate_vread_reply(@location, versioned_resource_class('Location'))
      end

      test :history_interaction do
        metadata do
          id '08'
          name 'Server returns correct Location resource from Location history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Location history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Location, [:history])
        skip_if_not_found(resource_type: 'Location', delayed: true)

        validate_history_reply(@location, versioned_resource_class('Location'))
      end

      test 'Server returns Provenance resources from Location search by name + _revIncludes: Provenance:target' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(

            A Server SHALL be capable of supporting the following _revincludes: Provenance:target.

            This test will perform a search for name + _revIncludes: Provenance:target and will pass
            if a Provenance resource is found in the reponse.

          )
          versions :r4
        end

        skip_if_known_revinclude_not_supported('Location', 'Provenance:target')
        skip_if_not_found(resource_type: 'Location', delayed: true)

        provenance_results = []

        search_params = {
          'name': get_value_for_search_param(resolve_element_from_path(@location_ary, 'name') { |el| get_value_for_search_param(el).present? })
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('Location'), search_params)

        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results += fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
          .select { |resource| resource.resourceType == 'Provenance' }

        save_resource_references(versioned_resource_class('Provenance'), provenance_results)
        save_delayed_sequence_references(provenance_results, USCore310LocationSequenceDefinitions::DELAYED_REFERENCES)

        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '10'
          name 'Location resources returned from previous search conform to the US Core Location Profile.'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-location'
          description %(

            This test verifies resources returned from the first search conform to the [US Core Location Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-location).
            It verifies the presence of manditory elements and that elements with required bindgings contain appropriate values.
            CodeableConcept element bindings will fail if none of its codings have a code/system that is part of the bound ValueSet.
            Quantity, Coding, and code element bindings will fail if its code/system is not found in the valueset.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Location', delayed: true)
        test_resources_against_profile('Location')
        bindings = USCore310LocationSequenceDefinitions::BINDINGS
        invalid_binding_messages = []
        invalid_binding_resources = Set.new
        bindings.select { |binding_def| binding_def[:strength] == 'required' }.each do |binding_def|
          begin
            invalid_bindings = resources_with_invalid_binding(binding_def, @location_ary)
          rescue Inferno::Terminology::UnknownValueSetException => e
            warning do
              assert false, e.message
            end
            invalid_bindings = []
          end
          invalid_bindings.each { |invalid| invalid_binding_resources << "#{invalid[:resource]&.resourceType}/#{invalid[:resource].id}" }
          invalid_binding_messages.concat(invalid_bindings.map { |invalid| invalid_binding_message(invalid, binding_def) })
        end
        assert invalid_binding_messages.blank?, "#{invalid_binding_messages.count} invalid required #{'binding'.pluralize(invalid_binding_messages.count)}" \
        " found in #{invalid_binding_resources.count} #{'resource'.pluralize(invalid_binding_resources.count)}: " \
        "#{invalid_binding_messages.join('. ')}"

        bindings.select { |binding_def| binding_def[:strength] == 'extensible' }.each do |binding_def|
          begin
            invalid_bindings = resources_with_invalid_binding(binding_def, @location_ary)
            binding_def_new = binding_def
            # If the valueset binding wasn't valid, check if the codes are in the stated codesystem
            if invalid_bindings.present?
              invalid_bindings = resources_with_invalid_binding(binding_def.except(:system), @location_ary)
              binding_def_new = binding_def.except(:system)
            end
          rescue Inferno::Terminology::UnknownValueSetException, Inferno::Terminology::ValueSet::UnknownCodeSystemException => e
            warning do
              assert false, e.message
            end
            invalid_bindings = []
          end
          invalid_binding_messages.concat(invalid_bindings.map { |invalid| invalid_binding_message(invalid, binding_def_new) })
        end
        warning do
          invalid_binding_messages.each do |error_message|
            assert false, error_message
          end
        end
      end

      test 'All must support elements are provided in the Location resources returned.' do
        metadata do
          id '11'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through the Location resources found previously for the following must support elements:

            * status
            * name
            * telecom
            * address
            * address.line
            * address.city
            * address.state
            * address.postalCode
            * managingOrganization
          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Location', delayed: true)
        must_supports = USCore310LocationSequenceDefinitions::MUST_SUPPORTS

        missing_must_support_elements = must_supports[:elements].reject do |element|
          @location_ary&.any? do |resource|
            value_found = resolve_element_from_path(resource, element[:path]) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@location_ary&.length} provided Location resource(s)"
        @instance.save!
      end

      test 'Every reference within Location resources can be read.' do
        metadata do
          id '12'
          link 'http://hl7.org/fhir/references.html'
          description %(

            This test will attempt to read the first 50 reference found in the resources from the first search.
            The test will fail if Inferno fails to read any of those references.

          )
          versions :r4
        end

        skip_if_known_not_supported(:Location, [:search, :read])
        skip_if_not_found(resource_type: 'Location', delayed: true)

        validated_resources = Set.new
        max_resolutions = 50

        @location_ary&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
