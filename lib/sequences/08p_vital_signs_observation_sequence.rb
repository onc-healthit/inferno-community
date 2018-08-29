class ArgonautVitalSignsSequence < SequenceBase

  group 'Argonaut Profile Conformance'

  title 'Vital Signs'

  description 'Verify that Vital Signs are collected on the FHIR server according to the Argonaut Data Query Implementation Guide'

  test_id_prefix 'ADQ-VS'

  requires :token, :patient_id

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
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

  test '20', '', 'Vital Signs resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-vitalsigns.html',
          'Vital Signs resources associated with Patient conform to Argonaut profiles.' do
    test_resources_against_profile('Observation', ValidationUtil::VITAL_SIGNS_URL)
    skip_unless @profiles_encountered.include?(ValidationUtil::VITAL_SIGNS_URL), 'No Vital Sign Observations found.'
    assert !@profiles_failed.include?(ValidationUtil::VITAL_SIGNS_URL), "Vital Sign Observations failed validation.<br/>#{@profiles_failed[ValidationUtil::VITAL_SIGNS_URL]}"
  end

end
