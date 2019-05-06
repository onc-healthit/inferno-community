
require_relative 'bdt_base'

module Inferno
  module Sequence
    class BDTAuthPatientLevelSequence < BDTBase

      group 'FIXME'

      title 'Auth Patient Level'

      description 'Kick-off request at the patient-level export endpoint'

      test_id_prefix 'Auth_patient_level'

      requires :token
      conformance_supports :CarePlan

      details %(
        Auth Patient Level
      )
      
      test 'patient-level export - requires authorization header' do
        metadata {
          id '01.1.0'
          link 'http://bulkdatainfo'
          desc %(
            The server should require authorization header
          )
          versions :r4
        }

        run_bdt('0.1.0')

      end
      test 'patient-level export - rejects expired token' do
        metadata {
          id '01.1.1'
          link 'http://bulkdatainfo'
          desc %(
            
          )
          versions :r4
        }

        run_bdt('0.1.1')

      end
      test 'patient-level export - rejects invalid token' do
        metadata {
          id '01.1.2'
          link 'http://bulkdatainfo'
          desc %(
            
          )
          versions :r4
        }

        run_bdt('0.1.2')

      end

    end
  end
end