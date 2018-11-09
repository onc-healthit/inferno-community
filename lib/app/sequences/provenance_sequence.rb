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
            A Provenance search should not work without providing proper authorization.
          )
        end

        @client.set_no_auth
        skip 'Could not verify this functionality when bearer token is not set' if @instance.token.blank?

        reply = get_resource_by_params(FHIR::DSTU2::Provenance, patient: @instance.patient_id)
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply
      end

      test 'Server returns expected results from Provenance search by patient' do
        metadata do
          id '02'
          link 'https://www.hl7.org/fhir/DSTU2/provenance.html'
          optional
          desc %(
            A server should be capable of returning Provenance resources related to a patient.
          )
        end

        reply = get_resource_by_params(FHIR::DSTU2::Provenance, patient: @instance.patient_id)
        @provenance = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(FHIR::DSTU2::Provenance, reply)
      end

      test 'Server returns expected results from Provenance search by patient + target' do
        metadata do
          id '03'
          link 'https://www.hl7.org/fhir/DSTU2/provenance.html'
          optional
          desc %(
            Provenance should be searchable by patient and target.
          )
        end

        assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
        target = @provenance.try(:target).try(:first).try(:reference)
        target = target.split('/')[-1] if target.include?('/')
        assert !target.nil?, 'Provenance target not returned'
        reply = get_resource_by_params(FHIR::DSTU2::Provenance, patient: @instance.patient_id, target: target)
        validate_search_reply(FHIR::DSTU2::Provenance, reply)
      end

      test 'Server returns expected results from Provenance search by patient + start + end' do
        metadata do
          id '04'
          link 'https://www.hl7.org/fhir/DSTU2/provenance.html'
          optional
          desc %(
            Provenance should be searchable by patient, start and end.
          )
        end

        assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
        period_start = @provenance.try(:period).try(:start)
        assert !period_start.nil?, 'Provenance period start not returned'
        period_end = @provenance.try(:period).try(:end)
        assert !period_end.nil?, 'Provenance period end not returned'
        reply = get_resource_by_params(FHIR::DSTU2::Provenance,
                                       patient: @instance.patient_id,
                                       start: period_start, end: period_end)
        validate_search_reply(FHIR::DSTU2::Provenance, reply)
      end

      test 'Server returns expected results from Provenance search by patient + target + start + end' do
        metadata do
          id '05'
          link 'https://www.hl7.org/fhir/DSTU2/provenance.html'
          optional
          desc %(
            Provenance should be searchable by patient, target, start and end.
          )
        end

        assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
        target = @provenance.try(:target).try(:first).try(:reference)
        target = target.split('/')[-1] if target.include?('/')
        assert !target.nil?, 'Provenance target not returned'
        period_start = @provenance.try(:period).try(:start)
        assert !period_start.nil?, 'Provenance period start not returned'
        period_end = @provenance.try(:period).try(:end)
        assert !period_end.nil?, 'Provenance period end not returned'
        reply = get_resource_by_params(FHIR::DSTU2::Provenance,
                                       patient: @instance.patient_id,
                                       target: target,
                                       start: period_start,
                                       end: period_end)
        validate_search_reply(FHIR::DSTU2::Provenance, reply)
      end

      test 'Server returns expected results from Provenance search by userid' do
        metadata do
          id '06'
          link 'https://www.hl7.org/fhir/DSTU2/provenance.html'
          optional
          desc %(
            Provenance should be searchable by userid.
          )
        end

        assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
        userid = @provenance.try(:agent).try(:first).try(:userId).try(:value)
        assert !userid.nil?, 'Provenance agent userId not returned'
        reply = get_resource_by_params(FHIR::DSTU2::Provenance, userid: userid)
        validate_search_reply(FHIR::DSTU2::Provenance, reply)
      end

      test 'Server returns expected results from Provenance search by agent' do
        metadata do
          id '07'
          link 'https://www.hl7.org/fhir/DSTU2/provenance.html'
          optional
          desc %(
            Provenance should be searchable by agent.
          )
        end

        assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
        actor = @provenance.try(:agent).try(:first).try(:actor).try(:reference)
        actor = actor.split('/')[-1] if actor.include?('/')
        assert !actor.nil?, 'Provenance agent actor not returned'
        reply = get_resource_by_params(FHIR::DSTU2::Provenance, agent: actor)
        validate_search_reply(FHIR::DSTU2::Provenance, reply)
      end

      test 'Provenance read resource supported' do
        metadata do
          id '08'
          link 'https://www.hl7.org/fhir/DSTU2/provenance.html'
          optional
          desc %(
            The server should make read interactions available for Provenance resources.
          )
        end

        validate_read_reply(@provenance, FHIR::DSTU2::Provenance)
      end

      test 'Provenance history resource supported' do
        metadata do
          id '09'
          link 'https://www.hl7.org/fhir/DSTU2/provenance.html'
          optional
          desc %(
            The server should make history interactions available for Provenance resources.
          )
        end

        validate_history_reply(@provenance, FHIR::DSTU2::Provenance)
      end

      test 'Provenance vread resource supported' do
        metadata do
          id '10'
          link 'https://www.hl7.org/fhir/DSTU2/provenance.html'
          optional
          desc %(
            The server should make vread interactions available for Provenance resources.
          )
        end

        validate_vread_reply(@provenance, FHIR::DSTU2::Provenance)
      end
    end
  end
end
