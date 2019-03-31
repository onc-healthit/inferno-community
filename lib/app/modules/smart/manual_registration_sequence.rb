module Inferno
  module Sequence
    class ManualRegistrationSequence < SequenceBase

      title 'Manual Registration'

      description 'Manually register the Inferno application with the authorization service'

      test_id_prefix 'MR'

      optional

      requires :initiate_login_uri, :redirect_uris, :confidential_client,:initiate_login_uri, :redirect_uris, :client_id, :client_secret
      defines :client_id, :client_secret
      
      show_uris

      details %(
        # Background

        Apps need to be registered with the authorization service in order to be launched.  The registration process provides
        the client app with a `client_id` which identifies the client.  A `client_secret` may also be issued if the app is
        designated a confidential app that can satisfactorily protect the secret.  The app provides the authorization service:

         * zero or more launch URLs
         * one or more redirect URLs

        A launch URLs are used for executing an EHR launch, but are unnecessary for a Standalone launch.

        # Test Methodology

        This test sets the `client_id` to be used by Inferno.

        For more information see:

        * [Registering a SMART App with an EHR](http://hl7.org/fhir/smart-app-launch/#registering-a-smart-app-with-an-ehr)
        * [Support for "public" and "confidential" apps](http://hl7.org/fhir/smart-app-launch/#support-for-public-and-confidential-apps)
              )

      test 'User entered client id, and client secret if confidential client' do

        metadata {
          id '01'
          link 'https://www.hl7.org/fhir/security.html'
          desc %(
            Received client id (and client secret if necessary)
          )
        }

        assert !@instance.client_id.blank?, 'User must register the Inferno client with the authorizaton service and enter in Client ID'

      end
    end
  end
end
