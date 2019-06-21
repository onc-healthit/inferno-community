# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4EncounterSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Encounter Tests'

      description 'Verify that Encounter resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Encounter' # change me

      requires :token, :patient_id
      conformance_supports :Encounter

      def validate_resource_item(resource, property, value)
        case property

        when '_id'
          assert resource&.id == value, '_id on resource did not match _id requested'

        when 'class'
          assert resource&.local_class&.code == value, 'class on resource did not match class requested'

        when 'date'

        when 'identifier'
          assert resource&.identifier&.any? { |identifier| identifier.value == value }, 'identifier on resource did not match identifier requested'

        when 'patient'
          assert resource&.subject&.reference&.include?(value), 'patient on resource does not match patient requested'

        when 'status'
          assert resource&.status == value, 'status on resource did not match status requested'

        when 'type'
          codings = resource&.type&.first&.coding
          assert !codings.nil?, 'type on resource did not match type requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'type on resource did not match type requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Encounter Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-encounter)

      )

      @resources_found = false

      test 'Server rejects Encounter search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Encounter'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Encounter search by patient' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        patient_val = @instance.patient_id
        search_params = { 'patient': patient_val }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @encounter = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('Encounter'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('Encounter'), reply)
      end

      test 'Server returns expected results from Encounter search by _id' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@encounter.nil?, 'Expected valid Encounter resource to be present'

        id_val = @encounter&.id
        search_params = { '_id': id_val }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Encounter search by date+patient' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@encounter.nil?, 'Expected valid Encounter resource to be present'

        date_val = @encounter&.period&.start
        patient_val = @instance.patient_id
        search_params = { 'date': date_val, 'patient': patient_val }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Encounter search by identifier' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@encounter.nil?, 'Expected valid Encounter resource to be present'

        identifier_val = @encounter&.identifier&.first&.value
        search_params = { 'identifier': identifier_val }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Encounter search by patient+status' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@encounter.nil?, 'Expected valid Encounter resource to be present'

        patient_val = @instance.patient_id
        status_val = @encounter&.status
        search_params = { 'patient': patient_val, 'status': status_val }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Encounter search by class+patient' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@encounter.nil?, 'Expected valid Encounter resource to be present'

        class_val = @encounter&.local_class&.code
        patient_val = @instance.patient_id
        search_params = { 'class': class_val, 'patient': patient_val }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        assert_response_ok(reply)
      end

      test 'Server returns expected results from Encounter search by patient+type' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@encounter.nil?, 'Expected valid Encounter resource to be present'

        patient_val = @instance.patient_id
        type_val = @encounter&.type&.first&.coding&.first&.code
        search_params = { 'patient': patient_val, 'type': type_val }

        reply = get_resource_by_params(versioned_resource_class('Encounter'), search_params)
        assert_response_ok(reply)
      end

      test 'Encounter read resource supported' do
        metadata do
          id '09'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Encounter, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@encounter, versioned_resource_class('Encounter'))
      end

      test 'Encounter vread resource supported' do
        metadata do
          id '10'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Encounter, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@encounter, versioned_resource_class('Encounter'))
      end

      test 'Encounter history resource supported' do
        metadata do
          id '11'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Encounter, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@encounter, versioned_resource_class('Encounter'))
      end

      test 'Demonstrates that the server can supply must supported elements' do
        metadata do
          id '12'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        extensions_list = {
        }
        extensions_list.each do |id, url|
          already_found = @instance.must_support_confirmed.include?(id.to_s)
          element_found = already_found || @encounter.extension.any? { |extension| extension.url == url }
          skip "Could not find #{id.to_s} in the provided resource" unless element_found
          @instance.must_support_confirmed += "#{id.to_s}," unless already_found
        end

        must_support_elements = [
          'Encounter.identifier',
          'Encounter.identifier.system',
          'Encounter.identifier.value',
          'Encounter.status',
          'Encounter.local_class',
          'Encounter.type',
          'Encounter.subject',
          'Encounter.participant',
          'Encounter.participant.type',
          'Encounter.participant.period',
          'Encounter.participant.individual',
          'Encounter.period',
          'Encounter.reasonCode',
          'Encounter.hospitalization',
          'Encounter.hospitalization.dischargeDisposition',
          'Encounter.location',
          'Encounter.location.location',
        ]
        must_support_elements.each do |path|
          truncated_path = path.gsub('Encounter.', '')
          already_found = @instance.must_support_confirmed.include?(path)
          element_found = already_found || can_resolve_path(@encounter, truncated_path)
          skip "Could not find #{path} in the provided resource" unless element_found
          @instance.must_support_confirmed += "#{path}," unless already_found
        end
        @instance.save!
      end

      test 'Encounter resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '13'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-encounter.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Encounter')
      end

      test 'All references can be resolved' do
        metadata do
          id '14'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Encounter, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@encounter)
      end
    end
  end
end
