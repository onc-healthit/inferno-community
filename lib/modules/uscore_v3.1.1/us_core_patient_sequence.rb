# frozen_string_literal: true

require_relative './data_absent_reason_checker'
require_relative './profile_definitions/us_core_patient_definitions'

module Inferno
  module Sequence
    class USCore311PatientSequence < SequenceBase
      include Inferno::DataAbsentReasonChecker
      include Inferno::USCore311ProfileDefinitions

      title 'Patient Tests'

      description 'Verify support for the server capabilities required by the US Core Patient Profile.'

      details %(
        # Background

        The US Core #{title} sequence verifies that the system under test is able to provide correct responses
        for Patient queries.  These queries must contain resources conforming to US Core Patient Profile as specified
        in the US Core v3.1.1 Implementation Guide.

        # Testing Methodology


        ## Searching
        This test sequence will first perform each required search associated with this resource. This sequence will perform searches
        with the following parameters:

          * _id
          * identifier
          * name
          * birthdate + name
          * gender + name



        ### Search Parameters
        The first search uses the selected patient(s) from the prior launch sequence. Any subsequent searches will look for its
        parameter values from the results of the first search. For example, the `identifier` search in the patient sequence is
        performed by looking for an existing `Patient.identifier` from any of the resources returned in the `_id` search. If a
        value cannot be found this way, the search is skipped.

        ### Search Validation
        Inferno will retrieve up to the first 20 bundle pages of the reply for Patient resources and save them
        for subsequent tests.
        Each of these resources is then checked to see if it matches the searched parameters in accordance
        with [FHIR search guidelines](https://www.hl7.org/fhir/search.html). The test will fail, for example, if a patient search
        for gender=male returns a female patient.

        ## Must Support
        Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
        at least once. If at least one cannot be found, the test will fail. The test will look through the Patient
        resources found for these elements.

        ## Profile Validation
        Each resource returned from the first search is expected to conform to the [US Core Patient Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient).
        Each element is checked against teminology binding and cardinality requirements.

        Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
        of the valueset, then the test will fail.

        ## Reference Validation
        Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
        and will fail if any attempted read fails.
      )

      test_id_prefix 'USCP'

      requires :token, :patient_ids
      conformance_supports :Patient

      def validate_resource_item(resource, property, value)
        case property

        when '_id'
          values_found = resolve_path(resource, 'id')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "_id in Patient/#{resource.id} (#{values_found}) does not match _id requested (#{value})"

        when 'birthdate'
          values_found = resolve_path(resource, 'birthDate')
          match_found = values_found.any? { |date| validate_date_search(value, date) }
          assert match_found, "birthdate in Patient/#{resource.id} (#{values_found}) does not match birthdate requested (#{value})"

        when 'family'
          values_found = resolve_path(resource, 'name.family')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "family in Patient/#{resource.id} (#{values_found}) does not match family requested (#{value})"

        when 'gender'
          values_found = resolve_path(resource, 'gender')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "gender in Patient/#{resource.id} (#{values_found}) does not match gender requested (#{value})"

        when 'given'
          values_found = resolve_path(resource, 'name.given')
          values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
          match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
          assert match_found, "given in Patient/#{resource.id} (#{values_found}) does not match given requested (#{value})"

        when 'identifier'
          values_found = resolve_path(resource, 'identifier')
          identifier_system = value.split('|').first.empty? ? nil : value.split('|').first
          identifier_value = value.split('|').last
          match_found = values_found.any? do |identifier|
            identifier.value == identifier_value && (!value.include?('|') || identifier.system == identifier_system)
          end
          assert match_found, "identifier in Patient/#{resource.id} (#{values_found}) does not match identifier requested (#{value})"

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
          assert match_found, "name in Patient/#{resource.id} (#{values_found}) does not match name requested (#{value})"

        end
      end

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

      @resources_found = false

      test :search_by__id do
        metadata do
          id '01'
          name 'Server returns valid results for Patient search by _id.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by _id on the Patient resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.
            Because this is the first search of the sequence, resources in the response will be used for subsequent tests.
          )
          versions :r4
        end

        skip_if_known_search_not_supported('Patient', ['_id'])
        @patient_ary = {}
        patient_ids.each do |patient|
          search_params = {
            '_id': patient
          }

          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)

          assert_response_ok(reply)
          assert_bundle_response(reply)

          any_resources = reply&.resource&.entry&.any? { |entry| entry&.resource&.resourceType == 'Patient' }

          next unless any_resources

          @patient_ary[patient] = fetch_all_bundled_resources(reply, check_for_data_absent_reasons)

          @patient = @patient_ary[patient]
            .find { |resource| resource.resourceType == 'Patient' }
          @resources_found = @patient.present?

          save_resource_references(versioned_resource_class('Patient'), @patient_ary[patient])
          save_delayed_sequence_references(@patient_ary[patient], USCore311PatientSequenceDefinitions::DELAYED_REFERENCES)
          validate_reply_entries(@patient_ary[patient], search_params)
        end

        skip_if_not_found(resource_type: 'Patient', delayed: false)
      end

      test :search_by_identifier do
        metadata do
          id '02'
          name 'Server returns valid results for Patient search by identifier.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by identifier on the Patient resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Patient', ['identifier'])
        skip_if_not_found(resource_type: 'Patient', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'identifier': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'identifier') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)

          validate_search_reply(versioned_resource_class('Patient'), reply, search_params)

          value_with_system = get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'identifier'), true)
          token_with_system_search_params = search_params.merge('identifier': value_with_system)
          reply = get_resource_by_params(versioned_resource_class('Patient'), token_with_system_search_params)
          validate_search_reply(versioned_resource_class('Patient'), reply, token_with_system_search_params)
        end

        skip 'Could not resolve all parameters (identifier) in any resource.' unless resolved_one
      end

      test :search_by_name do
        metadata do
          id '03'
          name 'Server returns valid results for Patient search by name.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by name on the Patient resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Patient', ['name'])
        skip_if_not_found(resource_type: 'Patient', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'name': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'name') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)

          validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
        end

        skip 'Could not resolve all parameters (name) in any resource.' unless resolved_one
      end

      test :search_by_birthdate_name do
        metadata do
          id '04'
          name 'Server returns valid results for Patient search by birthdate+name.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by birthdate+name on the Patient resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Patient', ['birthdate', 'name'])
        skip_if_not_found(resource_type: 'Patient', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'birthdate': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'birthDate') { |el| get_value_for_search_param(el).present? }),
            'name': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'name') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)

          validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
        end

        skip 'Could not resolve all parameters (birthdate, name) in any resource.' unless resolved_one
      end

      test :search_by_gender_name do
        metadata do
          id '05'
          name 'Server returns valid results for Patient search by gender+name.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by gender+name on the Patient resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Patient', ['gender', 'name'])
        skip_if_not_found(resource_type: 'Patient', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'gender': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'gender') { |el| get_value_for_search_param(el).present? }),
            'name': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'name') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)

          validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
        end

        skip 'Could not resolve all parameters (gender, name) in any resource.' unless resolved_one
      end

      test :search_by_birthdate_family do
        metadata do
          id '06'
          name 'Server returns valid results for Patient search by birthdate+family.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by birthdate+family on the Patient resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Patient', ['birthdate', 'family'])
        skip_if_not_found(resource_type: 'Patient', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'birthdate': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'birthDate') { |el| get_value_for_search_param(el).present? }),
            'family': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'name.family') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)

          validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
        end

        skip 'Could not resolve all parameters (birthdate, family) in any resource.' unless resolved_one
      end

      test :search_by_family_gender do
        metadata do
          id '07'
          name 'Server returns valid results for Patient search by family+gender.'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by family+gender on the Patient resource.
            This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

          )
          versions :r4
        end

        skip_if_known_search_not_supported('Patient', ['family', 'gender'])
        skip_if_not_found(resource_type: 'Patient', delayed: false)

        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'family': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'name.family') { |el| get_value_for_search_param(el).present? }),
            'gender': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'gender') { |el| get_value_for_search_param(el).present? })
          }

          next if search_params.any? { |_param, value| value.nil? }

          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)

          validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
        end

        skip 'Could not resolve all parameters (family, gender) in any resource.' unless resolved_one
      end

      test :read_interaction do
        metadata do
          id '08'
          name 'Server returns correct Patient resource from Patient read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the Patient read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Patient, [:read])
        skip_if_not_found(resource_type: 'Patient', delayed: false)

        validate_read_reply(@patient, versioned_resource_class('Patient'), check_for_data_absent_reasons)
      end

      test :vread_interaction do
        metadata do
          id '09'
          name 'Server returns correct Patient resource from Patient vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Patient vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Patient, [:vread])
        skip_if_not_found(resource_type: 'Patient', delayed: false)

        validate_vread_reply(@patient, versioned_resource_class('Patient'))
      end

      test :history_interaction do
        metadata do
          id '10'
          name 'Server returns correct Patient resource from Patient history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Patient history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Patient, [:history])
        skip_if_not_found(resource_type: 'Patient', delayed: false)

        validate_history_reply(@patient, versioned_resource_class('Patient'))
      end

      test 'Server returns Provenance resources from Patient search by _id + _revIncludes: Provenance:target' do
        metadata do
          id '11'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(

            A Server SHALL be capable of supporting the following _revincludes: Provenance:target.

            This test will perform a search for _id + _revIncludes: Provenance:target and will pass
            if a Provenance resource is found in the reponse.

          )
          versions :r4
        end

        skip_if_known_revinclude_not_supported('Patient', 'Provenance:target')
        skip_if_not_found(resource_type: 'Patient', delayed: false)

        provenance_results = []
        patient_ids.each do |patient|
          search_params = {
            '_id': patient
          }

          search_params['_revinclude'] = 'Provenance:target'
          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)

          assert_response_ok(reply)
          assert_bundle_response(reply)
          provenance_results += fetch_all_bundled_resources(reply, check_for_data_absent_reasons)
            .select { |resource| resource.resourceType == 'Provenance' }
        end
        save_resource_references(versioned_resource_class('Provenance'), provenance_results)
        save_delayed_sequence_references(provenance_results, USCore311PatientSequenceDefinitions::DELAYED_REFERENCES)

        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '12'
          name 'Patient resources returned from previous search conform to the US Core Patient Profile.'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'
          description %(

            This test verifies resources returned from the first search conform to the [US Core Patient Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient).
            It verifies the presence of mandatory elements and that elements with required bindings contain appropriate values.
            CodeableConcept element bindings will fail if none of its codings have a code/system that is part of the bound ValueSet.
            Quantity, Coding, and code element bindings will fail if its code/system is not found in the valueset.

          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Patient', delayed: false)
        test_resources_against_profile('Patient')
      end

      test 'All must support elements are provided in the Patient resources returned.' do
        metadata do
          id '13'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through the Patient resources found previously for the following must support elements:

            * identifier
            * identifier.system
            * identifier.value
            * name
            * name.family
            * name.given
            * telecom
            * telecom.system
            * telecom.value
            * telecom.use
            * gender
            * birthDate
            * address
            * address.line
            * address.city
            * address.state
            * address.postalCode
            * address.period
            * communication
            * communication.language
            * Patient.extension:race
            * Patient.extension:ethnicity
            * Patient.extension:birthsex
          )
          versions :r4
        end

        skip_if_not_found(resource_type: 'Patient', delayed: false)
        must_supports = USCore311PatientSequenceDefinitions::MUST_SUPPORTS

        missing_must_support_extensions = must_supports[:extensions].reject do |must_support_extension|
          @patient_ary&.values&.flatten&.any? do |resource|
            resource.extension.any? { |extension| extension.url == must_support_extension[:url] }
          end
        end

        missing_must_support_elements = must_supports[:elements].reject do |element|
          @patient_ary&.values&.flatten&.any? do |resource|
            value_found = resolve_element_from_path(resource, element[:path]) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        missing_must_support_elements += missing_must_support_extensions.map { |must_support| must_support[:id] }

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@patient_ary&.values&.flatten&.length} provided Patient resource(s)"
        @instance.save!
      end

      test 'Every reference within Patient resources can be read.' do
        metadata do
          id '14'
          link 'http://hl7.org/fhir/references.html'
          description %(

            This test will attempt to read the first 50 reference found in the resources from the first search.
            The test will fail if Inferno fails to read any of those references.

          )
          versions :r4
        end

        skip_if_known_not_supported(:Patient, [:search, :read])
        skip_if_not_found(resource_type: 'Patient', delayed: false)

        validated_resources = Set.new
        max_resolutions = 50

        @patient_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
