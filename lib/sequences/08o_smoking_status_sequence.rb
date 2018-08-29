class ArgonautSmokingStatusSequence < SequenceBase

  group 'Argonaut Query and Data'

  title 'Argonaut Smoking Status Profile'

  description 'Verify that Smoking Status is collected on the FHIR server according to the Argonaut Data Query Implementation Guide'

  test_id_prefix 'ADQ-SS'

  requires :token, :patient_id

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  test '01', '', 'Server rejects Smoking Status search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A Smoking Status search does not work without proper authorization.' do

    skip_if_not_supported(:Observation, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, code: "72166-2"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '02', '', 'Server returns expected results from Smoking Status search by patient + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning a patient's smoking status." do

    skip_if_not_supported(:Observation, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::Observation, {patient: @instance.patient_id, code: "72166-2"})
    validate_search_reply(FHIR::DSTU2::Observation, reply)
    # TODO check for 72166-2
    save_resource_ids_in_bundle(FHIR::DSTU2::Observation, reply)

  end

  test '11', '', 'Smoking Status resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-smokingstatus.html',
          'Procedure resources associated with Procedure conform to Argonaut profiles.' do
    test_resources_against_profile('Observation', ValidationUtil::SMOKING_STATUS_URL)
    skip_unless @profiles_encountered.include?(ValidationUtil::SMOKING_STATUS_URL), 'No Smoking Status Observations found.'
    assert !@profiles_failed.include?(ValidationUtil::SMOKING_STATUS_URL), "Smoking Status Observations failed validation.<br/>#{@profiles_failed[ValidationUtil::SMOKING_STATUS_URL]}"
  end

end
