# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4PractitionerroleSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Practitionerrole Tests'

      description 'Verify that PractitionerRole resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'PractitionerRole' # change me

      requires :token, :patient_id
      conformance_supports :PractitionerRole

      def validate_resource_item(resource, property, value)
        case property

        when 'specialty'
          codings = resource&.specialty&.coding
          assert !codings.nil?, 'specialty on resource did not match specialty requested'
          assert codings.any? { |coding| !coding.try(:code).nil? && coding.try(:code) == value }, 'specialty on resource did not match specialty requested'

        when 'practitioner'
          assert resource&.practitioner&.reference&.include?(value), 'practitioner on resource does not match practitioner requested'

        end
      end

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Practitionerrole Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-practitionerrole)

      )

      @resources_found = false

      test 'Server rejects PractitionerRole search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from PractitionerRole search by specialty' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        specialty_val = @practitionerrole&.specialty&.coding&.first&.code
        search_params = { 'specialty': specialty_val }

        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)
        assert_response_ok(reply)
        assert_bundle_response(reply)

        resource_count = reply.try(:resource).try(:entry).try(:length) || 0
        @resources_found = true if resource_count.positive?

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        @practitionerrole = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(versioned_resource_class('PractitionerRole'), reply, search_params)
        save_resource_ids_in_bundle(versioned_resource_class('PractitionerRole'), reply)
      end

      test 'Server returns expected results from PractitionerRole search by practitioner' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        assert !@practitionerrole.nil?, 'Expected valid PractitionerRole resource to be present'

        practitioner_val = @practitionerrole&.practitioner&.reference&.first
        search_params = { 'practitioner': practitioner_val }

        reply = get_resource_by_params(versioned_resource_class('PractitionerRole'), search_params)
        assert_response_ok(reply)
      end

      test 'PractitionerRole read resource supported' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:PractitionerRole, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@practitionerrole, versioned_resource_class('PractitionerRole'))
      end

      test 'PractitionerRole vread resource supported' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:PractitionerRole, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@practitionerrole, versioned_resource_class('PractitionerRole'))
      end

      test 'PractitionerRole history resource supported' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:PractitionerRole, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@practitionerrole, versioned_resource_class('PractitionerRole'))
      end

      test 'Demonstrates that the server can supply must supported elements' do
        metadata do
          id '07'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        must_support_elements = [
          'PractitionerRole.practitioner',
          'PractitionerRole.organization',
          'PractitionerRole.code',
          'PractitionerRole.specialty',
          'PractitionerRole.location',
          'PractitionerRole.telecom',
          'PractitionerRole.telecom.system',
          'PractitionerRole.telecom.value',
          'PractitionerRole.endpoint'
        ]
        must_support_elements.each do |path|
          truncated_path = path.gsub('PractitionerRole.', '')
          already_found = @instance.must_support_confirmed.include?(path)
          element_found = already_found || can_resolve_path(@practitionerrole, truncated_path)
          skip "Could not find #{path} in the provided resource" unless element_found
          @instance.must_support_confirmed += "#{path}," unless already_found
        end
        @instance.save!
      end

      test 'PractitionerRole resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '08'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-practitionerrole.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('PractitionerRole')
      end

      test 'All references can be resolved' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:PractitionerRole, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@practitionerrole)
      end
    end
  end
end
