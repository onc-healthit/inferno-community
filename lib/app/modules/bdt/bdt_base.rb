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
          'clientId' => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6InJlZ2lzdHJhdGlvbi10b2tlbiJ9.eyJqd2tzIjp7ImtleXMiOlt7Imt0eSI6IkVDIiwiY3J2IjoiUC0zODQiLCJ4IjoiTTFyM0dVZDBZRHBXbHF0ZjRHYXJPcmN3SWoyRnhDQlFmQnN4QmlLUzdmTTl1Z1pVUlBialp6YjZ5bDZOSlFETCIsInkiOiJmUWVvRm9wTTc0VjlXSWRYR0NHX3NtVm56c2N4eGlXM0hNQnNjd2tiUlVRSWxqMmFrTTM2WVB4ZDF2Z2M5WWVJIiwia2V5X29wcyI6WyJ2ZXJpZnkiXSwiZXh0Ijp0cnVlLCJraWQiOiJmMjkzOTdlZjQ0NmQ1YzE0ODBhZGViYmNiNTk5MTBiMyIsImFsZyI6IkVTMzg0In0seyJrdHkiOiJFQyIsImNydiI6IlAtMzg0IiwiZCI6IkxfOGh3VXlsbndoYWpNUGRqdkV0MTUtd0ZLbldDVEJ2WG1kSm5waTkySHN4TFVYWEwzS1ZidDlVYndFRjN2S0giLCJ4IjoiTTFyM0dVZDBZRHBXbHF0ZjRHYXJPcmN3SWoyRnhDQlFmQnN4QmlLUzdmTTl1Z1pVUlBialp6YjZ5bDZOSlFETCIsInkiOiJmUWVvRm9wTTc0VjlXSWRYR0NHX3NtVm56c2N4eGlXM0hNQnNjd2tiUlVRSWxqMmFrTTM2WVB4ZDF2Z2M5WWVJIiwia2V5X29wcyI6WyJzaWduIl0sImV4dCI6dHJ1ZSwia2lkIjoiZjI5Mzk3ZWY0NDZkNWMxNDgwYWRlYmJjYjU5OTEwYjMiLCJhbGciOiJFUzM4NCJ9XX0sImFjY2Vzc1Rva2Vuc0V4cGlyZUluIjoxNSwiaWF0IjoxNTU3NTAwNDIwfQ.2NJEarwScjRZZaDlpL1ixLxhWdfWFo_EFcaKJfL1oHE',
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

      def run_bdt(path)
        payload = {
          'path' => path,
          'settings' => BDT_CONFIG
        }
        response = RestClient.post(BDT_URL, payload.to_json, content_type: :json, accept: :json)
        response.body.split('\n').each do |chunk|
          message = JSON.parse(chunk.strip)

          data = message['data']
          next if data.nil?

          warning do
            data['warnings'].each do |warning|
              assert false, warning
            end
          end
          # request = {
          #   method: :post,
          #   url: url,
          #   headers: headers,
          #   payload: payload
          # }
          # response = {
          #   code: response.code,
          #   headers: response.headers,
          #   body: response.body
          # }
          # LoggedRestClient.record_response()

          requests = {}

          data['decorations'].each do |key, value|
            if value['__type'] == 'request'
              last_request = {
                method: value['method'],
                url: value['url'],
                headers: value['headers'],
                payload: value['body']
              }
              # binding.pry if value['method'] == 'POST'
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

          assert message['status'] != 'error', data['error']
        end
      rescue RestClient::Exception => e
        assert false, "Error connecting to BDT Service: #{e.message}"
      end
    end
  end
end
