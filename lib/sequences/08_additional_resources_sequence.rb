class AdditionalResourcesSequence < SequenceBase

  title 'Additional Resources'

  description 'The FHIR server properly follows the Argonaut Data Query Implementation Guide Server.'

  preconditions 'Client must be authorized.' do
    !@instance.token.nil?
  end

  test 'Composition search without authorization',
          'https://www.hl7.org/fhir/DSTU2/composition.html',
          'Additional Composition resource requirement' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'Composition search by patient',
          'https://www.hl7.org/fhir/DSTU2/composition.html',
          'Additional Composition resource requirement',
          :optional do

    reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id})
    @composition = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Composition, reply)

  end

  test 'Composition search by patient + type',
          'https://www.hl7.org/fhir/DSTU2/composition.html',
          'Additional Composition resource requirement',
          :optional do

    assert !@composition.nil?, 'Expected valid DSTU2 Composition resource to be present'
    type = @composition.try(:type)
    assert !type.nil?, "Composition type not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id, type: type})
    validate_search_reply(FHIR::DSTU2::Composition, reply)

  end

  test 'Composition search by patient + period',
          'https://www.hl7.org/fhir/DSTU2/composition.html',
          'Additional Composition resource requirement',
          :optional do

    assert !@composition.nil?, 'Expected valid DSTU2 Composition resource to be present'
    period = @composition.try(:event).try(:first).try(:period)
    assert !period.nil?, "Composition period not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Composition, {patient: @instance.patient_id, period: period})
    validate_search_reply(FHIR::DSTU2::Composition, reply)

  end

  test 'Composition search by patient + type + period',
          'https://www.hl7.org/fhir/DSTU2/composition.html',
          'Additional Composition resource requirement',
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
          'https://www.hl7.org/fhir/DSTU2/composition.html',
          'Additional Composition resource requirement',
          :optional do

    validate_read_reply(@composition, FHIR::DSTU2::Composition)

  end

  test 'Composition resource contains section text',
          '',
          'Additional Composition resource requirement' do

    assert !@composition.nil?, 'Expected valid DSTU2 Composition resource to be present'
    assert @composition.is_a?(FHIR::DSTU2::Composition), 'Expected resource to be valid DSTU2 Composition'
    text = @composition.try(:section).try(:first).try(:text)
    assert !text.nil?, 'Composition section text not returned'

  end

  test 'Provenance search without authorization',
          'https://www.hl7.org/fhir/DSTU2/provenance.html',
          'Additional Provenance resource requirement' do

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test 'Provenance search by patient',
          'https://www.hl7.org/fhir/DSTU2/provenance.html',
          'Additional Provenance resource requirement',
          :optional do

    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id})
    @provenance = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Provenance, reply)

  end

  test 'Provenance search by patient + entitytype',
          'https://www.hl7.org/fhir/DSTU2/provenance.html',
          'Additional Provenance resource requirement',
          :optional do

    assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
    entitytype = @provenance.try(:entity).try(:first).try(:type)
    assert !entitytype.nil?, "Provenance entitytype not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id, entitytype: entitytype})
    validate_search_reply(FHIR::DSTU2::Provenance, reply)

  end

  test 'Provenance search by patient + start',
          'https://www.hl7.org/fhir/DSTU2/provenance.html',
          'Additional Provenance resource requirement',
          :optional do

    assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
    start = @provenance.try(:period).try(:start)
    assert !start.nil?, "Provenance period start not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id, start: start})
    validate_search_reply(FHIR::DSTU2::Provenance, reply)

  end

  test 'Provenance search by patient + entitytype + start',
          'https://www.hl7.org/fhir/DSTU2/provenance.html',
          'Additional Provenance resource requirement',
          :optional do

    assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
    entitytype = @provenance.try(:entity).try(:first).try(:type)
    assert !entitytype.nil?, "Provenance entitytype not returned"
    start = @provenance.try(:period).try(:start)
    assert !start.nil?, "Provenance period start not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {patient: @instance.patient_id, entitytype: entitytype, start: start})
    validate_search_reply(FHIR::DSTU2::Provenance, reply)

  end

  test 'Provenance search by agent',
          'https://www.hl7.org/fhir/DSTU2/provenance.html',
          'Additional Provenance resource requirement',
          :optional do

    assert !@provenance.nil?, 'Expected valid DSTU2 Provenance resource to be present'
    actor = @provenance.try(:agent).try(:first).try(:actor)
    assert !actor.nil?, "Provenance agent actor not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Provenance, {agent: actor})
    validate_search_reply(FHIR::DSTU2::Provenance, reply)

  end

  test 'Provenance read resource supported',
          'https://www.hl7.org/fhir/DSTU2/provenance.html',
          'Additional Provenance resource requirement',
          :optional do

    validate_read_reply(@provenance, FHIR::DSTU2::Provenance)

  end

end
