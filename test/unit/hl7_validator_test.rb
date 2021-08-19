# frozen_string_literal: true

require_relative '../test_helper'

describe Inferno::HL7Validator do
  before do
    @validator_url = 'http://example.com:8080'
    @validator = Inferno::HL7Validator.new(@validator_url)
  end

  describe 'Validating a good resource' do
    before do
      @resource = FHIR::CapabilityStatement.new
      @profile = FHIR::Definitions.resource_definition(@resource.resourceType).url
    end

    it "Shouldn't pass back any messages" do
      patient = FHIR::Patient.new
      stub_request(:post, "#{@validator_url}/validate")
        .with(
          query: { profile: 'http://hl7.org/fhir/StructureDefinition/Patient' },
          body: patient.source_contents
        )
        .to_return(status: 200, body: load_fixture('validator_good_response'))
      result = @validator.validate(patient, FHIR)

      assert_empty result[:errors]
      assert_empty result[:warnings]
      assert_empty result[:information]
    end

    it 'removes excluded errors' do
      outcome = load_fixture('hl7_validator_operation_outcome')

      stub_request(:post, "#{@validator_url}/validate")
        .with(
          query: { 'profile': @profile },
          body: @resource.source_contents
        )
        .to_return(
          status: 200,
          body: outcome
        )

      result = @validator.validate(@resource, FHIR, @profile)
      assert_equal 3, result[:errors].length
      assert_equal 1, result[:warnings].length
      assert_equal 4, result[:information].length
    end

    it 'adds Resource id error' do
      outcome = load_fixture('hl7_validator_operation_outcome')
      @resource.id = '1234567890123456789012345678901234567890123456789012345678901234567890'

      stub_request(:post, "#{@validator_url}/validate")
        .with(
          query: { 'profile': @profile },
          body: @resource.source_contents
        )
        .to_return(
          status: 200,
          body: outcome
        )

      result = @validator.validate(@resource, FHIR, @profile)
      assert(result[:errors].any? { |err| err.match?(/FHIR id value shall match Regex/) })
    end
  end

  describe 'Fetching the validator version' do
    it 'Should return the version string' do
      stub_request(:get, "#{@validator_url}/version")
        .to_return(status: 200, body: '5.0.11-SNAPSHOT')

      assert_equal '5.0.11-SNAPSHOT', @validator.version
    end

    it 'Should return nil if /version is not found' do
      stub_request(:get, "#{@validator_url}/version")
        .to_return(status: 404)
      assert_nil @validator.version
    end
  end

  describe 'Validating Resource ID' do
    before do
      @resource = FHIR::Patient.new
    end

    it 'catches Resource id longer than 64 characters' do
      @resource.id = '1234567890123456789012345678901234567890123456789012345678901234567890'
      result = @validator.validate_resource_id(@resource)

      refute result.empty?
      assert result.first.match?(/^Patient\.id: FHIR id value shall match Regex/)
    end

    it 'catches Resource id with invalid character' do
      @resource.id = '1234567890$'
      result = @validator.validate_resource_id(@resource)

      refute result.empty?
      assert result.first.match?(/^Patient\.id: FHIR id value shall match Regex/)
    end

    it 'catches Resource id in internal resource' do
      @resource.id = '1234567890123456789012345678901234567890123456789012345678901234567890'
      bundle = wrap_resources_in_bundle(@resource)
      bundle.id = '1234567890$'
      result = @validator.validate_resource_id(bundle)

      assert result.size == 2
    end

    it 'passes Resource without id' do
      result = @validator.validate_resource_id(@resource)

      assert result.empty?
    end

    it 'passes Resource with valid id' do
      @resource.id = 'A-123.b'
      result = @validator.validate_resource_id(@resource)

      assert result.empty?
    end
  end
end
