class ArgonautObservationSequence < SequenceBase

  group 'Argonaut Query and Data'

  title 'Argonaut Observation Profile'

  description 'Verify that Observation resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

  test_id_prefix 'ADQ-OB'

  requires :token, :patient_id

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  # --------------------------------------------------
  # Observation Search
  # --------------------------------------------------

  test '01', '', 'Observation Results search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'An Observation Results search does not work without proper authorization.' do

    skip_if_not_supported(:Observation, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '02', '', 'Server returns expected results from Observation Results search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory results queried by category." do

    skip_if_not_supported(:Observation, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory"})
    @observationresults = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Observation, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::Observation, reply)

  end

  test '03', '', 'Server returns expected results from Observation Results search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory results queried by category code and date range." do

    skip_if_not_supported(:Observation, [:search, :read])

    assert !@observationresults.nil?, 'Expected valid DSTU2 Observation resource to be present'
    date = @observationresults.try(:effectiveDateTime)
    assert !date.nil?, "Observation effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory", date: date})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test '04', '', 'Server returns expected results from Observation Results search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory results queried by category and code." do

    skip_if_not_supported(:Observation, [:search, :read])

    assert !@observationresults.nil?, 'Expected valid DSTU2 Observation resource to be present'
    code = @observationresults.try(:code).try(:coding).try(:first).try(:code)
    assert !code.nil?, "Observation code not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory", code: code})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test '05', '', 'Server returns expected results from Observation Results search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable of returning all of a patient's laboratory results queried by category and one or more codes and date range.",
          :optional do

    skip_if_not_supported(:Observation, [:search, :read])

    assert !@observationresults.nil?, 'Expected valid DSTU2 Observation resource to be present'
    code = @observationresults.try(:code).try(:coding).try(:first).try(:code)
    assert !code.nil?, "Observation code not returned"
    date = @observationresults.try(:effectiveDateTime)
    assert !date.nil?, "Observation effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, category: "laboratory", code: code, date: date})
    validate_search_reply(FHIR::DSTU2::Observation, reply)

  end

  test '06', '', 'Server rejects Smoking Status search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Smoking Status search does not work without proper authorization.' do

    skip_if_not_supported(:Observation, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, code: "72166-2"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '07', '', 'Server returns expected results from Smoking Status search by patient + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning a patient's smoking status." do

    skip_if_not_supported(:Observation, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, code: "72166-2"})
    validate_search_reply(FHIR::DSTU2::Observation, reply)
    # TODO check for 72166-2
    save_resource_ids_in_bundle(FHIR::DSTU2::Observation, reply)

  end

  test '13', '', 'Observation read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:Observation, [:search, :read])

    validate_read_reply(@observationresults, FHIR::DSTU2::Observation)

  end

  test '14', '', 'Observation history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Observation, [:history])

    validate_history_reply(@observationresults, FHIR::DSTU2::Observation)

  end

  test '15', '', 'Observation vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Observation, [:vread])

    validate_vread_reply(@observationresults, FHIR::DSTU2::Observation)

  end

  test '16', '', 'Observation Result resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-observationresults.html',
          'Observation Result resources associated with Patient conform to Argonaut profiles.' do
    test_resources_against_profile('Observation', ValidationUtil::OBSERVATION_RESULTS_URL)
    skip_unless @profiles_encountered.include?(ValidationUtil::OBSERVATION_RESULTS_URL), 'No Observation Results found.'
    assert !@profiles_failed.include?(ValidationUtil::OBSERVATION_RESULTS_URL), "Observation Results failed validation.<br/>#{@profiles_failed[ValidationUtil::OBSERVATION_RESULTS_URL]}"
  end

end
