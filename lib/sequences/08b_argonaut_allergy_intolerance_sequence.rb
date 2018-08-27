class ArgonautAllergyIntoleranceSequence < SequenceBase

  group 'Argonaut Query and Data'

  title 'Argonaut Allergy Intolerance Profile'

  modal_before_run

  description 'Verify that the FHIR server follows the Argonaut Data Query Implementation Guide Server for Allergy Intolerance.'

  test_id_prefix 'ADQ-AI'

  requires :token, :patient_id

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  # --------------------------------------------------
  # AllergyIntolerance Search
  # --------------------------------------------------

  test '01', '', 'Server rejects AllergyIntolerance search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'An AllergyIntolerance search does not work without proper authorization.' do

    skip_if_not_supported(:AllergyIntolerance, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::AllergyIntolerance, {patient: @instance.patient_id})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '02', '', 'Server returns expected results from AllergyIntolerance search by patient',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning a patient's allergies." do

    skip_if_not_supported(:AllergyIntolerance, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::AllergyIntolerance, {patient: @instance.patient_id})
    @allergyintolerance = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::AllergyIntolerance, reply)
    save_resource_ids_in_bundle(FHIR::DSTU2::AllergyIntolerance, reply)

  end

  test '03', '', 'Server returns expected results from AllergyIntolerance read resource',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:AllergyIntolerance, [:search, :read])
    validate_read_reply(@allergyintolerance, FHIR::DSTU2::AllergyIntolerance)

  end

  test '04', '', 'AllergyIntolerance history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:AllergyIntolerance, [:history])
    validate_history_reply(@allergyintolerance, FHIR::DSTU2::AllergyIntolerance)

  end

  test '05', '', 'AllergyIntolerance vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:AllergyIntolerance, [:vread])

    validate_vread_reply(@allergyintolerance, FHIR::DSTU2::AllergyIntolerance)

  end

  def skip_if_not_supported(resource, methods)

    skip "This server does not support #{resource.to_s} #{methods.join(',').to_s} operation(s) according to conformance statement." unless @instance.conformance_supported?(resource, methods)

  end

end
