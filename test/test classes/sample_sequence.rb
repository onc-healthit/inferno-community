class SampleSequence < SequenceBase
  title 'Smaple'

  description 'Verify that the server supports the OAuth 2.0 Dynamic Client Registration Protocol.'

  details %(
    # Sample
  )

  test_id_prefix 'SAMPLE'

  show_uris

  requires :oauth_register_endpoint, :client_name, :initiate_login_uri, :redirect_uris, :scopes, :confidential_client, :initiate_login_uri, :redirect_uris, :dynamic_registration_token
  defines :client_id, :client_secret

  test 'Sample Omitted Test' do
    metadata do
      id '01'
      link ''
      desc %(
        Sample Test used for testing omission
      )
    end

    omit
  end
end