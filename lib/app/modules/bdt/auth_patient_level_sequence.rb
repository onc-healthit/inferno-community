# frozen_string_literal: true

require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTAuthPatientLevelSequence < BDTBase
      title 'Auth Patient Level'

      description 'Kick-off request at the patient-level export endpoint'

      test_id_prefix 'Auth_patient_level'

      requires :bulk_url, :bulk_token_endpoint, :bulk_client_id, \
               :bulk_system_export_endpoint, :bulk_patient_export_endpoint, :bulk_group_export_endpoint, \
               :bulk_fastest_resource, :bulk_requires_auth, :bulk_since_param, :bulk_jwks_url_auth, :bulk_jwks_url_auth, \
               :bulk_public_key, :bulk_private_key

      details %(
        Auth Patient Level
      )

      test 'Requires authorization header' do
        metadata do
          id '01.1.0'
          link 'http://bulkdatainfo'
          description %(
            The server should require authorization header at the patient-level export endpoint
          )
          versions :r4
        end

        run_bdt('0.1.0')
      end
      test 'Rejects expired token' do
        metadata do
          id '01.1.1'
          link 'http://bulkdatainfo'
          description %(
            The server should reject expired tokens at the patient-level export endpoint
          )
          versions :r4
        end

        run_bdt('0.1.1')
      end
      test 'Rejects invalid token' do
        metadata do
          id '01.1.2'
          link 'http://bulkdatainfo'
          description %(
            The server should reject invalid tokens at the patient-level export endpoint
          )
          versions :r4
        end

        run_bdt('0.1.2')
      end
    end
  end
end
