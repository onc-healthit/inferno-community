# frozen_string_literal: true

module Inferno
  module Sequence
    class USCore310PatientSequence < SequenceBase
      title 'Patient Tests'

      description 'Verify that Patient resources on the FHIR server follow the US Core Implementation Guide'

      test_id_prefix 'USCP'

      requires :token, :patient_ids
      conformance_supports :Patient

      def validate_resource_item(resource, property, value)
        case property

        when '_id'
          value_found = resolve_element_from_path(resource, 'id') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, '_id on resource does not match _id requested'

        when 'birthdate'
          value_found = resolve_element_from_path(resource, 'birthDate') { |date| validate_date_search(value, date) }
          assert value_found.present?, 'birthdate on resource does not match birthdate requested'

        when 'family'
          value_found = resolve_element_from_path(resource, 'name.family') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'family on resource does not match family requested'

        when 'gender'
          value_found = resolve_element_from_path(resource, 'gender') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'gender on resource does not match gender requested'

        when 'given'
          value_found = resolve_element_from_path(resource, 'name.given') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'given on resource does not match given requested'

        when 'identifier'
          value_found = resolve_element_from_path(resource, 'identifier.value') { |value_in_resource| value.split(',').include? value_in_resource }
          assert value_found.present?, 'identifier on resource does not match identifier requested'

        when 'name'
          value = value.downcase
          value_found = resolve_element_from_path(resource, 'name') do |name|
            name&.text&.start_with?(value) ||
              name&.family&.downcase&.include?(value) ||
              name&.given&.any? { |given| given.downcase.start_with?(value) } ||
              name&.prefix&.any? { |prefix| prefix.downcase.start_with?(value) } ||
              name&.suffix&.any? { |suffix| suffix.downcase.start_with?(value) }
          end
          assert value_found.present?, 'name on resource does not match name requested'

        end
      end

      details %(
        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.
      )

      def patient_ids
        @instance.patient_ids.split(',').map(&:strip)
      end

      @resources_found = false

      test :unauthorized_search do
        metadata do
          id '01'
          name 'Server rejects Patient search without authorization'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'
          description %(
            A server SHALL reject any unauthorized requests by returning an HTTP 401 unauthorized response code.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Patient, [:search])

        @client.set_no_auth
        omit 'Do not test if no bearer token set' if @instance.token.blank?

        patient_ids.each do |patient|
          search_params = {
            '_id': patient
          }

          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)
          assert_response_unauthorized reply
        end

        @client.set_bearer_token(@instance.token)
      end

      test :search_by__id do
        metadata do
          id '02'
          name 'Server returns expected results from Patient search by _id'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by _id on the Patient resource

          )
          versions :r4
        end

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

          @resources_found = true

          @patient = reply.resource.entry
            .find { |entry| entry&.resource&.resourceType == 'Patient' }
            .resource
          @patient_ary[patient] = fetch_all_bundled_resources(reply.resource)
          save_resource_ids_in_bundle(versioned_resource_class('Patient'), reply)
          save_delayed_sequence_references(@patient_ary[patient])
          validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
        end

        skip 'No Patient resources appear to be available. Please use patients with more information.' unless @resources_found
      end

      test :search_by_identifier do
        metadata do
          id '03'
          name 'Server returns expected results from Patient search by identifier'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by identifier on the Patient resource

          )
          versions :r4
        end

        skip 'No Patient resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'identifier': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'identifier'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)

          validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :search_by_name do
        metadata do
          id '04'
          name 'Server returns expected results from Patient search by name'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by name on the Patient resource

          )
          versions :r4
        end

        skip 'No Patient resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'name': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'name'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)

          validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :search_by_gender_name do
        metadata do
          id '05'
          name 'Server returns expected results from Patient search by gender+name'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by gender+name on the Patient resource

          )
          versions :r4
        end

        skip 'No Patient resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'gender': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'gender')),
            'name': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'name'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)

          validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :search_by_birthdate_name do
        metadata do
          id '06'
          name 'Server returns expected results from Patient search by birthdate+name'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(

            A server SHALL support searching by birthdate+name on the Patient resource

          )
          versions :r4
        end

        skip 'No Patient resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'birthdate': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'birthDate')),
            'name': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'name'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)

          validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :search_by_birthdate_family do
        metadata do
          id '07'
          name 'Server returns expected results from Patient search by birthdate+family'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by birthdate+family on the Patient resource

          )
          versions :r4
        end

        skip 'No Patient resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'birthdate': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'birthDate')),
            'family': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'name.family'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)

          validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :search_by_family_gender do
        metadata do
          id '08'
          name 'Server returns expected results from Patient search by family+gender'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(

            A server SHOULD support searching by family+gender on the Patient resource

          )
          versions :r4
        end

        skip 'No Patient resources appear to be available. Please use patients with more information.' unless @resources_found

        could_not_resolve_all = []
        resolved_one = false

        patient_ids.each do |patient|
          search_params = {
            'family': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'name.family')),
            'gender': get_value_for_search_param(resolve_element_from_path(@patient_ary[patient], 'gender'))
          }

          if search_params.any? { |_param, value| value.nil? }
            could_not_resolve_all = search_params.keys
            next
          end
          resolved_one = true

          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)

          validate_search_reply(versioned_resource_class('Patient'), reply, search_params)
        end

        skip "Could not resolve all parameters (#{could_not_resolve_all.join(', ')}) in any resource." unless resolved_one
      end

      test :read_interaction do
        metadata do
          id '09'
          name 'Server returns correct Patient resource from Patient read interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          description %(
            A server SHALL support the Patient read interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Patient, [:read])
        skip 'No Patient resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@patient, versioned_resource_class('Patient'))
      end

      test :vread_interaction do
        metadata do
          id '10'
          name 'Server returns correct Patient resource from Patient vread interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Patient vread interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Patient, [:vread])
        skip 'No Patient resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@patient, versioned_resource_class('Patient'))
      end

      test :history_interaction do
        metadata do
          id '11'
          name 'Server returns correct Patient resource from Patient history interaction'
          link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'
          optional
          description %(
            A server SHOULD support the Patient history interaction.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Patient, [:history])
        skip 'No Patient resources could be found for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@patient, versioned_resource_class('Patient'))
      end

      test 'Server returns Provenance resources from Patient search by _id + _revIncludes: Provenance:target' do
        metadata do
          id '12'
          link 'https://www.hl7.org/fhir/search.html#revinclude'
          description %(
            A Server SHALL be capable of supporting the following _revincludes: Provenance:target
          )
          versions :r4
        end

        provenance_results = []
        patient_ids.each do |patient|
          search_params = {
            '_id': patient
          }

          search_params['_revinclude'] = 'Provenance:target'
          reply = get_resource_by_params(versioned_resource_class('Patient'), search_params)

          assert_response_ok(reply)
          assert_bundle_response(reply)
          provenance_results += fetch_all_bundled_resources(reply.resource).select { |resource| resource.resourceType == 'Provenance' }
          provenance_results.each { |reference| @instance.save_resource_reference('Provenance', reference.id) }
        end

        skip 'No Provenance resources were returned from this search' unless provenance_results.present?
      end

      test :validate_resources do
        metadata do
          id '13'
          name 'Patient resources returned conform to US Core R4 profiles'
          link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'
          description %(

            This test checks if the resources returned from prior searches conform to the US Core profiles.
            This includes checking for missing data elements and valueset verification.

          )
          versions :r4
        end

        skip 'No Patient resources appear to be available. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Patient')
      end

      test 'All must support elements are provided in the Patient resources returned.' do
        metadata do
          id '14'
          link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'
          description %(

            US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
            This will look through all Patient resources returned from prior searches to see if any of them provide the following must support elements:

            Patient.identifier

            Patient.identifier.system

            Patient.identifier.value

            Patient.name

            Patient.name.family

            Patient.name.given

            Patient.telecom

            Patient.telecom.system

            Patient.telecom.value

            Patient.telecom.use

            Patient.gender

            Patient.birthDate

            Patient.address

            Patient.address.line

            Patient.address.city

            Patient.address.state

            Patient.address.postalCode

            Patient.address.period

            Patient.communication

            Patient.communication.language

            Patient.extension:race

            Patient.extension:ethnicity

            Patient.extension:birthsex

          )
          versions :r4
        end

        skip 'No Patient resources appear to be available. Please use patients with more information.' unless @resources_found

        must_support_extensions = {
          'Patient.extension:race': 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race',
          'Patient.extension:ethnicity': 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity',
          'Patient.extension:birthsex': 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex'
        }
        missing_must_support_extensions = must_support_extensions.reject do |_id, url|
          @patient_ary&.values&.flatten&.any? do |resource|
            resource.extension.any? { |extension| extension.url == url }
          end
        end

        must_support_elements = [
          { path: 'Patient.identifier' },
          { path: 'Patient.identifier.system' },
          { path: 'Patient.identifier.value' },
          { path: 'Patient.name' },
          { path: 'Patient.name.family' },
          { path: 'Patient.name.given' },
          { path: 'Patient.telecom' },
          { path: 'Patient.telecom.system' },
          { path: 'Patient.telecom.value' },
          { path: 'Patient.telecom.use' },
          { path: 'Patient.gender' },
          { path: 'Patient.birthDate' },
          { path: 'Patient.address' },
          { path: 'Patient.address.line' },
          { path: 'Patient.address.city' },
          { path: 'Patient.address.state' },
          { path: 'Patient.address.postalCode' },
          { path: 'Patient.address.period' },
          { path: 'Patient.communication' },
          { path: 'Patient.communication.language' }
        ]

        missing_must_support_elements = must_support_elements.reject do |element|
          truncated_path = element[:path].gsub('Patient.', '')
          @patient_ary&.values&.flatten&.any? do |resource|
            value_found = resolve_element_from_path(resource, truncated_path) { |value| element[:fixed_value].blank? || value == element[:fixed_value] }
            value_found.present?
          end
        end
        missing_must_support_elements.map! { |must_support| "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}" }

        missing_must_support_elements += missing_must_support_extensions.keys

        skip_if missing_must_support_elements.present?,
                "Could not find #{missing_must_support_elements.join(', ')} in the #{@patient_ary&.values&.flatten&.length} provided Patient resource(s)"
        @instance.save!
      end

      test 'Every reference within Patient resource is valid and can be read.' do
        metadata do
          id '15'
          link 'http://hl7.org/fhir/references.html'
          description %(
            This test checks if references found in resources from prior searches can be resolved.
          )
          versions :r4
        end

        skip_if_known_not_supported(:Patient, [:search, :read])
        skip 'No Patient resources appear to be available. Please use patients with more information.' unless @resources_found

        validated_resources = Set.new
        max_resolutions = 50

        @patient_ary&.values&.flatten&.each do |resource|
          validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
        end
      end
    end
  end
end
