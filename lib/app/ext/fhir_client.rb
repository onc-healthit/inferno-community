# frozen_string_literal: true

module FHIR
  VERSIONS = [:dstu2, :stu3, :r4].freeze

  class Client
    attr_accessor :requests, :testing_instance

    def record_requests(reply)
      reply.response[:timestamp] = DateTime.now
      @requests ||= []
      @requests << reply
    end

    def monitor_requests
      return if @decorated

      @decorated = true
      [:get, :put, :post, :delete, :head, :patch].each do |method|
        class_eval <<~RUBY, __FILE__, __LINE__ + 1
          alias #{method}_original #{method}
          def #{method}(*args, &block)
            refresh_token_if_needed
            reply = #{method}_original(*args, &block)
            record_requests(reply)
            return reply
          end
        RUBY
      end
    end

    def refresh_token_if_needed
      return if testing_instance&.refresh_token.blank?

      perform_refresh if time_to_refresh?
    end

    def time_to_refresh?
      return true if testing_instance.token_expires_in.blank?

      testing_instance.token_expiration_time.to_i - DateTime.now.to_i < 60
    end

    def perform_refresh
      oauth2_params = {
        'grant_type' => 'refresh_token',
        'refresh_token' => testing_instance.refresh_token
      }
      oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

      if testing_instance.confidential_client
        oauth2_headers['Authorization'] = encoded_secret(testing_instance.client_id, testing_instance.client_secret)
      else
        oauth2_params['client_id'] = testing_instance.client_id
      end

      begin
        token_response = Inferno::LoggedRestClient.post(
          testing_instance.oauth_token_endpoint,
          oauth2_params,
          oauth2_headers
        )

        return if token_response.code != 200

        token_response_body = JSON.parse(token_response.body)

        expires_in = token_response_body['expires_in'].is_a?(Numeric) ? token_response_body['expires_in'] : nil

        update_params = {
          token: token_response_body['access_token'],
          token_retrieved_at: DateTime.now,
          token_expires_in: expires_in
        }

        update_params[:refresh_token] = token_response_body['refresh_token'] if token_response_body['refresh_token'].present?
        testing_instance.save
        testing_instance.update(update_params)

        set_bearer_token(token_response_body['access_token'])
      rescue StandardError => e
        Inferno.logger.error "Unable to refresh token: #{e.message}"
      end
    end

    def encoded_secret(client_id, client_secret)
      "Basic #{Base64.strict_encode64(client_id + ':' + client_secret)}"
    end

    def self.for_testing_instance(instance)
      new(instance.url).tap do |client|
        client.testing_instance = instance
        case instance.fhir_version
        when 'stu3'
          client.use_stu3
        when 'dstu2'
          client.use_dstu2
        else
          client.use_r4
        end
        client.default_json
      end
    end
  end
end
