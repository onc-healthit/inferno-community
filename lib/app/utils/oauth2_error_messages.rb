# frozen_string_literal: true

module Inferno
  class App
    module OAuth2ErrorMessages
      def no_instance_for_state_error_message
        %(
          <p>
            Inferno has detected an issue with the SMART launch.
            No actively running launch sequences found with a state of #{params[:state]}.
            The authorization server is not returning the correct state variable and
            therefore Inferno cannot identify which server is currently under test.
            Please click your browser's "Back" button to return to Inferno,
            and click "Refresh" to ensure that the most recent test results are visible.
          </p>
          #{server_error_message}
          #{server_error_description}
        )
      end

      def server_error_message
        return '' if params[:error].blank?

        "<p>Error returned by server: <strong>#{params[:error]}</strong>.</p>"
      end

      def server_error_description
        return '' if params[:error_description].blank?

        "<p>Error description returned by server: <strong>#{params[:error_description]}</strong>.</p>"
      end

      def bad_state_error_message
        "State provided in redirect (#{params[:state]}) does not match expected state (#{@instance.state})."
      end

      def no_instance_for_iss_error_message
        %(
          Error: No actively running launch sequences found for iss #{params[:iss]}.
          Please ensure that the EHR launch test is actively running before attempting to launch Inferno from the EHR.
        )
      end

      def no_iss_error_message
        'No iss for redirect'
      end

      def no_running_test_error_message
        'Error: Could not find a running test that matches this set of criteria'
      end
    end
  end
end
