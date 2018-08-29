class ArgonautConditionSequence < SequenceBase

  group 'Argonaut Profile Conformance'

  title 'Condition'

  description 'Verify that Condition resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

  test_id_prefix 'ADQ-CO'

  requires :token, :patient_id

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  # --------------------------------------------------
  # Condition Search
  # --------------------------------------------------

  test '01', '', 'Server rejects Condition search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Condition search does not work without proper authorization.' do

    skip_if_not_supported(:Condition, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '02', '', 'Server returns expected results from Condition search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server is capable of returning a patients conditions list.' do

    skip_if_not_supported(:Condition, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id})
    @condition = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Condition, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::Condition, reply)

  end

  test '03', '', 'Server returns expected results from Condition search by patient + clinicalstatus',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patients active problems and health concerns.',
          :optional do

    skip_if_not_supported(:Condition, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, clinicalstatus: "active,recurrance,remission"})
    validate_search_reply(FHIR::DSTU2::Condition, reply)

  end

  test '04', '', 'Server returns expected results from Condition search by patient + problem category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patients problems or all of patients health concerns.',
          :optional do

    skip_if_not_supported(:Condition, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, category: "problem"})
    validate_search_reply(FHIR::DSTU2::Condition, reply)

  end

  test '05', '', 'Server returns expected results from Condition search by patient + health-concern category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A server SHOULD be capable returning all of a patients problems or all of patients health concerns.',
          :optional do

    skip_if_not_supported(:Condition, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Condition, {patient: @instance.patient_id, category: "health-concern"})
    validate_search_reply(FHIR::DSTU2::Condition, reply)

  end

  test '06', '', 'Condition read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:Condition, [:search, :read])

    validate_read_reply(@condition, FHIR::DSTU2::Condition)

  end

  test '07', '', 'Condition history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Condition, [:history])

    validate_history_reply(@condition, FHIR::DSTU2::Condition)

  end

  test '08', '', 'Condition vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Condition, [:vread])

    validate_vread_reply(@condition, FHIR::DSTU2::Condition)

  end

  test '09', '', 'Condition resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-condition.html',
         'Condition resources associated with Patient conform to Argonaut profiles..' do
    test_resources_against_profile('Condition')
  end

end
