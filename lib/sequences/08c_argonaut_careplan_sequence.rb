class ArgonautCarePlanSequence < SequenceBase

  group 'Argonaut Query and Data'

  title 'Argonaut Care plan Profile'

  modal_before_run

  description 'Verify that the FHIR server follows the Argonaut Data Query Implementation Guide Server for Care plans.'

  test_id_prefix 'ADQ-CP'

  requires :token, :patient_id

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  # --------------------------------------------------
  # CarePlan Search
  # --------------------------------------------------

  test '15', '', 'Server rejects CarePlan search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A CarePlan search does not work without proper authorization.' do

    skip_if_not_supported(:CarePlan, [:search, :read])
    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '16', '', 'Server returns expected results from CarePlan search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's Assessment and Plan of Treatment information." do

    skip_if_not_supported(:CarePlan, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan"})
    @careplan = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::CarePlan, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::CarePlan, reply)

  end

  test '17', '', 'Server returns expected results from CarePlan search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable of returning a patient's Assessment and Plan of Treatment information over a specified time period.",
          :optional do

    skip_if_not_supported(:CarePlan, [:search, :read])

    assert !@careplan.nil?, 'Expected valid DSTU2 CarePlan resource to be present'

    date = @careplan.try(:period).try(:start)
    assert !date.nil?, "CarePlan period not returned"
    reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan", date: date})
    validate_search_reply(FHIR::DSTU2::CarePlan, reply)

  end

  test '18', '', 'Server returns expected results from CarePlan search by patient + category + status',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable returning all of a patient's active Assessment and Plan of Treatment information.",
          :optional do

    skip_if_not_supported(:CarePlan, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan", status: "active"})
    validate_search_reply(FHIR::DSTU2::CarePlan, reply)

  end

  test '19', '', 'Server returns expected results from CarePlan search by patient + category + status + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable returning a patient's active Assessment and Plan of Treatment information over a specified time period.",
          :optional do

    skip_if_not_supported(:CarePlan, [:search, :read])

    assert !@careplan.nil?, 'Expected valid DSTU2 CarePlan resource to be present'
    date = @careplan.try(:period).try(:start)
    assert !date.nil?, "CarePlan period not returned"
    reply = get_resource_by_params(FHIR::DSTU2::CarePlan, {patient: @instance.patient_id, category: "assess-plan", status: "active", date: date})
    validate_search_reply(FHIR::DSTU2::CarePlan, reply)

  end

  test '20', '', 'CarePlan read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:CarePlan, [:search, :read])

    validate_read_reply(@careplan, FHIR::DSTU2::CarePlan)

  end

  test '21', '', 'CarePlan history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:CarePlan, [:history])

    validate_history_reply(@careplan, FHIR::DSTU2::CarePlan)

  end

  test '22', '', 'CarePlan vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:CarePlan, [:vread])

    validate_vread_reply(@careplan, FHIR::DSTU2::CarePlan)

  end

  def skip_if_not_supported(resource, methods)

    skip "This server does not support #{resource.to_s} #{methods.join(',').to_s} operation(s) according to conformance statement." unless @instance.conformance_supported?(resource, methods)

  end

end
