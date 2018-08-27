class ArgonautProcedureSequence < SequenceBase

  group 'Argonaut Query and Data'

  title 'Argonaut Procedure Profile'

  modal_before_run

  description 'Verify that Procedure resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

  test_id_prefix 'ADQ-PR'

  requires :token, :patient_id

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  # --------------------------------------------------
  # Procedure Search
  # --------------------------------------------------

  test '88', '', 'Server rejects Procedure search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Procedure search does not work without proper authorization.' do


    skip_if_not_supported(:Procedure, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Procedure, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply
    save_resource_ids_in_bundle(FHIR::DSTU2::Procedure, reply)

  end

  test '89', '', 'Server returns expected results from Procedure search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning a patient's procedures." do

    skip_if_not_supported(:Procedure, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Procedure, {patient: @instance.patient_id})
    @procedure = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Procedure, reply)

  end

  test '90', '', 'Server returns expected results from Procedure search by patient + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of all of a patient's procedures over a specified time period." do

    skip_if_not_supported(:Procedure, [:search, :read])

    assert !@procedure.nil?, 'Expected valid DSTU2 Procedure resource to be present'
    date = @procedure.try(:performedDateTime) || @procedure.try(:performedPeriod).try(:start)
    assert !date.nil?, "Procedure performedDateTime or performedPeriod not returned"
    reply = get_resource_by_params(FHIR::DSTU2::Procedure, {patient: @instance.patient_id, date: date})
    validate_search_reply(FHIR::DSTU2::Procedure, reply)

  end

  test '91', '', 'Procedure read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:Procedure, [:search, :read])

    validate_read_reply(@procedure, FHIR::DSTU2::Procedure)

  end

  test '92', '', 'Procedure history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Procedure, [:history])

    validate_history_reply(@procedure, FHIR::DSTU2::Procedure)

  end

  test '93', '', 'Procedure vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Procedure, [:vread])

    validate_vread_reply(@procedure, FHIR::DSTU2::Procedure)

  end

  def skip_if_not_supported(resource, methods)

    skip "This server does not support #{resource.to_s} #{methods.join(',').to_s} operation(s) according to conformance statement." unless @instance.conformance_supported?(resource, methods)

  end

end
