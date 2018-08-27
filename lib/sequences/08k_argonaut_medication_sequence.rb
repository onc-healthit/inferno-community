class ArgonautMedicationStatementSequence < SequenceBase

  group 'Argonaut Query and Data'

  title 'Argonaut Medication Statement Profile'

  modal_before_run

  description 'Verify that Medication resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

  test_id_prefix 'ADQ-MP'

  requires :token, :patient_id

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  # --------------------------------------------------
  # MedicationStatement Search
  # --------------------------------------------------

  test '63', '', 'Server rejects MedicationStatement search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'An MedicationStatement search does not work without proper authorization.' do

    skip_if_not_supported(:MedicationStatement, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::MedicationStatement, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '64', '', 'Server returns expected results from MedicationStatement search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning a patient's medications." do

    skip_if_not_supported(:MedicationStatement, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::MedicationStatement, {patient: @instance.patient_id})
    @medicationstatement = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::MedicationStatement, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::MedicationStatement, reply)

  end

  test '65', '', 'MedicationStatement read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:MedicationStatement, [:search, :read])

    validate_read_reply(@medicationstatement, FHIR::DSTU2::MedicationStatement)

  end

  test '66', '', 'MedicationStatement history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:MedicationStatement, [:history])

    validate_history_reply(@medicationstatement, FHIR::DSTU2::MedicationStatement)

  end

  test '67', '', 'MedicationStatement vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:MedicationStatement, [:vread])

    validate_vread_reply(@medicationstatement, FHIR::DSTU2::MedicationStatement)

  end


  def skip_if_not_supported(resource, methods)

    skip "This server does not support #{resource.to_s} #{methods.join(',').to_s} operation(s) according to conformance statement." unless @instance.conformance_supported?(resource, methods)

  end

end
