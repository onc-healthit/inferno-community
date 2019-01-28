module Inferno
  module Sequence
    class ManualRegistrationSequence < SequenceBase

      title 'Manual Registration'

      description 'Manually register the Inferno application with the authorization service'

      test_id_prefix 'MR'

      optional

      requires :initiate_login_uri, :redirect_uris, :confidential_client,:initiate_login_uri, :redirect_uris, :client_id, :client_secret
      # defines :client_id, :client_secret

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
