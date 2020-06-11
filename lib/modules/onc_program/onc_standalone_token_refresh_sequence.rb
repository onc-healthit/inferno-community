# frozen_string_literal: true

require_relative './shared_onc_launch_tests'
require_relative './onc_token_refresh_sequence'

module Inferno
  module Sequence
    class OncStandaloneTokenRefreshSequence < OncTokenRefreshSequence
      extends_sequence OncTokenRefreshSequence

      title 'Token Refresh'
      test_id_prefix 'SA-OTR'

      title 'Token Refresh'
      description 'Demonstrate token refresh capability.'
      test_id_prefix 'TR'

      requires :onc_sl_url, :onc_sl_client_id, :onc_sl_confidential_client, :onc_sl_client_secret, :refresh_token, :oauth_token_endpoint
      defines :token, :refresh_token, :onc_sl_token, :onc_sl_refresh_token, :onc_sl_patient_id, :onc_sl_oauth_token_endpoint

      def url_property
        'onc_sl_url'
      end

      def instance_url
        @instance.send(url_property)
      end

      def instance_client_id
        @instance.onc_sl_client_id
      end

      def instance_confidential_client
        @instance.onc_sl_confidential_client
      end

      def instance_client_secret
        @instance.onc_sl_client_secret
      end

      def instance_scopes
        @instance.onc_sl_scopes
      end

      def after_save_refresh_token(refresh_token)
        # This method is used to save off the refresh token for standalone launch to be used for token
        # revocation later.  We must do this because we are overwriting our standalone refresh/access token
        # with the one used in the ehr launch.

        @instance.onc_sl_refresh_token = refresh_token
        @instance.save!
      end

      def after_save_access_token(token)
        # This method is used to save off the access token for standalone launch to be used for token
        # revocation later.  We must do this because we are overwriting our standalone refresh/access token
        # with the one used in the ehr launch.
        @instance.onc_sl_token = token

        # save a copy so patient_id and oauth_token_endpoint are not overwritten
        @instance.onc_sl_patient_id = @instance.patient_id

        @instance.save!
      end
    end
  end
end
