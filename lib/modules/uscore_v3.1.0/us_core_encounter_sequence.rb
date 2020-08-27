# frozen_string_literal: true

require_relative './data_absent_reason_checker'
require_relative './profile_definitions/us_core_encounter_definitions'

module Inferno
  module Sequence
    class USCore310EncounterSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker
      include Inferno::USCore310ProfileDefinitions

      title 'Encounter Tests'

      description 'Verify support for the server capabilities required by the US Core Encounter Profile.'

      details %(
        # Background

        The US Core #{title} sequence verifies that the system under test is able to provide correct responses
        for Encounter queries.  These queries must contain resources conforming to US Core Encounter Profile as specified
        in the US Core v3.1.0 Implementation Guide.

        # Testing Methodology


        Because Encounter resources are not present or do not exist in USCDI, no searches are performed on this test sequence. Instead, references to
        this profile found in other resources are used for testing. If no references can be found this way, then all the tests
        in this sequence are skipped.


        ## Must Support
        Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
        at least once. If at least one cannot be found, the test will fail. The test will look through the Encounter
        resources found for these elements.

        ## Profile Validation
        Each resource returned from the first search is expected to conform to the [US Core Encounter Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter).
        Each element is checked against teminology binding and cardinality requirements.

        Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
        of the valueset, then the test will fail.

        ## Reference Validation
        Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
        and will fail if any attempted read fails.
      )

      test_id_prefix 'USCE'

      requires :token
      conformance_supports :Encounter
      delayed_sequence

      def validate_resource_item(resource, property, value)
        case property

        when '_id'
          values_found = resolve_path(resource, 'id')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "_id in Encounter/#{resource.id} (#{values_found}) does not match _id requested (#{value})"

        when 'class'
          values_found = resolve_path(resource, 'local_class')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "class in Encounter/#{resource.id} (#{values_found}) does not match class requested (#{value})"

        when 'date'
          values_found = resolve_path(resource, 'period')
          match_found = values_found.any? { |date| validate_date_search(value, date) }
          assert match_found, "date in Encounter/#{resource.id} (#{values_found}) does not match date requested (#{value})"

        when 'identifier'
          values_found = resolve_path(resource, 'identifier')
          identifier_system = value.split('|').first.empty? ? nil : value.split('|').first
          identifier_value = value.split('|').last
          match_found = values_found.any? do |identifier|
            identifier.value == identifier_value && (!value.include?('|') || identifier.system == identifier_system)
          end
          assert match_found, "identifier in Encounter/#{resource.id} (#{values_found}) does not match identifier requested (#{value})"

        when 'patient'
          values_found = resolve_path(resource, 'subject.reference')
          value = value.split('Patient/').last
          match_found = values_found.any? { |reference| [value, 'Patient/' + value, "#{@instance.url}/Patient/#{value}"].include? reference }
          assert match_found, "patient in Encounter/#{resource.id} (#{values_found}) does not match patient requested (#{value})"

        when 'status'
          values_found = resolve_path(resource, 'status')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "status in Encounter/#{resource.id} (#{values_found}) does not match status requested (#{value})"

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
          assert match_found, "type in Encounter/#{resource.id} (#{values_found}) does not match type requested (#{value})"

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
          assert @instance.server_capabilities&.search_documented?('Encounter'),
                 %(Server returned a status of 400 with an OperationOutcome, but the
                 search interaction for this resource is not documented in the
                 CapabilityStatement. If this response was due to the server
                 requiring a status parameter, the server must document this
                 requirement in its CapabilityStatement.)
        end

        ['planned', 'arrived', 'triaged', 'in-progress', 'onleave', 'finished', 'cancelled', 'entered-in-error', 'unknown'].each do |status_value|
          params_with_status = search_param.merge('status': status_value)
          reply = get_resource_by_params(versioned_resource_class('Encounter'), params_with_status)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          entries = reply.resource.entry.select { |entry| entry.resource.resourceType == 'Encounter' }
          next if entries.blank?

          search_param.merge!('status': status_value)
          break
        end

        reply
      end

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

      @resources_found = false

      test :resource_read do
        metadata do
          id '01'
          name 'Server returns correct Encounter resource from the Encounter read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            This test will attempt to Reference to Encounter can be resolved and read.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Encounter, [:read])

        encounter_references = @instance.resource_references.select { |reference| reference.resource_type == 'Encounter' }
        skip 'No Encounter references found from the prior searches' if encounter_references.blank?

        @encounter_ary = encounter_references.map do |reference|
          validate_read_reply(
            FHIR::Encounter.new(id: reference.resource_id),
            FHIR::Encounter,
            check_for_data_absent_reasons
          )
        end
        @encounter = @encounter_ary.first
        @resources_found = @encounter.present?
      end

      test :validate_resources do
        metadata do
          id '02'
          name 'Encounter resources returned from previous search conform to the US Core Encounter Profile.'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter'
          description %(

            This test verifies resources returned from the first search conform to the [US Core Encounter Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter).
            It verifies the presence of mandatory elements and that elements with required bindgings contain appropriate values.
            CodeableConcept element bindings will fail if none of its codings have a code/system that is part of the bound ValueSet.
            Quantity, Coding, and code element bindings will fail if its code/system is not found in the valueset.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Encounter', delayed: true)
        test_resources_against_profile('Encounter')
      end

      test 'All must support elements are provided in the Encounter resources returned.' do
        metadata do
          id '03'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through the Encounter resources found previously for the following must support elements:

            * identifier
            * identifier.system
            * identifier.value
            * status
            * class
            * type
            * subject
            * participant
            * participant.type
            * participant.period
            * participant.individual
            * period
            * reasonCode
            * hospitalization
            * hospitalization.dischargeDisposition
            * location
            * location.location
          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Encounter', delayed: true)
        must_supports = USCore310EncounterSequenceDefinitions::MUST_SUPPORTS

        missing_must_support_elements = must_supports[:elements].reject do |element|
          @encounter_ary&.any? do |resource|
            value_found = resolve_element_from_path(resource, element[:path]) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@encounter_ary&.length} provided Encounter resource(s)"
        @instance.save!
      end

      test 'Every reference within Encounter resources can be read.' do
        metadata do
          id '04'
          link 'http://hl7.org/fhir/references.html'
          description %(

            This test will attempt to read the first 50 reference found in the resources from the first search.
            The test will fail if Inferno fails to read any of those references.

          )
          versions :r4
        end

        skip_if_known_not_supported(:Encounter, [:search, :read])
        skip_if_not_found(resource_type: 'Encounter', delayed: true)

        validated_resources = Set.new
        max_resolutions = 50

        @encounter_ary&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
