class ConformanceSequence < SequenceBase

  description 'The FHIR server properly exposes a capability statement with necessary information.'

  test 'Responds to metadata endpoint with DSTU2 Conformance resource',
          'https://documentationlocation',
          'Exact Language' do

    @conformance = @client.conformance_statement
    assert_response_ok @client.reply
    assert @conformance.class == FHIR::DSTU2::Conformance, 'Expected valid DSTU2 Conformance resource'
  end

  test 'Conformance states proper JSON or XML support' do
    json = @conformance.format.include?(FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2)
    xml = @conformance.format.include?(FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2)
    assert (json || xml), "Conformance statement does not state support for either #{FHIR::Formats::ResourceFormat::RESOURCE_JSON_DSTU2} or #{FHIR::Formats::ResourceFormat::RESOURCE_XML_DSTU2}."
  end

  test 'Conformance lists valid OAuth 2.0 endpoints' do
    oauth_metadata = @client.get_oauth2_metadata_from_conformance
    assert !oauth_metadata.nil?, 'No OAuth Metadata in conformance statement'
    authorize_url = oauth_metadata[:authorize_url]
    token_url = oauth_metadata[:token_url]
    assert (authorize_url =~ /\A#{URI::regexp(['http', 'https'])}\z/) == 0, "Invalid authorize url: '#{authorize_url}'"
    assert (token_url =~ /\A#{URI::regexp(['http', 'https'])}\z/) == 0, "Invalid token url: '#{token_url}'"

    @instance.update(oauth_authorize_endpoint: authorize_url, oauth_token_endpoint: token_url)
  end
end
