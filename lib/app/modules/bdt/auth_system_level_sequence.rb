# frozen_string_literal: true

require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTAuthSystemLevelSequence < BDTBase
      title 'Auth System Level'

      description 'Kick-off request at the system-level export endpoint'

      test_id_prefix 'Auth_system_level'

      requires :bulk_url, :bulk_token_endpoint, :bulk_client_id, \
               :bulk_system_export_endpoint, :bulk_patient_export_endpoint, :bulk_group_export_endpoint, \
               :bulk_fastest_resource, :bulk_requires_auth, :bulk_since_param, :bulk_jwks_url_auth, :bulk_jwks_url_auth, \
               :bulk_public_key, :bulk_private_key

      details %(
        Auth System Level
      )

      test 'Requires authorization header' do
        metadata do
          id '01.0.0'
          link 'http://bulkdatainfo'
          description %(
            The server should require authorization header at the system-level export endpoint
          )
          versions :r4
        end

        run_bdt('0.0.0')
      end
      test 'Rejects expired token' do
        metadata do
          id '01.0.1'
          link 'http://bulkdatainfo'
          description %(
            The server should reject expired tokens at the system-level export endpoint
          )
          versions :r4
        end

        run_bdt('0.0.1')
      end
      test 'Rejects invalid token' do
        metadata do
          id '01.0.2'
          link 'http://bulkdatainfo'
          description %(
            The server should reject invalid tokens at the system-level export endpoint
          )
          versions :r4
        end

        run_bdt('0.0.2')
      end
    end
  end
end
