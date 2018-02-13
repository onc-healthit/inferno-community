class ConformanceSequence < SequenceBase

  title 'Conformance Statement'

  description 'The FHIR server properly exposes a capability statement with necessary information.'

  test 'Responds to metadata endpoint with DSTU2 Conformance resource',
          'https://documentationlocation',
          'Exact Language' do

    @conformance = @client.conformance_statement(FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2)
    assert_response_ok @client.reply
    assert @conformance.class == FHIR::DSTU2::Conformance, 'Expected valid DSTU2 Conformance resource'
  end

  test 'Conformance states json support' do
    assert @conformance.class == FHIR::DSTU2::Conformance, 'Expected valid DSTU2 Conformance resource'
    assert @conformance.format.include?('json') || @conformance.format.include?('application/json+fhir'), 'Conformance does not state support for json.'
  end

  test 'Conformance lists valid OAuth 2.0 endpoints' do
    assert @conformance.class == FHIR::DSTU2::Conformance, 'Expected valid DSTU2 Conformance resource'
    oauth_metadata = @client.get_oauth2_metadata_from_conformance
    assert !oauth_metadata.nil?, 'No OAuth Metadata in conformance statement'
    authorize_url = oauth_metadata[:authorize_url]
    token_url = oauth_metadata[:token_url]
    assert (authorize_url =~ /\A#{URI::regexp(['http', 'https'])}\z/) == 0, "Invalid authorize url: '#{authorize_url}'"
    assert (token_url =~ /\A#{URI::regexp(['http', 'https'])}\z/) == 0, "Invalid token url: '#{token_url}'"

    registration_url = nil

    warning {
      security_info = @conformance.rest.first.security.extension.find{|x| x.url == 'http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris' }
      registration_url = security_info.extension.find{|x| x.url == 'register'}
      registration_url = registration_url.value if registration_url
      assert !registration_url.blank?,  'No dynamic registration endpoint in conformance.'
      assert (registration_url =~ /\A#{URI::regexp(['http', 'https'])}\z/) == 0, "Invalid registration url: '#{registration_url}'"
    }

    @instance.update(oauth_authorize_endpoint: authorize_url, oauth_token_endpoint: token_url, oauth_register_endpoint: registration_url)
  end

  test 'Conformance statement lists core capabilities' do
    assert @conformance.class == FHIR::DSTU2::Conformance, 'Expected valid DSTU2 Conformance resource'

    required_capabilities = ['launch-ehr',
      'launch-standalone',
      'client-public',
      'client-confidential-symmetric',
      'sso-openid-connect',
      'context-ehr-patient',
      'context-standalone-patient',
      'context-standalone-encounter',
      'permission-offline',
      'permission-patient',
      'permission-user'
    ]

    warning {
      capabilities = @conformance.rest.first.security.extension.find{|x| x.url == 'http://fhir-registry.smarthealthit.org/StructureDefinition/capabilities' }
      assert !capabilities.nil?, 'No SMART capabilities listed in conformance.'
      available_capabilities = capabilities.map{ |v| v['valueCode']}
      missing_capabilities = (required_capabilities - available_capabilities)
      assert missing_capabilities.empty?, "Conformance statement does not list required SMART capabilties: #{missing_capabilities.join(', ')}"
    }
  end

end
