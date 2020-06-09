# frozen_string_literal: true

require_relative './data_absent_reason_checker'
require_relative './profile_definitions/us_core_practitionerrole_definitions'
require_relative './uscore_helpers'

module Inferno
  module Sequence
    class USCore310PractitionerroleSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker
      include Inferno::USCore310ProfileDefinitions
      include Inferno::USCoreHelpers

      title 'PractitionerRole Tests'

      description 'Verify support for the server capabilities required by the US Core PractitionerRole Profile.'

      details %(
        # Background

        The US Core #{title} sequence verifies that the system under test is able to provide correct responses
        for PractitionerRole queries.  These queries must contain resources conforming to US Core PractitionerRole Profile as specified
        in the US Core v3.1.0 Implementation Guide.

        # Testing Methodology


        Because PractitionerRole resources are not present o not exist in USCDI, no searches are performed on this test sequence. Instead, references to
        this profile found in other resources are used for testing. If no references can be found this way, then all the tests
        in this sequence are skipped.


        ## Must Support
        Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
        at least once. If at least one cannot be found, the test will fail. The test will look through the `#{title.gsub(/\s+/, '')}`
        resources found for these elements.

        ## Profile Validation
        Each resource returned from the first search is expected to conform to the [US Core PractitionerRole Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitionerrole).
        Each element is checked against teminology binding and cardinality requirements.

        Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
        of the valueset, then the test will fail.

        ## Reference Validation
        Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
        and will fail if any attempted read fails.
      )

      test_id_prefix 'USCPRO'

      requires :token
      conformance_supports :PractitionerRole
      delayed_sequence

      def validate_resource_item(resource, property, value)
        case property

        when 'specialty'
          values_found = resolve_path(resource, 'specialty')
          coding_system = value.split('|').first.empty? ? nil : value.split('|').first
          coding_value = value.split('|').last
          match_found = values_found.any? do |codeable_concept|
            if value.include? '|'
              codeable_concept.coding.any? { |coding| coding.system == coding_system && coding.code == coding_value }
            else
              codeable_concept.coding.any? { |coding| coding.code == value }
            end
          end
          assert match_found, "specialty in PractitionerRole/#{resource.id} (#{values_found}) does not match specialty requested (#{value})"

        when 'practitioner'
          values_found = resolve_path(resource, 'practitioner.reference')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "practitioner in PractitionerRole/#{resource.id} (#{values_found}) does not match practitioner requested (#{value})"

        end
      end

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

      @resources_found = false

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct PractitionerRole resource from the PractitionerRole read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            This test will attempt to Reference to PractitionerRole can be resolved and read.
          )
          versions :r4
        end

        skip_if_known_not_supported(:PractitionerRole, [:read])

        practitioner_role_references = @instance.resource_references.select { |reference| reference.resource_type == 'PractitionerRole' }
        skip 'No PractitionerRole references found from the prior searches' if practitioner_role_references.blank?

        @practitioner_role_ary = practitioner_role_references.map do |reference|
          validate_read_reply(
            FHIR::PractitionerRole.new(id: reference.resource_id),
            FHIR::PractitionerRole,
            check_for_data_absent_reasons
          )
        end
        @practitioner_role = @practitioner_role_ary.first
        @resources_found = @practitioner_role.present?
      end

      test :search_by_specialty do
        metadata do
          id '02'
          name 'Server returns valid results for PractitionerRole search by specialty.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by specialty on the PractitionerRole resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.
            Because this is the first search of the sequence, resources in the response will be used for subsequent tests.
          )
          versions :r4
        end

        skip_if_known_search_not_supported('PractitionerRole', ['specialty'])

        search_params = {
          'specialty': get_value_for_search_param(resolve_element_from_path(@practitioner_role_ary, 'specialty') { |el| get_value_for_search_param(el).present? })
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)

        assert_response_ok(reply)
        assert_bundle_response(reply)

        @resources_found = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'PractitionerRole' }
        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)
        search_result_resources = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
        @practitioner_role_ary += search_result_resources
        @practitioner_role = @practitioner_role_ary
          .find { |resource| resource.resourceType == 'PractitionerRole' }

        save_resource_references(versioned_resource_class('PractitionerRole'), @practitioner_role_ary)
        save_delayed_sequence_references(@practitioner_role_ary, USCore310PractitionerroleSequenceDefinitions::DELAYED_REFERENCES)
        validate_reply_entries(search_result_resources, search_params)
      end

      test :search_by_practitioner do
        metadata do
          id '03'
          name 'Server returns valid results for PractitionerRole search by practitioner.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by practitioner on the PractitionerRole resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('PractitionerRole', ['practitioner'])
        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)

        search_params = {
          'practitioner': get_value_for_search_param(resolve_element_from_path(@practitioner_role_ary, 'practitioner') { |el| get_value_for_search_param(el).present? })
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)

        validate_search_reply(versioned_resource_class('PractitionerRole'), reply, search_params)
      end

      test :chained_search_by_practitioner do
        metadata do
          id '04'
          name 'Server returns expected results from PractitionerRole chained search by practitioner.identifier and practitioner.name'
          link 'https://www.hl7.org/fhir/us/core/StructureDefinition-us-core-practitionerrole.html#mandatory-search-parameters'
          description %(

            A server SHALL support searching the PractitionerRole resource
            with the chained parameters practitioner.identifier and practitioner.name

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)

        practitioner_role = @practitioner_role_ary.find { |role| role.practitioner&.reference.present? }
        skip_if practitioner_role.blank?, 'No PractitionerRoles containing a Practitioner reference were found'

        begin
          practitioner = practitioner_role.practitioner.read
        rescue ClientException => e
          assert false, "Unable to resolve Practitioner reference: #{e}"
        end

        assert practitioner.resourceType == 'Practitioner', "Expected FHIR Practitioner but found: #{practitioner.resourceType}"

        name = practitioner.name&.first&.family
        skip_if name.blank?, 'Practitioner has no family name'

        name_search_response = @client.search(FHIR::PractitionerRole, search: { parameters: { 'practitioner.name': name } })
        assert_response_ok(name_search_response)
        assert_bundle_response(name_search_response)

        name_bundle_entries = fetch_all_bundled_resources(name_search_response, check_for_data_absent_reasons)

        practitioner_role_found = name_bundle_entries.any? { |entry| entry.id == practitioner_role.id }
        assert practitioner_role_found, "PractitionerRole with id #{practitioner_role.id} not found in search results for practitioner.name = #{name}"

        identifier = practitioner.identifier.first
        skip_if identifier.blank?, 'Practitioner has no identifier'
        identifier_string = "#{identifier.system}|#{identifier.value}"

        identifier_search_response = @client.search(
          FHIR::PractitionerRole,
          search: { parameters: { 'practitioner.identifier': identifier_string } }
        )
        assert_response_ok(identifier_search_response)
        assert_bundle_response(identifier_search_response)

        identifier_bundle_entries = fetch_all_bundled_resources(identifier_search_response, check_for_data_absent_reasons)

        practitioner_role_found = identifier_bundle_entries.any? { |entry| entry.id == practitioner_role.id }
        assert practitioner_role_found, "PractitionerRole with id #{practitioner_role.id} not found in search results for practitioner.identifier = #{identifier_string}"
      end

      test :vread_interaction do
        metadata do
          id '05'
          name 'Server returns correct PractitionerRole resource from PractitionerRole vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the PractitionerRole vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:PractitionerRole, [:vread])
        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)

        validate_vread_reply(@practitioner_role, versioned_resource_class('PractitionerRole'))
      end

      test :history_interaction do
        metadata do
          id '06'
          name 'Server returns correct PractitionerRole resource from PractitionerRole history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the PractitionerRole history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:PractitionerRole, [:history])
        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)

        validate_history_reply(@practitioner_role, versioned_resource_class('PractitionerRole'))
      end

      test 'Server returns the appropriate resource from the following specialty +  _includes: PractitionerRole:endpoint, PractitionerRole:practitioner' do
        metadata do
          id '07'
          link 'https://www.hl7.org/fhir/search.html#include'
          optional
          description %(

            A Server SHOULD be capable of supporting the following _includes: PractitionerRole:endpoint, PractitionerRole:practitioner
            This test will perform a search for specialty + each of the following  _includes: PractitionerRole:endpoint, PractitionerRole:practitioner
            The test will fail unless resources for PractitionerRole:endpoint, PractitionerRole:practitioner are returned in their search.

          )
          versions :r4
        end

        search_params = {
          'specialty': get_value_for_search_param(resolve_element_from_path(@practitioner_role_ary, 'specialty') { |el| get_value_for_search_param(el).present? })
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        skip_if_known_include_not_supported('PractitionerRole', 'PractitionerRole:endpoint')
        search_params['_include'] = 'PractitionerRole:endpoint'
        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        endpoint_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Endpoint' }
        assert endpoint_results, 'No Endpoint resources were returned from this search'

        skip_if_known_include_not_supported('PractitionerRole', 'PractitionerRole:practitioner')
        search_params['_include'] = 'PractitionerRole:practitioner'
        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)
        practitioner_results = reply&.resource&.entry&.map(&:resource)&.any? { |resource| resource.resourceType == 'Practitioner' }
        assert practitioner_results, 'No Practitioner resources were returned from this search'
      end

      test 'Server returns Provenance resources from PractitionerRole search by specialty + _revIncludes: Provenance:target' do
        metadata do
          id '08'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(

            A Server SHALL be capable of supporting the following _revincludes: Provenance:target.

            This test will perform a search for specialty + _revIncludes: Provenance:target and will pass
            if a Provenance resource is found in the reponse.

          )
          versions :r4
        end

        skip_if_known_revinclude_not_supported('PractitionerRole', 'Provenance:target')
        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)

        provenance_results = []

        search_params = {
          'specialty': get_value_for_search_param(resolve_element_from_path(@practitioner_role_ary, 'specialty') { |el| get_value_for_search_param(el).present? })
        }

        search_params.each { |param, value| skip "Could not resolve #{param} in any resource." if value.nil? }

        search_params['_revinclude'] = 'Provenance:target'
        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)

        assert_response_ok(reply)
        assert_bundle_response(reply)
        provenance_results += fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
          .select { |resource| resource.resourceType == 'Provenance' }

        save_resource_references(versioned_resource_class('Provenance'), provenance_results)
        save_delayed_sequence_references(provenance_results, USCore310PractitionerroleSequenceDefinitions::DELAYED_REFERENCES)

        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '09'
          name 'PractitionerRole resources returned from previous search conform to the US Core PractitionerRole Profile.'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitionerrole'
          description %(

            This test verifies resources returned from the first search conform to the [US Core PractitionerRole Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitionerrole).
            It verifies the presence of manditory elements and that elements with required bindgings contain appropriate values.
            CodeableConcept element bindings will fail if none of its codings have a code/system that is part of the bound ValueSet.
            Quantity, Coding, and code element bindings will fail if its code/system is not found in the valueset.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)
        test_resources_against_profile('PractitionerRole')
        bindings = USCore310PractitionerroleSequenceDefinitions::BINDINGS
        invalid_binding_messages = []
        invalid_binding_resources = Set.new
        bindings.select { |binding_def| binding_def[:strength] == 'required' }.each do |binding_def|
          begin
            invalid_bindings = resources_with_invalid_binding(binding_def, @practitioner_role_ary)
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
            invalid_bindings = resources_with_invalid_binding(binding_def, @practitioner_role_ary)
            binding_def_new = binding_def
            # If the valueset binding wasn't valid, check if the codes are in the stated codesystem
            if invalid_bindings.present?
              invalid_bindings = resources_with_invalid_binding(binding_def.except(:system), @practitioner_role_ary)
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

      test 'All must support elements are provided in the PractitionerRole resources returned.' do
        metadata do
          id '10'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through the PractitionerRole resources found previously for the following must support elements:

            * practitioner
            * organization
            * code
            * specialty
            * location
            * telecom
            * telecom.system
            * telecom.value
            * endpoint
          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)
        must_supports = USCore310PractitionerroleSequenceDefinitions::MUST_SUPPORTS

        missing_must_support_elements = must_supports[:elements].reject do |element|
          @practitioner_role_ary&.any? do |resource|
            value_found = resolve_element_from_path(resource, element[:path]) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@practitioner_role_ary&.length} provided PractitionerRole resource(s)"
        @instance.save!
      end

      test 'Every reference within PractitionerRole resources can be read.' do
        metadata do
          id '11'
          link 'http://hl7.org/fhir/references.html'
          description %(

            This test will attempt to read the first 50 reference found in the resources from the first search.
            The test will fail if Inferno fails to read any of those references.

          )
          versions :r4
        end

        skip_if_known_not_supported(:PractitionerRole, [:search, :read])
        skip_if_not_found(resource_type: 'PractitionerRole', delayed: true)

        validated_resources = Set.new
        max_resolutions = 50

        @practitioner_role_ary&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
