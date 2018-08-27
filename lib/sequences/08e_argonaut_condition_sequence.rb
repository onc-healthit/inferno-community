class ArgonautConditionSequence < SequenceBase

  group 'Argonaut Query and Data'

  title 'Argonaut Condition Profile'

  modal_before_run

  description 'Verify that the FHIR server follows the Argonaut Data Query Implementation Guide Server.'

  test_id_prefix 'ADQ-CO'

  requires :token, :patient_id

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  # --------------------------------------------------
  # Condition Search
  # --------------------------------------------------

  test '23', '', 'Server rejects Condition search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Condition search does not work without proper authorization.' do

    skip_if_not_supported(:Condition, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '24', '', 'Server returns expected results from Condition search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning a patients conditions list.' do

    skip_if_not_supported(:Condition, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id})
    @condition = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Condition, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::Condition, reply)

  end

  test '25', '', 'Server returns expected results from Condition search by patient + clinicalstatus',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patients active problems and health concerns.',
          :optional do

    skip_if_not_supported(:Condition, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, clinicalstatus: "active,recurrance,remission"})
    validate_search_reply(FHIR::DSTU2::Condition, reply)

  end

  test '26', '', 'Server returns expected results from Condition search by patient + problem category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patients problems or all of patients health concerns.',
          :optional do

    skip_if_not_supported(:Condition, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, category: "problem"})
    validate_search_reply(FHIR::DSTU2::Condition, reply)

  end

  test '27', '', 'Server returns expected results from Condition search by patient + health-concern category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patients problems or all of patients health concerns.',
          :optional do

    skip_if_not_supported(:Condition, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, category: "health-concern"})
    validate_search_reply(FHIR::DSTU2::Condition, reply)

  end

  test '28', '', 'Condition read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:Condition, [:search, :read])

    validate_read_reply(@condition, FHIR::DSTU2::Condition)

  end

  test '29', '', 'Condition history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Condition, [:history])

    validate_history_reply(@condition, FHIR::DSTU2::Condition)

  end

  test '30', '', 'Condition vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Condition, [:vread])

    validate_vread_reply(@condition, FHIR::DSTU2::Condition)

  end



  def skip_if_not_supported(resource, methods)

    skip "This server does not support #{resource.to_s} #{methods.join(',').to_s} operation(s) according to conformance statement." unless @instance.conformance_supported?(resource, methods)

  end

end
