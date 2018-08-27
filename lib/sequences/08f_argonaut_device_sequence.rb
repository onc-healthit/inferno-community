class ArgonautDeviceSequence < SequenceBase

  group 'Argonaut Query and Data'

  title 'Argonaut Device Profile'

  modal_before_run

  description 'Verify that the FHIR server follows the Argonaut Data Query Implementation Guide Server.'

  test_id_prefix 'ADQ-DE'

  requires :token, :patient_id

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  # --------------------------------------------------
  # Device Search
  # --------------------------------------------------

  test '31', '', 'Server rejects Device search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Device search does not work without proper authorization.' do

    skip_if_not_supported(:Device, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Device, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '32', '', 'Server returns expected results from Device search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all Unique device identifier(s)(UDI) for a patient's implanted device(s)." do

    skip_if_not_supported(:Device, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Device, {patient: @instance.patient_id})
    @device = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Device, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::Device, reply)

  end

  test '33', '', 'Device read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:Device, [:search, :read])

    validate_read_reply(@device, FHIR::DSTU2::Device)

  end

  test '34', '', 'Device history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Device, [:history])

    validate_history_reply(@device, FHIR::DSTU2::Device)

  end

  test '35', '', 'Device vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Device, [:vread])

    validate_vread_reply(@device, FHIR::DSTU2::Device)

  end

  def skip_if_not_supported(resource, methods)

    skip "This server does not support #{resource.to_s} #{methods.join(',').to_s} operation(s) according to conformance statement." unless @instance.conformance_supported?(resource, methods)

  end

end
