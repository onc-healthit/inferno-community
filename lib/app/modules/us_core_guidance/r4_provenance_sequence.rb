# frozen_string_literal: true

module Inferno
  module Sequence
    # Sequence of tests for the Provenance Resource
    class R4ProvenanceSequence < SequenceBase
      title 'Preliminary R4 Provenance'

      test_id_prefix 'P'

      requires :token, :patient_id

      conformance_supports :Provenance

      description 'Tests for Provenance resources'

      def patient_reference
        "Patient/#{@instance.patient_id}"
      end

      def valid_resource?(resource)
        resource&.target&.any? { |target| target.reference.include? @instance.patient_id }
      end

      def validate_resource_item(resource, property, _value)
        case property
        when 'target'
          assert valid_resource?(resource), 'No target on resource matches patient requested'
        end
      end

      test 'Server rejects Provenance search without authorization' do
        metadata do
          id '01'
          link 'https://www.hl7.org/fhir/R4/provenance.html'
          desc %(
            A Provenance search should not work without providing proper
            authorization. This test attempts to search for Provenance resources
            associated with a patient without providing a bearer token as is
            required.
          )
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(FHIR::Provenance, target: patient_reference)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns Provenance resources associated with the Patient target resource.' do
        metadata do
          id '02'
          link 'https://www.hl7.org/fhir/R4/provenance.html'
          desc %(
            A server should be capable of returning Provenance resources related
            to a patient resource.

            This test uses the `target` search paramenter as it can be used more
            generically than the `patient` search parameter.
          )
        end

        search_params = { target: patient_reference }
        reply = get_resource_by_params(FHIR::Provenance, search_params)
        validate_search_reply(FHIR::Provenance, reply, search_params)
        @provenance = reply&.resource&.entry&.first&.resource

        assert @provenance.present?, 'Expected valid R4 Provenance resource to be present'
      end

      test 'Provenance read resource supported' do
        metadata do
          id '03'
          link 'https://www.hl7.org/fhir/R4/provenance.html'
          desc %(
            The server should make read interactions available for Provenance
            resources.
          )
        end

        assert @provenance.present?, 'Expected valid R4 Provenance resource to be present'

        validate_read_reply(@provenance, FHIR::Provenance)
      end
    end
  end
end
