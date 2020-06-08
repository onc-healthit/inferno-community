# frozen_string_literal: true

require_relative './data_absent_reason_checker'
require_relative './profile_definitions/us_core_careplan_definitions'

module Inferno
  module Sequence
    class USCore310CareplanSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker
      include Inferno::USCore310ProfileDefinitions

      title 'CarePlan Tests'

      description 'Verify support for the server capabilities required by the US Core CarePlan Profile.'

      details %(
        # Background

        The US Core #{title} sequence verifies that the system under test is able to provide correct responses
        for CarePlan queries.  These queries must contain resources conforming to US Core CarePlan Profile as specified
        in the US Core v3.1.0 Implementation Guide.

        # Testing Methodology


        ## Searching
        This test sequence will first perform each required search associated with this resource. This sequence will perform searches
        with the following parameters:

          * patient + category



        ### Search Parameters
        The first search uses the selected patient(s) from the prior launch sequence. Any subsequent searches will look for its
        parameter values from the results of the first search. For example, the `identifier` search in the patient sequence is
        performed by looking for an existing `Patient.identifier` from any of the resources returned in the `_id` search. If a
        value cannot be found this way, the search is skipped.

        ### Search Validation
        Inferno will retrieve up to the first 20 bundle pages of the reply for CarePlan resources and save them
        for subsequent tests.
        Each of these resources is then checked to see if it matches the searched parameters in accordance
        with [FHIR search guidelines](https://www.hl7.org/fhir/search.html). The test will fail, for example, if a patient search
        for gender=male returns a female patient.

        ## Must Support
        Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
        at least once. If at least one cannot be found, the test will fail. The test will look through the `#{title.gsub(/\s+/, '')}`
        resources found for these elements.

        ## Profile Validation
        Each resource returned from the first search is expected to conform to the [US Core CarePlan Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-careplan).
        Each element is checked against teminology binding and cardinality requirements.

        Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
        of the valueset, then the test will fail.

        ## Reference Validation
        Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
        and will fail if any attempted read fails.
      )

      test_id_prefix 'USCCP'

      requires :token, :patient_ids
      conformance_supports :CarePlan

      def validate_resource_item(resource, property, value)
        case property

        when 'category'
          values_found = resolve_path(resource, 'category')
          coding_system = value.split('|').first.empty? ? nil : value.split('|').first
          coding_value = value.split('|').last
          match_found = values_found.any? do |codeable_concept|
            if value.include? '|'
              codeable_concept.coding.any? { |coding| coding.system == coding_system && coding.code == coding_value }
            else
              codeable_concept.coding.any? { |coding| coding.code == value }
            end
          end
          assert match_found, "category in CarePlan/#{resource.id} (#{values_found}) does not match category requested (#{value})"

        when 'date'
          values_found = resolve_path(resource, 'period')
          match_found = values_found.any? { |date| validate_date_search(value, date) }
          assert match_found, "date in CarePlan/#{resource.id} (#{values_found}) does not match date requested (#{value})"

        when 'patient'
          values_found = resolve_path(resource, 'subject.reference')
          value = value.split('Patient/').last
          match_found = values_found.any? { |reference| [value, 'Patient/' + value, "#{@instance.url}/Patient/#{value}"].include? reference }
          assert match_found, "patient in CarePlan/#{resource.id} (#{values_found}) does not match patient requested (#{value})"

        when 'status'
          values_found = resolve_path(resource, 'status')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "status in CarePlan/#{resource.id} (#{values_found}) does not match status requested (#{value})"

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
          assert @instance.server_capabilities&.search_documented?('CarePlan'),
                 %(Server returned a status of 400 with an OperationOutcome, but the
                 search interaction for this resource is not documented in the
                 CapabilityStatement. If this response was due to the server
                 requiring a status parameter, the server must document this
                 requirement in its CapabilityStatement.)
        end

        ['draft,active,on-hold,revoked,completed,entered-in-error,unknown'].each do |status_value|
          params_with_status = search_param.merge('status': status_value)
          reply = get_resource_by_params(versioned_resource_class('CarePlan'), params_with_status)
          assert_response_ok(reply)
          assert_bundle_response(reply)

          entries = reply.resource.entry.select { |entry| entry.resource.resourceType == 'CarePlan' }
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

      test :search_by_patient_category do
        metadata do
          id '01'
          name 'Server returns valid results for CarePlan search by patient+category.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by patient+category on the CarePlan resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.
            Because this is the first search of the sequence, resources in the response will be used for subsequent tests.
          )
          versions :r4
        end

        skip_if_known_search_not_supported('CarePlan', ['patient', 'category'])
        @care_plan_ary = {}
        @resources_found = false

        category_val = ['assess-plan']
        patient_ids.each do |patient|
          @care_plan_ary[patient] = []
          category_val.each do |val|
            search_params = { 'patient': patient, 'category': val }
            reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)

            reply = perform_search_with_status(reply, search_params) if reply.code == 400

            assert_response_ok(reply)
            assert_bundle_response(reply)

            next unless reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'CarePlan' }

            @resources_found = true
            resources_returned = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
            @care_plan = resources_returned.first
            @care_plan_ary[patient] += resources_returned

            save_resource_references(versioned_resource_class('CarePlan'), @care_plan_ary[patient])
            save_delayed_sequence_references(resources_returned, USCore310CareplanSequenceDefinitions::DELAYED_REFERENCES)
            validate_reply_entries(resources_returned, search_params)

            value_with_system = get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'category'), true)
            token_with_system_search_params = search_params.merge('category': value_with_system)
            reply = get_resource_by_params(versioned_resource_class('CarePlan'), token_with_system_search_params)
            validate_search_reply(versioned_resource_class('CarePlan'), reply, token_with_system_search_params)

            search_params_with_type = search_params.merge('patient': "Patient/#{patient}")
            reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params_with_type)

            reply = perform_search_with_status(reply, search_params) if reply.code == 400

            assert_response_ok(reply)
            assert_bundle_response(reply)
            search_with_type = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
            assert search_with_type.length == resources_returned.length, 'Expected search by Patient/ID to have the same results as search by ID'

            break
          end
        end
        skip_if_not_found(resource_type: 'CarePlan', delayed: false)
      end

      test :search_by_patient_category_date do
        metadata do
          id '02'
          name 'Server returns valid results for CarePlan search by patient+category+date.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+category+date on the CarePlan resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

              This will also test support for these date comparators: gt, lt, le, ge. Comparator values are created by taking
              a date value from a resource returned in the first search of this sequence and adding/subtracting a day. For example, a date
              of 05/05/2020 will create comparator values of lt2020-05-06 and gt2020-05-04

          )
          versions :r4
        end

        skip_if_known_search_not_supported('CarePlan', ['patient', 'category', 'date'])
        skip_if_not_found(resource_type: 'CarePlan', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'category') { |el| get_value_for_search_param(el).present? }),
            'date': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'period') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)

          ['gt', 'lt', 'le', 'ge'].each do |comparator|
            comparator_val = date_comparator_value(comparator, search_params[:date])
            comparator_search_params = search_params.merge('date': comparator_val)
            reply = get_resource_by_params(versioned_resource_class('CarePlan'), comparator_search_params)
            validate_search_reply(versioned_resource_class('CarePlan'), reply, comparator_search_params)
          end

          value_with_system = get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'category'), true)
          token_with_system_search_params = search_params.merge('category': value_with_system)
          reply = get_resource_by_params(versioned_resource_class('CarePlan'), token_with_system_search_params)
          validate_search_reply(versioned_resource_class('CarePlan'), reply, token_with_system_search_params)
        end

        skip 'Could not resolve all parameters (patient, category, date) in any resource.' unless resolved_one
      end

      test :search_by_patient_category_status_date do
        metadata do
          id '03'
          name 'Server returns valid results for CarePlan search by patient+category+status+date.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+category+status+date on the CarePlan resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

              This will also test support for these date comparators: gt, lt, le, ge. Comparator values are created by taking
              a date value from a resource returned in the first search of this sequence and adding/subtracting a day. For example, a date
              of 05/05/2020 will create comparator values of lt2020-05-06 and gt2020-05-04

          )
          versions :r4
        end

        skip_if_known_search_not_supported('CarePlan', ['patient', 'category', 'status', 'date'])
        skip_if_not_found(resource_type: 'CarePlan', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'category') { |el| get_value_for_search_param(el).present? }),
            'status': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'status') { |el| get_value_for_search_param(el).present? }),
            'date': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'period') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)

          validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)

          ['gt', 'lt', 'le', 'ge'].each do |comparator|
            comparator_val = date_comparator_value(comparator, search_params[:date])
            comparator_search_params = search_params.merge('date': comparator_val)
            reply = get_resource_by_params(versioned_resource_class('CarePlan'), comparator_search_params)
            validate_search_reply(versioned_resource_class('CarePlan'), reply, comparator_search_params)
          end

          value_with_system = get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'category'), true)
          token_with_system_search_params = search_params.merge('category': value_with_system)
          reply = get_resource_by_params(versioned_resource_class('CarePlan'), token_with_system_search_params)
          validate_search_reply(versioned_resource_class('CarePlan'), reply, token_with_system_search_params)
        end

        skip 'Could not resolve all parameters (patient, category, status, date) in any resource.' unless resolved_one
      end

      test :search_by_patient_category_status do
        metadata do
          id '04'
          name 'Server returns valid results for CarePlan search by patient+category+status.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by patient+category+status on the CarePlan resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('CarePlan', ['patient', 'category', 'status'])
        skip_if_not_found(resource_type: 'CarePlan', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'category') { |el| get_value_for_search_param(el).present? }),
            'status': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'status') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)

          validate_search_reply(versioned_resource_class('CarePlan'), reply, search_params)

          value_with_system = get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'category'), true)
          token_with_system_search_params = search_params.merge('category': value_with_system)
          reply = get_resource_by_params(versioned_resource_class('CarePlan'), token_with_system_search_params)
          validate_search_reply(versioned_resource_class('CarePlan'), reply, token_with_system_search_params)
        end

        skip 'Could not resolve all parameters (patient, category, status) in any resource.' unless resolved_one
      end

      test :read_interaction do
        metadata do
          id '05'
          name 'Server returns correct CarePlan resource from CarePlan read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the CarePlan read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:CarePlan, [:read])
        skip_if_not_found(resource_type: 'CarePlan', delayed: false)

        validate_read_reply(@care_plan, versioned_resource_class('CarePlan'), check_for_data_absent_reasons)
      end

      test :vread_interaction do
        metadata do
          id '06'
          name 'Server returns correct CarePlan resource from CarePlan vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the CarePlan vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:CarePlan, [:vread])
        skip_if_not_found(resource_type: 'CarePlan', delayed: false)

        validate_vread_reply(@care_plan, versioned_resource_class('CarePlan'))
      end

      test :history_interaction do
        metadata do
          id '07'
          name 'Server returns correct CarePlan resource from CarePlan history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the CarePlan history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:CarePlan, [:history])
        skip_if_not_found(resource_type: 'CarePlan', delayed: false)

        validate_history_reply(@care_plan, versioned_resource_class('CarePlan'))
      end

      test 'Server returns Provenance resources from CarePlan search by patient + category + _revIncludes: Provenance:target' do
        metadata do
          id '08'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(

            A Server SHALL be capable of supporting the following _revincludes: Provenance:target.

            This test will perform a search for patient + category + _revIncludes: Provenance:target and will pass
            if a Provenance resource is found in the reponse.

          )
          versions :r4
        end

        skip_if_known_revinclude_not_supported('CarePlan', 'Provenance:target')
        skip_if_not_found(resource_type: 'CarePlan', delayed: false)

        resolved_one = false

        provenance_results = []
        patient_ids.each do |patient|
          search_params = {
            'patient': patient,
            'category': get_value_for_search_param(resolve_element_from_path(@care_plan_ary[patient], 'category') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          search_params['_revinclude'] = 'Provenance:target'
          reply = get_resource_by_params(versioned_resource_class('CarePlan'), search_params)

          reply = perform_search_with_status(reply, search_params) if reply.code == 400

          assert_response_ok(reply)
          assert_bundle_response(reply)
          provenance_results += fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
            .select { |resource| resource.resourceType == 'Provenance' }
        end
        save_resource_references(versioned_resource_class('Provenance'), provenance_results)
        save_delayed_sequence_references(provenance_results, USCore310CareplanSequenceDefinitions::DELAYED_REFERENCES)
        skip 'Could not resolve all parameters (patient, category) in any resource.' unless resolved_one
        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '09'
          name 'CarePlan resources returned from previous search conform to the US Core CarePlan Profile.'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-careplan'
          description %(

            This test verifies resources returned from the first search conform to the [US Core CarePlan Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-careplan).
            It verifies the presence of manditory elements and that elements with required bindgings contain appropriate values.
            CodeableConcept element bindings will fail if none of its codings have a code/system that is part of the bound ValueSet.
            Quantity, Coding, and code element bindings will fail if its code/system is not found in the valueset.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'CarePlan', delayed: false)
        test_resources_against_profile('CarePlan')
        bindings = USCore310CareplanSequenceDefinitions::BINDINGS
        invalid_binding_messages = []
        invalid_binding_resources = Set.new
        bindings.select { |binding_def| binding_def[:strength] == 'required' }.each do |binding_def|
          begin
            invalid_bindings = resources_with_invalid_binding(binding_def, @care_plan_ary&.values&.flatten)
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
            invalid_bindings = resources_with_invalid_binding(binding_def, @care_plan_ary&.values&.flatten)
            binding_def_new = binding_def
            # If the valueset binding wasn't valid, check if the codes are in the stated codesystem
            if invalid_bindings.present?
              invalid_bindings = resources_with_invalid_binding(binding_def.except(:system), @care_plan_ary&.values&.flatten)
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

      test 'All must support elements are provided in the CarePlan resources returned.' do
        metadata do
          id '10'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through the CarePlan resources found previously for the following must support elements:

            * text
            * text.status
            * status
            * intent
            * category
            * subject
            * CarePlan.category:AssessPlan
          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'CarePlan', delayed: false)
        must_supports = USCore310CareplanSequenceDefinitions::MUST_SUPPORTS

        missing_slices = must_supports[:slices].reject do |slice|
          @care_plan_ary&.values&.flatten&.any? do |resource|
            slice_found = find_slice(resource, slice[:path], slice[:discriminator])
            slice_found.present?
          end
        end

        missing_must_support_elements = must_supports[:elements].reject do |element|
          @care_plan_ary&.values&.flatten&.any? do |resource|
            value_found = resolve_element_from_path(resource, element[:path]) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        missing_must_support_elements += missing_slices.map { |slice| slice[:name] }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@care_plan_ary&.values&.flatten&.length} provided CarePlan resource(s)"
        @instance.save!
      end

      test 'Every reference within CarePlan resources can be read.' do
        metadata do
          id '11'
          link 'http://hl7.org/fhir/references.html'
          description %(

            This test will attempt to read the first 50 reference found in the resources from the first search.
            The test will fail if Inferno fails to read any of those references.

          )
          versions :r4
        end

        skip_if_known_not_supported(:CarePlan, [:search, :read])
        skip_if_not_found(resource_type: 'CarePlan', delayed: false)

        validated_resources = Set.new
        max_resolutions = 50

        @care_plan_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
