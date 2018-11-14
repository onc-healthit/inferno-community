# frozen_string_literal: true

module Inferno
  module Sequence
    # Sequence of tests for the Provenance Resource
    class ProvenanceSequence < SequenceBase
      title 'Provenance'

      test_id_prefix 'P'

      requires :token, :patient_id

      conformance_supports :Provenance

      description 'Tests for Provenance resources'

      test 'Server rejects Provenance search without authorization' do
        metadata do
          id '01'
          link 'https://www.hl7.org/fhir/DSTU2/provenance.html'
          desc %(
            A Provenance search should not work without providing proper authorization. This test
            attempts to search for Provenance resources associated with a patient without providing
            a bearer token as is required.
          )
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(FHIR::DSTU2::Provenance, target: 'Patient/' + @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns Provenance resources associated with the Patient target resource.' do
        metadata do
          id '02'
          link 'https://www.hl7.org/fhir/DSTU2/provenance.html'
          optional
          desc %(
            A server should be capable of returning Provenance resources related to a patient resource.

            This test uses the `target` search paramenter as it can be used more generically than the `patient` search parameter.
          )
        end

        reply = get_resource_by_params(FHIR::DSTU2::Provenance, target: "Patient/" + @instance.patient_id)
        validate_search_reply(FHIR::DSTU2::Provenance, reply)
        @provenance = reply.try(:resource).try(:entry).try(:first).try(:resource)

        assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
      end

      test 'Provenance read resource supported' do
        metadata do
          id '03'
          link 'https://www.hl7.org/fhir/DSTU2/provenance.html'
          optional
          desc %(
            The server should make read interactions available for Provenance resources.
          )
        end

        assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'

        validate_read_reply(@provenance, FHIR::DSTU2::Provenance)
      end
    end
  end
end
