# frozen_string_literal: true

require_relative './data_absent_reason_checker'
require_relative './profile_definitions/resprate_definitions'

module Inferno
  module Sequence
    class USCore310ResprateSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker
      include Inferno::USCore310ProfileDefinitions

      title 'Observation Respiratory Rate Tests'

      description 'Verify support for the server capabilities required by the Observation Respiratory Rate Profile.'

      details %(
        # Background

        The US Core #{title} sequence verifies that the system under test is able to provide correct responses
        for Observation queries.  These queries must contain resources conforming to Observation Respiratory Rate Profile as specified
        in the US Core v3.1.0 Implementation Guide.

        # Testing Methodology


        ## Searching
        This test sequence will first perform each required search associated with this resource. This sequence will perform searches
        with the following parameters:

          * patient + code
          * patient + category + date
          * patient + category



        ### Search Parameters
        The first search uses the selected patient(s) from the prior launch sequence. Any subsequent searches will look for its
        parameter values from the results of the first search. For example, the `identifier` search in the patient sequence is
        performed by looking for an existing `Patient.identifier` from any of the resources returned in the `_id` search. If a
        value cannot be found this way, the search is skipped.

        ### Search Validation
        Inferno will retrieve up to the first 20 bundle pages of the reply for Observation resources and save them
        for subsequent tests.
        Each of these resources is then checked to see if it matches the searched parameters in accordance
        with [FHIR search guidelines](https://www.hl7.org/fhir/search.html). The test will fail, for example, if a patient search
        for gender=male returns a female patient.

        ## Must Support
        Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
        at least once. If at least one cannot be found, the test will fail. The test will look through the Observation
        resources found for these elements.

        ## Profile Validation
        Each resource returned from the first search is expected to conform to the [Observation Respiratory Rate Profile](http://hl7.org/fhir/StructureDefinition/resprate).
        Each element is checked against teminology binding and cardinality requirements.

        Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
        of the valueset, then the test will fail.

        ## Reference Validation
        Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
        and will fail if any attempted read fails.
      )

      test_id_prefix 'USCORR'

      requires :token, :patient_ids
      conformance_supports :Observation

      def validate_resource_item(resource, property, value)
        case property

        when 'status'
          values_found = resolve_path(resource, 'Observation.status')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "status in Observation/#{resource.id} (#{values_found}) does not match status requested (#{value})"

        when 'category'
          values_found = resolve_path(resource, 'Observation.category')
          coding_system = value.split('|').first.empty? ? nil : value.split('|').first
          coding_value = value.split('|').last
          match_found = values_found.any? do |codeable_concept|
            if value.include? '|'
              codeable_concept.coding.any? { |coding| coding.system == coding_system && coding.code == coding_value }
            else
              codeable_concept.coding.any? { |coding| coding.code == value }
            end
          end
          assert match_found, "category in Observation/#{resource.id} (#{values_found}) does not match category requested (#{value})"

        when 'code'
          values_found = resolve_path(resource, 'Observation.code')
          coding_system = value.split('|').first.empty? ? nil : value.split('|').first
          coding_value = value.split('|').last
          match_found = values_found.any? do |codeable_concept|
            if value.include? '|'
              codeable_concept.coding.any? { |coding| coding.system == coding_system && coding.code == coding_value }
            else
              codeable_concept.coding.any? { |coding| coding.code == value }
            end
          end
          assert match_found, "code in Observation/#{resource.id} (#{values_found}) does not match code requested (#{value})"

        when 'date'
          values_found = resolve_path(resource, 'Observation.effective')
          match_found = values_found.any? { |date| validate_date_search(value, date) }
          assert match_found, "date in Observation/#{resource.id} (#{values_found}) does not match date requested (#{value})"

        when 'patient'
          values_found = resolve_path(resource, 'Observation.subject.reference')
          value = value.split('Patient/').last
          match_found = values_found.any? { |reference| [value, 'Patient/' + value, "#{@instance.url}/Patient/#{value}"].include? reference }
          assert match_found, "patient in Observation/#{resource.id} (#{values_found}) does not match patient requested (#{value})"

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
          assert @instance.server_capabilities&.search_documented?('Observation'),
                 %(Server returned a status of 400 with an OperationOutcome, but the
                 search interaction for this resource is not documented in the
                 CapabilityStatement. If this response was due to the server
                 requiring a status parameter, the server must document this
                 requirement in its CapabilityStatement.)
        end

        ['registered,preliminary,final,amended,corrected,cancelled,entered-in-error,unknown'].each do |status_value|
          params_with_status = search_param.merge('status': status_value)
          reply = get_resource_by_params(versioned_resource_class('Observation'), params_with_status)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          entries = reply.resource.entry.select { |entry| entry.resource.resourceType == 'Observation' }
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

      test :search_by_patient_code do
        metadata do
          id '01'
          name 'Server returns valid results for Observation search by patient+code.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+code on the Observation resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.
            Because this is the first search of the sequence, resources in the response will be used for subsequent tests.
          )
          versions :r4
        end

        skip_if_known_search_not_supported('Observation', ['patient', 'code'])
        @observation_ary = {}
        @resources_found = false
        search_query_variants_tested_once = false
        code_val = ['9279-1']
        patient_ids.each do |patient|
          @observation_ary[patient] = []
          code_val.each do |val|
            search_params = { 'patient': patient, 'code': val }
            reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)

            reply = perform_search_with_status(reply, search_params) if reply.code == 400

            assert_response_ok(reply)
            assert_bundle_response(reply)

            next unless reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Observation' }

            @resources_found = true
            resources_returned = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
            @observation = resources_returned.first
            @observation_ary[patient] += resources_returned

            save_resource_references(versioned_resource_class('Observation'), @observation_ary[patient], Inferno::ValidationUtil::US_CORE_R4_URIS[:resp_rate])
            save_delayed_sequence_references(resources_returned, USCore310ResprateSequenceDefinitions::DELAYED_REFERENCES)
            validate_reply_entries(resources_returned, search_params)

            next if search_query_variants_tested_once

            value_with_system = get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'code'), true)
            token_with_system_search_params = search_params.merge('code': value_with_system)
            reply = get_resource_by_params(versioned_resource_class('Observation'), token_with_system_search_params)
            validate_search_reply(versioned_resource_class('Observation'), reply, token_with_system_search_params)

            search_params_with_type = search_params.merge('patient': "Patient/#{patient}")
            reply = get_resource_by_params(versioned_resource_class('Observation'), search_params_with_type)

            reply = perform_search_with_status(reply, search_params) if reply.code == 400

            assert_response_ok(reply)
            assert_bundle_response(reply)
            search_with_type = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
            assert search_with_type.length == resources_returned.length, 'Expected search by Patient/ID to have the same results as search by ID'

            search_query_variants_tested_once = true
          end
        end
        skip_if_not_found(resource_type: 'Observation', delayed: false)
      end

      test :search_by_patient_category_date do
        metadata do
          id '02'
          name 'Server returns valid results for Observation search by patient+category+date.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+category+date on the Observation resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

              This will also test support for these date comparators: gt, lt, le, ge. Comparator values are created by taking
              a date value from a resource returned in the first search of this sequence and adding/subtracting a day. For example, a date
              of 05/05/2020 will create comparator values of lt2020-05-06 and gt2020-05-04

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Observation', ['patient', 'category', 'date'])
        skip_if_not_found(resource_type: 'Observation', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'category') { |el| get_value_for_search_param(el).present? }),
            'date': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'effective') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('Observation'), reply, search_params)

          ['gt', 'lt', 'le', 'ge'].each do |comparator|
            comparator_val = date_comparator_value(comparator, resolve_element_from_path(@observation_ary[patient], 'effective') { |el| get_value_for_search_param(el).present? })
            comparator_search_params = search_params.merge('date': comparator_val)
            reply = get_resource_by_params(versioned_resource_class('Observation'), comparator_search_params)
            validate_search_reply(versioned_resource_class('Observation'), reply, comparator_search_params)
          end

          value_with_system = get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'category'), true)
          token_with_system_search_params = search_params.merge('category': value_with_system)
          reply = get_resource_by_params(versioned_resource_class('Observation'), token_with_system_search_params)
          validate_search_reply(versioned_resource_class('Observation'), reply, token_with_system_search_params)
        end

        skip 'Could not resolve all parameters (patient, category, date) in any resource.' unless resolved_one
      end

      test :search_by_patient_category do
        metadata do
          id '03'
          name 'Server returns valid results for Observation search by patient+category.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+category on the Observation resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Observation', ['patient', 'category'])
        skip_if_not_found(resource_type: 'Observation', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'category') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('Observation'), reply, search_params)

          value_with_system = get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'category'), true)
          token_with_system_search_params = search_params.merge('category': value_with_system)
          reply = get_resource_by_params(versioned_resource_class('Observation'), token_with_system_search_params)
          validate_search_reply(versioned_resource_class('Observation'), reply, token_with_system_search_params)
        end

        skip 'Could not resolve all parameters (patient, category) in any resource.' unless resolved_one
      end

      test :search_by_patient_code_date do
        metadata do
          id '04'
          name 'Server returns valid results for Observation search by patient+code+date.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+code+date on the Observation resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

              This will also test support for these date comparators: gt, lt, le, ge. Comparator values are created by taking
              a date value from a resource returned in the first search of this sequence and adding/subtracting a day. For example, a date
              of 05/05/2020 will create comparator values of lt2020-05-06 and gt2020-05-04

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Observation', ['patient', 'code', 'date'])
        skip_if_not_found(resource_type: 'Observation', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'code': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'code') { |el| get_value_for_search_param(el).present? }),
            'date': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'effective') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('Observation'), reply, search_params)

          ['gt', 'lt', 'le', 'ge'].each do |comparator|
            comparator_val = date_comparator_value(comparator, resolve_element_from_path(@observation_ary[patient], 'effective') { |el| get_value_for_search_param(el).present? })
            comparator_search_params = search_params.merge('date': comparator_val)
            reply = get_resource_by_params(versioned_resource_class('Observation'), comparator_search_params)
            validate_search_reply(versioned_resource_class('Observation'), reply, comparator_search_params)
          end

          value_with_system = get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'code'), true)
          token_with_system_search_params = search_params.merge('code': value_with_system)
          reply = get_resource_by_params(versioned_resource_class('Observation'), token_with_system_search_params)
          validate_search_reply(versioned_resource_class('Observation'), reply, token_with_system_search_params)
        end

        skip 'Could not resolve all parameters (patient, code, date) in any resource.' unless resolved_one
      end

      test :search_by_patient_category_status do
        metadata do
          id '05'
          name 'Server returns valid results for Observation search by patient+category+status.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+category+status on the Observation resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Observation', ['patient', 'category', 'status'])
        skip_if_not_found(resource_type: 'Observation', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'category') { |el| get_value_for_search_param(el).present? }),
            'status': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'status') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)

          validate_search_reply(versioned_resource_class('Observation'), reply, search_params)

          value_with_system = get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'category'), true)
          token_with_system_search_params = search_params.merge('category': value_with_system)
          reply = get_resource_by_params(versioned_resource_class('Observation'), token_with_system_search_params)
          validate_search_reply(versioned_resource_class('Observation'), reply, token_with_system_search_params)
        end

        skip 'Could not resolve all parameters (patient, category, status) in any resource.' unless resolved_one
      end

      test :read_interaction do
        metadata do
          id '06'
          name 'Server returns correct Observation resource from Observation read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the Observation read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Observation, [:read])
        skip_if_not_found(resource_type: 'Observation', delayed: false)

        validate_read_reply(@observation, versioned_resource_class('Observation'), check_for_data_absent_reasons)
      end

      test :vread_interaction do
        metadata do
          id '07'
          name 'Server returns correct Observation resource from Observation vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Observation vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Observation, [:vread])
        skip_if_not_found(resource_type: 'Observation', delayed: false)

        validate_vread_reply(@observation, versioned_resource_class('Observation'))
      end

      test :history_interaction do
        metadata do
          id '08'
          name 'Server returns correct Observation resource from Observation history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Observation history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Observation, [:history])
        skip_if_not_found(resource_type: 'Observation', delayed: false)

        validate_history_reply(@observation, versioned_resource_class('Observation'))
      end

      test 'Server returns Provenance resources from Observation search by patient + code + _revIncludes: Provenance:target' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(

            A Server SHALL be capable of supporting the following _revincludes: Provenance:target.

            This test will perform a search for patient + code + _revIncludes: Provenance:target and will pass
            if a Provenance resource is found in the reponse.

          )
          versions :r4
        end

        skip_if_known_revinclude_not_supported('Observation', 'Provenance:target')
        skip_if_not_found(resource_type: 'Observation', delayed: false)

        resolved_one = false

        provenance_results = []
        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'code': get_value_for_search_param(resolve_element_from_path(@observation_ary[patient], 'code') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          search_params['_revinclude'] = 'Provenance:target'
          reply = get_resource_by_params(versioned_resource_class('Observation'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          assert_response_ok(reply)
          assert_bundle_response(reply)
          provenance_results += fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
            .select { |resource| resource.resourceType == 'Provenance' }
        end
        save_resource_references(versioned_resource_class('Provenance'), provenance_results)
        save_delayed_sequence_references(provenance_results, USCore310ResprateSequenceDefinitions::DELAYED_REFERENCES)
        skip 'Could not resolve all parameters (patient, code) in any resource.' unless resolved_one
        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '10'
          name 'Observation resources returned from previous search conform to the Observation Respiratory Rate Profile.'
          link 'http://hl7.org/fhir/StructureDefinition/resprate'
          description %(

            This test verifies resources returned from the first search conform to the [US Core Observation Profile](http://hl7.org/fhir/StructureDefinition/resprate).
            It verifies the presence of mandatory elements and that elements with required bindings contain appropriate values.
            CodeableConcept element bindings will fail if none of its codings have a code/system that is part of the bound ValueSet.
            Quantity, Coding, and code element bindings will fail if its code/system is not found in the valueset.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Observation', delayed: false)
        test_resources_against_profile('Observation', Inferno::ValidationUtil::US_CORE_R4_URIS[:resp_rate])
      end

      test 'All must support elements are provided in the Observation resources returned.' do
        metadata do
          id '11'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through the Observation resources found previously for the following must support elements:

            status

            category

            category.coding

            category.coding.system

            category.coding.code

            code

            subject

            effective[x]

            value[x]

            value[x].value

            value[x].unit

            value[x].system

            value[x].code

            dataAbsentReason

            * Observation.category:VSCat
            * Observation.value[x]:valueQuantity
          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Observation', delayed: false)
        must_supports = USCore310ResprateSequenceDefinitions::MUST_SUPPORTS

        missing_slices = must_supports[:slices].reject do |slice|
          @observation_ary&.values&.flatten&.any? do |resource|
            slice_found = find_slice(resource, slice[:path], slice[:discriminator])
            slice_found.present?
          end
        end

        missing_must_support_elements = must_supports[:elements].reject do |element|
          @observation_ary&.values&.flatten&.any? do |resource|
            value_found = resolve_element_from_path(resource, element[:path]) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        missing_must_support_elements += missing_slices.map { |slice| slice[:name] }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@observation_ary&.values&.flatten&.length} provided Observation resource(s)"
        @instance.save!
      end

      test 'Every reference within Observation resources can be read.' do
        metadata do
          id '12'
          link 'http://hl7.org/fhir/references.html'
          description %(

            This test will attempt to read the first 50 reference found in the resources from the first search.
            The test will fail if Inferno fails to read any of those references.

          )
          versions :r4
        end

        skip_if_known_not_supported(:Observation, [:search, :read])
        skip_if_not_found(resource_type: 'Observation', delayed: false)

        validated_resources = Set.new
        max_resolutions = 50

        @observation_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
