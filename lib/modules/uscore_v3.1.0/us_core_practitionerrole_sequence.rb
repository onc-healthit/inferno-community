# frozen_string_literal: true

require_relative './data_absent_reason_checker'
require_relative './profile_definitions/us_core_practitionerrole_definitions'

module Inferno
  module Sequence
    class USCore310PractitionerroleSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker
      include Inferno::USCore310ProfileDefinitions

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

      test :validate_resources do
        metadata do
          id '02'
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
          id '03'
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
          id '04'
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
