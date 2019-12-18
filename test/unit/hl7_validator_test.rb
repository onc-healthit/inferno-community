# frozen_string_literal: true

require_relative '../test_helper'
require 'byebug'

describe Inferno::HL7Validator do
  before do
    @validator_url = 'http://example.com:8080'
    @validator = Inferno::HL7Validator.new(@validator_url)
  end

  describe 'Validating a good resource' do
    it 'Shouldn\'t pass back any messages' do
      patient = FHIR::Patient.new
      stub_request(:post, "#{@validator_url}/validate")
        .with(query: { profile: 'http://hl7.org/fhir/StructureDefinition/Patient' })
        .to_return(status: 200, body: load_fixture('validator_good_response'))
      result = @validator.validate(patient, FHIR)

      assert_empty result[:errors]
      assert_empty result[:warnings]
    end
  end

  describe 'Validating a bad resource' do
    it 'Should pass back an error message' do
      patient = FHIR::Patient.new(gender: 'robot')

      stub_request(:post, "#{@validator_url}/validate")
        .with(query: { profile: 'http://hl7.org/fhir/StructureDefinition/Patient' })
        .to_return(status: 200, body: load_fixture('validator_bad_response'))
      result = @validator.validate(patient, FHIR)

      assert_equal 2, result[:errors].size
      assert_equal 2, result[:warnings].size
    end
  end
end
