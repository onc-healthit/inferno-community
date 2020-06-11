# frozen_string_literal: true

module Inferno
  module Sequence
    class BulkCacheCheckSequence < SequenceBase
      title 'Multi-patient JWK Set URL Cache'
      description 'Demonstrate that the mult-patient server obeys the JWK Set URL cache expiration header.'

      test_id_prefix 'JSCC'

      requires :bulk_client_id, :bulk_jwks_url_auth, :bulk_encryption_method, :bulk_token_endpoint, :bulk_scope
      defines :bulk_access_token

      test 'Test to be implemented by v1.0' do
        metadata do
          id '01'
          link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#file-request'
          description %(
              Test description
          )
        end
      end
    end
  end
end
