# frozen_string_literal: true

require_relative './data_absent_reason_checker'
require_relative './profile_definitions/us_core_encounter_definitions'
require_relative './uscore_helpers'

module Inferno
  module Sequence
    class USCore310EncounterSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker
      include Inferno::USCore310ProfileDefinitions
      include Inferno::USCoreHelpers

      title 'Encounter Tests'

      description 'Verify support for the server capabilities required by the US Core Encounter Profile.'

      details %(
        # Background

        The US Core #{title} sequence verifies that the system under test is able to provide correct responses
        for Encounter queries.  These queries must contain resources conforming to US Core Encounter Profile as specified
        in the US Core v3.1.0 Implementation Guide.

        # Testing Methodology


        ## Searching
        This test sequence will first perform each required search associated with this resource. This sequence will perform searches
        with the following parameters:

          * patient
          * _id
          * date + patient



        ### Search Parameters
        The first search uses the selected patient(s) from the prior launch sequence. Any subsequent searches will look for its
        parameter values from the results of the first search. For example, the `identifier` search in the patient sequence is
        performed by looking for an existing `Patient.identifier` from any of the resources returned in the `_id` search. If a
        value cannot be found this way, the search is skipped.

        ### Search Validation
        Inferno will retrieve up to the first 20 bundle pages of the reply for Encounter resources and save them
        for subsequent tests.
        Each of these resources is then checked to see if it matches the searched parameters in accordance
        with [FHIR search guidelines](https://www.hl7.org/fhir/search.html). The test will fail, for example, if a patient search
        for gender=male returns a female patient.

        ## Must Support
        Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
        at least once. If at least one cannot be found, the test will fail. The test will look through the `#{title.gsub(/\s+/, '')}`
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

      requires :token, :patient_ids
      conformance_supports :Encounter

      def validate_resource_item(resource, property, value)
        case property

        when '_id'
          values_found = resolve_path(resource, 'id')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "_id in Encounter/#{resource.id} (#{values_found}) does not match _id requested (#{value})"

        when 'class'
          values_found = resolve_path(resource, 'local_class')
          coding_system = value.split('|').first.empty? ? nil : value.split('|').first
          coding_value = value.split('|').last
          match_found = values_found.any? do |coding|
            if value.include? '|'
              coding.system == coding_system && coding.code == coding_value
            else
              coding.code == value
            end
          end
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

      test :search_by_patient do
        metadata do
          id '01'
          name 'Server returns valid results for Encounter search by patient.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient on the Encounter resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.
            Because this is the first search of the sequence, resources in the response will be used for subsequent tests.
          )
          versions :r4
        end

        skip_if_known_search_not_supported('Encounter', ['patient'])
        @encounter_ary = {}
        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          assert_response_ok(reply)
          assert_bundle_response(reply)

          any_resources = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Encounter' }

          next unless any_resources

          @encounter_ary[patient] = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)

          @encounter = @encounter_ary[patient]
            .find { |resource| resource.resourceType == 'Encounter' }
          @resources_found = @encounter.present?

          save_resource_references(versioned_resource_class('Encounter'), @encounter_ary[patient])
          save_delayed_sequence_references(@encounter_ary[patient], USCore310EncounterSequenceDefinitions::DELAYED_REFERENCES)
          validate_reply_entries(@encounter_ary[patient], search_params)

          search_params = search_params.merge('patient': "Patient/#{patient}")
          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
          assert_response_ok(reply)
          assert_bundle_response(reply)
          search_with_type = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
          assert search_with_type.length == @encounter_ary[patient].length, 'Expected search by Patient/ID to have the same results as search by ID'
        end

        skip_if_not_found(resource_type: 'Encounter', delayed: false)
      end

      test :search_by__id do
        metadata do
          id '02'
          name 'Server returns valid results for Encounter search by _id.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by _id on the Encounter resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Encounter', ['_id'])
        skip_if_not_found(resource_type: 'Encounter', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            '_id': get_value_for_search_param(resolve_element_from_path(@encounter_ary[patient], 'id') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
        end

        skip 'Could not resolve all parameters (_id) in any resource.' unless resolved_one
      end

      test :search_by_date_patient do
        metadata do
          id '03'
          name 'Server returns valid results for Encounter search by date+patient.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by date+patient on the Encounter resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

              This will also test support for these date comparators: gt, lt, le, ge. Comparator values are created by taking
              a date value from a resource returned in the first search of this sequence and adding/subtracting a day. For example, a date
              of 05/05/2020 will create comparator values of lt2020-05-06 and gt2020-05-04

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Encounter', ['date', 'patient'])
        skip_if_not_found(resource_type: 'Encounter', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'date': get_value_for_search_param(resolve_element_from_path(@encounter_ary[patient], 'period') { |el| get_value_for_search_param(el).present? }),
            'patient': patient
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)

          ['gt', 'lt', 'le', 'ge'].each do |comparator|
            comparator_val = date_comparator_value(comparator, search_params[:date])
            comparator_search_params = search_params.merge('date': comparator_val)
            reply = get_resource_by_params(versioned_resource_class('Encounter'), comparator_search_params)
            validate_search_reply(versioned_resource_class('Encounter'), reply, comparator_search_params)
          end
        end

        skip 'Could not resolve all parameters (date, patient) in any resource.' unless resolved_one
      end

      test :search_by_identifier do
        metadata do
          id '04'
          name 'Server returns valid results for Encounter search by identifier.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by identifier on the Encounter resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Encounter', ['identifier'])
        skip_if_not_found(resource_type: 'Encounter', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'identifier': get_value_for_search_param(resolve_element_from_path(@encounter_ary[patient], 'identifier') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)

          value_with_system = get_value_for_search_param(resolve_element_from_path(@encounter_ary[patient], 'identifier'), true)
          token_with_system_search_params = search_params.merge('identifier': value_with_system)
          reply = get_resource_by_params(versioned_resource_class('Encounter'), token_with_system_search_params)
          validate_search_reply(versioned_resource_class('Encounter'), reply, token_with_system_search_params)
        end

        skip 'Could not resolve all parameters (identifier) in any resource.' unless resolved_one
      end

      test :search_by_patient_status do
        metadata do
          id '05'
          name 'Server returns valid results for Encounter search by patient+status.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+status on the Encounter resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Encounter', ['patient', 'status'])
        skip_if_not_found(resource_type: 'Encounter', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'status': get_value_for_search_param(resolve_element_from_path(@encounter_ary[patient], 'status') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)

          validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
        end

        skip 'Could not resolve all parameters (patient, status) in any resource.' unless resolved_one
      end

      test :search_by_class_patient do
        metadata do
          id '06'
          name 'Server returns valid results for Encounter search by class+patient.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by class+patient on the Encounter resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Encounter', ['class', 'patient'])
        skip_if_not_found(resource_type: 'Encounter', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'class': get_value_for_search_param(resolve_element_from_path(@encounter_ary[patient], 'local_class') { |el| get_value_for_search_param(el).present? }),
            'patient': patient
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)

          value_with_system = get_value_for_search_param(resolve_element_from_path(@encounter_ary[patient], 'local_class'), true)
          token_with_system_search_params = search_params.merge('class': value_with_system)
          reply = get_resource_by_params(versioned_resource_class('Encounter'), token_with_system_search_params)
          validate_search_reply(versioned_resource_class('Encounter'), reply, token_with_system_search_params)
        end

        skip 'Could not resolve all parameters (class, patient) in any resource.' unless resolved_one
      end

      test :search_by_patient_type do
        metadata do
          id '07'
          name 'Server returns valid results for Encounter search by patient+type.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+type on the Encounter resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Encounter', ['patient', 'type'])
        skip_if_not_found(resource_type: 'Encounter', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'type': get_value_for_search_param(resolve_element_from_path(@encounter_ary[patient], 'type') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)

          value_with_system = get_value_for_search_param(resolve_element_from_path(@encounter_ary[patient], 'type'), true)
          token_with_system_search_params = search_params.merge('type': value_with_system)
          reply = get_resource_by_params(versioned_resource_class('Encounter'), token_with_system_search_params)
          validate_search_reply(versioned_resource_class('Encounter'), reply, token_with_system_search_params)
        end

        skip 'Could not resolve all parameters (patient, type) in any resource.' unless resolved_one
      end

      test :read_interaction do
        metadata do
          id '08'
          name 'Server returns correct Encounter resource from Encounter read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the Encounter read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Encounter, [:read])
        skip_if_not_found(resource_type: 'Encounter', delayed: false)

        validate_read_reply(@encounter, versioned_resource_class('Encounter'), check_for_data_absent_reasons)
      end

      test :vread_interaction do
        metadata do
          id '09'
          name 'Server returns correct Encounter resource from Encounter vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Encounter vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Encounter, [:vread])
        skip_if_not_found(resource_type: 'Encounter', delayed: false)

        validate_vread_reply(@encounter, versioned_resource_class('Encounter'))
      end

      test :history_interaction do
        metadata do
          id '10'
          name 'Server returns correct Encounter resource from Encounter history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Encounter history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Encounter, [:history])
        skip_if_not_found(resource_type: 'Encounter', delayed: false)

        validate_history_reply(@encounter, versioned_resource_class('Encounter'))
      end

      test 'Server returns Provenance resources from Encounter search by patient + _revIncludes: Provenance:target' do
        metadata do
          id '11'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(

            A Server SHALL be capable of supporting the following _revincludes: Provenance:target.

            This test will perform a search for patient + _revIncludes: Provenance:target and will pass
            if a Provenance resource is found in the reponse.

          )
          versions :r4
        end

        skip_if_known_revinclude_not_supported('Encounter', 'Provenance:target')
        skip_if_not_found(resource_type: 'Encounter', delayed: false)

        provenance_results = []
        patient_ids.each do |patient|
          search_params = {
            'patient': patient
          }

          search_params['_revinclude'] = 'Provenance:target'
          reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          assert_response_ok(reply)
          assert_bundle_response(reply)
          provenance_results += fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
            .select { |resource| resource.resourceType == 'Provenance' }
        end
        save_resource_references(versioned_resource_class('Provenance'), provenance_results)
        save_delayed_sequence_references(provenance_results, USCore310EncounterSequenceDefinitions::DELAYED_REFERENCES)

        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '12'
          name 'Encounter resources returned from previous search conform to the US Core Encounter Profile.'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter'
          description %(

            This test verifies resources returned from the first search conform to the [US Core Encounter Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter).
            It verifies the presence of manditory elements and that elements with required bindgings contain appropriate values.
            CodeableConcept element bindings will fail if none of its codings have a code/system that is part of the bound ValueSet.
            Quantity, Coding, and code element bindings will fail if its code/system is not found in the valueset.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Encounter', delayed: false)
        test_resources_against_profile('Encounter')
        bindings = USCore310EncounterSequenceDefinitions::BINDINGS
        invalid_binding_messages = []
        invalid_binding_resources = Set.new
        bindings.select { |binding_def| binding_def[:strength] == 'required' }.each do |binding_def|
          begin
            invalid_bindings = resources_with_invalid_binding(binding_def, @encounter_ary&.values&.flatten)
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
            invalid_bindings = resources_with_invalid_binding(binding_def, @encounter_ary&.values&.flatten)
            binding_def_new = binding_def
            # If the valueset binding wasn't valid, check if the codes are in the stated codesystem
            if invalid_bindings.present?
              invalid_bindings = resources_with_invalid_binding(binding_def.except(:system), @encounter_ary&.values&.flatten)
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

      test 'All must support elements are provided in the Encounter resources returned.' do
        metadata do
          id '13'
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

        skip_if_not_found(resource_type: 'Encounter', delayed: false)
        must_supports = USCore310EncounterSequenceDefinitions::MUST_SUPPORTS

        missing_must_support_elements = must_supports[:elements].reject do |element|
          @encounter_ary&.values&.flatten&.any? do |resource|
            value_found = resolve_element_from_path(resource, element[:path]) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@encounter_ary&.values&.flatten&.length} provided Encounter resource(s)"
        @instance.save!
      end

      test 'Every reference within Encounter resources can be read.' do
        metadata do
          id '14'
          link 'http://hl7.org/fhir/references.html'
          description %(

            This test will attempt to read the first 50 reference found in the resources from the first search.
            The test will fail if Inferno fails to read any of those references.

          )
          versions :r4
        end

        skip_if_known_not_supported(:Encounter, [:search, :read])
        skip_if_not_found(resource_type: 'Encounter', delayed: false)

        validated_resources = Set.new
        max_resolutions = 50

        @encounter_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
