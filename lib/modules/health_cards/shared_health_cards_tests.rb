# frozen_string_literal: true

module Inferno
  module Sequence
    module SharedHealthCardsTests
      def self.included(klass)
        klass.extend(ClassMethods)
      end

        module ClassMethods
          def valid_jws(index:)
            test :valid_jws do
              metadata do
                id index
                name 'Verifiable credentials contain valid JWS'
                link 'https://smarthealth.cards/#protocol-details'
                description %(
                )
              end

              skip_if @verifiable_credentials_jws.nil?, 'No verifiable credentials received'

              @verifiable_credentials = []
              @verifiable_credential_bundles = []
              @decoded_jws = []

              @verifiable_credentials_jws.each do |jws|

                # The JWT library does not seem to work when parts are zipped
                # So unzip the payload and reencode

                jws_segments = jws.split('.')
                assert jws_segments.length == 3, 'JWS must contain three segments, separated by "."'
                jws_segments.second

                raw_deflate_magic_number = -15

                unzipped = nil
                begin
                  zlib_runner = Zlib::Inflate.new(raw_deflate_magic_number)
                  unzipped = zlib_runner.inflate(JWT::Base64.url_decode(jws_segments[1]))
                rescue StandardError => e
                  # TODO: pick up this error
                  assert false, "Error inflating payload segment using ZLib (#{jws_segments[1]}): #{e.message}"
                end

                jws_segments[1] = JWT::Base64.url_encode(unzipped)
                #TODO: check minified
                #Perhaps we should minify it again and see if it is unchanged?

                unzipped_jws = jws_segments.join('.')

                decoded_token = nil
                begin
                  decoded_token =
                    JWT.decode(
                      unzipped_jws,
                      nil,
                      false
                    )
                rescue StandardError => e # Show parse error as failure
                  assert false, "ID token is not a properly constructed JWT: #{e.message}"
                end
                decoded_payload, decoded_header = decoded_token

                # TODO: CHECK THE PAYLOAD
                @decoded_jws<< {
                  payload: decoded_payload,
                  header: decoded_header
                }

                # Store these off for later tests
                @verifiable_credentials << decoded_payload

              end
            end

            omit
          end
          def retrieve_jwks(index:)
            test :retrieve_jwks do
              metadata do
                id index
                name 'Well-known file available and contains required jwks information'
                link 'https://smarthealth.cards/#protocol-details'
                description %(
                )
              end

              skip_if @decoded_jws.empty?, 'No JWS were decoded properly'

              # just do the first for now
              # do all of the signatures need to have the same issuer?

              assert @decoded_jws.first[:payload].include?('iss'), 'No iss was provided in the JWS.'
              issuer = @decoded_jws.first[:payload]['iss']

              headers = {
                Accept: 'application/json'
              }
      
              jwks_uri = issuer.chomp('/') + '/.well-known/jwks.json'
      
              jwks_response = LoggedRestClient.get(jwks_uri, headers: headers)

              assert_response_ok(jwks_response)
              assert_valid_json(jwks_response.body)
      
              @raw_jwks = JSON.parse(jwks_response.body).deep_symbolize_keys
              assert @raw_jwks[:keys].is_a?(Array), 'JWKS "keys" field must be an array'


              skip 'Test not yet updated to support correct key types'
              # BELOW IS FROM OPENID TESTS, NEED TO BE UPDATED
      
              @raw_jwks[:keys].each do |jwk|
                # https://tools.ietf.org/html/rfc7517#section-5
                # Implementations SHOULD ignore JWKs within a JWK Set that use "kty"
                # (key type) values that are not understood by them
                # next unless jwk[:kty] == 'RSA' # SMART only requires support of RSA SHA-256 keys

                assert jwk[:kty] == 'EC', 'kty shall be EC' 
      
                begin
                  JWT::JWK.import(jwk)
                rescue StandardError => e
                  assert false, "Invalid JWK: #{jwk.to_json}, #{e.message}"
                end
              end
      
              @jwks = @raw_jwks[:keys].select { |jwk| jwk[:kty] == 'EC' }
              assert @jwks.present?, 'JWKS contains no EC keys'
            end
          end
      
          def credential_header(index:)
            test :credential_header do
              metadata do
                id index
                link 'https://openid.net/specs/openid-connect-core-1_0.html#IDToken'
                name 'Verifiable Credential header contains required information'
                description %(
                )
              end

              skip 'Test not yet implemented'

              # BELOW IS FROM OPENID, NEEDS ADAPTATION
      
              skip_if_id_token_not_requested
              skip_if_id_token_could_not_be_decoded
              skip_if_configuration_could_not_be_retrieved
              skip_unless @jwks.present?, 'RSA keys could not be retrieved from JWKS'
      
              warning do
                discouraged_fields = discouraged_header_fields & @decoded_header.keys
                assert discouraged_fields.blank?, "ID token header contains fields that should not be used: #{discouraged_fields.join(', ')}"
              end
      
              algorithm = @decoded_header['alg']
              assert algorithm == 'RS256', "ID Token signed with #{algorithm} rather than RS256"
      
              kid = @decoded_header['kid']
      
              if @raw_jwks[:keys].length > 1
                assert kid.present?, '"kid" field must be present if JWKS contains multiple keys'
                @jwk = @jwks.find { |jwk| jwk[:kid] == kid }
                assert @jwk.present?, "JWKS did not contain an RS256 key with an id of #{kid}"
              else
                @jwk = @jwks.first
                assert @jwk[:kid] == kid, "JWKS did not contain an RS256 key with an id of #{kid}" if kid.present?
              end
            end
          end
      
          def credential_payload(index:)
            test :credential_payload do
              metadata do
                id index
                link 'https://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation'
                name 'Credential payload has required information and a valid signature'
                description %(
                )
              end

              @verifiable_credentials_bundles = []

              no_bundle = false

              @verifiable_credentials.each do |verifiable_credentials|
                bundle = verifiable_credentials&.dig('vc', 'credentialSubject', 'fhirBundle')
                @verifiable_credentials_bundles << FHIR::Bundle.new(bundle) unless bundle.nil?
                no_bundle ||= bundle.nil?
              end

              assert !no_bundle, 'One of the verifiable credentials did not contain a fhir bundle'

              skip 'Test not yet implemented'

              # BELOW IS FROM OPENID, NEEDS ADAPTATION
      
              skip_if_id_token_not_requested
              skip_if_id_token_could_not_be_decoded
              skip_if_configuration_could_not_be_retrieved
      
              missing_claims = required_payload_claims - @decoded_payload.keys
              assert missing_claims.empty?, "ID token missing required claims: #{missing_claims.join(', ')}"
      
              skip_if @jwk.blank?, 'No JWK was found'
      
              begin
                JWT.decode(
                  @instance.id_token,
                  JWT::JWK.import(@jwk).public_key,
                  true,
                  algorithms: ['RS256'],
                  exp_leeway: 60,
                  iss: @oidc_configuration['issuer'],
                  aud: @instance.client_id,
                  verify_not_before: false,
                  verify_iat: false,
                  verify_jti: false,
                  verify_sub: false,
                  verify_iss: true,
                  verify_aud: true
                )
              rescue StandardError => e
                assert false, "Token validation error: #{e.message}"
              end
            end
          end

          def credential_payload_fhir_validated(index:)
            test :credential_payload_fhir_validated do
              metadata do
                id index
                link 'https://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation'
                name 'FHIR bundle in credential is valid FHIR'
                description %(
                )
              end


              @verifiable_credentials_bundles.each do |bundle|

                #TODO: VALIDATE THE BASIC FHIR BUNDLES HERE

              end

              skip 'Test not yet implemented'

            end

            omit
          end
        end
      end
    end
  end
end
