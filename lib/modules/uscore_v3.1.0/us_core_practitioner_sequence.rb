# frozen_string_literal: true

require_relative './data_absent_reason_checker'
require_relative './profile_definitions/us_core_practitioner_definitions'
require_relative './uscore_helpers'

module Inferno
  module Sequence
    class USCore310PractitionerSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker
      include Inferno::USCore310ProfileDefinitions
      include Inferno::USCoreHelpers

      title 'Practitioner Tests'

      description 'Verify support for the server capabilities required by the US Core Practitioner Profile.'

      details %(
        # Background

        The US Core #{title} sequence verifies that the system under test is able to provide correct responses
        for Practitioner queries.  These queries must contain resources conforming to US Core Practitioner Profile as specified
        in the US Core v3.1.0 Implementation Guide.

        # Testing Methodology


        Because Practitioner resources are not present o not exist in USCDI, no searches are performed on this test sequence. Instead, references to
        this profile found in other resources are used for testing. If no references can be found this way, then all the tests
        in this sequence are skipped.


        ## Must Support
        Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
        at least once. If at least one cannot be found, the test will fail. The test will look through the `#{title.gsub(/\s+/, '')}`
        resources found for these elements.

        ## Profile Validation
        Each resource returned from the first search is expected to conform to the [US Core Practitioner Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner).
        Each element is checked against teminology binding and cardinality requirements.

        Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
        of the valueset, then the test will fail.

        ## Reference Validation
        Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
        and will fail if any attempted read fails.
      )

      test_id_prefix 'USCPR'

      requires :token
      conformance_supports :Practitioner
      delayed_sequence

      def validate_resource_item(resource, property, value)
        case property

        when 'name'
          values_found = resolve_path(resource, 'name')
          value_downcase = value.downcase
          match_found = values_found.any? do |name|
            name&.text&.downcase&.start_with?(value_downcase) ||
              name&.family&.downcase&.include?(value_downcase) ||
              name&.given&.any? { |given| given.downcase.start_with?(value_downcase) } ||
              name&.prefix&.any? { |prefix| prefix.downcase.start_with?(value_downcase) } ||
              name&.suffix&.any? { |suffix| suffix.downcase.start_with?(value_downcase) }
          end
          assert match_found, "name in Practitioner/#{resource.id} (#{values_found}) does not match name requested (#{value})"

        when 'identifier'
          values_found = resolve_path(resource, 'identifier')
          identifier_system = value.split('|').first.empty? ? nil : value.split('|').first
          identifier_value = value.split('|').last
          match_found = values_found.any? do |identifier|
            identifier.value == identifier_value && (!value.include?('|') || identifier.system == identifier_system)
          end
          assert match_found, "identifier in Practitioner/#{resource.id} (#{values_found}) does not match identifier requested (#{value})"

        end
      end

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

      @resources_found = false

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Practitioner resource from the Practitioner read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            This test will attempt to Reference to Practitioner can be resolved and read.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Practitioner, [:read])

        practitioner_references = @instance.resource_references.select { |reference| reference.resource_type == 'Practitioner' }
        skip 'No Practitioner references found from the prior searches' if practitioner_references.blank?

        @practitioner_ary = practitioner_references.map do |reference|
          validate_read_reply(
            FHIR::Practitioner.new(id: reference.resource_id),
            FHIR::Practitioner,
            check_for_data_absent_reasons
          )
        end
        @practitioner = @practitioner_ary.first
        @resources_found = @practitioner.present?
      end

      test :search_by_name do
        metadata do
          id '02'
          name 'Server returns valid results for Practitioner search by name.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by name on the Practitioner resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.
            Because this is the first search of the sequence, resources in the response will be used for subsequent tests.
          )
          versions :r4
        end

        skip_if_known_search_not_supported('Practitioner', ['name'])

        search_params = {
          'name': get_value_for_search_param(resolve_element_from_path(@practitioner_ary, 'name') { |el| get_value_for_search_param(el).present? })
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Practitioner'), search_params)

        assert_response_ok(reply)
        assert_bundle_response(reply)

        @resources_found = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Practitioner' }
        skip_if_not_found(resource_type: 'Practitioner', delayed: true)
        search_result_resources = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
        @practitioner_ary += search_result_resources
        @practitioner = @practitioner_ary
          .find { |resource| resource.resourceType == 'Practitioner' }

        save_resource_references(versioned_resource_class('Practitioner'), @practitioner_ary)
        save_delayed_sequence_references(@practitioner_ary, USCore310PractitionerSequenceDefinitions::DELAYED_REFERENCES)
        validate_reply_entries(search_result_resources, search_params)
      end

      test :search_by_identifier do
        metadata do
          id '03'
          name 'Server returns valid results for Practitioner search by identifier.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by identifier on the Practitioner resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Practitioner', ['identifier'])
        skip_if_not_found(resource_type: 'Practitioner', delayed: true)

        search_params = {
          'identifier': get_value_for_search_param(resolve_element_from_path(@practitioner_ary, 'identifier') { |el| get_value_for_search_param(el).present? })
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('Practitioner'), search_params)

        validate_search_reply(versioned_resource_class('Practitioner'), reply, search_params)

        value_with_system = get_value_for_search_param(resolve_element_from_path(@practitioner_ary, 'identifier'), true)
        token_with_system_search_params = search_params.merge('identifier': value_with_system)
        reply = get_resource_by_params(versioned_resource_class('Practitioner'), token_with_system_search_params)
        validate_search_reply(versioned_resource_class('Practitioner'), reply, token_with_system_search_params)
      end

      test :vread_interaction do
        metadata do
          id '04'
          name 'Server returns correct Practitioner resource from Practitioner vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Practitioner vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Practitioner, [:vread])
        skip_if_not_found(resource_type: 'Practitioner', delayed: true)

        validate_vread_reply(@practitioner, versioned_resource_class('Practitioner'))
      end

      test :history_interaction do
        metadata do
          id '05'
          name 'Server returns correct Practitioner resource from Practitioner history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Practitioner history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Practitioner, [:history])
        skip_if_not_found(resource_type: 'Practitioner', delayed: true)

        validate_history_reply(@practitioner, versioned_resource_class('Practitioner'))
      end

      test 'Server returns Provenance resources from Practitioner search by name + _revIncludes: Provenance:target' do
        metadata do
          id '06'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(

            A Server SHALL be capable of supporting the following _revincludes: Provenance:target.

            This test will perform a search for name + _revIncludes: Provenance:target and will pass
            if a Provenance resource is found in the reponse.

          )
          versions :r4
        end

        skip_if_known_revinclude_not_supported('Practitioner', 'Provenance:target')
        skip_if_not_found(resource_type: 'Practitioner', delayed: true)

        provenance_results = []

        search_params = {
          'name': get_value_for_search_param(resolve_element_from_path(@practitioner_ary, 'name') { |el| get_value_for_search_param(el).present? })
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('Practitioner'), search_params)

        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results += fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
          .select { |resource| resource.resourceType == 'Provenance' }

        save_resource_references(versioned_resource_class('Provenance'), provenance_results)
        save_delayed_sequence_references(provenance_results, USCore310PractitionerSequenceDefinitions::DELAYED_REFERENCES)

        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '07'
          name 'Practitioner resources returned from previous search conform to the US Core Practitioner Profile.'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner'
          description %(

            This test verifies resources returned from the first search conform to the [US Core Practitioner Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner).
            It verifies the presence of manditory elements and that elements with required bindgings contain appropriate values.
            CodeableConcept element bindings will fail if none of its codings have a code/system that is part of the bound ValueSet.
            Quantity, Coding, and code element bindings will fail if its code/system is not found in the valueset.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Practitioner', delayed: true)
        test_resources_against_profile('Practitioner')
        bindings = USCore310PractitionerSequenceDefinitions::BINDINGS
        invalid_binding_messages = []
        invalid_binding_resources = Set.new
        bindings.select { |binding_def| binding_def[:strength] == 'required' }.each do |binding_def|
          begin
            invalid_bindings = resources_with_invalid_binding(binding_def, @practitioner_ary)
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
            invalid_bindings = resources_with_invalid_binding(binding_def, @practitioner_ary)
            binding_def_new = binding_def
            # If the valueset binding wasn't valid, check if the codes are in the stated codesystem
            if invalid_bindings.present?
              invalid_bindings = resources_with_invalid_binding(binding_def.except(:system), @practitioner_ary)
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

      test 'All must support elements are provided in the Practitioner resources returned.' do
        metadata do
          id '08'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through the Practitioner resources found previously for the following must support elements:

            * identifier
            * identifier.system
            * identifier.value
            * name
            * name.family
            * Practitioner.identifier:NPI
          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Practitioner', delayed: true)
        must_supports = USCore310PractitionerSequenceDefinitions::MUST_SUPPORTS

        missing_slices = must_supports[:slices].reject do |slice|
          @practitioner_ary&.any? do |resource|
            slice_found = find_slice(resource, slice[:path], slice[:discriminator])
            slice_found.present?
          end
        end

        missing_must_support_elements = must_supports[:elements].reject do |element|
          @practitioner_ary&.any? do |resource|
            value_found = resolve_element_from_path(resource, element[:path]) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        missing_must_support_elements += missing_slices.map { |slice| slice[:name] }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@practitioner_ary&.length} provided Practitioner resource(s)"
        @instance.save!
      end

      test 'Every reference within Practitioner resources can be read.' do
        metadata do
          id '09'
          link 'http://hl7.org/fhir/references.html'
          description %(

            This test will attempt to read the first 50 reference found in the resources from the first search.
            The test will fail if Inferno fails to read any of those references.

          )
          versions :r4
        end

        skip_if_known_not_supported(:Practitioner, [:search, :read])
        skip_if_not_found(resource_type: 'Practitioner', delayed: true)

        validated_resources = Set.new
        max_resolutions = 50

        @practitioner_ary&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
