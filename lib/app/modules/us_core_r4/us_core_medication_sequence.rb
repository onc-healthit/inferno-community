# frozen_string_literal: true

module Inferno
  module Sequence
    class UsCoreR4MedicationSequence < SequenceBase
      group 'US Core R4 Profile Conformance'

      title 'Medication Tests'

      description 'Verify that Medication resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

      test_id_prefix 'Medication' # change me

      requires :token, :patient_id
      conformance_supports :Medication

      details %(

        The #{title} Sequence tests `#{title.gsub(/\s+/, '')}` resources associated with the provided patient.  The resources
        returned will be checked for consistency against the [Medication Argonaut Profile](https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-medication)

      )

      @resources_found = false

      test 'Server rejects Medication search without authorization' do
        metadata do
          id '01'
          link 'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html'
          desc %(
          )
          versions :r4
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(versioned_resource_class('Medication'), patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Medication read resource supported' do
        metadata do
          id '02'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Medication, [:read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_read_reply(@medication, versioned_resource_class('Medication'))
      end

      test 'Medication vread resource supported' do
        metadata do
          id '03'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Medication, [:vread])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_vread_reply(@medication, versioned_resource_class('Medication'))
      end

      test 'Medication history resource supported' do
        metadata do
          id '04'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/CapabilityStatement-us-core-server.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Medication, [:history])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_history_reply(@medication, versioned_resource_class('Medication'))
      end

      test 'Demonstrates that the server can supply must supported elements' do
        metadata do
          id '05'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/general-guidance.html/#must-support'
          desc %(
          )
          versions :r4
        end

        extensions_list = {
        }
        extensions_list.each do |id, url|
          already_found = @instance.must_support_confirmed.include?(id.to_s)
          element_found = already_found || @medication.extension.any? { |extension| extension.url == url }
          skip "Could not find #{id.to_s} in the provided resource" unless element_found
          @instance.must_support_confirmed += "#{id.to_s}," unless already_found
        end

        must_support_elements = [
          'Medication.code',
        ]
        must_support_elements.each do |path|
          truncated_path = path.gsub('Medication.', '')
          already_found = @instance.must_support_confirmed.include?(path)
          element_found = already_found || can_resolve_path(@medication, truncated_path)
          skip "Could not find #{path} in the provided resource" unless element_found
          @instance.must_support_confirmed += "#{path}," unless already_found
        end
        @instance.save!
      end

      test 'Medication resources associated with Patient conform to Argonaut profiles' do
        metadata do
          id '06'
          link 'https://build.fhir.org/ig/HL7/US-Core-R4/StructureDefinition-us-core-medication.json'
          desc %(
          )
          versions :r4
        end

        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found
        test_resources_against_profile('Medication')
      end

      test 'All references can be resolved' do
        metadata do
          id '07'
          link 'https://www.hl7.org/fhir/DSTU2/references.html'
          desc %(
          )
          versions :r4
        end

        skip_if_not_supported(:Medication, [:search, :read])
        skip 'No resources appear to be available for this patient. Please use patients with more information.' unless @resources_found

        validate_reference_resolutions(@medication)
      end
    end
  end
end
