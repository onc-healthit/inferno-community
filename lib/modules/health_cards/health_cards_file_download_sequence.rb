# frozen_string_literal: true

require 'zlib'
require_relative './shared_health_cards_tests'

module Inferno
  module Sequence
    class HealthCardsFileDownloadSequence < SequenceBase
      include SharedHealthCardsTests

      title 'Download and validate a health card via File download'

      test_id_prefix 'HCF'

      requires :file_download_url, :extra_headers

      description 'Download and validate a health card via File download'

      details %(
        Download and validate a health card via File download
      )

      test :download_health_card do
        metadata do
          id '01'
          name 'Health Card can be downloaded'
          link 'https://smarthealth.cards/'
          description %(
            Health card can be downloaded.
          )
        end

        headers = {
          Accept: 'application/json'
        }

        @health_card_response = LoggedRestClient.get(@instance.file_download_url)

        assert_response_ok(@health_card_response)
        @health_card_downloaded = true
        assert_valid_json(@health_card_response.body)

        @health_card = JSON.parse(@health_card_response.body)
        
      end

      test :response_content_type do
        metadata do
          id '02'
          name 'Response contains correct Content-Type of application/smart-health-card'
          link 'https://smarthealth.cards/'
          description %(
            Placeholder
          )
        end
        skip_unless @health_card_downloaded, 'Health card not successfully downloaded'

        assert_response_content_type(@health_card_response, 'application/smart-health-card')
        
      end

      test :response_extension do
        metadata do
          id '03'
          name 'Health card is provided as a file download with a .smart-health-card extension.'
          link 'https://smarthealth.cards/'
          description %(
            Placeholder
          )
        end
        skip_unless @health_card_downloaded, 'Health card not successfully downloaded'
        assert @health_card_response.headers.include?(:content_disposition), 'Response must include a Content-Disposition header to signal clients to download as file'
        content_disposition = @health_card_response.headers[:content_disposition]
        correct_file_type = /filename\=.*\.smart-health-card/.match?(content_disposition)
        assert correct_file_type, "File provided in Content-Disposition must be of type '.smart-health-card'.  Content-Disposition provided: '#{content_disposition}'."
        
      end

      test :response_json do
        metadata do
          id '04'
          name 'Response body content is JSON object containing array of Verifiable Credential JWT strings'
          link 'https://smarthealth.cards/'
          description %(
            The guide says "should contain"?  What else could it contain?
          )
        end

        skip_if @health_card.nil?, 'Health card not successfully downloaded.'

        assert @health_card.include?('verifiableCredential'), 'Health card JSON must contain "VerifiableCredential" key.'
        assert @health_card['verifiableCredential'].kind_of?(Array), 'Health card verifiableCredential key must contain an array.'
        assert @health_card['verifiableCredential'].length, 'Health card must contain at least on verifiable credential'
        @verifiable_credentials_jws = @health_card['verifiableCredential']

        pass "Received #{@verifiable_credentials_jws.length} verifiable credential(s)."

      end

      valid_jws(index: '05')
      retrieve_jwks(index: '06')
      credential_header(index: '07')
      credential_payload(index: '08')
      credential_payload_fhir_validated(index: '09')


    end
  end
end
