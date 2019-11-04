# frozen_string_literal: true

require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTAuthSystemLevelSequence < BDTBase
      group 'FIXME'

      title 'Auth System Level'

      description 'Kick-off request at the system-level export endpoint'

      test_id_prefix 'Auth_system_level'

      requires :token
      conformance_supports :CarePlan

      details %(
        Auth System Level
      )

      test 'system-level export - requires authorization header' do
        metadata do
          id '01.0.0'
          link 'http://bulkdatainfo'
          description %(
            The server should require authorization header
          )
          versions :r4
        end

        run_bdt('0.0.0')
      end
      test 'system-level export - rejects expired token' do
        metadata do
          id '01.0.1'
          link 'http://bulkdatainfo'
          description %(

          )
          versions :r4
        end

        run_bdt('0.0.1')
      end
      test 'system-level export - rejects invalid token' do
        metadata do
          id '01.0.2'
          link 'http://bulkdatainfo'
          description %(

          )
          versions :r4
        end

        run_bdt('0.0.2')
      end
    end
  end
end
