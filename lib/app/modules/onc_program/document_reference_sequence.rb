# frozen_string_literal: true

module Inferno
  module Sequence
    # Sequence of tests for the DocumentReference Resource
    class DocumentReferenceSequence < SequenceBase
      title 'Document Reference'

      test_id_prefix 'DOC'

      requires :token, :patient_id

      conformance_supports :DocumentReference

      description 'Tests for DocumentReference resources'

      def validate_resource_item(resource, property, value)
        case property
        when 'patient'
          assert (resource.patient&.reference&.include?(value)), 'Patient on resource does not match patient requested'
        end
      end

      test 'Server rejects DocumentReference search without authorization' do
        metadata do
          id '01'
          link 'https://www.hl7.org/fhir/DSTU2/documentreference.html'
          desc %(
            A DocumentReference search should not work without providing proper authorization.
          )
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(FHIR::DSTU2::DocumentReference, patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from DocumentReference search by patient' do
        metadata do
          id '02'
          link 'https://www.hl7.org/fhir/DSTU2/documentreference.html'
          optional
          desc %(
            A server should be capable of returning DocumentReferences related to a patient.
          )
        end

        search_params = { patient: @instance.patient_id }
        reply = get_resource_by_params(FHIR::DSTU2::DocumentReference, search_params)
        @document_reference = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(FHIR::DSTU2::DocumentReference, reply, search_params)
      end

      test 'DocumentReference read resource supported' do
        metadata do
          id '03'
          link 'https://www.hl7.org/fhir/DSTU2/documentreference.html'
          optional
          desc %(
            The server should make read interactions available for DocumentReference resources.
          )
        end

        validate_read_reply(@document_reference, FHIR::DSTU2::DocumentReference)
      end

      test 'DocumentReference history resource supported' do
        metadata do
          id '04'
          link 'https://www.hl7.org/fhir/DSTU2/documentreference.html'
          optional
          desc %(
            The server should make history interactions available for DocumentReference resources.
          )
        end
        validate_history_reply(@document_reference, FHIR::DSTU2::DocumentReference)
      end

      test 'DocumentReference vread resource supported' do
        metadata do
          id '05'
          link 'https://www.hl7.org/fhir/DSTU2/documentreference.html'
          optional
          desc %(
            The server should make vread interactions available for DocumentReference resources.
          )
        end

        validate_vread_reply(@document_reference, FHIR::DSTU2::DocumentReference)
      end

      test 'DocumentReference resource contains content' do
        metadata do
          id '06'
          optional
          link 'https://www.hl7.org/fhir/DSTU2/documentreference.html'
          desc %(
            DocumentReferences should contain content regarding the document.
          )
        end

        assert !@document_reference.nil?, 'Expected valid DSTU2 DocumentReference resource to be present'
        assert @document_reference.is_a?(FHIR::DSTU2::DocumentReference),
               'Expected resource to be valid DSTU2 DocumentReference'
        text = @document_reference&.content[0]&.attachment
        assert !text.nil?, 'DocumentReference section text not returned'
      end
    end
  end
end
