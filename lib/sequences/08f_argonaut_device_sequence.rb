class ArgonautDeviceSequence < SequenceBase

  group 'Argonaut Query and Data'

  title 'Argonaut Device Profile'

  description 'Verify that Device resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

  test_id_prefix 'ADQ-DE'

  requires :token, :patient_id

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  # --------------------------------------------------
  # Device Search
  # --------------------------------------------------

  test '01', '', 'Server rejects Device search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Device search does not work without proper authorization.' do

    skip_if_not_supported(:Device, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Device, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '02', '', 'Server returns expected results from Device search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all Unique device identifier(s)(UDI) for a patient's implanted device(s)." do

    skip_if_not_supported(:Device, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Device, {patient: @instance.patient_id})
    @device = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Device, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::Device, reply)

  end

  test '03', '', 'Device read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:Device, [:search, :read])

    validate_read_reply(@device, FHIR::DSTU2::Device)

  end

  test '04', '', 'Device history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Device, [:history])

    validate_history_reply(@device, FHIR::DSTU2::Device)

  end

  test '05', '', 'Device vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Device, [:vread])

    validate_vread_reply(@device, FHIR::DSTU2::Device)

  end

  test '10', '', 'Device resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-device.html',
          'Device resources associated with Patient conform to Argonaut profiles' do
    test_resources_against_profile('Device')
  end


end
