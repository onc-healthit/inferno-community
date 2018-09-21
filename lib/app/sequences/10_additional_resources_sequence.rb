module Inferno
  module Sequence
    class AdditionalResourcesSequence < SequenceBase

      inactive

      title 'Additional Resources'

      description 'Verify additional non-Argonaut resource requirements.'

      test_id_prefix 'ARS'

      test 'Server rejects Composition search without authorization' do

        metadata {
          id '01'
          desc %(
            Additional Composition resource requirement.
          )
        }

        @client.set_no_auth
        reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test 'Server returns expected results from Composition search by patient' do

        metadata {
          id '02'
          desc %(
            Additional Composition resource requirement.
          )
        }

        reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id})
        @composition = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(FHIR::DSTU2::Composition, reply)

      end

      test 'Server returns expected results from Composition search by patient + type' do

        metadata {
          id '03'
          optional
          desc %(
            Additional Composition resource requirement.
          )
        }

        assert !@composition.nil?, 'Expected valid DSTU2 Composition resource to be present'
        type = @composition.try(:type).try(:coding).try(:first).try(:code)
        assert !type.nil?, "Composition type not returned"
        reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id, type: type})
        validate_search_reply(FHIR::DSTU2::Composition, reply)

      end

      test 'Server returns expected results from Composition search by patient + period' do

        metadata {
          id '04'
          optional
          desc %(
            Additional Composition resource requirement.
          )
        }

        assert !@composition.nil?, 'Expected valid DSTU2 Composition resource to be present'
        period = @composition.try(:event).try(:first).try(:period).try(:start)
        period ||= @composition.try(:event).try(:first).try(:period).try(:end)
        assert !period.nil?, "Composition period not returned"
        reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id, period: period})
        validate_search_reply(FHIR::DSTU2::Composition, reply)

      end

      test 'Server returns expected results from Composition search by patient + type + period' do

        metadata {
          id '05'
          optional
          desc %(
            Additional Composition resource requirement.
          )
        }

        assert !@composition.nil?, 'Expected valid DSTU2 Composition resource to be present'
        type = @composition.try(:type).try(:coding).try(:first).try(:code)
        assert !type.nil?, "Composition type not returned"
        period = @composition.try(:event).try(:first).try(:period).try(:start)
        period ||= @composition.try(:event).try(:first).try(:period).try(:end)
        assert !period.nil?, "Composition period not returned"
        reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id, type: type, period: period})
        validate_search_reply(FHIR::DSTU2::Composition, reply)

      end

      test 'Composition read resource supported' do

        metadata {
          id '06'
          optional
          desc %(
            Additional Composition resource requirement.
          )
        }

        validate_read_reply(@composition, FHIR::DSTU2::Composition)

      end

      test 'Composition history resource supported' do

        metadata {
          id '07'
          optional
          desc %(
            Additional Composition resource requirement.
          )
        }
        validate_history_reply(@composition, FHIR::DSTU2::Composition)

      end

      test 'Composition vread resource supported' do

        metadata {
          id '08'
          optional
          desc %(
            Additional Composition resource requirement.
          )
        }

        validate_vread_reply(@composition, FHIR::DSTU2::Composition)

      end

      test 'Composition resource contains section text' do

        metadata {
          id '09'
          desc %(
            Additional Composition resource requirement.
          )
        }

        assert !@composition.nil?, 'Expected valid DSTU2 Composition resource to be present'
        assert @composition.is_a?(FHIR::DSTU2::Composition), 'Expected resource to be valid DSTU2 Composition'
        text = @composition.try(:section).try(:first).try(:text)
        assert !text.nil?, 'Composition section text not returned'

      end

      test 'Server rejects Provenance search without authorization' do

        metadata {
          id '10'
          desc %(
            Additional Provenance resource requirement.
          )
        }

        @client.set_no_auth
        reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id})
        @client.set_bearer_token(@instance.token)
        assert_response_unauthorized reply

      end

      test 'Server rejects Provenance search without authorization' do

        metadata {
          id '11'
          optional
          desc %(
            Additional Provenance resource requirement.
          )
        }

        reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id})
        @provenance = reply.try(:resource).try(:entry).try(:first).try(:resource)
        validate_search_reply(FHIR::DSTU2::Provenance, reply)

      end

      test 'Server returns expected results from Provenance search by patient + target' do

        metadata {
          id '12'
          optional
          desc %(
            Additional Provenance resource requirement.
          )
        }

        assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
        target = @provenance.try(:target).try(:first).try(:reference)
        target = target.split('/')[-1] if target.include?('/')
        assert !target.nil?, "Provenance target not returned"
        reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id, target: target})
        validate_search_reply(FHIR::DSTU2::Provenance, reply)

      end

      test 'Server returns expected results from Provenance search by patient + start + end' do

        metadata {
          id '13'
          optional
          desc %(
            Additional Provenance resource requirement.
          )
        }

        assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
        periodStart = @provenance.try(:period).try(:start)
        assert !periodStart.nil?, "Provenance period start not returned"
        periodEnd = @provenance.try(:period).try(:end)
        assert !periodEnd.nil?, "Provenance period end not returned"
        reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id, start: periodStart, end: periodEnd})
        validate_search_reply(FHIR::DSTU2::Provenance, reply)

      end

      test 'Server returns expected results from Provenance search by patient + target + start + end' do

        metadata {
          id '14'
          optional
          desc %(
            Additional Provenance resource requirement.
          )
        }

        assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
        target = @provenance.try(:target).try(:first).try(:reference)
        target = target.split('/')[-1] if target.include?('/')
        assert !target.nil?, "Provenance target not returned"
        periodStart = @provenance.try(:period).try(:start)
        assert !periodStart.nil?, "Provenance period start not returned"
        periodEnd = @provenance.try(:period).try(:end)
        assert !periodEnd.nil?, "Provenance period end not returned"
        reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id, target: target, start: periodStart, end: periodEnd})
        validate_search_reply(FHIR::DSTU2::Provenance, reply)

      end

      test 'Server returns expected results from Provenance search by userid' do

        metadata {
          id '15'
          optional
          desc %(
            Additional Provenance resource requirement.
          )
        }

        assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
        userid = @provenance.try(:agent).try(:first).try(:userId).try(:value)
        assert !userid.nil?, "Provenance agent userId not returned"
        reply = get_resource_by_params(FHIR::DSTU2::Provenance, {userid: userid})
        validate_search_reply(FHIR::DSTU2::Provenance, reply)

      end

      test 'Server returns expected results from Provenance search by agent' do

        metadata {
          id '16'
          optional
          desc %(
            Additional Provenance resource requirement.
          )
        }

        assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
        actor = @provenance.try(:agent).try(:first).try(:actor).try(:reference)
        actor = actor.split('/')[-1] if actor.include?('/')
        assert !actor.nil?, "Provenance agent actor not returned"
        reply = get_resource_by_params(FHIR::DSTU2::Provenance, {agent: actor})
        validate_search_reply(FHIR::DSTU2::Provenance, reply)

      end

      test 'Provenance read resource supported' do

        metadata {
          id '17'
          optional
          desc %(
            Additional Provenance resource requirement.
          )
        }

        validate_read_reply(@provenance, FHIR::DSTU2::Provenance)

      end

      test 'Provenance history resource supported' do

        metadata {
          id '18'
          optional
          desc %(
            Additional Provenance resource requirement.
          )
        }

        validate_history_reply(@provenance, FHIR::DSTU2::Provenance)

      end

      test 'Provenance vread resource supported' do

        metadata {
          id '19'
          optional
          desc %(
            Additional Provenance resource requirement.
          )
        }

        validate_vread_reply(@provenance, FHIR::DSTU2::Provenance)

      end

    end

  end
end
