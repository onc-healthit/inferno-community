class ArgonautSmokingStatusSequence < SequenceBase

  group 'Argonaut Query and Data'

  title 'Argonaut Smoking Status Profile'

  modal_before_run

  description 'Verify that the FHIR server follows the Argonaut Data Query Implementation Guide Server.'

  test_id_prefix 'ADQ-SS'

  requires :token, :patient_id

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  test '78', '', 'Server rejects Smoking Status search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Smoking Status search does not work without proper authorization.' do

    skip_if_not_supported(:Observation, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, code: "72166-2"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '79', '', 'Server returns expected results from Smoking Status search by patient + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning a patient's smoking status." do

    skip_if_not_supported(:Observation, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, code: "72166-2"})
    validate_search_reply(FHIR::DSTU2::Observation, reply)
    # TODO check for 72166-2
    save_resource_ids_in_bundle(FHIR::DSTU2::Observation, reply)

  end

  test '80', '', 'Server rejects Vital Signs search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Vital Signs search does not work without proper authorization.' do

    skip_if_not_supported(:Observation, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '81', '', 'Server returns expected results from Vital Signs search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's vital signs that it supports." do

    skip_if_not_supported(:Observation, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs"})
    @vitalsigns = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Observation, reply)
    # TODO check for `vital-signs` category
    save_resource_ids_in_bundle(FHIR::DSTU2::Observation, reply)

  end

  test '82', '', 'Server returns expected results from Vital Signs search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's vital signs queried by date range." do

    skip_if_not_supported(:Observation, [:search, :read])

    assert !@vitalsigns.nil?, 'Expected valid DSTU2 Observation resource to be present'
    date = @vitalsigns.try(:effectiveDateTime)
    assert !date.nil?, "Observation effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs", date: date})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test '83', '', 'Server returns expected results from Vital Signs search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning any of a patient's vital signs queried by one or more of the specified codes." do

    skip_if_not_supported(:Observation, [:search, :read])

    assert !@vitalsigns.nil?, 'Expected valid DSTU2 Observation resource to be present'
    code = @vitalsigns.try(:code).try(:coding).try(:first).try(:code)
    assert !code.nil?, "Observation code not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs", code: code})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test '84', '', 'Server returns expected results from Vital Signs search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable of returning any of a patient's vital signs queried by one or more of the codes listed below and date range.",
          :optional do

    skip_if_not_supported(:Observation, [:search, :read])

    assert !@vitalsigns.nil?, 'Expected valid DSTU2 Observation resource to be present'
    code = @vitalsigns.try(:code).try(:coding).try(:first).try(:code)
    assert !code.nil?, "Observation code not returned"
    date = @vitalsigns.try(:effectiveDateTime)
    assert !date.nil?, "Observation effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "vital-signs", code: code, date: date})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test '85', '', 'Observation read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:Observation, [:search, :read])

    validate_read_reply(@observationresults, FHIR::DSTU2::Observation)

  end

  test '86', '', 'Observation history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Observation, [:history])

    validate_history_reply(@observationresults, FHIR::DSTU2::Observation)

  end

  test '87', '', 'Observation vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Observation, [:vread])

    validate_vread_reply(@observationresults, FHIR::DSTU2::Observation)

  end


  def skip_if_not_supported(resource, methods)

    skip "This server does not support #{resource.to_s} #{methods.join(',').to_s} operation(s) according to conformance statement." unless @instance.conformance_supported?(resource, methods)

  end

end
