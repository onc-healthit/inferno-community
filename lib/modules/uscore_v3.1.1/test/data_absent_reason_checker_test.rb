# frozen_string_literal: true

# NOTE: This is a generated file. Any changes made to this file will be
#       overwritten when it is regenerated

require_relative '../../../../test/test_helper'

describe Inferno::DataAbsentReasonChecker do
  class DataAbsentReasonCheckerTest
    include Inferno::DataAbsentReasonChecker

    attr_reader :instance

    def initialize
      @instance = Inferno::Models::TestingInstance.new
    end
  end

  describe '#check_for_data_absent_reasons' do
    it 'detects data absent extensions' do
      resource = FHIR::Patient.new(
        name: [{
          extension: [
            {
              url: 'http://hl7.org/fhir/StructureDefinition/data-absent-reason',
              valueCode: 'unknown'
            }
          ]
        }]
      )

      checker = DataAbsentReasonCheckerTest.new
      reply = OpenStruct.new(body: resource.to_json)

      checker.check_for_data_absent_reasons.call(reply)
      assert checker.instance.data_absent_extension_found
      refute checker.instance.data_absent_code_found
    end

    it 'detects data absent codes' do
      resource = FHIR::Condition.new(
        category: [{
          coding: [
            {
              system: 'http://terminology.hl7.org/CodeSystem/data-absent-reason',
              code: 'unknown'
            }
          ]
        }]
      )

      checker = DataAbsentReasonCheckerTest.new
      reply = OpenStruct.new(body: resource.to_json)

      checker.check_for_data_absent_reasons.call(reply)
      assert checker.instance.data_absent_code_found
      refute checker.instance.data_absent_extension_found
    end
  end
end
