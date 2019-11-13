# frozen_string_literal: true

require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTAuthGroupLevelSequence < BDTBase
      title 'Auth Group Level'

      description 'Kick-off request at the group-level export endpoint'

      test_id_prefix 'Auth_group_level'

      requires :bulk_url, :bulk_token_endpoint, :bulk_client_id, \
               :bulk_system_export_endpoint, :bulk_patient_export_endpoint, :bulk_group_export_endpoint, \
               :bulk_fastest_resource, :bulk_requires_auth, :bulk_since_param, :bulk_jwks_url_auth, :bulk_jwks_url_auth, \
               :bulk_public_key, :bulk_private_key

      details %(
        Auth Group Level
      )

      test 'Requires authorization header' do
        metadata do
          id '01.2.0'
          link 'http://bulkdatainfo'
          description %(
            The server should require authorization header at the group-level export endpoint
          )
          versions :r4
        end

        run_bdt('0.2.0')
      end
      test 'Rejects expired token' do
        metadata do
          id '01.2.1'
          link 'http://bulkdatainfo'
          description %(
            The server should reject expired tokens at the group-level export endpoint
          )
          versions :r4
        end

        run_bdt('0.2.1')
      end
      test 'Rejects invalid token' do
        metadata do
          id '01.2.2'
          link 'http://bulkdatainfo'
          description %(
            The server should reject invalid tokens at the group-level export endpoint
          )
          versions :r4
        end

        run_bdt('0.2.2')
      end
    end
  end
end
