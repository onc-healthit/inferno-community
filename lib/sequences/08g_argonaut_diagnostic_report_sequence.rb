class ArgonautDiagnosticReportSequence < SequenceBase

  group 'Argonaut Profile Conformance'

  title 'Diagnostic Report'

  description 'Verify that DiagnosticReport resources on the FHIR server follow the Argonaut Data Query Implementation Guide'

  test_id_prefix 'ADQ-DR'

  requires :token, :patient_id

  preconditions 'Client must be authorized' do
    !@instance.token.nil?
  end

  # --------------------------------------------------
  # DiagnosticReport Search
  # --------------------------------------------------

  test '01', '', 'Server rejects DiagnosticReport search without authorization',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'A DiagnosticReport search does not work without proper authorization.' do

    skip_if_not_supported(:DiagnosticReport, [:search, :read])

    @client.set_no_auth
    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB"})
    @client.set_bearer_token(@instance.token)
    assert_response_unauthorized reply

  end

  test '02', '', 'Server returns expected results from DiagnosticReport search by patient + category',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory diagnostic reports queried by category." do

    skip_if_not_supported(:DiagnosticReport, [:search, :read])

    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB"})
    @diagnosticreport = reply.try(:resource).try(:entry).try(:first).try(:resource)
    validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)

  end

  test '03', '', 'Server returns expected results from DiagnosticReport search by patient + category + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory diagnostic reports queried by category code and date range." do

    skip_if_not_supported(:DiagnosticReport, [:search, :read])

    assert !@diagnosticreport.nil?, 'Expected valid DSTU2 DiagnosticReport resource to be present'
    date = @diagnosticreport.try(:effectiveDateTime)
    assert !date.nil?, "DiagnosticReport effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB", date: date})
    validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)

  end

  test '04', '', 'Server returns expected results from DiagnosticReport search by patient + category + code',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server is capable of returning all of a patient's laboratory diagnostic reports queried by category and code." do

    skip_if_not_supported(:DiagnosticReport, [:search, :read])

    assert !@diagnosticreport.nil?, 'Expected valid DSTU2 DiagnosticReport resource to be present'
    code = @diagnosticreport.try(:code).try(:coding).try(:first).try(:code)
    assert !code.nil?, "DiagnosticReport code not returned"
    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB", code: code})
    validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)

  end

  test '05', '', 'Server returns expected results from DiagnosticReport search by patient + category + code + date',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          "A server SHOULD be capable of returning all of a patient's laboratory diagnostic reports queried by category and one or more codes and date range.",
          :optional do

    skip_if_not_supported(:DiagnosticReport, [:search, :read])

    assert !@diagnosticreport.nil?, 'Expected valid DSTU2 DiagnosticReport resource to be present'
    code = @diagnosticreport.try(:code).try(:coding).try(:first).try(:code)
    assert !code.nil?, "DiagnosticReport code not returned"
    date = @diagnosticreport.try(:effectiveDateTime)
    assert !date.nil?, "DiagnosticReport effectiveDateTime not returned"
    reply = get_resource_by_params(FHIR::DSTU2::DiagnosticReport, {patient: @instance.patient_id, category: "LAB", code: code, date: date})
    validate_search_reply(FHIR::DSTU2::DiagnosticReport, reply)

  end

  test '06', '', 'DiagnosticReport read resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHALL make available the read interactions for the Argonaut Profiles the server chooses to support.' do

    skip_if_not_supported(:DiagnosticReport, [:search, :read])

    validate_read_reply(@diagnosticreport, FHIR::DSTU2::DiagnosticReport)

  end

  test '07', '', 'DiagnosticReport history resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:DiagnosticReport, [:history])

    validate_history_reply(@diagnosticreport, FHIR::DSTU2::DiagnosticReport)

  end

  test '08', '', 'DiagnosticReport vread resource supported',
          'http://www.fhir.org/guides/argonaut/r2/Conformance-server.html',
          'All servers SHOULD make available the vread and history-instance interactions for the Argonaut Profiles the server chooses to support.',
          :optional do

    skip_if_not_supported(:DiagnosticReport, [:vread])

    validate_vread_reply(@diagnosticreport, FHIR::DSTU2::DiagnosticReport)

  end

  test '09', '', 'DiagnosticReport resources associated with Patient conform to Argonaut profiles',
          'http://www.fhir.org/guides/argonaut/r2/StructureDefinition-argo-diagnosticreport.html',
         'DiagnosticReport resources associated with Patient conform to Argonaut profiles.' do
    test_resources_against_profile('DiagnosticReport')
  end

end
