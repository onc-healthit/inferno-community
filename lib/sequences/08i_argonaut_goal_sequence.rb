class ArgonautGoalSequence < SequenceBase

  group 'Argonaut Query and Data'

  title 'Argonaut Goal Profile'

  modal_before_run

  description 'Verify that the FHIR server follows the Argonaut Data Query Implementation Guide Server.'

  test_id_prefix 'ADQ'

  requires :token, :patient_id

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  # --------------------------------------------------
  # Goal Search
  # --------------------------------------------------

  test '44', '', 'Server rejects Goal search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Goal search does not work without proper authorization.' do

    skip_if_not_supported(:Goal, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Goal, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '45', '', 'Server returns expected results from Goal search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's goals." do

    skip_if_not_supported(:Goal, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Goal, {patient: @instance.patient_id})
    @goal = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::Goal, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::Goal, reply)

  end

  test '46', '', 'Server returns expected results from Goal search by patient + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of all of a patient's goals over a specified time period." do

    skip_if_not_supported(:Goal, [:search, :read])

    assert !@goal.nil?, 'Expected valid DSTU2 Goal resource to be present'
    date = @goal.try(:statusDate) || @goal.try(:targetDate) || @goal.try(:startDate)
    assert !date.nil?, "Goal statusDate, targetDate, nor startDate returned"
    reply = get_resource_by_params(FHIR::DSTU2::Goal, {patient: @instance.patient_id, date: date})
    validate_search_reply(FHIR::DSTU2::Goal, reply)

  end

  test '47', '', 'Goal read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:Goal, [:search, :read])

    validate_read_reply(@goal, FHIR::DSTU2::Goal)

  end

  test '48', '', 'Goal history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Goal, [:history])

    validate_history_reply(@goal, FHIR::DSTU2::Goal)

  end

  test '49', '', 'Goal vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:Goal, [:vread])

    validate_vread_reply(@goal, FHIR::DSTU2::Goal)

  end


  def skip_if_not_supported(resource, methods)

    skip "This server does not support #{resource.to_s} #{methods.join(',').to_s} operation(s) according to conformance statement." unless @instance.conformance_supported?(resource, methods)

  end

end
