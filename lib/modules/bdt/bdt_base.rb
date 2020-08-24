# frozen_string_literal: true

module Inferno
  module Sequence
    class BDTBase < SequenceBase
      BDT_URL = 'http://localhost:4500/api/tests'

      def settings
        {
          'baseURL' => @instance.bulk_url,
          # REQUIRED. Can be "backend-services", "client-credentials" or "none".
          'authType' => 'backend-services',
          'requiresAuth' => !@instance.bulk_requires_auth.nil?,
          'strictSSL' => false,
          'tokenEndpoint' => @instance.bulk_token_endpoint,
          'clientId' => @instance.bulk_client_id,
          'fastestResource' => @instance.bulk_fastest_resource,
          'sinceParam' => '_since',
          'systemExportEndpoint' => @instance.bulk_system_export_endpoint,
          'patientExportEndpoint' => @instance.bulk_patient_export_endpoint,
          'groupExportEndpoint' => @instance.bulk_group_export_endpoint,
          'jwksUrlAuth' => @instance.bulk_jwks_url_auth.present?,
          'jwksUrl' => @instance.bulk_jwks_url_auth,
          'privateKey' => JSON.parse(@instance.bulk_private_key)
        }
      end

      def run_bdt(path)
        payload = {
          'path' => path,
          'settings' => settings
        }
        response = RestClient.post(BDT_URL, payload.to_json, content_type: :json, accept: :json)
        response.body.split("\n").each do |chunk|
          message = JSON.parse(chunk.strip)

          data = message['data']
          next if data.nil?

          warning do
            data['warnings'].each do |warning|
              assert false, warning
            end
          end

          requests = {}

          data['decorations'].each do |key, value|
            if value['__type'] == 'request'
              last_request = {
                method: value['method'],
                url: value['url'],
                headers: value['headers'],
                payload: value['body']
              }
              requests['request_' + key.chomp('Request').strip] = last_request
            end

            next unless value['__type'] == 'response'

            request_key = 'request_' + key.gsub(/[ ]*Response[ \d]*/, '')
            next unless requests.key? request_key

            referenced_request = requests[request_key]
            response = {
              code: value['statusCode'],
              headers: value['headers'],
              body: value['body']&.to_json
            }
            LoggedRestClient.record_response(referenced_request, response)
          end

          omit 'Not supported' if data['status'] == 'not-supported'
          todo 'Not Implemented' if data['status'] == 'not-supported'

          assert data['status'] != 'failed', data['error'] && data['error']['message']
        end
      rescue RestClient::Exception => e
        assert false, "Error connecting to BDT Service: #{e.message}"
      end
    end
  end
end
