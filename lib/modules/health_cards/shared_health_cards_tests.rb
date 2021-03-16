# frozen_string_literal: true

module Inferno
    module Sequence
      module SharedHealthCardsTests
        def self.included(klass)
          klass.extend(ClassMethods)
        end

        module ClassMethods
          def well_known(index:)
            test :well_known do
              metadata do
                id index
                name 'Well-known file available and contains required information'
                link 'https://smarthealth.cards/#protocol-details'
                description %(
                )
              end

              omit
  
            end
          end
          def valid_jws(index:)
            test :valid_jws do
              metadata do
                id index
                name 'Verifiable credentials contain valid JWT'
                link 'https://smarthealth.cards/#protocol-details'
                description %(
                )
              end

              omit
  
            end
          end
        end
      end
    end
  end
  