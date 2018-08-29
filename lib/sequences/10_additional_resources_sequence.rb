class AdditionalResourcesSequence < SequenceBase

  inactive

  title 'Additional Resources'

  description 'Verify additional non-Argonaut resource requirements.'

  test_id_prefix 'ARS'

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  test '01', '', 'Server rejects Composition search without authorization',
          '',
          'Additional Composition resource requirement.' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '02', '', 'Server returns expected results from Composition search by patient',
          '',
          'Additional Composition resource requirement.',
          :optional do

    reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id})
    @composition = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Composition, reply)

  end

  test '03', '', 'Server returns expected results from Composition search by patient + type',
          '',
          'Additional Composition resource requirement.',
          :optional do

    assert !@composition.nil?, 'Expected valid DSTU2 Composition resource to be present'
    type = @composition.try(:type).try(:coding).try(:first).try(:code)
    assert !type.nil?, "Composition type not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id, type: type})
    validate_search_reply(FHIR::DSTU2::Composition, reply)

  end

  test '04', '', 'Server returns expected results from Composition search by patient + period',
          '',
          'Additional Composition resource requirement.',
          :optional do

    assert !@composition.nil?, 'Expected valid DSTU2 Composition resource to be present'
    period = @composition.try(:event).try(:first).try(:period).try(:start)
    period ||= @composition.try(:event).try(:first).try(:period).try(:end)
    assert !period.nil?, "Composition period not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id, period: period})
    validate_search_reply(FHIR::DSTU2::Composition, reply)

  end

  test '05', '', 'Server returns expected results from Composition search by patient + type + period',
          '',
          'Additional Composition resource requirement.',
          :optional do

    assert !@composition.nil?, 'Expected valid DSTU2 Composition resource to be present'
    type = @composition.try(:type).try(:coding).try(:first).try(:code)
    assert !type.nil?, "Composition type not returned"
    period = @composition.try(:event).try(:first).try(:period).try(:start)
    period ||= @composition.try(:event).try(:first).try(:period).try(:end)
    assert !period.nil?, "Composition period not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id, type: type, period: period})
    validate_search_reply(FHIR::DSTU2::Composition, reply)

  end

  test '06', '', 'Composition read resource supported',
          '',
          'Additional Composition resource requirement.',
          :optional do

    validate_read_reply(@composition, FHIR::DSTU2::Composition)

  end

  test '07', '', 'Composition history resource supported',
          '',
          'Additional Composition resource requirement.',
          :optional do

    validate_history_reply(@composition, FHIR::DSTU2::Composition)

  end

  test '08', '', 'Composition vread resource supported',
          '',
          'Additional Composition resource requirement.',
          :optional do

    validate_vread_reply(@composition, FHIR::DSTU2::Composition)

  end

  test '09', '', 'Composition resource contains section text',
          '',
          'Additional Composition resource requirement.' do

    assert !@composition.nil?, 'Expected valid DSTU2 Composition resource to be present'
    assert @composition.is_a?(FHIR::DSTU2::Composition), 'Expected resource to be valid DSTU2 Composition'
    text = @composition.try(:section).try(:first).try(:text)
    assert !text.nil?, 'Composition section text not returned'

  end

  test '10', '', 'Server rejects Provenance search without authorization',
          '',
          'Additional Provenance resource requirement.' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '11', '', 'Server returns expected results from Provenance search by patient',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id})
    @provenance = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Provenance, reply)

  end

  test '12', '', 'Server returns expected results from Provenance search by patient + target',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
    target = @provenance.try(:target).try(:first).try(:reference)
    target = target.split('/')[-1] if target.include?('/')
    assert !target.nil?, "Provenance target not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id, target: target})
    validate_search_reply(FHIR::DSTU2::Provenance, reply)

  end

  test '13', '', 'Server returns expected results from Provenance search by patient + start + end',
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

  test '14', '', 'Server returns expected results from Provenance search by patient + target + start + end',
          '',
          'Additional Provenance resource requirement.',
          :optional do

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

  test '15', '', 'Server returns expected results from Provenance search by userid',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
    userid = @provenance.try(:agent).try(:first).try(:userId).try(:value)
    assert !userid.nil?, "Provenance agent userId not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {userid: userid})
    validate_search_reply(FHIR::DSTU2::Provenance, reply)

  end

  test '16', '', 'Server returns expected results from Provenance search by agent',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
    actor = @provenance.try(:agent).try(:first).try(:actor).try(:reference)
    actor = actor.split('/')[-1] if actor.include?('/')
    assert !actor.nil?, "Provenance agent actor not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {agent: actor})
    validate_search_reply(FHIR::DSTU2::Provenance, reply)

  end

  test '17', '', 'Provenance read resource supported',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    validate_read_reply(@provenance, FHIR::DSTU2::Provenance)

  end

  test '18', '', 'Provenance history resource supported',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    validate_history_reply(@provenance, FHIR::DSTU2::Provenance)

  end

  test '19', '', 'Provenance vread resource supported',
          '',
          'Additional Provenance resource requirement.',
          :optional do

    validate_vread_reply(@provenance, FHIR::DSTU2::Provenance)

  end

end
