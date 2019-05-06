
require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTAuthGroupLevelSequence < BDTBase

      group 'FIXME'

      title 'Auth Group Level'

      description 'Kick-off request at the group-level export endpoint'

      test_id_prefix 'Auth_group_level'

      requires :token
      conformance_supports :CarePlan

      details %(
        Auth Group Level
      )
      
      test 'group-level export - requires authorization header' do
        metadata {
          id '01.2.0'
          link 'http://bulkdatainfo'
          desc %(
            The server should require authorization header
          )
          versions :r4
        }

        run_bdt('0.2.0')

      end
      test 'group-level export - rejects expired token' do
        metadata {
          id '01.2.1'
          link 'http://bulkdatainfo'
          desc %(
            
          )
          versions :r4
        }

        run_bdt('0.2.1')

      end
      test 'group-level export - rejects invalid token' do
        metadata {
          id '01.2.2'
          link 'http://bulkdatainfo'
          desc %(
            
          )
          versions :r4
        }

        run_bdt('0.2.2')

      end

    end
  end
end