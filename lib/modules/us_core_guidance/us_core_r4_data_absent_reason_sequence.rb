# frozen_string_literal: true

module Inferno
  module Sequence
    class USCoreR4DataAbsentReasonSequence < SequenceBase
      title 'Missing Data Tests'

      description %(
        Verify that the server is capable of representing missing data
      )

      details %(
        The [US Core Missing Data
        Guidance](http://hl7.org/fhir/us/core/general-guidance.html#missing-data)
        gives instructions on how to represent various types of missing data.

        In the previous resource tests, each resource returned from the server
        was checked for the presence of missing data. These tests will pass if
        the specified method of representing missing data was observed in the
        earlier tests.
      )

      test_id_prefix 'USCDAR'

      test :extension do
        metadata do
          id '01'
          name 'Server represents missing data with the DataAbsentReason Extension'
          link 'http://hl7.org/fhir/us/core/general-guidance.html#missing-data'
          description %(
            For non-coded data elements, servers shall use the DataAbsentReason
            Extension to represent missing data in a required field
          )
          versions :r4
        end

        skip_unless @instance.data_absent_extension_found,
                    'No resources using the DataAbsentReason Extension have been found'
      end

      test :code do
        metadata do
          id '02'
          name 'Server represents missing data with the DataAbsentReason CodeSystem'
          link 'http://hl7.org/fhir/us/core/general-guidance.html#missing-data'
          description %(
            For coded data elements with example, preferred, or extensible
            binding strengths to ValueSets which do not include an appropriate
            "unknown" code, servers shall use the "unknown" code from the
            DataAbsentReason CodeSystem.
          )
          versions :r4
        end

        skip_unless @instance.data_absent_code_found,
                    'No resources using the DataAbsentReason CodeSystem have been found'
      end
    end
  end
end
