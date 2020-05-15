# frozen_string_literal: true

module Inferno
  module Sequence
    class BDTBase < SequenceBase
      BDT_URL = 'http://localhost:4500/api/tests'

      BDT_CONFIG = {
        'path' => '5.0',
        'format' => 'json',
        'settings' => {
          'baseURL' => 'https://bulk-data.smarthealthit.org/eyJlcnIiOiIiLCJwYWdlIjoxMDAsImR1ciI6MTAsInRsdCI6MTUsIm0iOjF9/fhir',
          'tokenEndpoint' => 'https://bulk-data.smarthealthit.org/auth/token',
          'clientId' => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6InJlZ2lzdHJhdGlvbi10b2tlbiJ9.eyJqd2tzIjp7ImtleXMiOlt7Imt0eSI6IkVDIiwiY3J2I' \
                        'joiUC0zODQiLCJ4IjoiTTFyM0dVZDBZRHBXbHF0ZjRHYXJPcmN3SWoyRnhDQlFmQnN4QmlLUzdmTTl1Z1pVUlBialp6YjZ5bDZOSlFETCIsInkiOiJmUWV' \
                        'vRm9wTTc0VjlXSWRYR0NHX3NtVm56c2N4eGlXM0hNQnNjd2tiUlVRSWxqMmFrTTM2WVB4ZDF2Z2M5WWVJIiwia2V5X29wcyI6WyJ2ZXJpZnkiXSwiZXh0I' \
                        'jp0cnVlLCJraWQiOiJmMjkzOTdlZjQ0NmQ1YzE0ODBhZGViYmNiNTk5MTBiMyIsImFsZyI6IkVTMzg0In0seyJrdHkiOiJFQyIsImNydiI6IlAtMzg0Iiw' \
                        'iZCI6IkxfOGh3VXlsbndoYWpNUGRqdkV0MTUtd0ZLbldDVEJ2WG1kSm5waTkySHN4TFVYWEwzS1ZidDlVYndFRjN2S0giLCJ4IjoiTTFyM0dVZDBZRHBXb' \
                        'HF0ZjRHYXJPcmN3SWoyRnhDQlFmQnN4QmlLUzdmTTl1Z1pVUlBialp6YjZ5bDZOSlFETCIsInkiOiJmUWVvRm9wTTc0VjlXSWRYR0NHX3NtVm56c2N4eGl' \
                        'XM0hNQnNjd2tiUlVRSWxqMmFrTTM2WVB4ZDF2Z2M5WWVJIiwia2V5X29wcyI6WyJzaWduIl0sImV4dCI6dHJ1ZSwia2lkIjoiZjI5Mzk3ZWY0NDZkNWMxN' \
                        'DgwYWRlYmJjYjU5OTEwYjMiLCJhbGciOiJFUzM4NCJ9XX0sImFjY2Vzc1Rva2Vuc0V4cGlyZUluIjoxNSwiaWF0IjoxNTU3NTAwNDIwfQ.2NJEarwScjRZ' \
                        'ZaDlpL1ixLxhWdfWFo_EFcaKJfL1oHE',
          'systemExportEndpoint' => '/$export',
          'patientExportEndpoint' => '/Patient/$export',
          'groupExportEndpoint' => '/Group/6/$export',
          'fastestResource' => 'ImagingStudy',
          'requiresAuth' => false,
          'sinceParam' => '_since',
          'jwksUrlAuth' => true,
          'jwksAuth' => true,
          'publicKey' => {
            'kty' => 'EC',
            'crv' => 'P-384',
            'x' => 'M1r3GUd0YDpWlqtf4GarOrcwIj2FxCBQfBsxBiKS7fM9ugZURPbjZzb6yl6NJQDL',
            'y' => 'fQeoFopM74V9WIdXGCG_smVnzscxxiW3HMBscwkbRUQIlj2akM36YPxd1vgc9YeI',
            'key_ops' => [
              'verify'
            ],
            'ext' => true,
            'kid' => 'f29397ef446d5c1480adebbcb59910b3',
            'alg' => 'ES384'
          },
          'privateKey' => {
            'kty' => 'EC',
            'crv' => 'P-384',
            'd' => 'L_8hwUylnwhajMPdjvEt15-wFKnWCTBvXmdJnpi92HsxLUXXL3KVbt9UbwEF3vKH',
            'x' => 'M1r3GUd0YDpWlqtf4GarOrcwIj2FxCBQfBsxBiKS7fM9ugZURPbjZzb6yl6NJQDL',
            'y' => 'fQeoFopM74V9WIdXGCG_smVnzscxxiW3HMBscwkbRUQIlj2akM36YPxd1vgc9YeI',
            'key_ops' => [
              'sign'
            ],
            'ext' => true,
            'kid' => 'f29397ef446d5c1480adebbcb59910b3',
            'alg' => 'ES384'
          }
        }
      }.freeze

      def settings
        {
          'baseURL' => @instance.bulk_url,
          'tokenEndpoint' => @instance.bulk_token_endpoint,
          'clientId' => @instance.bulk_client_id,
          'systemExportEndpoint' => @instance.bulk_system_export_endpoint,
          'patientExportEndpoint' => @instance.bulk_patient_export_endpoint,
          'groupExportEndpoint' => @instance.bulk_group_export_endpoint,
          'fastestResource' => @instance.bulk_fastest_resource,
          'requiresAuth' => !@instance.bulk_requires_auth.nil?,
          'sinceParam' => '_since',
          'jwksUrlAuth' => !@instance.bulk_jwks_url_auth.nil?,
          'jwksAuth' => true,
          'jwksUrl' => @instance.bulk_jwks_url_auth,
          'strictSSL' => false,
          'publicKey' => JSON.parse(@instance.bulk_public_key),
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
