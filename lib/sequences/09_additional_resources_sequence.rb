class AdditionalResourcesSequence < SequenceBase

  title 'Additional Resources'

  description 'Verify additional resource requirements.'

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  test 'Composition search without authorization',
          '',
          'Additional Composition resource requirement.' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'Composition search by patient',
          '',
          'Additional Composition resource requirement.',
          :optional do

    reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id})
    @composition = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Composition, reply)

  end

  test 'Composition search by patient + type',
          '',
          'Additional Composition resource requirement.',
          :optional do

    assert !@composition.nil?, 'Expected valid DSTU2 Composition resource to be present'
    type = @composition.try(:type)
    assert !type.nil?, "Composition type not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id, type: type})
    validate_search_reply(FHIR::DSTU2::Composition, reply)

  end

  test 'Composition search by patient + period',
          '',
          'Additional Composition resource requirement.',
          :optional do

    assert !@composition.nil?, 'Expected valid DSTU2 Composition resource to be present'
    period = @composition.try(:event).try(:first).try(:period)
    assert !period.nil?, "Composition period not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id, period: period})
    validate_search_reply(FHIR::DSTU2::Composition, reply)

  end

  test 'Composition search by patient + type + period',
          '',
          'Additional Composition resource requirement.',
          :optional do

    assert !@composition.nil?, 'Expected valid DSTU2 Composition resource to be present'
    type = @composition.try(:type)
    assert !type.nil?, "Composition type not returned"
    period = @composition.try(:event).try(:first).try(:period)
    assert !period.nil?, "Composition period not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id, type: type, period: period})
    validate_search_reply(FHIR::DSTU2::Composition, reply)

  end

  test 'Composition read resource supported',
          '',
          'Additional Composition resource requirement.',
          :optional do

    validate_read_reply(@composition, FHIR::DSTU2::Composition)

  end

  test 'Composition history resource supported',
          '',
          'Additional Composition resource requirement.',
          :optional do

    validate_history_reply(@composition, FHIR::DSTU2::Composition)

  end

  test 'Composition vread resource supported',
          '',
          'Additional Composition resource requirement.',
          :optional do

    validate_vread_reply(@composition, FHIR::DSTU2::Composition)

  end

  test 'Composition resource contains section text',
          '',
          'Additional Composition resource requirement.' do

    assert !@composition.nil?, 'Expected valid DSTU2 Composition resource to be present'
    assert @composition.is_a?(FHIR::DSTU2::Composition), 'Expected resource to be valid DSTU2 Composition'
    text = @composition.try(:section).try(:first).try(:text)
    assert !text.nil?, 'Composition section text not returned'

  end

  test 'Provenance search without authorization',
          '',
          'Additional Provenance resource requirement.' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'Provenance search by patient',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id})
    @provenance = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Provenance, reply)

  end

  test 'Provenance search by patient + target',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
    target = @provenance.try(:target)
    assert !target.nil?, "Provenance target not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id, target: target})
    validate_search_reply(FHIR::DSTU2::Provenance, reply)

  end

  test 'Provenance search by patient + start + end',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
    periodStart = @provenance.try(:period).try(:start)
    assert !periodStart.nil?, "Provenance period start not returned"
    periodEnd = @provenance.try(:period).try(:end)
    assert !periodEnd.nil?, "Provenance period end not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id, start: periodStart, end: periodEnd})
    validate_search_reply(FHIR::DSTU2::Provenance, reply)

  end

  test 'Provenance search by patient + target + start + end',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
    target = @provenance.try(:target)
    assert !target.nil?, "Provenance target not returned"
    periodStart = @provenance.try(:period).try(:start)
    assert !periodStart.nil?, "Provenance period start not returned"
    periodEnd = @provenance.try(:period).try(:end)
    assert !periodEnd.nil?, "Provenance period end not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id, target: target, start: periodStart, end: periodEnd})
    validate_search_reply(FHIR::DSTU2::Provenance, reply)

  end

  test 'Provenance search by userid',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
    userid = @provenance.try(:agent).try(:first).try(:userId)
    assert !userid.nil?, "Provenance agent userId not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {userid: userid})
    validate_search_reply(FHIR::DSTU2::Provenance, reply)

  end

  test 'Provenance search by agent',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
    actor = @provenance.try(:agent).try(:first).try(:actor)
    assert !actor.nil?, "Provenance agent actor not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {agent: actor})
    validate_search_reply(FHIR::DSTU2::Provenance, reply)

  end

  test 'Provenance read resource supported',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    validate_read_reply(@provenance, FHIR::DSTU2::Provenance)

  end

  test 'Provenance history resource supported',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    validate_history_reply(@provenance, FHIR::DSTU2::Provenance)

  end

  test 'Provenance vread resource supported',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    validate_vread_reply(@provenance, FHIR::DSTU2::Provenance)

  end

end
